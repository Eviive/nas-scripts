#!/bin/bash

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
IFS=$'\n\t'

qbt_host=$QBITTORRENT_HOST
qbt_username=$QBITTORRENT_USERNAME
qbt_password=$QBITTORRENT_PASSWORD

declare -a live_trackers_list_urls=(
  "https://cf.trackerslist.com/best.txt"
  "https://raw.githubusercontent.com/ngosang/trackerslist/refs/heads/master/trackers_best.txt"
  "https://newtrackon.com/api/stable"
)

url_encode() {
  local string="${1}"

  if command -v xxd >/dev/null 2>&1; then
    printf '%s' "$string" | xxd -p | sed 's/\(..\)/%\1/g' | tr -d '\n'
  else
    jq -nr --arg s "$string" '$s|@uri'
  fi
}

get_cookie() {
  echo "Logging in to qBittorrent..."

  if ! encoded_username=$(url_encode "$qbt_username"); then
    echo "Error during URL encoding of username"
    return 1
  fi

  if ! encoded_password=$(url_encode "$qbt_password"); then
    echo "Error during URL encoding of password"
    return 1
  fi

  qbt_cookie=$(curl "$qbt_host/api/v2/auth/login" \
    -fsS \
    --header "Referer: $qbt_host" \
    --cookie-jar - \
    --data "username=${encoded_username}&password=${encoded_password}")
}

generate_trackers_list() {
  trackers_list=""
  all_failed=true

  for url in "${live_trackers_list_urls[@]}"; do
    echo "Fetching trackers from $url..."
    new_trackers=$(curl -sS "$url")
    if [[ $? -eq 0 && -n "$new_trackers" ]]; then
      trackers_list+="$new_trackers"$'\n'
      all_failed=false
    else
      echo "Failed to fetch trackers from $url."
    fi
  done

  if [[ $all_failed == true ]]; then
    echo "All live tracker URLs failed. Aborting."
    exit 1
  fi

  trackers_list=$(echo "$trackers_list" | sed -r '/^\s*$/d' | sort -u)

  if [[ -z $trackers_list ]]; then
    echo "No trackers found. Aborting."
    exit 1
  fi
}

set_application_preferences() {
  echo "Setting trackers in qBittorrent..."

  payload='{"add_trackers":"'
  payload+=$trackers_list
  payload+='"}'

  if ! encoded_payload=$(url_encode "$payload"); then
    echo "Error during URL encoding of password"
    return 1
  fi

  echo "$qbt_cookie" | curl "$qbt_host/api/v2/app/setPreferences" \
    -fsS \
    -X POST \
    -H "Referer: $qbt_host" \
    -b - \
    --data-raw "json=$encoded_payload"
}

get_cookie

generate_trackers_list

set_application_preferences
