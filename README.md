# Yocto CI/CD for Raspberry Pi 4 (64-bit)

<img alt="Yocto Project" src="https://img.shields.io/badge/Yocto-Project-blue.svg">
<img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg">
<img alt="Docker" src="https://img.shields.io/badge/Docker-Supported-blue.svg">
<img alt="Raspberry Pi" src="https://img.shields.io/badge/RaspberryPi-64bit-red.svg">
<img alt="GitHub Actions" src="https://img.shields.io/badge/CI/CD-GitHub_Actions-green.svg">

This repository contains a minimal Yocto build configuration for Raspberry Pi 4 (64-bit) with:
- SSH enabled
- systemd as init system
- Docker container runtime
- GitHub Actions CI/CD pipeline

## Project Structure and Components

### 1. Build Script (`scripts/build.sh`)
- Automates the Yocto build environment setup
- Downloads required Yocto layers (poky, meta-raspberrypi, meta-openembedded)
- Configures the build with systemd and SSH
- Runs the bitbake process to build the image

### 2. CI/CD Workflow (`.github/workflows/yocto-build.yml`)
- Uses GitHub Actions to automatically build the image on every push or PR
- Maximizes build space to accommodate Yocto's requirements
- Installs required dependencies
- Runs the build script
- Uploads the resulting image as an artifact using actions/upload-artifact@v4

### 3. Custom Layer (`meta-custom/`)
- `conf/layer.conf`: Registers the custom layer with Yocto
- `recipes-core/images/minimal-ssh-image.bb`: Defines the minimal image with SSH and systemd
- `recipes-core/systemd/systemd-networkd-configuration.bb`: Provides network configuration
- `recipes-core/systemd/files/20-wired.network`: Configures the ethernet interface

## Local Setup

1. Install dependencies (Ubuntu/Debian):
   ```bash
   sudo apt-get update
   sudo apt-get install -y gawk wget git diffstat unzip texinfo gcc build-essential \
     chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
     iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm
   ```

2. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/yocto-cicd-test.git
   cd yocto-cicd-test
   ```

3. Run the build script:
   ```bash
   ./scripts/build.sh
   ```

4. Find your image at `build/tmp/deploy/images/raspberrypi4-64/minimal-ssh-image-raspberrypi4-64.wic.bz2`

## Key Features

### Minimal SSH Image with Docker
The image recipe (`minimal-ssh-image.bb`) creates a streamlined 64-bit system with:
- OpenSSH server for remote access
- systemd init system
- Docker container runtime and docker-compose
- Network configuration via systemd-networkd
- OPKG package manager
- Raspberry Pi Camera support
- Audio/Voice capabilities
- U-Boot bootloader
- Essential kernel modules

### Network Configuration
The system is configured with:
- Static IP address (192.168.4.103) through systemd-networkd for Ethernet
- You can directly connect via SSH: `ssh root@192.168.4.103`
- WiFi support with WPA Supplicant pre-configured
- No password is required for SSH (debug-tweaks enabled)

## WiFi Configuration

The image comes with WiFi support pre-configured. To connect to your WiFi network:

1. Before building, customize the WiFi credentials in:
   ```
   meta-custom/recipes-core/systemd/files/wpa_supplicant-wlan0.conf
   ```

2. Alternatively, after first boot, edit the WiFi configuration:
   ```bash
   nano /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
   ```
   
   Then restart the WiFi service:
   ```bash
   systemctl restart wpa_supplicant@wlan0
   ```

3. Verify connectivity:
   ```bash
   ip a show wlan0
   ping -I wlan0 google.com
   ```

## API Usage Diagram

```
┌─────────────────┐     ┌──────────────────┐     ┌───────────────┐
│                 │     │                  │     │               │
│  Yocto Project  │────►│  Build System    │────►│ Custom Layer  │
│                 │     │                  │     │               │
└─────────────────┘     └──────────────────┘     └───────┬───────┘
                                                         │
                                                         ▼
