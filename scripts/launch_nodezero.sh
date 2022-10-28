#!/bin/bash
#
# Simple shell script for downloading and launching NodeZero.
#
# The script reads the op_id from the $H3_CLI_HOME/.h3-cli.op_id.  This file is written by start_pentest.sh.
#
# NodeZero will continue running the pentest in the background (as a Docker container) after this script exits
# (in other words, the script does not wait for NodeZero to finish).
#
# usage: launch_nodezero.sh 
#
#

# 0.
# include common utils
d=`dirname $0`
source $d/utils.sh
check_env_vars

# 1. 
# check if the pentest has already launched 
op_id=`read_op_id_file`
pentest=`fetch_pentest $op_id`
exit_if_pentest_has_launched "$pentest"

# 2. 
# download and run NodeZero™ IFF this is a NodeZero pentest
op_type=`cat <<<$op | jq -r .op_type`
if [ "$op_type" = "NodeZero" ]; then
    nodezero_script_url=`cat <<<$op | jq -r .nodezero_script_url`
    echoinfo "Downloading and launching NodeZero™ via the NodeZero launch script: $nodezero_script_url ... "
    curl "$nodezero_script_url" | bash 
fi

