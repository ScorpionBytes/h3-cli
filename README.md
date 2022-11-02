
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
MacOS and Linux machines, and generally should work on any [POSIX-compliant](https://en.wikipedia.org/wiki/POSIX) system with `bash` support.
All shell commands in this guide should be run from the root directory of this repo.


It is assumed you already have an account with Horizon3.ai.  If not, sign up
at [https://portal.horizon3ai.com/](https://portal.horizon3ai.com/).


### 1. Install this git repo

First, install this repo on your machine using the following `git` command within a shell/terminal.  

```shell
git clone git@gitlab.com:h3upperbounds/data/h3-cli.git
```

This will create a new directory, `h3-cli`, and download the contents of this repo to it.  The `h3-cli` directory
will be created in the directory where you run the `git` command.  You can install h3-cli anywhere on the filesystem;
there are no restrictions or dependencies on where it's located.

> If you don't have `git`, you can download the repo as a zip archive from the menu above, and unzip it anywhere in the filesystem.

### 2. Install dependencies: `jq` and `curl`

h3-cli has dependencies on `jq` and `curl`. `jq` is a sed-like JSON parser. `curl` is a popular CLI tool for posting HTTP requests. 

* Download `jq` from here: [https://stedolan.github.io/jq/](https://stedolan.github.io/jq/)
* Download `curl` from here: [https://curl.se/download.html](https://curl.se/download.html)
    * Most systems have `curl` installed by default. You can check by running `curl --version` from the command line.


Verify `jq` is installed by running:

```shell
echo '{"testing":"jq"}' | jq .
```

The output should be:

```shell
{
  "testing": "jq"
}
```


### 3. Obtain an API key

Obtain an API key from the Portal under the User -> Settings menu: [https://portal.horizon3ai.com/settings/api](https://portal.horizon3ai.com/settings/api).

An API key is required to access the H3 API.  Keep your API key safe and secure, as anyone with your API key
can access your H3 account.  

### 4. Set up your shell environment

Set the following environment variables in your shell environment:

```shell
export H3_API_KEY="your-key-here"
export H3_CLI_HOME=/path/to/h3-cli
export PATH=$H3_CLI_HOME/bin:$PATH
```

> Substitute `/path/to` with the actual path in your filesystem.



### 5. Run hello_world to verify connectivity

Run the [hello_world.graphql](queries/hello_world.graphql) query to verify connectivity with the API.

```shell
h3 hello_world
```

You should get the response:

```shell
{"data":{"hello":"world!"}}
```

All responses from the H3 API are in JSON format. For pretty-printing the JSON response, use `jq`:

```shell
h3 hello_world | jq .
```

You should get the response:

```shell
{
  "data": {
    "hello": "world!"
  }
}
```


⚠️ If you are getting an error response, please contact H3 via the chat icon in the Horizon3.ai Portal.


### 6. Query the list of pentests in your account

The command below will return the full list of pentests in your account.  

```shell
h3 pentests | jq .
```

To filter for pentests that match a given search term, use the following parameterized query:

```shell
h3 pentests '{"search":"sample"}' | jq .
```

Many of the [sample queries](#sample-queries) have optional or required parameters.
You can specify parameter values by passing them as the second argument to `h3`, in JSON format.

### 7. Query a specific pentest from your account

To fetch a single pentest from your account, you pass the `op_id` as a parameter to [pentest.graphql](queries/pentest.graphql).
The `op_id` can be found in the JSON output from the list of pentests in [step #6 above](#6-fetch-the-list-of-pentests-in-your-account).
Use the following command to get the list of `op_id`'s in your account:

```shell
h3 pentests | jq -r '.data.pentests_page.pentests[] | {op_id, name, scheduled_at, state}'
```

This example uses `jq` to parse the `op_id` field (and a few other fields) from the list of pentests in the JSON
response.  For more info on how to use `jq` see our guide [JSON Parsing with `jq`](json-parsing-with-jq.md).

Now substitute `your-op-id-here` in the command below with an `op_id` from your account:

```shell
op_id="your-op-id-here"
h3 pentest $op_id | jq .
```

> The terms "op" and "pentest" are often used interchangeably.


### 8. Schedule a pentest

Scheduling a pentest requires specifying an _op template_.  An op template specifies a full pentest configuration,
which includes scope, attack parameters, and other (optional) configuration.

Horizon3.ai provides new users with a default op template named `Default 1 - Recommended`.  This template is always 
up-to-date with our latest attack parameters and recommended configuration.  The default template does not define a scope,
in which case NodeZero will use _Intelligent Scope_ - NodeZero's host subnet will provide the initial scope, and it will expand 
organically during the pentest as more hosts and subnets are discovered.  For more information on Intelligent Scope and other 
deployment options, visit our [product documentation](https://portal.horizon3ai.com/documentation/nodezero-deployment-options).

For experienced users, custom op template(s) may be created via the [Horizon3.ai Portal](https://portal.horizon3ai.com/).
To create a custom op template, walk through the _Run a Pentest_ modal until you see the 
option to customize the pentest configuration. The op template can be created without actually running the pentest. 

To schedule a pentest using the default op template with Intelligent Scope:

```shell
h3 schedule_op_template | jq .
```

The JSON response contains the details for the newly scheduled pentest.
You can verify the pentest is provisioning by checking your [Horizon3.ai Portal](https://portal.horizon3ai.com/pentests).

There are several ways to specify additional parameters when scheduling pentests. For more information see additional examples [here](#scheduling-pentests-with-h3-cli).

**WAIT! YOU'RE NOT DONE!**: For internal pentests (which are the default), additional steps are required before the pentest will begin running.
See the next section about downloading and running NodeZero in order to complete the initiation of your pentest.


### 9. Run NodeZero™

**⚠️ The following instructions apply to Internal Pentests only, _not_ External Pentests.**

After scheduling an *internal pentest*, you then have to run our NodeZero container on a Docker Host inside your network.
This is done by running the NodeZero Launch Script on your Docker Host. 

You can retrieve the NodeZero Launch Script's _URL_ for a pentest by parsing the `nodezero_script_url` field from the pentest's 
JSON response, as shown in the commands below. 

You'll first need the `op_id` for the pentest, which you can retrieve from the output of the previous [step](#8-schedule-a-pentest),
or by re-listing the pentests in your account and looking for the one most recently scheduled (it will likely be in `provisioning` state).

The following commands will parse the `nodezero_script_url` from the pentest response, download it via `curl`,
and run it by piping to `bash`.  The NodeZero Launch Script itself will then download our NodeZero container and run it in Docker.  

```shell
op_id="your-op-id-here"
nodezero_script_url=`h3 pentest $op_id | jq -r .data.pentest.nodezero_script_url`
curl "$nodezero_script_url" | bash
```

> Don't forget to put quotes around the URL, otherwise it could be misinterpreted by the terminal and result in an error.

**YOUR PENTEST HAS BEEN LAUNCHED!**  Assuming the commands above ran successfully, then you have 
successfully scheduled and launched your pentest.  You should see output from the NodeZero Launch Script being logged
to the console.  The script will first verify your system is compatible with NodeZero before downloading and running it.
When the pentest is complete, NodeZero will automatically shut itself down.  

NodeZero is a Docker container.  You can view it using `docker ps`.  The container name will be of the form `n0-xxxx`.

### 10. Going further 

This completes the [Getting Started](#getting-started) section of this guide.  In this section we installed h3-cli, configured your 
environment, listed the pentests in your account, scheduled a pentest, and finally launched NodeZero, all using h3-cli. 

Check out the [sample queries](#sample-queries) and [use cases](#use-cases) below to further explore the capabilities
provided by h3-cli.


## Sample queries

The [queries](queries) directory contains a set of sample GraphQL queries 
you can use and modify to your needs.  The queries are documented in the [Horizon3.ai GraphQL API Reference](https://h3-graphql-docsite.horizon3ai.com/).

Examples:

```shell
h3 pentests | jq .

op_id="your-op-id-here" 
h3 pentest $op_id | jq .
h3 action_logs $op_id | jq .
h3 hosts_csv $op_id | jq -r .data.hosts_csv[]
h3 hosts_csv_url $op_id | jq -r .data.hosts_csv_url
h3 weaknesses_csv $op_id | jq -r .data.weaknesses_csv[]
h3 weaknesses_csv_url $op_id | jq -r .data.weaknesses_csv_url
h3 pentest_reports_zip_url $op_id | jq -r .data.pentest_reports_zip_url
h3 pause_op $op_id | jq .
h3 resume_op $op_id | jq .
h3 cancel_op $op_id | jq .
```


## Use cases

### Schedule recurring pentests

A common use case for h3-cli is running pentests automatically on a recurring basis, for example once a week.

See [this guide](recurring-pentests.md) to learn how to set up recurring pentests using h3-cli.


### Monitoring pentests

See [this guide](monitor-pentests.md) to learn how to monitor pentests using h3-cli.


### Paginating results

See [this guide](paginate-results.md) to learn how to paginate through large result sets using h3-cli.


### Downloading pentest reports

See [this guide](download-reports.md) to learn how to download pentest reports using h3-cli.



## Authentication

h3-cli uses your `H3_API_KEY` to authenticate to the Horizon3.ai API
and establish a session.  The session token (a JWT) is stored in `.h3-cli.jwt`.
The session expires after 1 hour, at which point h3-cli will
seamlessly and automatically re-authenticate and re-establish a session.

#### Forcing re-authentication

If you wish to force h3-cli to re-authenticate, use the `--re-auth` option.

```shell
h3 --re-auth pentests | jq .
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
h3 pentest "12341234-1234-1234-1234-123412341234" | jq -r '.errors[].message'
```

Output:

```shell
[403] op is not available
```

You can view the general structure of error responses using the [to_struct.jq](filters/to_struct.jq) filter.

```shell
h3 pentest "12341234-1234-1234-1234-123412341234" | jq -rf $H3_CLI_HOME/filters/to_struct.jq
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


## Scheduling pentests with h3-cli

This section contains additional examples for scheduling pentests using h3-cli.

For the simplest way to schedule a pentest (using the default op template and _Intelligent Scope_), see [step #8](#8-schedule-a-pentest) in this guide.

To schedule a pentest using the default op template:

```shell
h3 schedule_op_template | jq .
```

To schedule a pentest using a custom op template, specify it as a parameter to [schedule_op_template.graphql](queries/schedule_op_template.graphql):

```shell
h3 schedule_op_template '{"op_template_name":"your-op-template-here"}' | jq .
```

To schedule a pentest using the default op template but assign it a name of your choosing, use the optional `op_name` parameter: 

```shell
h3 schedule_op_template '{"op_name":"your-op-name-here"}' | jq .
```

To schedule a pentest using the default op template but specify its name and scope, use the optional `schedule_op_form` parameter:

```shell
h3 schedule_op_template '{"op_name":"your-op-name-here", "schedule_op_form":{"op_param_max_scope": "192.168.0.0/24"}}' | jq .
```


