#!/bin/bash --login
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

echo "set_sim_locale_and_lang('${1}', '${2}')">/tmp/calabash_pipe
echo "start_test_server_in_background(:device => '${1}')">/tmp/calabash_pipe

exit

