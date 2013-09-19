#!/bin/bash

source $(cd $(dirname $0); pwd)/lib.sh

if [ $# -lt 3 ]; then
    echo Usage: $0 [-y] REPO_TREE STASH_URL STASH_SSH
    exit 1
fi

if [ "$1" == "-y" ]; then
    interactive=
    shift
else
    interactive=yes
fi

log=$(mktemp)

repo_tree="$1"
s_base_url="$2"
s_ssh="$3"

read -ep "Stash Username: " s_username
read -esp "Stash Password: " s_password
echo

s_api_url=$s_base_url/rest/api/1.0

s_auth="$s_username:$s_password"

echo -n 'Extracting projects list... '
IFS=$'\n'
declare -a projects=($(get $s_api_url/projects?limit=65535 "$s_auth" |
    sed 's/}},{/\n/g' |
    sed -r 's/.*"key":"([^"]+)".*/\1/'))

echo "done (${#projects[@]} total)."

IFS=" "$'\t'$'\n'
declare -a repos=($(find "$repo_tree" -name '*?.git' | cut -b$(wc -c <<< "$repo_tree")- | cut -b2-))

i=0
for repo in ${repos[@]}; do
    i=$(($i+1))

    proj_link=$(grep -Eio "$(tr ' ' '|' <<< ${projects[@]})" <<< "$repo" |
        awk '{print length($1), $0}' |
        sort -nr |
        cut -d' ' -f2- |
        head -n1)
    if [ "$proj_link" ]; then
        proj_link="${proj_link^^}"
    fi

    progress=$(printf '[%3d/%3d]' $i ${#repos[@]})
    prompt=$(printf '%s {%s} link to (empty to skip): ' $progress $i ${#repos[@]} $repo)
    if [ "$interactive" ]; then
        if [ -z "$proj_link" ]; then
            read -p"$prompt" proj_link
        else
            read -e -p"$prompt" -i"$proj_link" proj_link
        fi
    fi

    if [ -z "$proj_link" ]; then
        continue
    fi

    if [ -z "$proj_link" ]; then
        proj_link=-i$(grep -Eo '^[^/]+/' <<< $repo | tr / -)
    fi

    repo_new=$(tr / - <<< "$repo" | sed -re "s/^$proj_link\W//I")
    repo_new=${repo_new%%.git}

    prompt=$(printf '%10s{%s} rename to: ' ' ' $repo)
    if [ "$interactive" ]; then
        read -ep "$prompt" -i"$repo_new" repo_new
    else
        echo $progress $repo -\> $proj_link/$repo_new
    fi

    post_json "$s_api_url/projects/$proj_link/repos" "$s_auth" \
        '{"name": "%s", "scmId": "git"}' "$repo_new" >> $log

    pushd . &> /dev/null
    cd "$repo_tree/$repo"
    git push --mirror "ssh://$s_ssh/${proj_link,,}/$repo_new.git"
    popd &> /dev/null
done

echo "Done. Log: $log"
