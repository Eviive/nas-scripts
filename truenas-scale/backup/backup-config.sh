#!/bin/bash

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
IFS=$'\n\t'

source .backup-config-env

server_url="https://truenas.home.albertv.dev"
api_key=$TRUENAS_SCALE_BACKUP_API_KEY
secret_seed="true"
backup_location="/mnt/hdd-1/truenas-scale/backups/config"
keep_last=10

truenas_scale_version=$(cut -d' ' -f1 < /etc/version)

backup_directory="$backup_location/$truenas_scale_version"

mkdir -p "$backup_directory"

if [[ $secret_seed = true ]]; then
  backup_extension="tar"
else
  backup_extension="db"
fi

backup_name=$(date +%Y%m%d-%H%M%S).$backup_extension
backup_path="$backup_directory/$backup_name"

last_backup_name=$(find "$backup_directory" -mindepth 1 -printf "%f\n" | sort -n | tail -1)

if [[ -z "$last_backup_name" ]]; then
  last_backup_path=""
else
  last_backup_path="$backup_directory/$last_backup_name"
fi

curl --no-progress-meter \
  -X "POST" \
  "$server_url/api/v2.0/config/save" \
  -H "Authorization: Bearer $api_key" \
  -H "Accept: */*" \
  -H "Content-Type: application/json" \
  -d '{"secretseed": '$secret_seed'}' \
  --output "$backup_path"

if [[ -n "$last_backup_path" ]] && [[ $backup_path != "$last_backup_path" ]] && cmp -s "$backup_path" "$last_backup_path"; then
  echo "Config hasn't changed, exiting..."
  rm "$backup_path"
  exit
fi

if [[ $keep_last -ne 0 ]]; then
  number_of_files=$(find "$backup_directory" -mindepth 1 | wc -l)

  if [[ $keep_last -lt "$number_of_files" ]]; then
    number_of_files_to_remove="$((number_of_files - keep_last))"
    echo "Removing $number_of_files_to_remove files in order to retain the last $keep_last backups..."

    while [[ $number_of_files_to_remove -gt 0 ]]; do
      file_to_remove=$(find "$backup_directory" -mindepth 1 -printf "%f\n" | sort -r | tail -1)
      echo "Removing $backup_directory/$file_to_remove..."
      rm "$backup_directory/$file_to_remove"
      number_of_files_to_remove="$((--number_of_files_to_remove))"
    done
  fi
fi

echo "Backed up config to $backup_path"
