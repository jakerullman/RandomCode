#!/bin/bash

if [[ -z $1 && -z $2 ]]; then
    echo "No message passed"
else
    if [[ -z $2 ]]; then
        curl -s --form-string "token=MYAPPTOKEN" --form-string "user=MYUSERTOKEN" --form-string "message=$1" https://api.pushover.net/1/messages.json
    else
        curl -s --form-string "token=MYAPPTOKEN" --form-string "user=MYUSERTOKEN" --form-string "title=$1" --form-string "message=$2"  https://api.pushover.net/1/messages.json
    fi
fi
