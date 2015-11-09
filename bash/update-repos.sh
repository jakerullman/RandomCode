#!/bin/bash

CUR_DIR=$(pwd)

echo -e "\n\033[1mPulling in the latest changes for all repositories...\033[0m\n"

for i in $(find . -name ".git" | cut -c 3-); do
	echo -e "";
	echo -e "\033[33m"$i"\033[0m";

	# go to parent dir to call pull
	cd "$i";
	cd ..;

	git pull origin master;

	cd $CUR_DIR
done

echo -e "\n\033[32mComplete!\033[0m\n"
