#!/bin/bash

set -euo pipefail
set -x
trap 'rc=$?; echo "ERROR: command '\''$BASH_COMMAND'\'' exited with status $rc on line ${LINENO}"; exit $rc' ERR

# Copy the contents of system_files/ of the git repo to /
if [ -d "/ctx/system_files" ]; then
  cp -avf "/ctx/system_files"/. /
else
  echo "WARNING: /ctx/system_files does not exist; skipping copy"
fi

echo "==> Installing Build Dependencies"
# Pick package manager (dnf5 if present, otherwise dnf)
if command -v dnf5 >/dev/null 2>&1; then
  PKG=dnf5
elif command -v dnf >/dev/null 2>&1; then
  PKG=dnf
else
  echo "ERROR: neither dnf5 nor dnf found on PATH; install dnf or run dependency installation manually" >&2
  exit 1
fi

$PKG install -y \
    git cmake gcc-c++ extra-cmake-modules \
    kwin-devel plasma-workspace-devel libplasma-devel \
    qt6-qtbase-devel qt6-qtbase-private-devel \
    kf6-kcoreaddons-devel kf6-kwindowsystem-devel kf6-knotifications-devel \
    kf6-kio-devel kf6-kcrash-devel kf6-ki18n-devel kf6-kguiaddons-devel \
    kf6-kglobalaccel-devel kf6-kcmutils-devel kf6-kconfigwidgets-devel \
    kf6-kdeclarative-devel kdecoration-devel \
    libepoxy-devel wayland-devel libdrm-devel

echo "==> Compiling Liquid Glass directly from source"
TMP_DIR=/tmp/kwin-effects-glass
rm -rf "$TMP_DIR"
git clone https://github.com/4v3ngR/kwin-effects-glass.git "$TMP_DIR"
cd "$TMP_DIR"

# Configure, build, and install into the system directories
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build -- -j"$(nproc)"
cmake --install build

echo "==> Preparing to sign image"
# Ensure cosign is available
if ! command -v cosign >/dev/null 2>&1; then
  echo "ERROR: cosign not found on PATH; install cosign before signing" >&2
  exit 1
fi

# Preferred: provide COSIGN_PRIVATE_KEY_BASE64 as a base64-encoded PEM secret
# Fallback: COSIGN_PRIVATE_KEY may contain either literal PEM (with newlines) or escaped \n sequences.
SIGN_KEY_FILE=""
if [ -n "${COSIGN_PRIVATE_KEY_BASE64:-}" ]; then
  echo "Decoding COSIGN_PRIVATE_KEY_BASE64 to cosign.key"
  printf '%s' "${COSIGN_PRIVATE_KEY_BASE64}" | base64 --decode > cosign.key
  SIGN_KEY_FILE=cosign.key
elif [ -n "${COSIGN_PRIVATE_KEY:-}" ]; then
  echo "Writing COSIGN_PRIVATE_KEY to cosign.key (detecting escaped newlines)"
  # If the secret contains escaped \n sequences, expand them; otherwise write as-is.
  if printf '%s' "${COSIGN_PRIVATE_KEY}" | grep -q '\\n'; then
    printf '%b\n' "${COSIGN_PRIVATE_KEY}" > cosign.key
  else
    printf '%s\n' "${COSIGN_PRIVATE_KEY}" > cosign.key
  fi
  SIGN_KEY_FILE=cosign.key
fi

if [ -n "${SIGN_KEY_FILE}" ]; then
  chmod 600 "${SIGN_KEY_FILE}"
  echo "Signing image with key file ${SIGN_KEY_FILE}"
  cosign sign -y --key "${SIGN_KEY_FILE}" "${IMAGE_REGISTRY}/${IMAGE_NAME}@${DIGEST}"
else
  # Last resort: try env:// if you really injected the full PEM with literal newlines into COSIGN_PRIVATE_KEY
  if [ -n "${COSIGN_PRIVATE_KEY:-}" ]; then
    echo "No key file prepared; attempting env://COSIGN_PRIVATE_KEY"
    cosign sign -y --key env://COSIGN_PRIVATE_KEY "${IMAGE_REGISTRY}/${IMAGE_NAME}@${DIGEST}"
  else
    echo "WARNING: no COSIGN_PRIVATE_KEY_BASE64 or COSIGN_PRIVATE_KEY provided; skipping signing"
  fi
fi
