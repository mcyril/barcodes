#!/bin/bash

hg pull -u

list=($(cat .hgsub | sed -n -e 's/ = .*//p'))

# echo ${list[@]}

for c in ${list[*]}; do
	pushd $c > /dev/null
	
	echo ">> SUB UP: $c"
	
	if [ -d .svn ]; then
		svn up
	else if [ -d .git ]; then
		git pull
	else if [ -d .hg ]; then
		hg pull -u
	fi fi fi

	popd > /dev/null
done
