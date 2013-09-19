#!/bin/bash

post_json() {
    local url="$1"
    local auth="$2"
    local template="$3"

    shift 3

    printf "$template" "$@" |
        curl -s -d@- \
            -H'Content-Type: application/json' \
            -H"Authorization: Basic $(echo -n "$auth" | base64 -w0)" \
            $url
}

get() {
    local url="$1"
    local auth="$2"

    curl -s \
        -H"Authorization: Basic $(echo -n "$auth" | base64 -w0)" \
        $url
}

delete() {
    local url="$1"
    local auth="$2"

    curl -s \
        -X DELETE \
        -H"Authorization: Basic $(echo -n "$auth" | base64 -w0)" \
        $url
}
