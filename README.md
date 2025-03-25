# Yocto CI/CD for Raspberry Pi 4

This repository contains a minimal Yocto build configuration for Raspberry Pi 4 with:
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

4. Find your image at `build/tmp/deploy/images/raspberrypi4/minimal-ssh-image-raspberrypi4.wic.bz2`

## Key Features

### Minimal SSH Image with Docker
The image recipe (`minimal-ssh-image.bb`) creates a streamlined system with:
- OpenSSH server for remote access
- systemd init system
- Docker container runtime and docker-compose
- Network configuration via systemd-networkd
- U-Boot bootloader
- Essential kernel modules

### Network Configuration
The system is configured to:
- Use DHCP on the Ethernet interface (eth0)
- Automatically connect when the interface is available

### CI/CD Pipeline

The GitHub Actions workflow will automatically:
1. Set up the Yocto build environment
2. Build the minimal SSH image for Raspberry Pi 4
3. Upload the image as a build artifact

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

## Flashing the Image

