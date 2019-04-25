#!/bin/sh

set -exu

ROOT="$1"

echo "rpi3" > "${ROOT}/etc/hostname"

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

cat << 'END' > "${ROOT}/usr/sbin/rpi3-resizerootfs"
#!/bin/sh

roottmp=$(lsblk -l -o NAME,MOUNTPOINT | grep '/$')
rootpart=/dev/${roottmp%% */}
rootdev=${rootpart%2}
rootdev=${rootdev%p}

flock $rootdev sfdisk -f $rootdev -N 2 <<EOF
,+
EOF

sleep 5

udevadm settle

sleep 5

flock $rootdev partprobe $rootdev

mount -o remount,rw $rootpart

resize2fs $rootpart

exit 0
END
chmod +x "${ROOT}/usr/sbin/rpi3-resizerootfs"

cat << END > "${ROOT}/etc/systemd/system/rpi3-resizerootfs.service"
[Unit]
Description=resize root file system
Before=local-fs-pre.target
DefaultDependencies=no

[Service]
Type=oneshot
TimeoutSec=infinity
ExecStart=/usr/sbin/rpi3-resizerootfs
ExecStart=/bin/systemctl --no-reload disable %n

[Install]
RequiredBy=local-fs-pre.target
END


mkdir -p "${ROOT}/etc/systemd/system/systemd-remount-fs.service.requires/"
ln -s /etc/systemd/system/rpi3-resizerootfs.service "${ROOT}/etc/systemd/system/systemd-remount-fs.service.requires/rpi3-resizerootfs.service"

cat << END > "${ROOT}/etc/systemd/system/rpi3-generate-ssh-host-keys.service"
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
ln -s /etc/systemd/system/rpi3-generate-ssh-host-keys.service "${ROOT}/etc/systemd/system/multi-user.target.requires/rpi3-generate-ssh-host-keys.service"

rm -f ${ROOT}/etc/ssh/ssh_host_*_key*
