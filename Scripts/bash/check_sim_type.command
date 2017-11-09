#!/bin/bash --login

result=$(xcrun simctl list devices | grep -E Booted | grep -E 'iPhone 6 |iPhone 7 |iPhone 8 ')

if [ -z "$result" ]; then
    echo "Wrong device"
else
    echo "Correct device"
fi

