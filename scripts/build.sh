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

# Add layers to bblayers.conf

# 1. meta-raspberrypi

# •  Use: Essential for tailoring the Yocto build to the Raspberry Pi 4 hardware.
# •  Need: Without it, your image won't boot or function correctly on the Raspberry Pi 4.
# •  Packages Provided:
#   •  Bootloader: U-Boot configuration specific to Raspberry Pi.
#   •  Kernel: Kernel configuration (.config fragments) and patches optimized for the Raspberry Pi's Broadcom SoC.
#   •  Device Tree Overlays (DTOs): Hardware configuration description for Raspberry Pi (like camera, display, etc.).
#   •  Raspberry Pi Firmware: Binary files (bootcode.bin, start.elf, fixup.dat) required for the Raspberry Pi's initial boot process.
#   •  Drivers: Kernel modules for Raspberry Pi-specific peripherals (e.g., camera, Wi-Fi, Bluetooth).
#   •  Configuration Files: config.txt (for boot options) and other Raspberry Pi-specific configurations.

# 2. meta-openembedded/meta-oe

# •  Use: Provides a broad base of general-purpose software packages, libraries, and utilities for building a functioning Linux system.
# •  Need: Essential for a minimum, functioning operating system. Without it, you wouldn't have basic command-line tools, system utilities, and core libraries.
# •  Packages Provided:
#   •  System Utilities: coreutils (ls, cp, rm, etc.), findutils, procps (ps, top), net-tools (ifconfig, netstat).
#   •  Libraries: glibc (C standard library), libstdc++ (C++ standard library), zlib (compression), openssl (cryptography).
#   •  Networking: dhcpcd (DHCP client), iptables (firewall), openssh (SSH server/client).
#   •  Text Editors: nano, vim (often you would not want to include vim in a minimal image, or you would be including a minimal version of it).
#   •  Build Tools: make, autoconf, automake (but often these would be removed from the final image).

# 3. meta-openembedded/meta-python

# •  Use: Enables support for Python.
# •  Need: Needed if your applications or system management tools rely on Python scripting.
# •  Packages Provided:
#   •  Python Interpreters: Python 2 and/or Python 3 interpreters.
#   •  Python Libraries: setuptools, pip, virtualenv, and numerous other Python packages (e.g., requests, numpy, scipy).

# 4. meta-openembedded/meta-networking

# •  Use: Adds networking-related software and configuration options.
# •  Need: Without it, you would have limited network connectivity options.
# •  Packages Provided:
#   •  Network Managers: NetworkManager, connman.
#   •  Wireless Tools: wpa_supplicant (Wi-Fi), bluez (Bluetooth).
#   •  Network Utilities: tcpdump, traceroute, ethtool, iwconfig.
#   •  Network Protocols: avahi (zeroconf), samba (Windows file sharing).

# 5. meta-openembedded/meta-filesystems

# •  Use: Provides support for various filesystems.
# •  Need: Enables the system to work with different filesystems.
# •  Packages Provided:
#   •  Filesystem Utilities: mkfs (filesystem creation tools), fsck (filesystem check and repair), e2fsprogs (ext2/ext3/ext4 filesystem tools), dosfstools (FAT filesystem tools), ntfs-3g (NTFS filesystem support).
#   •  Filesystem Drivers: Kernel modules for supporting various filesystems (e.g., fuse).

# 6. meta-openembedded/meta-multimedia

# •  Use: Enables multimedia capabilities.
# •  Need: Required if you want to play audio or video files, or use graphics libraries.
# •  Packages Provided:
#   •  Audio Codecs: alsa-lib, pulseaudio, lame (MP3 encoder), vorbis-tools (Ogg Vorbis).
#   •  Video Codecs: x264 (H.264 encoder), x265 (H.265 encoder), ffmpeg (multimedia framework).
#   •  Graphics Libraries: libpng, libjpeg, freetype (font rendering), mesa (OpenGL implementation).
#   •  Multimedia Frameworks: gstreamer, vlc.

# 7. meta-virtualization

# •  Use: Enables Virtualization technologies
# •  Need: Support for running Docker. Enables to install of containerized packages on image
# •  Packages Provided:
#   •  Docker: Docker Engine, Docker CLI
#   •  Containers: Containerd, Runc


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

# Enable audio support
DISTRO_FEATURES_append = " alsa pulseaudio"
MACHINE_FEATURES_append = " alsa"

# License configuration
LICENSE_FLAGS_WHITELIST = "commercial"

# Docker requirements
DISTRO_FEATURES_append = " virtualization"
KERNEL_FEATURES_append = " features/netfilter/netfilter.scc"
KERNEL_FEATURES_append = " features/cgroups/cgroups.scc"

# Package management configuration
# Output/Effect: The build system will generate packages in the IPK format.
PACKAGE_CLASSES ?= "package_ipk"
EXTRA_IMAGE_FEATURES += "package-management"

# Additional disk space
IMAGE_ROOTFS_EXTRA_SPACE = "1048576"

EOF

# Build the minimal SSH image
echo "Starting build..."
bitbake minimal-ssh-image

echo "Build complete! Your image is at: ${BUILD_DIR}/tmp/deploy/images/${MACHINE}/"
