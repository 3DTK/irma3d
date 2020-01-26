#!/bin/sh

set -xeu

pkgs=linux-image-amd64,task-desktop,wireless-tools,wpasupplicant,ssh,cmake
pkgs=$pkgs,build-essential,catkin,ros-message-generation,ros-std-msgs
pkgs=$pkgs,libroscpp-dev,libtf-dev,libnav-msgs-dev,libstd-srvs-dev,rviz,python-roslaunch

./mmdebstrap --verbose --mode=unshare \
	--aptopt='Apt::Install-Recommends "true"' \
	--include=$pkgs \
	--customize-hook='./setup_amd64.sh "$1"' \
	--customize-hook='./build.sh "$1"' \
	--arch=amd64 buster debian-buster.tar

cat << END > extlinux.conf
default linux
timeout 0

label linux
kernel /vmlinuz
append initrd=/initrd.img root=LABEL=rootfs rw
END

guestfish -N debian-buster.img=disk:8G -- \
	part-disk /dev/sda mbr : \
	part-set-bootable /dev/sda 1 true : mkfs ext2 /dev/sda1 : \
	set-label /dev/sda1 rootfs : mount /dev/sda1 / : \
	tar-in debian-buster.tar / xattrs:true : \
	upload /usr/lib/SYSLINUX/mbr.bin /mbr.bin : \
	copy-file-to-device /mbr.bin /dev/sda size:440 : rm /mbr.bin : \
	extlinux / : copy-in extlinux.conf / : \
	sync : umount / : shutdown