┌─────────────────┐     ┌──────────────────┐     ┌───────────────┐
│                 │     │                  │     │               │
│  CI/CD Pipeline │────►│  GitHub Actions  │────►│ Image Output  │
│                 │     │                  │     │               │
└─────────────────┘     └────────┬─────────┘     └───────▲───────┘
                                 │                       │
                                 ▼                       │
                        ┌──────────────────┐     ┌───────────────┐
                        │                  │     │               │
                        │  Raspberry Pi 4  │     │  Recipe       │
                        │  Image Files     │     │  Components   │
                        └──────────────────┘     └───────────────┘
```

## 🔍 Detailed System Explanation

The Yocto CI/CD for Raspberry Pi 4 system implements a complete pipeline for building customized Linux distributions:

1. **Source Layer**
   - Poky: Core Yocto Project files providing the build system
   - meta-raspberrypi: BSP layer for Raspberry Pi hardware support
   - meta-openembedded: Additional packages and recipes
   - meta-custom: Project-specific customizations and configurations

2. **Build System Layer**
   - BitBake: Task executor and scheduler for recipe processing
   - Shared State Cache: Accelerates builds by caching build artifacts
   - Fetch System: Downloads source code from upstream repositories
   - Package Management: Creates OPKG packages for the final system

3. **Integration Layer**
   - CI/CD Pipeline: Automates build process through GitHub Actions
   - Docker Integration: Provides containerized environment for final system
   - Deployment: Prepares bootable images for Raspberry Pi 4

4. **Runtime Layer**
   - systemd: Init system for service management
   - SSH: Remote access and administration
   - Docker: Container runtime for application deployment
   - Network Configuration: Ethernet and WiFi connectivity setup

## Customization

- Edit `meta-custom/recipes-core/images/minimal-ssh-image.bb` to add more packages
- Copy `conf/local.conf.sample` to your build directory as `local.conf` for local builds
- Modify `meta-custom/recipes-core/systemd/files/20-wired.network` to change network settings

## Using Docker

After booting your Raspberry Pi with the built image:

1. Docker is pre-installed and ready to use
2. Check Docker status:
   ```bash
   systemctl status docker
   ```

3. Run a test container:
   ```bash
   docker run --rm hello-world
   ```

4. Create containers with docker-compose:
   ```bash
   docker-compose up -d
   ```

## Using the Camera

The image comes with support for the Raspberry Pi Camera module:

1. Connect the camera module to the Raspberry Pi CSI connector
2. Use the following commands to test the camera:

   ```bash
   # List available cameras
   libcamera-hello --list-cameras
   
   # Display a preview
   libcamera-hello
   
   # Capture an image
   libcamera-still -o test.jpg
   
   # Record a video (5 seconds)
   libcamera-vid -t 5000 -o test.h264
   ```

3. GStreamer is also included for advanced video processing:
   ```bash
   gst-launch-1.0 libcamerasrc ! videoconvert ! jpegenc ! filesink location=test.jpg
   ```

## Using Audio/Voice

The image comes with full audio support for the Raspberry Pi:

1. Testing your audio setup:
   ```bash
   # List audio devices
   aplay -l
   
   # Test audio output
   speaker-test -t wav -c 2
   
   # Play an audio file
   aplay /usr/share/sounds/alsa/Front_Center.wav
   ```

2. Recording audio:
   ```bash
   # Record audio for 5 seconds
   arecord -d 5 -f cd test.wav
   
   # Play back the recording
   aplay test.wav
   ```

3. Audio configuration:
   ```bash
   # Adjust volume
   alsamixer
   
   # Save volume settings
   alsactl store
   ```

4. PulseAudio is also included for advanced audio routing and mixing.

## Package Management

The image comes with OPKG package manager pre-installed:

1. Update package lists:
   ```bash
   opkg update
   ```

2. Install a package:
   ```bash
   opkg install <package-name>
   ```

3. List installed packages:
   ```bash
   opkg list-installed
   ```

4. Search for packages:
   ```bash
   opkg list | grep <search-term>
   ```

## Flashing the Image

curl -L https://github.com/docker/compose/releases/download/v2.34.0/docker-compose-linux-armv7   -o /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose

