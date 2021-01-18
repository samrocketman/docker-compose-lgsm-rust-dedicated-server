#!/bin/bash

# DESCRIPTION:
#   Dedicated server LGSM startup script which initializes some security best
#   practices for Rust.

set -ex


export ENABLE_RUST_EAC seed salt worldsize maxplayers servername

function rand_password() {
  tr -dc -- '0-9a-zA-Z' < /dev/urandom | head -c12;echo
}

[ -f ./linuxgsm.sh ] || cp /linuxgsm.sh ./
[ -x ./rustserver ] || ./linuxgsm.sh rustserver
yes Y | ./rustserver install
[ -f ./lgsm/mods/rustoxide-files.txt ] || ./rustserver mods-install <<< $'rustoxide\n'
./rustserver mods-update

# remove passwordless sudo access since setup is complete
sudo rm -f /etc/sudoers.d/lgsm

/apply-settings.sh
/get-or-update-plugins.sh

# start rust server
./rustserver start
echo Sleeping for 30 seconds...
sleep 30
tail -f log/console/rustserver-console.log \
        log/script/rustserver-steamcmd.log \
        log/script/rustserver-script.log
