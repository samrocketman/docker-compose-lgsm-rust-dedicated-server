#!/bin/bash

if [ ! -d .git -a ! -d admin ]; then
  echo 'ERROR: must run this command from the root of the git repository.' >&2
  exit 1
fi

echo 'List of log files:'
docker compose exec -T lgsm find log -type f -name '*[0-9]*' -exec du -ch {} + |
  awk '
$2 == "total" {
  total=$1;
  next
};
{
 print "    "$2
};
END {
  print "Log size to be removed: "total
}'

cat <<EOF
WARNING: This is a permanent action.

Logs are not included in server backups due to their potential size.  Removed
logs will be unrecoverabled.  If you wish to save logs before, then you must
cancel this script and run the following script.

    ./admin/logs/create-backup.sh

EOF
read -erp 'Do you wish to permanently delete all logs? (y/N) ' response

if [ ! "$response" = y -a ! "$response" = Y ]; then
  echo 'Operation aborted.  Respond "y" next time if you want to proceed.'
  exit
fi

docker compose exec -T lgsm find log -type f -name '*[0-9]*' -exec rm -f {} +

cat <<'EOF'
Restart your server to complete cleanup.  Run the following commands.

    docker compose down
    docker compose up -d

EOF
