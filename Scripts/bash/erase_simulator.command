#!/bin/bash --login

if xcrun simctl list devices | grep ${1} | grep Booted > /dev/null ; then
    xcrun simctl shutdown ${1}
fi
xcrun simctl erase ${1}
xcrun simctl boot ${1}
open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/

exit

