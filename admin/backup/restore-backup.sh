#!/bin/bash

set -e

if [ ! -d .git -a ! -d admin ]; then
  echo 'ERROR: must run this command from the root of the git repository.' >&2
  exit 1
fi

if [ "$#" -ne 1 ]; then
  echo 'ERROR: No backup file argument given.  For example,' >&2
  echo '    ./admin/backup/restore-backup.sh backups/file.tgz' >&2
  exit 1
fi

ls "$1" > /dev/null

if [ ! "$(tar -tzf "$1" | head -n1)" = 'lgsm/' ]; then
  echo "File: $1"
  echo 'ERROR: File exists but not a valid backup.' >&2
  exit 1
fi

cat <<EOF
WARNING: This is a permanent action.

All maps, config, plugin config, and lgsm config  will be destroyed including
save backups in order to restore your backup:

    $1

EOF
read -erp 'Do you wish to delete the current map? (y/N) ' response

if [ ! "$response" = y -a ! "$response" = Y ]; then
  echo 'Operation aborted.  Respond "y" next time if you want to proceed.'
  exit
fi

server_container_id="$(docker compose ps -q lgsm)"

if [ -z "${server_container_id}" ]; then
  echo 'ERROR: Rust server not running... did you "docker compose up -d"?'
  exit 1
fi

echo "Restoring $1"

# copy backup file to server
backup_file="${1##*/}"
docker cp "$1" "${server_container_id}:/home/linuxgsm/${backup_file}"
docker compose exec -T lgsm chown linuxgsm: /home/linuxgsm/"${backup_file}"

# restore backup and reboot the server
docker compose exec -Tu linuxgsm lgsm bash -ex <<EOF
# kill the uptime monitor before restoring
if pgrep -f monitor-rust-server.sh &> /dev/null; then
  echo 'Stopping uptime monitor.'
  kill "\$(pgrep -f monitor-rust-server.sh)"
fi
./rustserver stop || true

REMOVE_DIRS=(
  lgsm
  serverfiles/server
)
if [ -d serverfiles/oxide ]; then
  REMOVE_DIRS+=( serverfiles/oxide )
fi

find "\${REMOVE_DIRS[@]}" \\( ! -type d \\) -exec rm -f {} +
tar -xzvf '${backup_file}'

rm -f '${backup_file}'

cat <<'EOT'
Rebooting the server in 3 seconds...
Watch restart logs with the following command.

    docker compose logs -f

EOT
echo ''
sleep 3
pgrep tail | xargs kill
EOF
