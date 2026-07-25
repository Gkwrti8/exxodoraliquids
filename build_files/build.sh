#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

echo "==> Installing Build Dependencies"
# We must install kwin-devel and cmake to build the effect from scratch
dnf5 install -y git cmake gcc-c++ extra-cmake-modules kwin-devel kf6-kcoreaddons-devel kf6-kwindowsystem-devel qt6-qtbase-devel libplasma-devel

echo "==> Compiling Liquid Glass directly from source"
git clone https://github.com/4v3ngR/kwin-effects-glass.git /tmp/kwin-effects-glass
cd /tmp/kwin-effects-glass

# Configure, build, and install into the system directories
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build
cmake --install build
