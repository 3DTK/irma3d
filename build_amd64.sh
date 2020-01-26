#!/bin/sh

set -exu

tar -c volksbot | chroot "$1" runuser -u user -- tar -C /home/user -x

chroot "$1" runuser -u user -- sh << 'END'
set -exu

mkdir /home/user/build /home/user/install
cmake -S /home/user/volksbot -B /home/user/build -DCMAKE_INSTALL_PREFIX=/home/user/install
cmake --build /home/user/build
cmake --build /home/user/build -- install
END
