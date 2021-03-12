#!/bin/bash -eux

# This script will configure a standard installation of Ubuntu so it can be trasformed into a VM template
# Tested on 18.04 LTS server

export DEBIAN_FRONTEND="noninteractive"

apt -y update -qq > /dev/null
apt -y upgrade -qq > /dev/null
apt -y autoremove > /dev/null
apt -y clean > /dev/null

# Install VMware Tools
#apt -y install open-vm-tools

#apt-get remove --purge open-vm-tools > /dev/null

# # Add usernames to add to /etc/sudoers for passwordless sudo
# users=("ubuntu")
# for user in "${users[@]}"
# do
#   cat /etc/sudoers | grep ^$user
#   RC=$?
#   if [ $RC != 0 ]; then
#     bash -c "echo \"$user ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers"
#   fi
# done

# Stop services for cleanup
service rsyslog stop

# clear audit logs
if [ -f /var/log/wtmp ]; then
    truncate -s0 /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
    truncate -s0 /var/log/lastlog
fi

# cleanup /tmp directories
rm -rf /tmp/*
rm -rf /var/tmp/*

# cleanup current ssh keys
rm -f /etc/ssh/ssh_host_*

# add check for ssh keys on reboot (regenerate if neccessary)
cat << 'EOL' | tee /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
#

# dynamically create hostname (optional)
if hostname | grep localhost; then
    hostnamectl set-hostname "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')"
fi

test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server
exit 0
EOL

# make sure the script is executable
chmod +x /etc/rc.local

# reset hostname
truncate -s0 /etc/hostname
hostnamectl set-hostname localhost

# Fix machine-id issue with duplicate IP addresses being assigned
if [ -f /etc/machine-id ]; then
    sudo truncate -s 0 /etc/machine-id
fi

# cleanup shell history
cat /dev/null > ~/.bash_history && history -c
history -w
