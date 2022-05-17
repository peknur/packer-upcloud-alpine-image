#!/bin/ash
echo https://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/main/ >> /etc/apk/repositories
echo https://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/community/ >> /etc/apk/repositories
apk -U upgrade
apk del syslinux

# Notes: 
#   - util-linux provides fstrim 
#   - e2fsprogs-extra provides resize2fs needed by cloud-init module
apk --no-cache add \
    sudo \
    grub \
    grub-bios \
    wget \
    acpid \
    cloud-utils-growpart \
    cloud-init \
    qemu-guest-agent \
    net-tools \
    util-linux \
    e2fsprogs-extra \
    rsyslog

echo "GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0 memhp_default_state=online\"" >> /etc/default/grub
sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
GRUB_DISABLE_OS_PROBER=true grub-install /dev/vda

setup-cloud-init

# replace busybox syslog with rsyslog
rc-service syslog stop
rc-update add rsyslog boot

# disable root logins with password and create .ssh dir for authorized keys
sed -i 's/^PermitRootLogin.*/PermitRootLogin without-password/g' /etc/ssh/sshd_config
mkdir /root/.ssh

# do cleanup
rm -vf /etc/hostname /etc/hosts /etc/ssh/*key*
fstrim --all --verbose
df -h
cloud-init clean
rm -fr $HOME/.ash_history \
    /var/cache/apk/* \
    /var/log/*
