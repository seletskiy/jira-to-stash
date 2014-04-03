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

put() {
    local url="$1"
    local auth="$2"
    local data="$3"

    curl -s \
        -X PUT \
        -H"Authorization: Basic $(echo -n "$auth" | base64 -w0)" \
        -H"Content-Type: application/json; charset=utf-8" \
        -d $data \
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
