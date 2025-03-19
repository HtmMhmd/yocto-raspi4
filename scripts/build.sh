#!/bin/bash

set -e

# Directory settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_DIR}/build"

# Yocto settings
YOCTO_RELEASE="dunfell"
MACHINE="raspberrypi4"

echo "=== Yocto CI/CD Build Script ==="
echo "Project dir: ${PROJECT_DIR}"
echo "Building for: ${MACHINE}"
echo "Yocto release: ${YOCTO_RELEASE}"

# Create build directory
mkdir -p ${BUILD_DIR}
cd ${PROJECT_DIR}

# Download Poky (Yocto)
if [ ! -d "poky" ]; then
  echo "Cloning poky (${YOCTO_RELEASE})..."
  git clone -b ${YOCTO_RELEASE} git://git.yoctoproject.org/poky.git
fi

# Download Raspberry Pi BSP layer
if [ ! -d "meta-raspberrypi" ]; then
  echo "Cloning meta-raspberrypi (${YOCTO_RELEASE})..."
  git clone -b ${YOCTO_RELEASE} git://git.yoctoproject.org/meta-raspberrypi.git
fi

# Download OpenEmbedded layer
if [ ! -d "meta-openembedded" ]; then
  echo "Cloning meta-openembedded (${YOCTO_RELEASE})..."
  git clone -b ${YOCTO_RELEASE} git://git.openembedded.org/meta-openembedded
fi

# Initialize build environment
source poky/oe-init-build-env ${BUILD_DIR}

# Configure build
echo "Configuring build..."

# Add required layers
bitbake-layers add-layer "${PROJECT_DIR}/meta-raspberrypi"
bitbake-layers add-layer "${PROJECT_DIR}/meta-openembedded/meta-oe"
bitbake-layers add-layer "${PROJECT_DIR}/meta-openembedded/meta-python"
bitbake-layers add-layer "${PROJECT_DIR}/meta-openembedded/meta-networking"
bitbake-layers add-layer "${PROJECT_DIR}/meta-custom"

# Configure local.conf
cat >> conf/local.conf << EOF
# Machine Selection
MACHINE = "${MACHINE}"

# Enable systemd
INIT_MANAGER = "systemd"

# Raspberry Pi specific settings
ENABLE_UART = "1"
RPI_USE_U_BOOT = "1"
DISTRO_FEATURES_append = " wifi"

# Runtime package management
PACKAGE_CLASSES ?= "package_ipk"

# Additional disk space
IMAGE_ROOTFS_EXTRA_SPACE = "1048576"

# Remove X11 dependencies
DISTRO_FEATURES_remove = "x11 wayland"
EOF

# Build the minimal SSH image
echo "Starting build..."
bitbake minimal-ssh-image

echo "Build complete! Your image is at: ${BUILD_DIR}/tmp/deploy/images/${MACHINE}/"
