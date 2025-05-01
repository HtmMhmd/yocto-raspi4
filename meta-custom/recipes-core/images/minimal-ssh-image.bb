SUMMARY = "Minimal SSH image with systemd and Docker for Raspberry Pi 4 (64-bit)"
DESCRIPTION = "A minimal image that has SSH, systemd, and Docker enabled for Raspberry Pi 4 (64-bit)"

LICENSE = "MIT"

inherit core-image

# Systemd Integration

# •  DISTRO_FEATURES += " systemd": Adds the systemd feature to the distribution's feature list. This signals to the build system that you want to use systemd as the init system.

# •  VIRTUAL-RUNTIME_init_manager = "systemd": Specifies systemd as the system's init manager. The VIRTUAL-RUNTIME_init_manager variable is a standard Yocto variable used to select the init system implementation.

# •  VIRTUAL-RUNTIME_initscripts = "systemd-compat-units": This provides compatibility with SysVinit scripts by converting them into systemd units. This helps ensure that older software that relies on SysVinit-style startup scripts can still function properly under systemd.

# •  DISTRO_FEATURES_BACKFILL_CONSIDERED = "sysvinit": This line hints to the build system to consider sysvinit as a fallback for compatibility but prioritize systemd.

# Use systemd
DISTRO_FEATURES += " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"
DISTRO_FEATURES_BACKFILL_CONSIDERED = "sysvinit"


# ====================================================================================


# Package Installation (Core Functionality)

#  •  IMAGE_INSTALL = " \ ... ": Defines a list of packages and package groups that will be included in the final image. Let's look at each item:

#  •  packagegroup-core-boot: A package group that installs essential boot-related components,
#     like the bootloader (often GRUB or syslinux) and necessary configuration files for booting the system. 
#     In the case of Raspberry Pi, this often includes files necessary to load the kernel.

#  •  packagegroup-core-ssh-openssh: A package group containing the OpenSSH server and client, 

#  •  kernel-modules: Installs the kernel modules that are built for your kernel. 

#  •  systemd: Installs the systemd init system itself and its core utilities.

#  •  systemd-networkd-configuration: This package provides the necessary configuration for systemd-networkd, 
#    a systemd-managed network configuration service.

#  •  docker-ce: The Docker CE (Community Edition) package, which provides the Docker engine and command-line tools.
#  •  git: The Git version control system, which is useful for managing source code and repositories.
#  •  opkg: The Open Package Management system, which is a lightweight package manager often used in embedded systems.


# Base packages for 64-bit support
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

# Audio/Voice support packages
IMAGE_INSTALL += " \
    alsa-utils \
    alsa-plugins \
    alsa-tools \
    pulseaudio \
    pulseaudio-server \
    pulseaudio-misc \
    libasound \
    libasound-module-pcm-pulse \
    mpg123 \
"

#   •  v4l-utils: Installs Video4Linux2 (V4L2) utilities. V4L2 is a Linux API for video capture devices (like cameras). 
#      These utilities provide tools for controlling and testing cameras.

#   •  libcamera: Modern camera support library aimed to replace V4l2 in the future.


# Camera support packages
IMAGE_INSTALL += " \
    v4l-utils \
    libcamera \
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
"

#   •  wpa-supplicant: Installs the WPA supplicant, which is responsible for connecting to Wi-Fi networks using WPA/WPA2/WPA3 encryption.

#   •  iw: Installs the iw command-line utility for configuring and managing wireless network interfaces.

#   •  linux-firmware-rpidistro-bcm43430: Includes the firmware for the Broadcom BCM43430 Wi-Fi chip, commonly found in Raspberry Pi boards.

#   •  linux-firmware-rpidistro-bcm43455(the one used in my raspi): Includes the firmware for the Broadcom BCM43455 Wi-Fi chip, another common Wi-Fi chip used in Raspberry Pi boards. 
#      The use of both ensures that firmware is available regardless of which of these two chips are available on board.

# WiFi support - use available packages
IMAGE_INSTALL += " \
    wpa-supplicant \
    iw \
    linux-firmware-rpidistro-bcm43430 \
    linux-firmware-rpidistro-bcm43455 \
"

# ====================================================================================

# Extra Image Features

#   •  EXTRA_IMAGE_FEATURES = " \ ... ": Enables extra features for the image.

#   •  ssh-server-openssh: Automatically configures the OpenSSH server to start on boot.

#   •  debug-tweaks: Enables various debugging features, such as setting a blank root password.

#   •  package-management: Includes the necessary files and configurations for package management (using opkg in this case).

# Enable SSH and empty root password
EXTRA_IMAGE_FEATURES = " \
    ssh-server-openssh \
    debug-tweaks \
    package-management \
"

# ====================================================================================

# Package Removal

# Remove unnecessary packages(This is often removed to keep the image size down)
IMAGE_INSTALL_remove = " \
    kernel-devicetree \
"


# ====================================================================================
# Image Size Configuration


# Image size
IMAGE_OVERHEAD_FACTOR = "1.3"
IMAGE_ROOTFS_SIZE ?= "16384"
IMAGE_ROOTFS_EXTRA_SPACE = "9097152"


# ====================================================================================

# Raspberry Pi configuration
ENABLE_UART = "1"


# Image Output Format

VIDEO_CAMERA = "1"

# Ensure the wic image is created
IMAGE_FSTYPES += "wic.bz2 wic.bmap"
