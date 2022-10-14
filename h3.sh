#!/bin/bash
#
# Simple utility for posting a GraphQL query to the H3 API.
# Reads the GraphQL query from a file, writes the response to STDOUT.
#
# See the accompanying README.md for usage info.
#

function echoerr { 
    echo "$@" 1>&2;   
}
 

if [ -z "$H3_API_KEY" ]; then
    echoerr "H3_API_KEY environment variable required"
    exit 1
fi

if [ -z "$H3_AUTH_URL" ]; then
    H3_AUTH_URL=https://api.horizon3ai.com/v1/auth
fi

if [ -z "$H3_GQL_URL" ]; then
    H3_GQL_URL=https://api.horizon3ai.com/v1/graphql
fi


# JWT is stored here
jwt_file=".h3-cli.jwt"

# -------------------------------------------------------------------------
# functions to gen/read/refresh the authentication token (JWT)
# -------------------------------------------------------------------------

# @returns json response: {"token":"..."}
function gen_jwt {
    curl -s -S -k \
      -X POST $H3_AUTH_URL \
      -H 'Content-Type: application/json' \
      -d "{\"key\": \"$H3_API_KEY\"}"

}


function refresh_jwt {
    echoerr "re-authenticating to H3_AUTH_URL=$H3_AUTH_URL ..."
    H3_API_JWT=`gen_jwt | jq -r .token`
    # echoerr H3_API_JWT=$H3_API_JWT
    echo $H3_API_JWT > $jwt_file
}


# 1. check env var 
# 2. read it from the file
# 3. refresh it
# sets H3_API_JWT in the environment
function read_jwt {
    if [ -z "$H3_API_JWT" ]; then
        if [ -f $jwt_file ]; then
            H3_API_JWT=`cat $jwt_file`
            H3_API_JWT=`echo $H3_API_JWT`    # gets rid of newlines 
        fi 
    fi
    if [ -z "$H3_API_JWT" ]; then
        refresh_jwt
    fi
}

# -------------------------------------------------------------------------
# functions to read the graphql query from a file, clean it, and post it
# -------------------------------------------------------------------------

# TODO: dont think STDIN will work since we're now taking $variables as the 2nd param.
# reads the graphql query from STDIN or first arg
function read_query {
    f=${1--} # POSIX-compliant; ${1:--} can be used either.
    cat -- "$f"
}


function escape_quotes {
    # echo "$1" | sed 's/"/\\"/g'
    cat <<<$1 | sed 's/"/\\"/g'
}


# @returns gql response (json)
function post_query {
    q=`escape_quotes "$1"`
    v="$2"
    # echoerr $q
    # echoerr $v
    if [ -z "$v" ]; then v="{}"; fi
    curl -s -S -k \
      -X POST $H3_GQL_URL/ \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $H3_API_JWT" \
      -d @- <<HERE 
{
    "query": "$q",
    "variables": $v
}
HERE
}

# -------------------------------------------------------------------------
# main function
# -------------------------------------------------------------------------

# read / refresh the jwt.
# read the graphql query from the file/stdin.
# post the query
# catch auth failures, refresh jwt, retry
# print out the response
function main {
    # check re-auth
    if [ "$1" = "--re-auth" ]; then 
        echo "" > $jwt_file
        shift
    fi

    # read the query
    read_jwt
    q=`read_query $*`
    if [ -z "$q" ]; then
        echoerr "ERROR: Empty query or file not found"
        exit 1
    fi

    # read the vars
    shift
    v="$*"  # otherwise doesn't handle spaces in $2

    # run the query 
    r=`post_query "$q" "$v"`
    if [ "$r" = '{"message":"The incoming token has expired"}' -o "$r" = '{"Message":"Access Denied"}' -o "$r" = '{"message":"Unauthorized"}' ]
    then 
        refresh_jwt
        r=`post_query "$q" "$v"`
    fi
    echo $r
}

main $*




