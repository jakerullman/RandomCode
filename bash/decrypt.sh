#!/bin/bash

IFS=$'\n'

dest=$1
echo "extracting files to ${dest}"
mkdir -p ${dest}
shift

read -s -p "Password" password

for f in $@; do
    echo $f
    filename=$(basename $f)
    dest_path="${dest}/${filename%.gpg}"
    echo $password | gpg --output "${dest_path}" --batch --passphrase-fd 0 --decrypt $f
    cd $(dirname $dest_path)
    tar xf $dest_path
    rm $dest_path
done
