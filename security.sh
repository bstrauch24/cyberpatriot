#!/bin/bash

# Ubuntu Security Script
# Brian Strauch

if [[ $EUID -ne 0 ]]
then
  echo "You must be root to run this script."
  exit 1
fi

# Firewall
ufw enable

# Updates
apt-get -y upgrade
apt-get -y update

# Lock Out Root User
passwd -l root

# Disable Guest Account
echo "allow-guest=false" >> /etc/lightdm/lightdm.conf

# Configure Password Aging Controls
sed -i '/^PASS_MAX_DAYS/ c\PASS_MAX_DAYS   90' /etc/login.defs
sed -i '/^PASS_MIN_DAYS/ c\PASS_MIN_DAYS   10'  /etc/login.defs
sed -i '/^PASS_WARN_AGE/ c\PASS_WARN_AGE   7' /etc/login.defs

# Password Authentication
sed -i '1 s/^/auth optional pam_tally.so deny=5 unlock_time=900 onerr=fail audit even_deny_root_account silent\n/' /etc/pam.d/common-auth

# Force Strong Passwords
apt-get -y install libpam-cracklib
sed -i '1 s/^/password requisite pam_cracklib.so retry=3 minlen=8 difok=3 reject_username minclass=3 maxrepeat=2 dcredit=1 ucredit=1 lcredit=1 ocredit=1\n/' /etc/pam.d/common-password

# MySQL
echo -n "MySQL [Y/n] "
read option
if [[ $option =~ ^[Yy]$ ]]
then
  apt-get -y install mysql-server
  # Disable remote access
  sed -i '/bind-address/ c\bind-address = 127.0.0.1' /etc/mysql/my.cnf
  service mysql restart
else
  apt-get -y purge mysql*
fi

# OpenSSH Server
echo -n "OpenSSH Server [Y/n] "
read option
if [[ $option =~ ^[Yy]$ ]]
then
  apt-get -y install openssh-server
  # Disable root login
  sed -i '/^PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config
  service ssh restart
else
  apt-get -y purge openssh-server*
fi

# VSFTPD
echo -n "VSFTP [Y/n] "
read option
if [[ $option =~ ^[Yy]$ ]]
then
  apt-get -y install vsftpd
  # Disable anonymous uploads
  sed -i '/^anon_upload_enable/ c\anon_upload_enable no' /etc/vsftpd.conf
  sed -i '/^anonymous_enable/ c\anonymous_enable=NO' /etc/vsftpd.conf
  # FTP user directories use chroot
  sed -i '/^chroot_local_user/ c\chroot_local_user=YES' /etc/vsftpd.conf
  service vsftpd restart
else
  apt-get -y purge vsftpd*
fi

# Malware
apt-get -y purge hydra*
apt-get -y purge john*
apt-get -y purge nikto*
apt-get -y purge netcat*

# Media Files
for suffix in mp3 txt wav wma aac mp4 mov avi gif jpg png bmp img exe msi bat sh
do
  find /home -name *.$suffix
done
