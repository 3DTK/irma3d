#!/bin/sh

set -exu

tar -c volksbot | chroot "$1" tar -C /root -x

chroot "$1" sh << 'END'
set -exu

mkdir /root/build /root/install
cmake -S /root/volksbot -B /root/build -DCMAKE_INSTALL_PREFIX=/root/install
cmake --build /root/build
cmake --build /root/build -- install
END
