#!/bin/bash

function cleanup_on() {
  if [ "$1" -ne 0 ]; then
    # backup failed so remove the bad backup file
    [ ! -f "backups/${BACKUP_FILE:-dummy.txt}" ] ||
      rm -f "backups/${BACKUP_FILE:-dummy.txt}"
  fi
}
trap 'cleanup_on $?' EXIT

set -e

# set the working directory to repository root
# only when this script is called by full path; e.g. from cron job
if grep '^/' <<<  "$0" > /dev/null; then
  echo "Changing working directory to: ${0%admin/*}"
  cd "${0%admin/*}"
fi

BACKUP_FILE="$(date  +%Y-%d-%m-%s)"_lgsm-logs-backup.tgz
export BACKUP_FILE

[ -d backups ] || mkdir backups
docker compose exec -Tu linuxgsm lgsm tar -czv log > backups/"$BACKUP_FILE"
(
echo
echo -n 'Created backup file: '
ls ./backups/"$BACKUP_FILE"
echo
)
