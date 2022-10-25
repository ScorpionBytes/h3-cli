
## h3-cli: CLI tool for the Horizon3.ai API

h3-cli is a convenient CLI (command-line interface) for accessing the 
Horizon3.ai API.  The Horizon3.ai API provides programmatic access to a subset 
of functionality available through the Horizon3.ai Portal.  At a high level, 
the API allows you to:

* schedule an autonomous pentest
* download and run NodeZero™
* monitor the status of a pentest while it is running
* retrieve a pentest report after it's complete

The API can be used for a variety of use cases such as periodically scheduling assessments 
of your environment or kicking off a pentest as part of a continuous integration build pipeline.


[[_TOC_]]

## Introduction

The Horizon3.ai API is powered by GraphQL.  In addition to this CLI document, 
relevant documentation includes:

- [Horizon3.ai GraphQL API Reference](https://h3-graphql-docsite.horizon3ai.com/)
- [Learn about GraphQL](https://graphql.org/)

## Getting started 

The steps below will get you up and running quickly with h3-cli. These instructions were tested on 
MacOS and Linux machines, and generally should work on any POSIX-compliant system with `bash` support.
All shell commands in this guide should be run from the root directory of this repo.

It is assumed you already have registered an account with Horizon3.ai.  If not, please sign up
at [https://portal.horizon3ai.com/](https://portal.horizon3ai.com/).


#### 1. Clone this repo

First, clone this repo onto your machine using the following `git` command.

```shell
git clone git@gitlab.com:h3upperbounds/data/h3-cli.git
```

If you don't have `git`, you can download the repo from the menu above.

#### 2. Install dependencies: `jq` and `curl`

h3-cli has dependencies on `jq` and `curl`. `jq` is a sed-like JSON parser. `curl` is a popular CLI tool for fetching URLs. 
Most systems have `curl` installed by default (you can check by simply trying to run `curl` from the command line).

* Download `jq` from here: [https://stedolan.github.io/jq/](https://stedolan.github.io/jq/)
* Download `curl` from here: [https://curl.se/download.html](https://curl.se/download.html)

#### 3. Obtain an API key

Obtain an API key from the Portal under the User -> Settings menu: [https://portal.horizon3ai.com/settings/api](https://portal.horizon3ai.com/settings/api).

An API key is required to access the H3 API.  Keep your API key safely secured as anyone with your API key
can access your H3 account.  

#### 4. Set up your shell environment

Set your API key in the `H3_API_KEY` environmenet variable in your shell environment:

```shell
export H3_API_KEY="your-key-here"
```

#### 5. Run hello_world.graphql to verify connectivity

First, change into the root directory of this repo.  All shell commands in this guide should be run 
from the h3-cli root directory.

```shell
cd /path/to/h3-cli
```

> Substitute `/path/to` in all examples with the actual path in your filesystem.

Run the [hello_world.graphql](queries/hello_world.graphql) query to verify connectivity with the API.

```shell
./h3.sh queries/hello_world.graphql 
```

You should get the response:

```shell
{"data":{"hello":"world!"}}
```

All responses from the H3 API are in JSON format. For pretty-printing the JSON response, use `jq`:

```shell
./h3.sh queries/hello_world.graphql | jq .
```

You should get the response:

```shell
{
  "data": {
    "hello": "world!"
  }
}
```

If you are getting an error response, please contact H3 via the chat icon in the Horizon3.ai Portal.


#### 6. Fetch the list of pentests in your account

```shell
./h3.sh queries/pentests.graphql | jq .
```

This will return the full list of pentests in your account.  To filter for pentests that match
a given search term, use the following parameterized query:

```shell
./h3.sh queries/pentests.graphql '{"search":"sample"}' | jq .
```

Many of the [sample queries](#sample-queries) have optional or required parameters.
You can specify parameter values by passing them as the second argument to `h3.sh`, in JSON format.

#### 7. Fetch a specific pentest from your account

Pass the `op_id` as a parameter to [pentest.graphql](queries/pentest.graphql).

```shell
./h3.sh queries/pentest.graphql '{"op_id":"your-op-id-here"}' | jq .
```

Substitute `your-op-id-here` with an `op_id` from your account. 
Use the following command to get a list of `op_id`'s in your account:

```shell
./h3.sh queries/pentests.graphql | jq -r '.data.pentests_page.pentests[].op_id'
```

This example uses `jq` to parse the `op_id` field from the set of pentests in the JSON
response.  For more info on `jq` see our guide [JSON Parsing with `jq`](json-parsing-with-jq.md).

> The terms "op" and "pentest" are often used interchangeably.

#### 8. Schedule a pentest

To schedule a pentest, it is required that an _op template_ be specified.
Horizon3.ai provides new users with a default op template, named `Default 1 - Recommended`.

For experienced users, custom op template(s) may be created via the [Horizon3.ai portal](https://portal.horizon3ai.com/).
To create a custom op template, walk through the _Run a Pentest_ modal until you see the 
option to customize the pentest configuration.

> A custom op template may be created without actually running the pentest. 

To schedule a pentest using the default op template:

```shell
./h3.sh queries/schedule_op_template.graphql | jq .
```

To schedule a pentest using a custom op template, specify it as a parameter to [schedule_op_template.graphql](queries/schedule_op_template.graphql):

```shell
./h3.sh queries/schedule_op_template.graphql '{"op_template_name":"your-op-template-here"}' | jq .
```

To schedule a pentest and optionally assign it a name of your choosing, specify the `op_name` parameter:

```shell
./h3.sh queries/schedule_op_template.graphql '{"op_template_name":"your-op-template-here", "op_name":"your-op-name-here"}' | jq .
```

**NOTE**: For internal pentests, additional steps are required before the pentest will begin running.
See the next section about downloading and running NodeZero™ by using the response from `schedule_op_template`.


#### 9. Download and run NodeZero™

**⚠️ The following instructions apply to Internal Pentests only, _not_ External Pentests.**

After scheduling an *internal pentest*, you must download and run NodeZero™ on a Docker Host inside your network.
This is done by running the NodeZero™ Launch Script on the Docker Host. 

To retrieve the NodeZero™ Launch Script _URL_ for a scheduled pentest:

```shell
./h3.sh queries/pentest.graphql '{"op_id":"your-op-id-here"}' | jq -r .data.pentest.nodezero_script_url
```

Then download the launch script on your Docker Host using `curl` and pipe it to `bash` to run it and launch NodeZero™:

```shell
curl "<nodezero-script-url>" | bash
```

Alternatively, retrieve the NodeZero™ Launch Script URL when scheduling a pentest by parsing it from the `schedule_op_template` response:

```shell
./h3.sh queries/schedule_op_template.graphql | jq -r .data.schedule_op_template.op.nodezero_script_url
```

Putting it all together, here's a simple shell script that fetches the URL,
downloads the launch script, and launches NodeZero™:

```shell
nodezero_script_url=`./h3.sh queries/pentest.graphql '{"op_id":"your-op-id-here"}' | jq -r .data.pentest.nodezero_script_url`
curl "$nodezero_script_url" | bash
```

> Don't forget to put quotes around the URL, otherwise it might not work properly.


## Sample queries

The [queries](queries) directory contains a set of sample GraphQL queries 
you can use and modify to your needs.  The queries are documented in the [Horizon3.ai GraphQL API Reference](https://h3-graphql-docsite.horizon3ai.com/).

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

h3-cli uses your `H3_API_KEY` to authenticate to the Horizon3.ai API
and establish a session.  The session token (a JWT) is stored in `.h3-cli.jwt`.
The session expires after 1 hour, at which point h3-cli will
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



## Use Case: Schedule recurring pentests

A common use case for h3-cli is running pentests automatically on a recurring basis, for example once a week.

See [this guide](recurring-pentests.md) to learn how to set up recurring pentests using h3-cli.


## Use Case: Monitoring pentests

See [this guide](monitor-pentests.md) to learn how to monitor pentests using h3-cli.


## Use Case: Paginating results

See [this guide](paginate-results.md) to learn how to paginate through large result sets using h3-cli.


## Use Case: Downloading pentest reports

See [this guide](download-reports.md) to learn how to download pentest reports using h3-cli.
