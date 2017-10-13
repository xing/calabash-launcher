#!/bin/bash --login

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

echo "screenshot_handling_no_loop">/tmp/calabash_pipe
echo "get_elements_by_offset(${1}, 667 - ${2})">/tmp/calabash_pipe

exit

