#!/bin/bash

# If you're a human, don't run this script on your daily machine.
# This script is for GitHub Actions and makes a bunch of assumptions you dear human will struggle with.
# This script is actively hostile against you human, you have been warned. :3

if [[ -z "$CI" ]]; then
    >&2 echo "Error, this script is only to be run from CI."
    exit 1
fi

set -eu

DEB_OS="${1?}" # Expecting "debian" or "ubuntu"
DEB_ARCH="${2?}" # Expecting "amd64" or "arm64" etc

# Ubuntu does not do multiarch correctly, does not document this at all etc,
# so we just need a bunch of dirty hacks to do it Their Way. GitHub Actions makes this even worse.
# Technically we don't need to do this with a native build, but it also doesn't hurt.
if [[ "$DEB_OS" == "ubuntu" ]]; then
    2>&1 echo "Patching Ubuntu apt sources for multiarch"
    # Default entries do not pin an arch, fix that
    sudo sed -E 's/^deb (http|mirror)/deb [arch=amd64] \1/' -i '/etc/apt/sources.list'
    # arm64 is on a completely different mirror structure, add that pinned to arm64
    echo 'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ jammy main restricted' | sudo tee /etc/apt/sources.list.d/arm64.list
    echo 'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ jammy-updates main restricted' | sudo tee -a /etc/apt/sources.list.d/arm64.list
fi

# From here on normal Debian multiarch logic applies
2>&1 echo "Enabling multiarch"
sudo dpkg --add-architecture $DEB_ARCH
sudo apt-get update
sudo apt-get install -y \
    libssl3:$DEB_ARCH \
    libpam0g:$DEB_ARCH \
    libudev1:$DEB_ARCH
