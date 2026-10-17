#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run with sudo or as root." >&2
  exit 1
fi

# Parse options
PARSED_OPTIONS=$(getopt -o q: --long quiet: -n "$0" -- "$@")
eval set -- "$PARSED_OPTIONS"
# Default values
QUIET=0

while true; do
    case "$1" in
        -q | --quiet)
            QUIET=1
            shift # Move to the next argument
            ;;
        --)
            shift # Separator found, stop parsing options
            break
            ;;
        *)
            echo "Unexpected option: $1"
            usage
            ;;
    esac
done

# Shift away the parsed options
shift $((OPTIND - 1))

if [ "$QUIET" -eq 0 ]; then
  echo "Downloading required packages..."
fi

wget https://developer.nvidia.com/downloads/embedded/L4T/r39_Release_v2.1/release/Jetson_Linux_R39.2.1_aarch64.tbz2 https://developer.nvidia.com/downloads/embedded/L4T/r39_Release_v2.1/release/Tegra_Linux_Sample-Root-Filesystem_R39.2.1_aarch64.tbz2 https://developer.nvidia.com/downloads/embedded/L4T/r39_Release_v2.1/sources/public_sources.tbz2

echo "Extracting packages into working directory..."
tar xf Jetson_Linux_R39.2.1_aarch64.tbz2
sudo tar jxpf Tegra_Linux_Sample-Root-Filesystem_R39.2.1_aarch64.tbz2 -C Linux_for_Tegra/rootfs/
tar xf public_sources.tbz2

if [ "$QUIET" -eq 0 ]; then
  echo "Getting required binaries and prerequisites..."
  cd Linux_for_Tegra
  sudo apt update
  sudo ./tools/l4t_flash_prerequisites.sh
  sudo ./apply_binaries.sh
  sudo apt install -y build-essential bc flex bison libssl-dev zstd libncurses-dev
else
  cd Linux_for_Tegra
  sudo apt update > /dev/null
  sudo ./tools/l4t_flash_prerequisites.sh > /dev/null
  sudo ./apply_binaries.sh > /dev/null
  sudo apt install -y build-essential bc flex bison libssl-dev zstd libncurses-dev > /dev/null
fi

cd sources

if [ "$QUIET" -eq 0 ]; then
  echo "Getting required binaries and prerequisites..."
  cd Linux_for_Tegra
  sudo apt update
  sudo ./tools/l4t_flash_prerequisites.sh
  sudo ./apply_binaries.sh
  sudo apt install -y build-essential bc flex bison libssl-dev zstd libncurses-dev
  echo "Syncronizing kernel"
  sh source_sync.sh -k -t jetson_39.2.1
  echo "Adding Wireguard as a module to build..."
  echo "\nCONFIG_WIREGUARD=m" >> kernel/kernel-noble/arch/arm64/configs/defconfig
  echo "Building kernel...this might take a while if building on a Jetson device."
  echo "Maybe go out for a walk, or put on Netflix or a YouTube video"
  make -C kernel
  echo "Done building the kernel..."
sleep 3
else
  cd Linux_for_Tegra
  sudo apt update > /dev/null
  sudo ./tools/l4t_flash_prerequisites.sh > /dev/null
  sudo ./apply_binaries.sh > /dev/null
  sudo apt install -y build-essential bc flex bison libssl-dev zstd libncurses-dev > /dev/null
  sh source_sync.sh -k -t jetson_39.2.1 > /dev/null
  echo "\nCONFIG_WIREGUARD=m" >> kernel/kernel-noble/arch/arm64/configs/defconfig
  make -C kernel > /dev/null
fi

sudo mkdir /lib/modules/$(uname -r)/kernel/drivers/net/wireguard/
sudo cp kernel/kernel-noble/drivers/net/wireguard/wireguard.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireguard/
sudo cp kernel/kernel-noble/lib/crypto/libchacha20poly1305.ko /lib/modules/$(uname -r)/kernel/lib/crypto/
sudo cp kernel/kernel-noble/arch/arm64/crypto/poly1305-neon.ko /lib/modules/$(uname -r)/kernel/arch/arm64/crypto/
sudo depmod -a
sudo modprobe wireguard

if [ "$QUIET" -eq 0 ]; then
  echo "Installing wireguard-tools..."
  sudo apt install wireguard-tools
else
  sudo apt install wireguard-tools > /dev/null
fi

if [ "$QUIET" -eq 0 ]; then
  echo "Done!"
fi
