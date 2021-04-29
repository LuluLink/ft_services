#!/bin/sh

#les user sont répertoriés dans /etc/passwd
adduser -D $USER
echo "$USER:$PASSWORD" | chpasswd
echo "$USER" >/etc/vsftpd/chroot.list

 /usr/sbin/vsftpd -opasv_min_port=30000 -opasv_max_port=30001 -opasv_address=172.17.0.2 /etc/vsftpd/vsftpd.conf