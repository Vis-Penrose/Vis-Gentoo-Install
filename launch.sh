#!/bin/bash

echo "IMPORTANT NOTE: this script is hard coded to my own configuration, please modify it before using on your own system."

## test internet connection
# Send 1 packet (-c 1) and wait at most 2 seconds (-W 2)
if ! ping -c 1 -W 2 gentoo.org &> /dev/null; then
    echo "No internet connection. Exiting..."
    exit 1
fi

echo "Connected! Running the rest of the script..."


# assuming paritioning is already done, /dev/nvme0n1p1 being efi partition, /dev/nvme0n1p3 being root partition, and /dev/nvme0n1p2 being swap partition
## Formatting
mkfs.vfat -F 32 /dev/nvme0n1p1
mkfs.ext4 /dev/nvme0n1p3
mkswap /dev/nvme0n1p2

# Mounting
swapon /dev/nvme0n1p2
mkdir --parents /mnt/gentoo
mount /dev/nvme0n1p3 /mnt/gentoo
mkdir --parents /mnt/gentoo/efi
mount /dev/nvme0n1p1 /mnt/gentoo/efi

# Installing the stage file (desktop profile openrc)
BASE_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds"
STAGE3_PATH=$(wget -qO- "$BASE_URL/latest-stage3-amd64-desktop-openrc.txt" \
    | grep -m1 -oE '^[^ ]+\.tar\.xz')

if [ -z "$STAGE3_PATH" ]; then
    echo "Failed to determine latest stage3 URL. Exiting..."
    exit 1
fi

wget "$BASE_URL/$STAGE3_PATH"


tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

# Configuring compile options

# remove the default COMMON_FLAGS line and replace it with a new one
sed -i '/^COMMON_FLAGS/c\COMMON_FLAGS="-march=native -O2 -pipe"' /mnt/gentoo/etc/portage/make.conf

echo -e 'RUSTFLAGS="${RUSTFLAGS} -C target-cpu=native"' >> /mnt/gentoo/etc/portage/make.conf
echo -e 'MAKEOPTS="-j12 -l13"' >> /mnt/gentoo/etc/portage/make.conf

# adding DNS info
echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > /mnt/gentoo/etc/resolv.conf

# creating the fstab file
emerge -1 genfstab
genfstab -U /mnt/gentoo >> /mnt/gentoo/etc/fstab

# moving the second script inside chroot
mv chroot.sh /mnt/gentoo

echo "The first part of the script is done, continue by running ./chroot.sh inside chroot environment"

# the official gentoo iso now ships with arch-chroot so you no longer have to mount a bunch of necessary filesystems manually
arch-chroot /mnt/gentoo
