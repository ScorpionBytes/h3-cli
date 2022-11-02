#!/bin/bash
#
# Utility functions used by other scripts in this guide.
#
# !! NOTE !! 
# H3_CLI_HOME must be set to the full path of the h3-cli directory.
# $ export H3_CLI_HOME=/path/to/h3-cli
#

OP_ID_FILE=$H3_CLI_HOME/.h3-cli.op_id


#
# writes message to stderr
# usage: echoerr "the message"
#
function echoerr { 
    echo "[`date`] $@" 1>&2;   
}

#
# writes message to stdout
# usage: echoerr "the message"
#
function echoinfo {
    echo "[`date`] $@" 
}

#
# asserts that required env vars have been set.
# usage: check_env_vars
#
function check_env_vars {
    if [ -z "$H3_CLI_HOME" ]; then 
        echoerr "ERROR: H3_CLI_HOME is required"
        exit 1
    fi
    if [ -z "$H3_API_KEY" ]; then 
        echoerr "ERROR: H3_API_KEY is required"
        exit 1
    fi
}

#
# Takes a GraphQL response payload and checks for errors.
# If an error is detected, it is printed to stderr and this script exits with RC=1.
# usage: check_gql_error $res
# $res: a JSON response from GraphQL
#
function check_gql_error {
    res=$1
    # -rx- echoerr "checking gql error on $res"
    error_message=`cat <<<$res | jq -r .errors[]?.message`
    if [ ! -z "$error_message" ]; then 
        echoerr "ERROR: $error_message" 
        exit 1
    fi
    # -rx- echoerr "check_gql_error exit"
}

#
# retrieve op_id from temp file 
# usage: read_op_id_file
#
function read_op_id_file {
    op_id=`cat $OP_ID_FILE`
    echo "$op_id"
}

#
# write op_id to temp file.
# usage: write_op_id_file $op_id
# $op_id: the op_id to write
#
function write_op_id_file {
    op_id=$1
    echo $op_id > $OP_ID_FILE
}

#
# wrap the op_id param in json.
# usage: op_id_to_json $op_id
# $op_id: the op_id to wrap in json
# 
function op_id_to_json {
    op_id=$1
    if [ -z "$op_id" ]; then
        return 0
    fi
    op_id_json=`cat <<HERE
{"op_id":"$op_id"}
HERE
`
    echo $op_id_json
}

#
# fetch and return the pentest record for the given op_id.
# usage: fetch_pentest $op_id
# $op_id: the op_id of the pentest
#
function fetch_pentest {
    op_id=$1
    # -rx- echoerr "fetch_pentest entry: $op_id"
    if [ -z "$op_id" ]; then
        return 0
    fi
    op_id_json=`op_id_to_json $op_id`
    res=`h3 pentest "$op_id_json"`
    # -rx- echoerr "fetch_pentest res: $res"
    check_gql_error "$res"      
    pentest=`cat <<<$res | jq .data.pentest`
    echo $pentest
}

#
# exit the bash script if the given pentest is still active.
# usage: exit_if_pentest_is_active $pentest
# $pentest: a pentest record in JSON format (as returned from fetch_pentest)
# 
function exit_if_pentest_is_active {
    pentest="$1"
    if [ -z "$pentest" ]; then
        return 0
    fi
    pentest_name=`cat <<<$pentest | jq -r .name`
    pentest_state=`cat <<<$pentest | jq -r .state`
    if [ "$pentest_state" = "done" -o "$pentest_state" = "ended" -o "$pentest_state" = "processing" ]; then
        return 0
    fi
    echoerr "ERROR: Pentest \"$pentest_name\" is still active; state=$pentest_state"
    exit 1
}


function exit_if_pentest_has_launched {
    pentest="$1"
    if [ -z "$pentest" ]; then
        return 0
    fi
    pentest_name=`cat <<<$pentest | jq -r .name`
    pentest_state=`cat <<<$pentest | jq -r .state`
    if [ "$pentest_state" = "scheduled" -o "$pentest_state" = "preparing" -o "$pentest_state" = "installation_needed" ]; then
        return 0
    fi
    echoerr "ERROR: Pentest \"$pentest_name\" has already launched; state=$pentest_state"
    exit 1
}


#
# schedule a pentest and return the Op record
# usage: schedule_pentest 
# usage: schedule_pentest '{"op_template_name":"your-op-template-here"}'
#
function schedule_pentest {
    json_params="$1"
    res=`h3 schedule_op_template "$json_params"`
    check_gql_error "$res"
    op=`cat <<<$res | jq .data.schedule_op_template.op`
    echo "$op"
}

#
# pause a pentest
# usage: pause_pentest $op_id
# $op_id: the op_id of the pentest
#
function pause_pentest {
    op_id=$1
    if [ -z "$op_id" ]; then
        return 0
    fi
    op_id_json=`op_id_to_json $op_id`
    res=`h3 pause_op "$op_id_json"`
    check_gql_error "$res"
}

#
# resume a pentest
# usage: resume_pentest $op_id
# $op_id: the op_id of the pentest
#
function resume_pentest {
    op_id=$1
    if [ -z "$op_id" ]; then
        return 0
    fi
    op_id_json=`op_id_to_json $op_id`
    res=`h3 resume_op "$op_id_json"`
    check_gql_error "$res"
}

#
# cancel a pentest
# usage: cancel_pentest $op_id
# $op_id: the op_id of the pentest
#
function cancel_pentest {
    op_id=$1
    if [ -z "$op_id" ]; then
        return 0
    fi
    op_id_json=`op_id_to_json $op_id`
    res=`h3 cancel_op "$op_id_json"`
    check_gql_error "$res"
}
