#!/bin/bash --login

if [[ ${3} == "simulator" ]];then
    EXT=app
else
    EXT=ipa
fi

APP_LOCATION=$(find ${2} -name "*.${EXT}" -print)

if (( $(grep -c . <<<"$APP_LOCATION") > 1 )); then
    echo "Multiple application bundle has found. Please keep only one that you want to install or define the path to your app in the settings"
elif (( $(grep -c . <<<"$APP_LOCATION") == 1 )); then
        if [[ ${3} == "simulator" ]];then
            if ! xcrun simctl list devices | grep ${1} | grep Booted > /dev/null ; then
                xcrun simctl boot ${1}
                open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/
            fi
            xcrun simctl install ${1} $APP_LOCATION
        else
            if [[ $(which brew) != *"/usr/local/bin/brew"* ]];then
                echo "Seems like you don't have 'brew' installed. Please install it by running: '/usr/bin/ruby -e \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\"' from your console"
            fi
            if [[ $(which node) != *"/usr/local/bin/node"* ]];then
                echo "Seems like you don't have 'node' installed. Please install it by running: 'brew install node' from your console"
            fi
            if [[ $(which ios-deploy) != *"/usr/local/bin/ios-deploy"* ]];then
                echo "Seems like you don't have 'ios-deploy' installed. Please install it by running: 'npm install -g ios-deploy' from your console"
            fi
            ios-deploy --uninstall --debug --bundle $APP_LOCATION
        fi
else
    echo "No files with *.${EXT} extension was found. Please make sure that the app is inside the test folder"
fi

exit

