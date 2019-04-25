#!/bin/sh

set -xu

# replace /bin/sync because:
#     update-initramfs: Generating /boot/initrd.img-4.19.0-4-arm64
#     qemu: Unsupported syscall: 276
#     qemu: Unsupported syscall: 267
#     /bin/sync: error syncing '/boot/initrd.img-4.19.0-4-arm64': Function not implemented
./mmdebstrap --verbose --mode=unshare \
	--components="main contrib non-free" \
	--include=raspi3-firmware,linux-image-arm64,firmware-brcm80211,wireless-tools,wpasupplicant,ssh,cmake,build-essential,catkin,ros-message-generation,ros-std-msgs,libroscpp-dev,libtf-dev,libnav-msgs-dev,libstd-srvs-dev \
	--essential-hook='mv "$1/bin/sync" "$1/bin/sync.bak"' \
	--essential-hook='ln -s /bin/true "$1/bin/sync"' \
	--customize-hook='./setup.sh "$1"' \
	--customize-hook='./build.sh "$1"' \
	--customize-hook='rm "$1/bin/sync"' \
	--customize-hook='mv "$1/bin/sync.bak" "$1/bin/sync"' \
	--arch=arm64 buster debian-buster.tar

guestfish -N raspi3.img=disk:2G -- \
	part-init /dev/sda mbr : \
	part-add /dev/sda p 2048 614399 : \
	part-add /dev/sda p 614400 -64 : \
	mkfs vfat /dev/sda1 : \
	mkfs ext4 /dev/sda2 : \
	part-set-bootable /dev/sda 1 true : \
	part-set-mbr-id /dev/sda 1 12 : \
	mount /dev/sda2 / : \
	mkdir-p /boot/firmware : \
	mount /dev/sda1 /boot/firmware : \
	tar-in debian-buster.tar /
