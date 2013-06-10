#!/usr/bin/bash

# XXX - TODO
# - if $ntp_hosts == "local", configure ntp for no external time source
# - try to figure out why ^C doesn't intr when running under SMF

PATH=/usr/sbin:/usr/bin
export PATH
. /lib/sdc/config.sh
load_sdc_sysinfo
load_sdc_config

# Defaults
datacenter_headnode_id=0
mail_to="root@localhost"
ntp_hosts="pool.ntp.org"
dns_resolver1="8.8.8.8"
dns_resolver2="8.8.4.4"

# Globals
declare -a states
declare -a nics
declare -a assigned
declare -a DISK_LIST

sigexit()
{
  echo
  echo "System configuration has not been completed."
  echo "You must reboot to re-run system configuration."
  exit 0
}



updatenicstates()
{
  states=(1)
  #states[0]=1
  while IFS=: read -r link state ; do
    states=( ${states[@]-} $(echo "$state") )
  done < <(dladm show-phys -po link,state 2>/dev/null)
}


trap sigexit SIGINT

#
# Get local NIC info
#
nic_cnt=0

while IFS=: read -r link addr ; do
    ((nic_cnt++))
    nics[$nic_cnt]=$link
    macs[$nic_cnt]=`echo $addr | sed 's/\\\:/:/g'`
    assigned[$nic_cnt]="-"
done < <(dladm show-phys -pmo link,address 2>/dev/null)

if [[ $nic_cnt -lt 1 ]]; then
  echo "ERROR: cannot configure the system, no NICs were found."
  exit 0
fi

ifconfig -a plumb
updatenicstates
ifconfig -a dhcp
/usr/node/bin/node /openNAS/app.js
