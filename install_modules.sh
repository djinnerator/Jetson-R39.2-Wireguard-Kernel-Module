#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run with sudo or as root." >&2
  exit 1
fi

sudo mkdir /lib/modules/$(uname -r)/kernel/drivers/net/wireguard/
sudo cp lib/modules/kernel-noble/drivers/net/wireguard/wireguard.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireguard/
sudo cp lib/modules/kernel-noble/lib/crypto/libchacha20poly1305.ko /lib/modules/$(uname -r)/kernel/lib/crypto/
sudo cp lib/modules/kernel-noble/arch/arm64/crypto/poly1305-neon.ko /lib/modules/$(uname -r)/kernel/arch/arm64/crypto/
sudo depmod -a
sudo modprobe wireguard
sudo apt update && sudo apt install wireguard-tools

echo "Done"
