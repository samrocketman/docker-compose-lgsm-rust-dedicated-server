#!/bin/bash

# DESCRIPTION:
#   Dedicated server LGSM startup script which initializes some security best
#   practices for Rust.

set -ex


export ENABLE_RUST_EAC seed salt worldsize maxplayers servername


[ -f ./linuxgsm.sh ] || cp /linuxgsm.sh ./
[ -x ./rustserver ] || ./linuxgsm.sh rustserver
yes Y | ./rustserver install
if ! grep rustoxide lgsm/mods/installed-mods.txt &> /dev/null; then
  ./rustserver mods-install <<< $'rustoxide\nyes\n'
fi
./rustserver mods-update

# remove passwordless sudo access since setup is complete
sudo rm -f /etc/sudoers.d/lgsm

/apply-settings.sh
mkdir -p serverfiles/oxide/plugins
/get-or-update-plugins.sh

# start rust server
./rustserver start
echo Sleeping for 30 seconds...
sleep 30
tail -f log/console/rustserver-console.log \
        log/script/rustserver-steamcmd.log \
        log/script/rustserver-script.log
