#!/bin/bash

source $(cd $(dirname $0); pwd)/lib.sh

if [ $# -ne 1 ]; then
	echo Usage: $0 STASH_URL
	exit 1
fi

s_base_url="$1"

hook_exe="\/home\/stash\/git-hooks\/pre-receive" # must be escaped
hook_params=""

read -ep "Stash Username: " s_username
read -esp "Stash Password: " s_password
echo

s_api_url=$s_base_url/rest/api/1.0
s_auth="$s_username:$s_password"
log=/tmp/install-hook.log

echo -n 'Extracting projects list... '
IFS=$'\n'
declare -a projects=($(get $s_api_url/projects?limit=65535 "$s_auth" |
	sed 's/}},{/\n/g' |
	sed -r 's/.*"key":"([^"]+)".*/\1/'))
echo "done (${#projects[@]} total)."

IFS=$'\t'$'\n'
i=0
for project in "${projects[@]}"; do
	i=$(($i+1))
	read -p"          process $project? [Y/n] " ok
	if [ "$ok" != "Y" -a "$ok" != "" ]; then
		continue
	fi

	printf '[%3d/%3d] updating %-15s\n' $i ${#projects[@]} $project
	declare -a repos=($(get $s_api_url/projects/$project/repos?limit=65535 "$s_auth" |
		sed 's/}},{/\n/g' |
		sed -r 's/.*"slug":"([^"]+)".*/\1/'))
	for repo in "${repos[@]}"; do
		read -p"          install hook to $repo? [Y/n] " ok
		if [ "$ok" != "Y" -a "$ok" != "" ]; then
			continue
		fi

		printf '%10supdating repo %-15s\n' ' ' $repo
		hl_url="$s_api_url/projects/$project/repos/$repo/settings/hooks"
		hook_pre=($(get $hl_url $s_auth | grep -oE 'key":"[^"]+"' |
			grep 'external-pre-receive' | cut -f3 -d\"))
		hook_post=($(get $hl_url $s_auth | grep -oE 'key":"[^"]+"' |
			grep 'external-post-receive' | cut -f3 -d\"))
		he_url_pre="$s_api_url/projects/$project/repos/$repo/settings/hooks/$hook_pre/enabled"
		he_url_post="$s_api_url/projects/$project/repos/$repo/settings/hooks/$hook_post/enabled"
		echo "pre_receive url $he_url_pre" >> $log
		delete "$he_url_pre" "$s_auth" >> $log
		delete "$he_url_post" "$s_auth" >> $log
		echo >> $log
		data_post="{\"exe\":\"$hook_exe\", \"params\": \"$hook_params\"}"
		put "$he_url_pre" "$s_auth" "$data_post" >> $log
		echo >> $log
	done
done

echo "Done. Log: $log"
