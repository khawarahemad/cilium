#!/usr/bin/env bash

# Copyright Authors of Cilium
# SPDX-License-Identifier: Apache-2.0

set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

packages=(
  # Bash completion for Cilium
  bash-completion
  # Additional misc runtime dependencies
  iproute2
  iptables
  ipset
  kmod
  ca-certificates
  libatomic1
  jq
)

# The apt stack, followed by the libraries that become orphaned once apt is
# removed.
# This list of apt dependencies corresponds to the ubuntu 26.04 package graph,
# it will need to be updated on base ubuntu image upgrades.
purge_packages=(
  # Package manager.
  apt
  libapt-pkg7.0
  # libapt-pkg compression backends, orphaned once apt is gone.
  liblz4-1
  libxxhash0
  # Repository signature verification, orphaned with apt.
  gpgv
  ubuntu-keyring
  # gpgv private dependencies, orphaned with it.
  libgcrypt20
  libgpg-error0
)

export DEBIAN_FRONTEND=noninteractive

apt-get update

# tzdata is one of the dependencies and a timezone must be set
# to avoid interactive prompt when it is being installed
ln -fs /usr/share/zoneinfo/UTC /etc/localtime

# Update ubuntu packages to the most recent versions. Bump FORCE_BUILD in the
# Dockerfile to force this to re-run for stale images.
apt-get upgrade -y

apt-get install -y --no-install-recommends "${packages[@]}"

apt-get purge --auto-remove
apt-get clean

# Purge the apt package manager and the libraries it is the sole consumer of.
# This is the last apt-based step: once apt is gone, no further apt-get steps can
# run, either here or downstream. dpkg is intentionally kept.
dpkg --purge "${purge_packages[@]}"

# Drop apt's leftover state directories.
rm -rf \
  /etc/apt \
  /var/lib/apt \
  /var/log/apt \
  /var/cache/apt
