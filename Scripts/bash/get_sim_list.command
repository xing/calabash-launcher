#!/bin/bash --login

xcrun instruments -s devices | grep -E "Simulator" | sed '/Known Devices:/d' | sed '/nb/d' | sed '/Apple Watch -/d' | sed '/Apple TV/d' | sort -nr -t/ -k2,2

