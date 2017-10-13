#!/bin/bash --login

xcrun instruments -s devices | grep -E "Simulator" | sed '/Known Devices:/d' | sed '/nb/d' | sed '/Apple Watch -/d' | sed '/Apple TV/d' | sort -nr -t/ -k2,2>/tmp/allout.txt 2>&1
xcrun instruments -s devices | sed '/Simulator/d' | sed '/Known Devices:/d' | sed '/nb/d' | sed '/Apple Watch -/d' | sed '/Apple TV/d'>/tmp/phys_dev.txt 2>&1


if xcrun instruments -s devices | sed '/Simulator/d' | sed '/Known Devices:/d' | sed '/nb/d' | sed '/Apple Watch/d' | grep -q '(null)'; then
  echo "Please unlock your iPhone and tap on 'Trust' button"
fi

exit
