#!/bin/bash

ubuntu_version="`lsb_release -r | awk '{print $2}'`";
major_version="`echo $ubuntu_version | awk -F. '{print $1}'`";

if [ "$ubuntu_version" = '17.10' ] || [ "$major_version" -ge "18" ]; then
  apt-get -y install network-manager isc-dhcp-client
  systemctl enable network-manager
  echo "Create netplan config for eth0"
  cat <<EOF >/etc/netplan/01-netcfg.yaml;
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    eth0:
      dhcp4: true
EOF
else
  # Adding a 2 sec delay to the interface up, to make the dhclient happy
  echo "pre-up sleep 2" >> /etc/network/interfaces;
fi

if [ -e /etc/yaboot.conf ] ; then
  sed -i 's/append\=\"/append\=\"net\.ifnames\=0 biosdevname\=0\ /' /etc/yaboot.conf
fi

if [ "$major_version" -ge "16" ] && [ -e /etc/default/grub ] ; then
  # Disable Predictable Network Interface names and use eth0
  sed -i 's/en[[:alnum:]]*/eth0/g' /etc/network/interfaces;
  sed -ie 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/g' /etc/default/grub;
  sed -ie 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 \1"/g' /etc/default/grub;
  update-grub;
fi
