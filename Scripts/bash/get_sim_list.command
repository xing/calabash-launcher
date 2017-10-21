#!/bin/bash --login

xcrun instruments -s devices | grep -E "Simulator" | grep -E 'iPhone|iPad' | sort -nr -t/ -k2,2

