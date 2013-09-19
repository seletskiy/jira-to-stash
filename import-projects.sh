#!/bin/bash

source $(cd $(dirname $0); pwd)/lib.sh

if [ $# -ne 2 ]; then
    echo Usage: $0 JIRA_URL STASH_URL
    exit 1
fi

j_base_url="$1"
s_base_url="$2"

read -ep "Jira Username: " j_username
read -esp "Jira Password: " j_password
echo

read -ep "Stash Username: " -i"$j_username" s_username
read -esp "Stash Password: " s_password
echo

j_auth_url=$j_base_url/rest/auth/1
j_api_url=$j_base_url/rest/api/2
s_api_url=$s_base_url/rest/api/1.0

j_auth="$j_username:$j_password"
s_auth="$s_username:$s_password"

echo -n 'Extracting projects list... '
IFS=$'\n'
declare -a projects=($(get $j_api_url/project "$j_auth" |
    sed 's/}},{/\n/g' |
    sed -r 's/.*"key":"([^"]+)","name":"([^"]+)".*"48x48":"([^"]+)".*/\1\t\2\t\3/'))
echo 'done.'

IFS=$'\t'$'\n'
i=0
for row in "${projects[@]}"; do
    i=$(($i+1))
    read key name avatar_url <<< "$row"
    printf '[%3d/%3d] importing %-15s\n' $i ${#projects[@]} $key
    avatar=$(get "$avatar_url" "$j_auth" | base64 -w0)
    post_json "$s_api_url/projects" "$s_auth" \
        '{"key": "%s", "name": "%s", "avatar": "data:image/png;base64,%s"}' \
        $key $name $avatar >> $log
done

echo "Done. Log: $log"
