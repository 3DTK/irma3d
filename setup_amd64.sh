#!/bin/sh

set -exu

ROOT="$1"

echo "irma3d" > "${ROOT}/etc/hostname"

#chroot "$ROOT" usermod -p '*' root
chroot "$ROOT" passwd -d root

cat << END >> "${ROOT}/etc/ssh/sshd_config"
PermitEmptyPasswords yes
PermitRootLogin yes
END

cat << END > "${ROOT}/etc/network/interfaces.d/eth0"
auto eth0

iface eth0 inet dhcp
END


cat << END > "${ROOT}/etc/systemd/system/generate-ssh-host-keys.service"
[Unit]
Description=generate SSH host keys
ConditionPathExistsGlob=!/etc/ssh/ssh_host_*_key

[Service]
Type=oneshot
ExecStart=/usr/sbin/dpkg-reconfigure -fnoninteractive openssh-server

[Install]
RequiredBy=multi-user.target
END

mkdir -p "${ROOT}/etc/systemd/system/multi-user.target.requires/"
ln -s /etc/systemd/system/generate-ssh-host-keys.service "${ROOT}/etc/systemd/system/multi-user.target.requires/generate-ssh-host-keys.service"

rm -f ${ROOT}/etc/ssh/ssh_host_*_key*

chroot "$ROOT" adduser --gecos user --disabled-password user

sed -i 's/^\[daemon\]$/&\nAutomaticLoginEnable = true\nAutomaticLogin = user\n/' "${ROOT}/etc/gdm3/daemon.conf"

# FIXME: replace by directly calling the right ioctl
chroot "$ROOT" apt-get --yes install setserial

chroot "$ROOT" usermod -a -G dialout user
cat << 'END' > "${ROOT}/etc/udev/rules.d/42-usb-serial-volksbot.rules"
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", ATTRS{serial}=="FTHJPYW1", SYMLINK+="volksbot"
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", ATTRS{serial}=="FTHJRKHP", SYMLINK+="xsens"
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", ATTRS{serial}=="FTGSEMAV", SYMLINK+="volksbot"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="a8b0", ATTRS{serial}=="662080008394", SYMLINK+="EPOS2R", GROUP="user", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="a8b0", ATTRS{serial}=="662080008432", SYMLINK+="EPOS2L", GROUP="user", MODE="0666"
END

chroot "$ROOT" runuser -u user -- mkdir -p "/home/user/.config/systemd/user/"
cat << 'END' > "${ROOT}/home/user/.config/systemd/user/localjoystick.service"
[Unit]
Description=ROS node for joystick control
After=network.target
AssertPathExists=/home/user/install

[Service]
WorkingDirectory=/home/user
Type=simple
KillSignal=SIGINT
#ROS_DISTRO=kinetic
#ROS_PORT=11311
#ROS_MASTER_URI=http://localhost:11311
#PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/ros/kinetic/bin
#PYTHONPATH=/opt/ros/kinetic/lib/python2.7/dist-packages
Environment="LD_LIBRARY_PATH=/home/user/install/lib"
Environment="CMAKE_PREFIX_PATH=/home/user/install"
Environment="ROS_ROOT=/home/user/install"
Environment="ROS_PACKAGE_PATH=/home/user/install"
ExecStart=/usr/bin/roslaunch volksbot localjoystick.launch
Restart=on-abort

[Install]
WantedBy=default.target
END
chroot "$ROOT" chown user:user "/home/user/.config/systemd/user/localjoystick.service"
