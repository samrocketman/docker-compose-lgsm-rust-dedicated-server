#!/bin/bash

if ! ls backups/*.tgz &> /dev/null; then
  echo 'No backups found.'
  exit
fi

function print_file() {
  local date="$(grep -o '[0-9]\+_' <<< "$1" | sed 's/_$//')"
  date="$(date -d @"$date")"
  echo "|  $date  |  $1  |"
}

function limit_output() {
  if [ "$1" = '--all' ]; then
    cat
  else
    cat | head -n5
  fi
}

if [ "$1" = '--all' ]; then
  echo 'ALL BACKUP FILES'
else
  echo 'LAST 5 BACKUP FILES (use --all option to show all)'
fi

python -c 'print("="*95)'

for x in  backups/*.tgz; do
print_file "$x"
done | limit_output "$1"
python -c 'print("="*95)'

echo
echo 'Restore your backup with the following command.'
echo '    ./admin/backup/restore-backup.sh backups/file.tgz'
echo
