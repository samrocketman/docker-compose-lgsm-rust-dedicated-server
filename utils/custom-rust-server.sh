#!/bin/bash

# DESCRIPTION:
#   Dedicated server LGSM startup script which initializes some security best
#   practices for Rust.

set -ex

[ -f ./linuxgsm.sh ] || (
  if [ -n "${LINUX_GSM_VERSION:-}" ]; then
    curl -fLo linuxgsm.sh \
      https://raw.githubusercontent.com/GameServerManagers/LinuxGSM/"${LINUX_GSM_VERSION}"/linuxgsm.sh
    chmod 755 linuxgsm.sh
  else
    cp /linuxgsm.sh ./
  fi
)
[ -x ./rustserver ] || ./linuxgsm.sh rustserver
yes Y | ./rustserver install
if ! grep rustoxide lgsm/mods/installed-mods.txt &> /dev/null; then
  ./rustserver mods-install <<< $'rustoxide\nyes\n'
fi
./rustserver mods-update
if [ ! -f 'serverfiles/RustDedicated_Data/Managed/Oxide.Ext.RustEdit.dll' ]; then
  curl -fLo serverfiles/RustDedicated_Data/Managed/Oxide.Ext.RustEdit.dll \
    https://github.com/k1lly0u/Oxide.Ext.RustEdit/raw/master/Oxide.Ext.RustEdit.dll
fi

# remove passwordless sudo access since setup is complete
sudo rm -f /etc/sudoers.d/lgsm

lgsm_cfg=lgsm/config-lgsm/rustserver/rustserver.cfg
grep -F -- /utils/apply-settings.sh "$lgsm_cfg" ||
  echo 'if [ ! "$1" = docker ]; then /utils/apply-settings.sh; source lgsm/config-lgsm/rustserver/rustserver.cfg docker; fi' >> "$lgsm_cfg"
/utils/get-or-update-plugins.sh
/utils/monitor-rust-server.sh &

# start rust server
./rustserver start
echo Sleeping for 30 seconds...
sleep 30
tail -f log/console/rustserver-console.log \
        log/script/rustserver-steamcmd.log \
        log/script/rustserver-script.log
