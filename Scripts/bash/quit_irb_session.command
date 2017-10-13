#!/bin/bash --login

ps axg | grep create_irb_session.command | grep ??>/dev/null
if [ $? -eq 0 ]; then
ps axg | grep create_irb_session.command | grep ?? | awk '{print "kill -9 " $1}' | sh
fi
