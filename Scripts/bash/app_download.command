#!/bin/bash --login
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

filename=${1##*/}
extension=${filename##*.}
PATH_TO_MOVE=${3}

cd ${2}
rm ${filename}
curl -O ${1}
if [ -e "$filename" ]; then
    echo "${filename} has been succesfully downloaded"
    if [[ ${PATH_TO_MOVE} ]]; then
        echo "Moving downloaded app to ${3} folder"
        mv ${filename} ${PATH_TO_MOVE}
    else
        PATH_TO_MOVE=.
    fi
else
    echo "Whoops, looks like your link is incorrect: '${1}'"
fi

if [ ${extension} == "zip" ]; then
    echo "Extracting app from archive"
    ditto -xk ${PATH_TO_MOVE}/${filename} ${PATH_TO_MOVE}
    rm ${PATH_TO_MOVE}/${filename}
    echo "Extracted Succesfully"
fi
