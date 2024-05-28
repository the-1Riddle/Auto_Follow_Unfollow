#!/bin/env bash

# GitHub username and token
GITHUB_USERNAME="${GITHUB_USERNAME}"
USAGE_TOKEN="${USAGE_TOKEN}"

# Function to fetch all pages of users
fetch_all_users() {
  local url=$1
  local users=()
  local page=1

  while : ; do
    response=$(curl -s -u "$GITHUB_USERNAME:$USAGE_TOKEN" "$url?per_page=100&page=$page")
    usernames=$(echo "$response" | jq -r '.[].login')

    if [[ -z "$usernames" ]]; then
      break
    fi

    while read -r username; do
      users+=("$username")
    done <<< "$usernames"

    ((page++))
  done

  echo "${users[@]}"
}

# Fetch all followers and following users
FOLLOWERS=($(fetch_all_users "https://api.github.com/users/$GITHUB_USERNAME/followers"))
FOLLOWING=($(fetch_all_users "https://api.github.com/users/$GITHUB_USERNAME/following"))

# Finds and follow back user that are following
for USERNAME in "${FOLLOWERS[@]}"; do
  if [[ ! " ${FOLLOWING[@]} " =~ " ${USERNAME} " ]]; then
    curl -s -L \
      -X PUT \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $USAGE_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/user/following/$USERNAME"
  fi
done

# Finds and unfollow users who aint following back
for USERNAME in "${FOLLOWING[@]}"; do
  if [[ ! " ${FOLLOWERS[@]} " =~ " ${USERNAME} " ]]; then
    curl -s -L \
      -X DELETE \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $USAGE_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/user/following/$USERNAME"
  fi
done
