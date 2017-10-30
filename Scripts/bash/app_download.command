#!/bin/bash --login
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

filename=${1##*/}
extension=${filename##*.}

cd ${2}
rm ${filename}
curl -O ${1}
if [ -e "$filename" ]; then
    echo "${filename} has been succesfully downloaded"
else
    echo "Whoops, looks like your link is incorrect: '${1}'"
fi

if [ ${extension} == "zip" ]; then
    echo "Extracting APP from archieve"
    ditto -xk ${filename} .
    rm ${filename}
    echo "Extracted Succesfully"
fi
