#!/bin/bash --login

xcrun instruments -s devices | grep -E "\(" | sed '/Simulator/d'


