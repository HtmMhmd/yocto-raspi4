#!/bin/bash

set -e

# Directory settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_DIR}/build"

# Yocto settings
YOCTO_RELEASE="dunfell"
MACHINE="raspberrypi4-64"

echo "=== Yocto CI/CD Build Script ==="
echo "Project dir: ${PROJECT_DIR}"
echo "Building for: ${MACHINE}"
echo "Yocto release: ${YOCTO_RELEASE}"

# Create build directory
mkdir -p ${BUILD_DIR}
cd ${PROJECT_DIR}

# Configure git for better reliability
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 300
git config --global core.compression 9

# Function to attempt git clone with retries
try_clone() {
    local url=$1
    local dir=$2
    local branch=$3
    local attempt=1
    local max_attempts=3

    if [ ! -d "$dir" ]; then
        while [ $attempt -le $max_attempts ]; do
            echo "Cloning $dir (attempt $attempt/$max_attempts)..."
            if git clone -b $branch $url $dir --verbose --progress; then
                echo "Successfully cloned $dir"
                return 0
            else
                if [ $attempt -lt $max_attempts ]; then
                    echo "Clone failed, retrying in 5 seconds..."
                    sleep 5
                else
                    echo "Failed to clone after $max_attempts attempts"
                    return 1
                fi
            fi
            attempt=$((attempt+1))
        done
    else
        echo "$dir already exists, skipping clone"
    fi
}

# Download Poky (Yocto) with retries
try_clone "https://git.yoctoproject.org/poky" "poky" "${YOCTO_RELEASE}" || {
    # Try backup mirror if primary fails
    echo "Trying backup mirror for poky..."
    try_clone "https://github.com/yoctoproject/poky.git" "poky" "${YOCTO_RELEASE}" || exit 1
}

# Download Raspberry Pi BSP layer with retries
try_clone "https://git.yoctoproject.org/meta-raspberrypi" "meta-raspberrypi" "${YOCTO_RELEASE}" || {
    # Try backup mirror if primary fails
    echo "Trying backup mirror for meta-raspberrypi..."
    try_clone "https://github.com/agherzan/meta-raspberrypi.git" "meta-raspberrypi" "${YOCTO_RELEASE}" || exit 1
}

# Download OpenEmbedded layer with retries
try_clone "https://git.openembedded.org/meta-openembedded" "meta-openembedded" "${YOCTO_RELEASE}" || {
    # Try backup mirror if primary fails
    echo "Trying backup mirror for meta-openembedded..."
    try_clone "https://github.com/openembedded/meta-openembedded.git" "meta-openembedded" "${YOCTO_RELEASE}" || exit 1
}

# Download meta-virtualization for Docker support with retries
try_clone "https://git.yoctoproject.org/meta-virtualization" "meta-virtualization" "${YOCTO_RELEASE}" || {
    # Try backup mirror if primary fails
    echo "Trying backup mirror for meta-virtualization..."
    try_clone "https://github.com/yoctoproject/meta-virtualization.git" "meta-virtualization" "${YOCTO_RELEASE}" || exit 1
}

# Initialize build environment
source poky/oe-init-build-env ${BUILD_DIR}

# Configure build
echo "Configuring build..."

# Add required layers
bitbake-layers add-layer "${PROJECT_DIR}/meta-raspberrypi"
bitbake-layers add-layer "${PROJECT_DIR}/meta-openembedded/meta-oe"
bitbake-layers add-layer "${PROJECT_DIR}/meta-openembedded/meta-python"
bitbake-layers add-layer "${PROJECT_DIR}/meta-openembedded/meta-networking"
bitbake-layers add-layer "${PROJECT_DIR}/meta-openembedded/meta-filesystems"
bitbake-layers add-layer "${PROJECT_DIR}/meta-openembedded/meta-multimedia"
bitbake-layers add-layer "${PROJECT_DIR}/meta-virtualization"
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

# Enable camera support
DISTRO_FEATURES_append = " camera"
GPU_MEM = "128"
VIDEO_CAMERA = "1"
ENABLE_DWC2_PERIPHERAL = "1"
CAMERA_ENABLE_CAMERA = "1"

# Docker requirements
DISTRO_FEATURES_append = " virtualization"
KERNEL_FEATURES_append = " features/netfilter/netfilter.scc"
KERNEL_FEATURES_append = " features/cgroups/cgroups.scc"

# Package management configuration
PACKAGE_CLASSES ?= "package_ipk"
EXTRA_IMAGE_FEATURES += "package-management"

# Additional disk space
IMAGE_ROOTFS_EXTRA_SPACE = "1048576"

# Remove X11 dependencies
DISTRO_FEATURES_remove = "x11 wayland"
EOF

# Build the minimal SSH image
echo "Starting build..."
bitbake minimal-ssh-image

echo "Build complete! Your image is at: ${BUILD_DIR}/tmp/deploy/images/${MACHINE}/"
