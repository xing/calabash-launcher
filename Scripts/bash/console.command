#!/bin/bash --login

file=${1}/Gemfile

if [ ! -e "$file" ]; then
echo $file
echo "The path to Calabash folder is incorrect; please choose the right one. File chooser is in the app Settings"
else

if open -Ra "iTerm" ; then
osascript <<EOD

tell application "iTerm"
tell current window
create window with default profile
tell current session
write text "cd ${1} && bundle exec calabash-ios console"

end tell
end tell
end tell
EOD

else
osascript <<EOD

tell application "Terminal"

do script "cd ${1} && bundle exec calabash-ios console"

end tell

EOD
fi

fi


exit
