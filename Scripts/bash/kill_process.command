#!/bin/bash --login


ps axg | grep irb | grep ?? | awk '{print "kill -9 " $1}' | sh
ps axg | grep .command | grep ?? | awk '{print "kill -9 " $1}' | sh
#ps axg | grep get_screen | grep ?? | awk '{print "kill -9 " $1}' | sh

exit
