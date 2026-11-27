#!/bin/bash

## Portage configuration
emerge-webrsync

# changing mirror
echo 'GENTOO_MIRRORS="http://tux.rainside.sk/gentoo ftp://tux.rainside.sk/gentoo/ https://mirror.freedif.org/gentoo"' >> /etc/portage/make.conf

# adding binary packages host
echo -e "[binhost]\npriority = 9999\nsync-uri = http://tux.rainside.sk/gentoo/releases/amd64/binpackages/23.0/x86-64/" > /etc/portage/binrepos.conf/gentoobinhost.conf
echo 'FEATURES="${FEATURES} getbinpkg"' >> /etc/portage/make.conf
getuto # set up the necessary keyring for verification

# CPU_FLAGS
emerge -1 app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

# VIDEO_CARDS
echo "*/* VIDEO_CARDS: amdgpu radeonsi" > /etc/portage/package.use/00video_cards

# Accepting all licenses
echo 'ACCEPT_LICENSE="*"' >> /etc/portage/make.conf

# Updating the @world set
# emerge --verbose --update --deep --changed-use @world


# Timezone 
ln -sf ../usr/share/zoneinfo/Asia/Bangkok /etc/localtime

# Locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen && echo "LANG=en_US.UTF-8" > /etc/env.d/02locale

# reload the environment
env-update && source /etc/profile

## Kernel configuration
emerge linux-firmware sof-firmware gentoolkit

# Bootloader
# systemd-boot
# adding USE flags to use systemd-boot on an openrc system
echo "sys-apps/systemd boot" > /etc/portage/package.use/systemd-boot
echo "sys-apps/systemd-utils boot kernel-install" >> /etc/portage/package.use/systemd-boot
echo "sys-kernel/installkernel systemd systemd-boot" >> /etc/portage/package.use/systemd-boot

# The kernel command line to use for new kernels should be specified in /etc/kernel/cmdline and /etc/cmdline. As they both need to be updated together, it make sense to symlink the two files now.
mkdir -p /etc/cmdline.d
mkdir -p /etc/kernel
ROOT_UUID=$(blkid -s UUID -o value /dev/nvme0n1p3)
echo "root=UUID=${ROOT_UUID} splash quiet" > /etc/kernel/cmdline
ln -s /etc/kernel/cmdline /etc/cmdline.d/00-installkernel.conf
emerge sys-kernel/installkernel

# Initramfs
echo "sys-kernel/installkernel dracut" > /etc/portage/package.use/installkernel
emerge sys-kernel/installkernel

# Installing a distribution kernel
emerge sys-kernel/gentoo-kernel-bin
euse -E dist-kernel

# creating the fstab file
emerge -1 genfstab
genfstab -U / >> /etc/fstab

# Making sure there's internet connection after boot
# wpa_supplicant isn't installed so NetworkManager should defaults to iwd
echo 'net-misc/networkmanager iwd wifi' > /etc/portage/package.use/networkmanager
emerge networkmanager
rc-update add NetworkManager default


## installing tools
emerge app-admin/sysklogd # System logger
rc-update add sysklogd default
emerge sys-process/cronie # Cron daemon
rc-update add cronie default
emerge sys-apps/mlocate # File indexing
emerge app-shells/bash-completion # Shell completion
emerge net-misc/chrony # Time synchronization
rc-update add chronyd default

# systemd-boot
emerge sys-apps/systemd-utils
bootctl install
bootctl list # verify that a new bootable entry exists before rebooting

echo 'All done, the last step is to set a password, exit chrooted environment and unmount all mounted partitions, Then type in that one magical command that initiates the final, true test: reboot.'
