#!/bin/bash --login

xcrun instruments -s devices | grep -E "Simulator" | grep -E 'iPhone|iPad' |  sed '/Watch/d' | sort -nr -t/ -k2,2

