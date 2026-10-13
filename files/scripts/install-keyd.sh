#!/usr/bin/env bash
# Build and install keyd (system-wide key remapper) from a pinned release.
# Its config comes from files/keyd/default.conf -> /etc/keyd/default.conf.
set -oue pipefail

KEYD_VERSION="v2.6.0"

workdir="$(mktemp -d)"
git clone --depth 1 --branch "${KEYD_VERSION}" https://github.com/rvaiya/keyd.git "${workdir}/keyd"
cd "${workdir}/keyd"
make
# PREFIX=/usr puts the binary and keyd.service in the image's /usr;
# FORCE_SYSTEMD=1 because systemd isn't running inside the build container.
make install PREFIX=/usr FORCE_SYSTEMD=1
cd /
rm -rf "${workdir}"
