#!/bin/bash

source $(cd $(dirname $0); pwd)/lib.sh

if [ $# -lt 1 -o $# -gt 2 ]; then
    echo Usage: $0 [-i] STASH_URL
    exit 1
fi

if [ "$1" == "-i" ]; then
    shift
    interactive=yes
else
    interactive=
fi

s_base_url="$1"

read -ep "Stash Username: " s_username
read -esp "Stash Password: " s_password
echo

s_api_url=$s_base_url/rest/api/1.0
s_auth="$s_username:$s_password"
log=$(mktemp)

echo -n 'Extracting projects list... '
IFS=$'\n'
declare -a projects=($(get $s_api_url/projects?limit=65535 "$s_auth" |
    sed 's/}},{/\n/g' |
    sed -r 's/.*"key":"([^"]+)".*/\1/'))
echo "done (${#projects[@]} total)."

echo "WARNING! ALL PROJECT DATA WILL BE WIPED OUT FROM $s_base_url!"
read -p"Type YES to erase all data: " ok
if [ "$ok" != "YES" ]; then
    exit 1
fi

IFS=$'\t'$'\n'
i=0
for project in "${projects[@]}"; do
    i=$(($i+1))
    printf '[%3d/%3d] wiping %-15s\n' $i ${#projects[@]} $project
    declare -a repos=($(get $s_api_url/projects/$project/repos?limit=65535 "$s_auth" |
        sed 's/}},{/\n/g' |
        sed -r 's/.*"slug":"([^"]+)".*/\1/'))
    for repo in "${repos[@]}"; do
        if [ "$interactive" ]; then
            prompt=$(printf '%10sremove repo %-15s? (y/n) ' ' ' $repo)
            yes=
            while grep -vqi '[yn]' <<< "$yes"; do
                read -p"$prompt" -ei n yes
            done
        else
            yes="y"
        fi
        if [ "$yes" == "y" ]; then
            printf '%10sremoving repo %-15s\n' ' ' $repo
            delete "$s_api_url/projects/$project/repos/$repo" "$s_auth" >> $log
        fi
    done
    delete "$s_api_url/projects/$project" "$s_auth" >> $log
done

echo "Done. Log: $log"
