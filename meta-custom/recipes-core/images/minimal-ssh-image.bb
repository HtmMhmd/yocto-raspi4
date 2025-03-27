SUMMARY = "Minimal SSH image with systemd and Docker for Raspberry Pi 4"
DESCRIPTION = "A minimal image that has SSH, systemd, and Docker enabled"

LICENSE = "MIT"

inherit core-image

# Use systemd
DISTRO_FEATURES += " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"
DISTRO_FEATURES_BACKFILL_CONSIDERED = "sysvinit"

# Base packages
IMAGE_INSTALL = " \
    packagegroup-core-boot \
    packagegroup-core-ssh-openssh \
    kernel-modules \
    u-boot \
    systemd \
    systemd-networkd-configuration \
    docker-ce \
    git \
    opkg \
"

# WiFi support - use available packages
IMAGE_INSTALL += " \
    wpa-supplicant \
    iw \
    linux-firmware-rpidistro-bcm43430 \
"

# Enable SSH and empty root password
EXTRA_IMAGE_FEATURES = " \
    ssh-server-openssh \
    debug-tweaks \
    package-management \
"

# Remove unnecessary packages
IMAGE_INSTALL_remove = " \
    kernel-devicetree \
"

# Image size
IMAGE_OVERHEAD_FACTOR = "1.3"
IMAGE_ROOTFS_SIZE ?= "16384"
IMAGE_ROOTFS_EXTRA_SPACE = "2097152"

# Raspberry Pi configuration
ENABLE_UART = "1"

# Ensure the wic image is created
IMAGE_FSTYPES += "wic.bz2 wic.bmap"
