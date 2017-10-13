#!/bin/bash --login

file=${5}/Gemfile
if [ ! -e "$file" ]; then
echo $file
echo "The path to Calabash folder is incorrect, please choose the right one. File chooser is in the APP Settings"
exit
fi

export ${3}
export ${4}
export ${1}

cd ${5}

if [[ $(bundle check) != *"The Gemfile's dependencies are satisfied"* ]];then
echo "Installing missing Gems"
bundle install
fi

cd ${5} && bundle exec cucumber -c ${6} ${2}
exit
