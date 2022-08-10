
## h3-cli : CLI tool for the Horizon3.ai API

The Horizon3.ai API provides programmatic access to a subset of functionality
available through the Horizon3.ai Portal.  At a high level, the API allows
you to:

* schedule an autonomous pentest
* download and run NodeZero 
* monitor the status of a pentest while it is running
* retrieve a pentest report after it's complete

The API can be used for a variety of use cases such as periodically scheduling assessments 
of your environment or kicking off a pentest as part of a continuous integration build pipeline.


[[_TOC_]]

## GraphQL API documentation

The H3 API is a [GraphQL](https://graphql.org/) API.
Documentation for the H3 GraphQL API can be found here: [https://h3-graphql-docsite.horizon3ai.com/](https://h3-graphql-docsite.horizon3ai.com/).


## Getting started 

The steps below will get you up and running with the H3 CLI.  These instructions were tested on 
a MacOS machine and should work in any POSIX-compliant shell environment with `bash` support.
All shell commands listed below should be run from the root directory of this repo.

#### 1. Clone this repo

```shell
git clone git@gitlab.com:h3upperbounds/data/h3-cli.git
```

If you don't have `git`, you can download this zip file instead: [h3-cli.zip](h3-cli.zip).


#### 2. Install dependencies: `jq` and `curl`

The h3-cli has dependencies on `jq` and `curl`. `jq` is a sed-like JSON parser. `curl` is a popular CLI tool for fetching URLs. 

* Download `jq` from here: [https://stedolan.github.io/jq/](https://stedolan.github.io/jq/)
* Download `curl` from here: [https://curl.se/download.html](https://curl.se/download.html)



#### 3. Obtain an API key

Obtain an API key from the Portal under the User -> Settings menu: [https://portal.horizon3ai.com/settings/api](https://portal.horizon3ai.com/settings/api).


#### 4. Set up your shell environment

Set your API key in `H3_API_KEY` in your shell environment :

```shell
export H3_API_KEY="{your key here}"
```

#### 5. Run hello_world.graphql

Run the [hello_world.graphql](queries/hello_world.graphql) query to test basic connectivity to the API.

```shell
./h3.sh queries/hello_world.graphql 
```

For pretty printing, use `jq`:

```shell
./h3.sh queries/hello_world.graphql | jq .
```


#### 6. Fetch the list of pentests in your account

```shell
./h3.sh queries/pentests.graphql | jq .
```

**Parameterized queries.** Some of the sample [queries](queries) are parameterized.
You can specify parameter values by passing them as the
second arg to `h3.sh`, in JSON notation.

For example, `search` is supported as a parameter in [pentests.graphql](queries/pentests.graphql):

```shell
./h3.sh queries/pentests.graphql '{"search":"sample"}' | jq .
```

**JSON parsing.** `jq` is a useful tool for parsing and transforming JSON payloads. 
For example check out the results of these commands:

```shell
./h3.sh queries/pentests.graphql | jq -r .data.pentests_page.pentests[].op_id
./h3.sh queries/pentests.graphql | jq -r .data.pentests_page.pentests[].name
./h3.sh queries/pentests.graphql \
    | jq -r '.data.pentests_page.pentests[] | {op_id, name, scheduled_at, state}'
./h3.sh queries/pentests.graphql \
    | jq -r '.data.pentests_page.pentests[] | {op_id, name, scheduled_at, state}' \
    | jq -rsf to_csv.jq
```


#### 7. Fetch a specific pentest from your account

Pass the `op_id` as a parameter to [pentest.graphql](queries/pentest.graphql).

```shell
./h3.sh queries/pentest.graphql '{"op_id":"your-op-id-here"}' | jq .
```


## Schedule a pentest

To schedule a pentest using the default configuration template (`Default 1 - Recommended`):

```shell
./h3.sh queries/schedule_op_template.graphql | jq .
```

You can also configure your own op template(s) in the Portal.
Op templates are created within the Run-a-Pentest modal.
(Note that you can create an op template in the modal without actually running the pentest).

After you've created an op template, specify it as a parameter to [schedule_op_template.graphql](queries/schedule_op_template.graphql):

```shell
./h3.sh queries/schedule_op_template.graphql '{"op_template_name":"your-op-template-here"}' | jq .
```

You can optionally specify an op name:

```shell
./h3.sh queries/schedule_op_template.graphql '{"op_template_name":"your-op-template-here", "op_name":"your-op-name-here"}' | jq .
```

## Download and run NodeZero

**NOTE: This part does NOT apply to External Pentesting.**

After scheduling an internal pentest, you must download and run NodeZero on a Docker Host inside your network.
This is done using the NodeZero Launch Script.

You can retrieve the NodeZero Launch Script URL from the `Pentest` data:

```shell
./h3.sh queries/pentest.graphql '{"op_id":"your-op-id-here"}' | jq -r .data.pentest.nodezero_script_url
```

> Note: `jq -r` strips any surrounding quotes from the output string.

You can also retrieve it directly from the `schedule_op_template` response:

```shell
./h3.sh queries/schedule_op_template.graphql | jq .data.schedule_op_template.op.nodezero_script_url
```

To download and launch NodeZero, fetch the NodeZero Launch Script via `curl` and pipe it to `bash` to execute it:

```shell
nodezero_script_url=`./h3.sh queries/pentest.graphql '{"op_id":"your-op-id-here"}' | jq -r .data.pentest.nodezero_script_url`
curl "$nodezero_script_url" | bash
```

Don't forget to put quotes around the URL, otherwise it might not work properly.


## Sample queries

The [queries](queries) directory contains a set of sample GraphQL queries 
you can use and modify to your needs.

Examples:

```shell
./h3.sh queries/pentests.graphql | jq .
./h3.sh queries/pentest.graphql '{"op_id":"your-op-id-here"}' | jq .
./h3.sh queries/action_logs.graphql '{"op_id":"your-op-id-here"}' | jq .
./h3.sh queries/hosts_csv.graphql '{"op_id":"your-op-id-here"}' | jq -r .data.hosts_csv[]
./h3.sh queries/hosts_csv_url.graphql '{"op_id":"your-op-id-here"}' | jq -r .data.hosts_csv_url
./h3.sh queries/weaknesses_csv.graphql '{"op_id":"your-op-id-here"}' | jq -r .data.weaknesses_csv[]
./h3.sh queries/weaknesses_csv_url.graphql '{"op_id":"your-op-id-here"}' | jq -r .data.weaknesses_csv_url
./h3.sh queries/pentest_reports_zip_url.graphql '{"op_id":"your-op-id-here"}' | jq -r .data.pentest_reports_zip_url
./h3.sh queries/schedule_op_template.graphql '{"op_template_name":"your-op-template-here"}' | jq .
./h3.sh queries/pause_op.graphql '{"op_id":"your-op-id-here"}' | jq .
./h3.sh queries/resume_op.graphql '{"op_id":"your-op-id-here"}' | jq .
./h3.sh queries/cancel_op.graphql '{"op_id":"your-op-id-here"}' | jq .
```


## Authentication

The h3-cli uses your `H3_API_KEY` to authenticate to the Horizon3.ai API
and establish a session.  The session token (a JWT) is stored in `.h3-cli.jwt`.
The session expires after 1 hour, at which point the h3-cli will
seamlessly and automatically re-authenticate and re-establish a session.

#### Forcing re-authentication

If you wish to force h3-cli to re-authenticate, use the `--re-auth` option.

```shell
./h3.sh --re-auth queries/schedule_op_template.graphql | jq .
```

This can be useful if you're switching from one `H3_API_KEY` to another and 
want to force authentcation against the new `H3_API_KEY` (rather than using 
the old key cached in `.h3-cli.jwt`).


## Handling API errors

Errors are returned in the GraphQL response under the `errors` field.  The 
field is a list that includes all errors that occurred during the request.  Note that
GraphQL will attempt to resolve as much of the query as possible, even if
errors occur for some fields.  

For example, if you try to read a non-existent `op_id`: 

```shell
./h3.sh queries/pentest.graphql '{"op_id":"12341234-1234-1234-1234-123412341234"}' | jq -r '.errors[].message'
```

Output:

```shell
[403] op is not available
```

You can view the general structure of error responses using the [to_struct.jq](to_struct.jq) filter.

```shell
./h3.sh queries/pentest.graphql '{"op_id":"12341234-1234-1234-1234-123412341234"}' | jq -rf to_struct.jq
```

Output:

```shell
.
.data
.data.pentest
.errors
.errors[]
.errors[].locations
.errors[].locations[]
.errors[].locations[].column
.errors[].locations[].line
.errors[].message
.errors[].path
.errors[].path[]
.errors[].statusCode
```


## Useful `jq` filters

#### View the JSON response structure

It's sometimes useful to view the structure of the JSON response payload:

```shell
./h3.sh queries/pentests.graphql | jq -rf to_struct.jq 
```

Output:

```shell
.
.data
.data.pentests_count
.data.pentests_page
.data.pentests_page.pentests
.data.pentests_page.pentests[]
.data.pentests_page.pentests[].aws_account_ids
.data.pentests_page.pentests[].canceled_at
.data.pentests_page.pentests[].client_name
.data.pentests_page.pentests[].completed_at
.data.pentests_page.pentests[].credentials_count
.data.pentests_page.pentests[].data_resources_count
.data.pentests_page.pentests[].data_stores_count
.data.pentests_page.pentests[].duration_s
.data.pentests_page.pentests[].etl_completed_at
.data.pentests_page.pentests[].exclude_scope
.data.pentests_page.pentests[].exclude_scope[]
.data.pentests_page.pentests[].external_domains_count
.data.pentests_page.pentests[].git_accounts
.data.pentests_page.pentests[].hosts_count
.data.pentests_page.pentests[].impacts_count
.data.pentests_page.pentests[].launched_at
.data.pentests_page.pentests[].max_scope
.data.pentests_page.pentests[].max_scope[]
.data.pentests_page.pentests[].min_scope
.data.pentests_page.pentests[].name
.data.pentests_page.pentests[].nodezero_ip
.data.pentests_page.pentests[].nodezero_script_url
.data.pentests_page.pentests[].op_id
.data.pentests_page.pentests[].op_type
.data.pentests_page.pentests[].osint_company_names
.data.pentests_page.pentests[].osint_company_names[]
.data.pentests_page.pentests[].osint_domains
.data.pentests_page.pentests[].osint_keywords
.data.pentests_page.pentests[].osint_keywords[]
.data.pentests_page.pentests[].out_of_scope_hosts_count
.data.pentests_page.pentests[].services_count
.data.pentests_page.pentests[].state
.data.pentests_page.pentests[].user_name
.data.pentests_page.pentests[].users_count
.data.pentests_page.pentests[].weakness_types_count
.data.pentests_page.pentests[].weaknesses_count
.data.pentests_page.pentests[].websites_count
```

#### Select a field/list from the response

If you want to select only the `pentests` array from the response:

```shell
./h3.sh queries/pentests.graphql | jq '.data.pentests_page.pentests'
```

This behaves more like a traditional REST API, where responses are often structured as a flat array of JSON objects.

You can also drop the surrounding array brackets `[]` from the response
and convert the output to a stream of JSON objects by adding `[]` to the filter:

```shell
./h3.sh queries/pentests.graphql | jq '.data.pentests_page.pentests[]'
```

You can then select a single field from the stream of JSON objects by adding it to the filter.
For example if you want just the list of op_ids: 


```shell
./h3.sh queries/pentests.graphql | jq -r '.data.pentests_page.pentests[].op_id'
```



#### Select a subset of fields from an object 

If you want to select a subset of fields from the JSON objects in the `pentests` array:

```shell
./h3.sh queries/pentests.graphql | jq '.data.pentests_page.pentests[] | {op_id, name, state, scheduled_at}'
```


#### Convert a list of JSON objects to CSV

If you want to convert the `pentests` array to a CSV:

```shell
./h3.sh queries/pentests.graphql | jq '.data.pentests_page.pentests[]' | jq -rsf to_csv.jq
```

> Note: the [to_csv.jq](to_csv.jq) filter will automatically convert lists and objects to JSON-encoded strings in the CSV.




## Use Case: Regularly scheduled pentests

You can wire up h3-cli to your job scheduler in order to run continuous, regularly scheduled pentests.

Note that if you're running internal pentests, you must download and run NodeZero 
as part of the regularly scheduled job.  This means h3-cli will need to be invoked from the 
machine where you intend to run NodeZero.

Here's an example shell script that (1) schedules the pentest and (2) downloads and runs NodeZero,
all in one go:

```shell
#!/bin/bash

#
# 1. schedule the pentest 
#
res=`./h3.sh queries/schedule_op_template.graphql`
op=`cat <<<$res | jq .data.schedule_op_template.op`
op_name=`cat <<<$op | jq -r .op_name`
scheduled_timestamp_iso=`cat <<<$op | jq -r .scheduled_timestamp_iso`
echo "Scheduled pentest \"$op_name\" at $scheduled_timestamp_iso."

#
# 2. download and run NodeZero
#
nodezero_script_url=`cat <<<$op | jq -r .nodezero_script_url`
echo "Download and run NodeZero from $nodezero_script_url ... "
curl "$nodezero_script_url" | bash
```


## Use Case: Monitoring pentests

You can use the h3-cli to monitor the status of a pentest. 
This is done by periodically polling the API to check on the pentest's `state`.

Monitoring enables you to trigger downstream actions or alerts when a pentest completes.
A pentest is fully complete when its `state` hits `done` or `ended`.

Here's an example shell script that periodically polls the `state` until 
the pentest is complete.


```shell
#!/bin/bash

#
# 1. take the op_id as a param. 
#    convert it to json format for the h3-cli.
#
op_id=$1
json_params=`cat <<HERE
{"op_id":"$op_id"}
HERE
`

#
# 2. loop forever until the pentest reaches 'done' or 'ended' state.
# 
while [ 1 ]; do
    res=`./h3.sh queries/pentest.graphql "$json_params"`
    pentest_state=`cat <<<$res | jq -r .data.pentest.state`
    pentest_name=`cat <<<$res | jq -r .data.pentest.name`
    if [ "$pentest_state" = "done" -o "$pentest_state" = "ended" ]; then
        echo "Pentest \"$pentest_name\" is complete; state=$pentest_state"
        break
    fi
    echo "Pentest \"$pentest_name\" is still active; state=$pentest_state ..."
    sleep 15
done

```



## Use Case: Paginating results

Queries that return potentially a lot of results can be paginated
by using the optional `page_input` on the GraphQL request.  

For example [action_logs.graphql](queries/action_logs.graphql) is parameterized
to accept `page_num` and `page_size` as parameters.  These parameters are passed
to `page_input` within the query file.

```shell
./h3.sh queries/action_logs.graphql '{"op_id":"your-op-id-here", "page_num":1, "page_size":100}' | jq .
```

Here's an example shell script that paginates thru the full result set.
It exits the loop when the query returns no further results.

```shell
#!/bin/bash

#
# Helper function for building the JSON parameters 
# for the GraphQL request.
#
function build_json_params {
    op_id=$1
    page_num=$2
    page_size=$3
    cat <<HERE
{"op_id":"$op_id", "page_num":$page_num, "page_size":$page_size}
HERE
}

#
# 1. take the op_id as a param to the shell script. 
#
op_id=$1
page_num=1
page_size=100

#
# 2. read page by page until the request returns no further results.
# 
while [ 1 ]; do
    json_params=`build_json_params $op_id $page_num $page_size`
    res=`./h3.sh queries/action_logs.graphql "$json_params"`
    len=`cat <<<$res | jq '.data.action_logs_page.action_logs | length'`
    echo "Read $len records on page $page_num"
    if [ -z "$len" -o $len -eq 0 ]; then
        break
    fi
    (( page_num++ ))
done
```


## Use Case: Downloading CSVs via URL

Below is a simple shell script that fetches the weaknesses CSV for a given op
by first fetching a presigned URL for it, then downloading the CSV file via the URL.
(Note that the presigned URL expires after a short time so it must be used promptly).

```shell
url=`./h3.sh queries/weaknesses_csv_url.graphql '{"op_id":"your-op-id-here"}' | jq -r .data.weaknesses_csv_url`
curl -o weaknesses.csv "$url"
```

The raw CSV data is also directly available via the API (without having to download from a URL):

```shell
./h3.sh queries/weaknesses_csv.graphql '{"op_id":"your-op-id-here"}' | jq -r .data.weaknesses_csv[]
```


## Use Case: Downloading the pentest reports archive via URL

Below is a simple shell script that fetches the pentest reports archive for a given op via URL.

```shell
url=`./h3.sh queries/pentest_reports_zip_url.graphql '{"op_id":"your-op-id-here"}' | jq -r .data.pentest_reports_zip_url`
curl -o pentest_reports.zip "$url"
```
