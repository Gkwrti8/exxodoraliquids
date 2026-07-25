#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

echo "==> Enabling kwin-effects-glass COPR repository"
curl -Lo /etc/yum.repos.d/_copr_ama1470-kwin-effects-glass.repo \
    https://copr.fedorainfracloud.org/coprs/ama1470/kwin-effects-glass/repo/fedora-$(rpm -E %fedora)/ama1470-kwin-effects-glass-fedora-$(rpm -E %fedora).repo

echo "==> Installing Core System Packages"
dnf5 install -y kwin-effects-glass
dnf5 install -y git cmake gcc-c++ extra-cmake-modules kf6-kcoreaddons-devel kf6-kwindowsystem-devel qt6-qtbase-devel libplasma-devel
