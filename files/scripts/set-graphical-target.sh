#!/usr/bin/env bash
# Exit on any error so a broken step fails the build instead of shipping silently.
set -oue pipefail

# Boot into the graphical login (cosmic-greeter) instead of a text console.
systemctl set-default graphical.target
