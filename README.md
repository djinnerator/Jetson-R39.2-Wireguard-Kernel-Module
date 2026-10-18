# Jetson-R39.2-Wireguard-Kernel-Module

Module and other requisite modules to update kernel for Wireguard

This was built around the kernel on Jetson Orin Nano Super using Jetson R39.2 (Jetpack 7.2). It should work with any Jetson device on R39.x in theory.

You could also build it yourself, it just takes about an hour to build the kernel on-device. You could probably build it on another computer, just make sure it's built for ARM64/AARCH64.

To install the module, clone the repo and copy the .ko files to your root filesystem following the exact same directory path.

You could also use this (note, with Jetson R39.x, the kernel release version (uname -r) is `6.8.12-1021-tegra`. On a matching system, you can either replace $(uname -r) with your kernel release version, in this case`6.8.12-1021-tegra`, or you could change the kernel source name to match yours, in this case `kernel-noble`...or just leave the commands as is and copy/paste):

### Quick Setup

You can either run the `install_modules.sh` script or run the commands manually:

```
sudo mkdir /lib/modules/$(uname -r)/kernel/drivers/net/wireguard/
sudo cp lib/modules/kernel-noble/drivers/net/wireguard/wireguard.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireguard/
sudo cp lib/modules/kernel-noble/lib/crypto/libchacha20poly1305.ko /lib/modules/$(uname -r)/kernel/lib/crypto/
sudo cp lib/modules/kernel-noble/arch/arm64/crypto/poly1305-neon.ko /lib/modules/$(uname -r)/kernel/arch/arm64/crypto/
sudo depmod -a
sudo modprobe wireguard
sudo apt update && sudo apt install wireguard-tools
```

Enjoy!

### Manual install

If you'd rather build the kernel yourself and enable Wireguard that way, follow these steps (anywhere you see R39.2.1, change to the version you're using), or you can run the `build_and_install.sh` script which performs the same operations:

(Note: If using the script, it can take one argument, `-q` or `--quiet`, which will suppress printing output to console. Default behavior is to print output to console.)

Download:

| Package Name                 | Download URL                                                                                                                         |
|------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| Driver Package (BSP)         | https://developer.nvidia.com/downloads/embedded/L4T/r39_Release_v2.1/release/Jetson_Linux_R39.2.1_aarch64.tbz2                       |
| Sample Root Filesystem       | https://developer.nvidia.com/downloads/embedded/L4T/r39_Release_v2.1/release/Tegra_Linux_Sample-Root-Filesystem_R39.2.1_aarch64.tbz2 |
| Driver Package (BSP) Sources | https://developer.nvidia.com/downloads/embedded/L4T/r39_Release_v2.1/sources/public_sources.tbz2                                     |

Note: If this hasn't been updated for the latest version of Jetson/Jetpack, you can always find the latest version, including the required packages, here: https://developer.nvidia.com/embedded/jetpack/downloads. The packages are further down on the page in the second table with the same names as in the preceding table here (Driver Package (BSP), and so on...)

Unzip BSP then the sample root filesystem:
```
tar xf Jetson_Linux_R39.2.1_aarch64.tbz2
sudo xjpf Tegra_Linux_Sample-Root-Filesystem_R39.2.1_aarch64.tbz2 -C Linux_for_Tegra/
tar xf public_sources.tbz2
```

Enter the work directory and finish setting up:
```
cd Linux_for_Tegra
sudo ./tools/l4t_flash_prerequisites.sh
sudo ./apply_binaries.sh
```

Configure kernel parameters and get prerequisites:
```
cd source
./source_sync.sh -k -t jetson_39.2.1

echo "\nCONFIG_WIREGUARD=m" >> kernel/kernel-noble/arch/arm64/configs/defconfig
# or you can use nano/vim/etc. to add `CONFIG_WIREGUARD=m` to the end of the file

sudo apt update && sudo apt install -y build-essential bc flex bison libssl-dev zstd libncurses-dev
```

Build kernel (this step takes a LONG time if ran on-device):
```
make -C kernel
```

When the kernel is done being built, run the commands in Quick Setup but with a slight change:

Instead of using cp on `lib/modules/kernel-noble/...`, you will be using it on `kernel/kernel-noble/...` or whatever your matching kernel source name.

For example:

```
sudo mkdir /lib/modules/$(uname -r)/kernel/drivers/net/wireguard/
sudo cp kernel/kernel-noble/drivers/net/wireguard/wireguard.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireguard/
...
```

### Thank You!
Huge thanks to the blog post by Toshihito Kikuchi - https://docs.kinesis.network/blog/enable-wireguard-on-nvidia-jetson - which this is based on. The steps are identical but this repo is to provide the completed module, and requisite modules, to get Wireguard working on Jetson devices without needing to put so much time into building the kernel and copying three files.

I may or may not keep this repo updated as newer versions of Jetson/Jetpack releases, but if I ever have to update my own Jetson devices, I'll be sure to update this repo so others can quickly get Wireguard working.
