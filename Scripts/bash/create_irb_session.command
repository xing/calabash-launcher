#!/bin/bash --login

file=${1}/Gemfile

if [ ! -e "$file" ]; then
echo "The path to your build could be wrong"
suffix="Calabash Launcher.app/Contents/Resources/helpers.rb"
NEW=${2%$suffix}
cd $NEW
cd "Calabash Launcher.app"
cd Contents/Resources/
bundle update
else
cd ${1}
fi
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TEST_PATH=$1
export HELPERS_FILE=$2

rm /tmp/calabash_pipe
mkfifo /tmp/calabash_pipe

if [[ $(bundle check) != *"The Gemfile's dependencies are satisfied"* ]];then
echo "Installing missing Gems"
bundle install
fi

calabash-ios console <<EOF

require_relative ENV['HELPERS_FILE']
eval_loop

EOF

exit

