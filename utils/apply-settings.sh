#!/bin/bash

set -e

if ! type -p python && type -p python3; then
  python() { python3 "$@"; }
fi

[ ! -r /rust-environment.sh ] || source /rust-environment.sh
export ENABLE_RUST_EAC CUSTOM_MAP_URL MAP_BASE_URL SELF_HOST_CUSTOM_MAP
export seed salt worldsize maxplayers servername apply_settings_debug_mode
if [ "${apply_settings_debug_mode:-false}" = true ]; then
  echo 'docker compose apply config debug enabled.' >&2
  set -x
fi

echo 'Applying server settings from rust-environment.sh:'

server_cfg=serverfiles/server/rustserver/cfg/server.cfg
lgsm_cfg=lgsm/config-lgsm/rustserver/rustserver.cfg

# disable EAC allowing Linux clients
sed -i '/^ *server\.secure/d' "$server_cfg"
sed -i '/^ *server\.encryption/d' "$server_cfg"
if [ -z "${ENABLE_RUST_EAC:-}" ]; then
  echo server.secure 0 >> "$server_cfg"
  echo server.encryption 0 >> "$server_cfg"
  echo '    EAC Disabled.'
else
  echo '    EAC Enabled.'
fi

# Checks for minimum version of python.  Will check the minor or higher.
#   * 2.7 will look for python 2.7 or higher but only for python 2.
#   * 3.2 will look for python 3.2 or higher but only for python 3.
# Example: minimum python 3.8
function minimum() (
  exec &> /dev/null
  local major="${2%.*}"
  local minor="${2#*.}"
  if ! type -P "$1"; then
    return false
  fi
  python -c 'import platform,sys; check=lambda x,y,z: x.startswith(y) and int(x.split(".")[0:2][-1]) >= z; sys.exit(0) if check(platform.python_version(), sys.argv[1], int(sys.argv[2])) else sys.exit(1)' \
  "${major}" "${minor}"
)

function rand_password() {
  tr -dc -- '0-9a-zA-Z' < /dev/urandom | head -c12;echo
}

# Map generation settings
function check-range() {
# Usage: check-range NUMBER MIN MAX
# exits nonzero if outside of range or not a number
python -c "
import sys;
i=int(sys.stdin.read());
exit(0) if i >= $2 and i <= $3 else exit(1)" &> /dev/null <<< "$1"
}
function apply-setting() {
  echo "    $3"
  sed -i "/^ *$2/d" $1
  echo "$3" >> "$1"
}

function apply-generated-map-settings() {
  if [ -z "$worldsize" ] || ! check-range "$worldsize" 1000 6000; then
    worldsize=3000
  fi
  # apply user-customized settings from rust-environment.sh
  apply-setting "$lgsm_cfg" worldsize "worldsize=$worldsize"
  if [ -n "$seed" ]; then
    apply-setting "$lgsm_cfg" seed "seed=$seed"
  fi
  if ( [ -z "$seed" ] || ! check-range "${seed:-invalid}" 1 2147483647 ) &&
     ! grep -F -- 'seed=' "$lgsm_cfg" > /dev/null; then
    # random seed; if seed is unset or invalid
    seed="$(python -c 'from random import randrange;print(randrange(2147483647))')"
    apply-setting "$lgsm_cfg" seed "seed=$seed"
  else
    echo -n '    '
    grep -F -- 'seed=' "$lgsm_cfg"
  fi
  if [ -n "$salt" ]; then
    apply-setting "$lgsm_cfg" salt "salt=$salt"
  else
    sed -i '/^ *salt/d' "$lgsm_cfg"
  fi
}

servername="${servername:-Rust}"
apply-setting "$lgsm_cfg" servername "servername=\"$servername\""
if [ -z "$maxplayers" ] || ! check-range "$maxplayers" 1 1000000; then
  maxplayers=50
fi
apply-setting "$lgsm_cfg" maxplayers "maxplayers=$maxplayers"

# Custom Map Support
function start-custom-map-server() (
  cd /custom-maps/
  if ! pgrep -f SimpleHTTPServer > /dev/null; then
    if minimum python '3.2'; then
      python -m http.server &
    elif minimum python3 '3.2'; then
      python3 -m http.server &
    elif minimum python '2.7'; then
      python -m SimpleHTTPServer &
    else
      echo 'ERROR: could not find suitable python version.' >&2
      exit 1
    fi
  fi
  echo '    Custom map server started on port 8000.' >&2
)
function get-custom-map-url() {
  MAP_BASE_URL="${MAP_BASE_URL:-http://localhost:8000/}"
  until curl -sIfLo /dev/null "http://localhost:8000/"; do sleep 1; done
  local map_url="$(curl -sfL "http://localhost:8000/" | grep -o 'href="[^"]\+.map"' | sed 's/.*"\([^"]\+\)"/\1/' | head -n1)"
  echo "${MAP_BASE_URL%/}/${map_url}"
}
function unquote-url() {
  python3 -c 'from urllib.parse import unquote;import sys;print(unquote(sys.stdin.read()).strip())'
}
function download-custom-map() {
  local custom_map="$(echo "${CUSTOM_MAP_URL}" | grep -o '[^/]\+\.map' | unquote-url)"
  if [ -z "${custom_map:-}" ]; then
    custom_map='custom-map.map'
  fi
  [ -f /custom-maps/"${custom_map}" ] || (
    echo '    Downloading custom map: '"${CUSTOM_MAP_URL}" >&2
    curl --retry 3 --retry-delay 10 -sfLo /custom-maps/"${custom_map}" "${CUSTOM_MAP_URL}"
  )
}
sed -i '/^fn_parms/d' "$lgsm_cfg"


if [ -n "${CUSTOM_MAP_URL:-}" ] || ls -1 /custom-maps/*.map &> /dev/null; then
  if [ -n "${CUSTOM_MAP_URL:-}" -a "${SELF_HOST_CUSTOM_MAP:-}" = true ]; then
    download-custom-map
    unset CUSTOM_MAP_URL
  fi
  start-custom-map-server
  if [ -z "${CUSTOM_MAP_URL:-}" ]; then
    export CUSTOM_MAP_URL="$(get-custom-map-url)"
  fi
  # custom map found so disabling map settings.
  cat >> "$lgsm_cfg" <<EOF
fn_parms(){ parms="-batchmode +app.listenip \${ip} +app.port \${appport} +server.ip \${ip} +server.port \${port} +server.tickrate \${tickrate} +server.hostname \"\${servername}\" +server.identity \"\${selfname}\" +server.maxplayers \${maxplayers} +levelurl '${CUSTOM_MAP_URL}' +server.saveinterval \${saveinterval} +rcon.web \${rconweb} +rcon.ip \${ip} +rcon.port \${rconport} +rcon.password \"\${rconpassword}\" -logfile"; }
EOF
  echo '    Custom Map URL for clients: '"${CUSTOM_MAP_URL}"
else
  apply-generated-map-settings
fi

if [ ! -f rcon_pass ]; then
  rand_password > rcon_pass
fi
(
  grep "$(<rcon_pass)" "$lgsm_cfg" || echo rconpassword="$(<rcon_pass)" >> "$lgsm_cfg"
) &> /dev/null
