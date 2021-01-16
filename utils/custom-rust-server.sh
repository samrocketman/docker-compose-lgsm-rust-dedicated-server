#!/bin/bash

# DESCRIPTION:
#   Dedicated server LGSM startup script which initializes some security best
#   practices for Rust.

set -ex

[ ! -r /tmp/rust-docker-environment.sh ] || source /tmp/rust-docker-environment.sh

function rand_password() {
  tr -dc -- '0-9a-zA-Z' < /dev/urandom | head -c12;echo
}

[ -f ./linuxgsm.sh ] || cp /linuxgsm.sh ./
[ -x ./rustserver ] || ./linuxgsm.sh rustserver
yes Y | ./rustserver install
[ -f ./lgsm/mods/rustoxide-files.txt ] || ./rustserver mods-install <<< $'rustoxide\n'
./rustserver mods-update

# disable EAC allowing Linux clients
server_cfg=serverfiles/server/rustserver/cfg/server.cfg
if [ -z "${ENABLE_RUST_EAC:-}" ]; then
  grep -F -- server.secure "$server_cfg" || echo server.secure 0 >> "$server_cfg"
  grep -F -- server.encryption "$server_cfg" || echo server.encryption 0 >> "$server_cfg"
fi

if [ ! -f rcon_pass ]; then
  rand_password > rcon_pass
fi
(
  grep rconpassword lgsm/config-lgsm/rustserver/rustserver.cfg || echo rconpassword="$(<rcon_pass)" >> lgsm/config-lgsm/rustserver/rustserver.cfg
) &> /dev/null

# remove passwordless sudo access since setup is complete
sudo rm -f /etc/sudoers.d/lgsm

# start rust server
./rustserver start
echo Sleeping for 30 seconds...
sleep 30
tail -f log/*/*.log
