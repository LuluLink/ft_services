#!/bin/sh

adduser -D -h /var/ftp lusokol
echo "lusokol:password" | chpasswd
vsftpd /etc/vsftpd/vsftpd.conf