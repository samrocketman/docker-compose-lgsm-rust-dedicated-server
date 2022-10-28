#!/bin/bash

backup_name="lgsm-rustserver-backup.tgz"
list_all=false

function python() {
  if type -P python3 > /dev/null; then
    command python3 "$@"
  elif type -P python > /dev/null; then
    command python "$@"
  else
    echo 'Python 2 or 3 could not be found. You may make it available via virtualenv.' >&2
    echo '    python3 -m venv .venv' >&2
    echo '    source .venv/bin/activate' >&2
    echo 'Note: you can run "deactivate" to unload venv.' >&2
    exit 1
  fi
}

while [ $# -gt 0 ]; do
  if [ "$1" = "--all" ]; then
    list_all=true
  fi
  if grep -- 'tgz$' >& /dev/null <<< "$1"; then
    backup_name="$1"
  fi
  shift
done

if ! ls backups/*"$backup_name" &> /dev/null; then
  echo 'No backups found.'
  exit
fi

function print_file() {
  local date="$(grep -o '[0-9]\+_' <<< "$1" | sed 's/_$//')"
  date="$(date -d @"$date")"
  echo "|  $date  |  $1  |"
}

function limit_output() {
  if [ "$1" = 'true' ]; then
    cat
  else
    cat | tail -n5
  fi
}

if [ "$list_all" = 'true' ]; then
  echo 'ALL BACKUP FILES'
else
  echo 'LAST 5 BACKUP FILES (use --all option to show all)'
fi

python -c 'print("="*95)'

for x in backups/*"$backup_name"; do
print_file "$x"
done | limit_output "$list_all"
python -c 'print("="*95)'

if [ "$backup_name" = 'lgsm-rustserver-backup.tgz' ]; then
  echo
  echo 'Restore your backup with the following command.'
  echo '    ./admin/backup/restore-backup.sh backups/file.tgz'
  echo
fi
