#!/bin/bash --login

dir=$(find ${1} -maxdepth 6 -type d -name 'features' -print -quit)
grep -R "@" ${dir} | tr -s " " "\012" | sed -n -e '/^@/p' | tr -d @ | sort -u
exit
