#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

echo "==> Installing Build Dependencies"
# Full dependency list per the kwin-effects-glass README (Fedora 41/42, Wayland build)
dnf5 install -y \
    git cmake gcc-c++ extra-cmake-modules \
    kwin-devel plasma-workspace-devel libplasma-devel \
    qt6-qtbase-devel qt6-qtbase-private-devel \
    kf6-kcoreaddons-devel kf6-kwindowsystem-devel kf6-knotifications-devel \
    kf6-kio-devel kf6-kcrash-devel kf6-ki18n-devel kf6-kguiaddons-devel \
    kf6-kglobalaccel-devel kf6-kcmutils-devel kf6-kconfigwidgets-devel \
    kf6-kdeclarative-devel kdecoration-devel \
    libepoxy-devel wayland-devel libdrm-devel

echo "==> Compiling Liquid Glass directly from source"
git clone https://github.com/4v3ngR/kwin-effects-glass.git /tmp/kwin-effects-glass
cd /tmp/kwin-effects-glass

# Configure, build, and install into the system directories
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build
cmake --install build
