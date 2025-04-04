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

get_cookie() {
  echo "Logging in to qBittorrent..."

  qbt_cookie=$(curl "$qbt_host/api/v2/auth/login" \
    -sSL \
    --header "Referer: $qbt_host" \
    --cookie-jar - \
    --data-urlencode "username=$qbt_username" \
    --data-urlencode "password=$qbt_password"
  )
}

generate_trackers_list() {
  trackers_list=""
  all_failed=true

  for url in "${live_trackers_list_urls[@]}"; do
    echo "Fetching trackers from $url..."

    if new_trackers=$(curl -sSL "$url") && [[ -n "$new_trackers" ]]; then
      trackers_list+="$new_trackers"$'\n'
      all_failed=false
    else
      echo "Failed to fetch trackers from $url."
    fi
  done

  if [[ $all_failed = true ]]; then
    echo "All live tracker URLs failed. Aborting."
    exit 1
  fi

  trackers_list=$(echo "$trackers_list" | sort -u | sed -e '1{/^$/d}' -e 's/$/\n/')

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

  echo "$qbt_cookie" | curl "$qbt_host/api/v2/app/setPreferences" \
    -sSL \
    -X POST \
    -H "Referer: $qbt_host" \
    -b - \
    --data-raw "json=$payload"
}

get_cookie

generate_trackers_list

set_application_preferences

echo "Finished updating qBittorrent trackers"
