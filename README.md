# Yocto CI/CD for Raspberry Pi 4

This repository contains a minimal Yocto build configuration for Raspberry Pi 4 with:
- SSH enabled
- systemd as init system
- GitHub Actions CI/CD pipeline

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

## CI/CD Pipeline

The GitHub Actions workflow will automatically:
1. Set up the Yocto build environment
2. Build the minimal SSH image for Raspberry Pi 4
3. Upload the image as a build artifact

## Customization

- Edit `meta-custom/recipes-core/images/minimal-ssh-image.bb` to add more packages
- Copy `conf/local.conf.sample` to your build directory as `local.conf` for local builds

## Flashing the Image

