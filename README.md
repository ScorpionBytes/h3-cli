
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

## Installation and initial setup

The steps below will get you up and running quickly with h3-cli. These instructions were tested on 
MacOS and Linux machines, and generally should work on any [POSIX-compliant](https://en.wikipedia.org/wiki/POSIX) system with `bash` support.

It is assumed you already have an account with Horizon3.ai.  If not, sign up
at [https://portal.horizon3ai.com/](https://portal.horizon3ai.com/).


### 1. Install this git repo

First, install this repo on your machine using the following `git` command within a shell/terminal.  

```shell
git clone git@gitlab.com:h3upperbounds/data/h3-cli.git
chmod -R a+x h3-cli/bin
```

This will create a new directory, `h3-cli`, and download the contents of this repo to it.  The `h3-cli` directory
will be created in the directory where you run the `git` command.  You can install h3-cli anywhere on the filesystem;
there are no restrictions or dependencies on where it's located.

The `chmod` command ensures that the scripts under `h3-cli/bin` are executable.

> If you don't have `git`, you can download the repo as a zip archive from the menu above, and unzip it anywhere in the filesystem.

### 2. Install dependency: `jq` 

h3-cli has a dependency on `jq`.  `jq` is a sed-like JSON parser.  All responses from the Horizon3 API are in JSON format.
h3-cli uses `jq` to parse and pretty-print JSON responses.

Download and install `jq` from here: [https://stedolan.github.io/jq/](https://stedolan.github.io/jq/)

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

If you see a `Permission Denied` error, you may have to set `jq` to be executable using `chmod a+x jq`


### 3. Obtain an API key

Obtain an API key from the Portal under the User -> Settings menu: [https://portal.horizon3ai.com/settings/api](https://portal.horizon3ai.com/settings/api).

An API key is required to access the H3 API.  Keep your API key secure, as anyone with your API key
can access your H3 account.  


### 4. Set up your h3-cli profile

Run the following commands to create your h3-cli profile.  

```shell
mkdir $HOME/.h3
chmod 600 $HOME/.h3
echo "H3_API_KEY=your-api-key-here" > $HOME/.h3/default.env
```

Substitute `your-api-key-here` with your actual API key.
The commands above create your h3-cli profile under the `$HOME/.h3` directory
and restrict permissions on the directory so that no other users (besides yourself) can read it.


### 5. Add h3-cli to the command `PATH`

Add the following to the bottom of your `$HOME/.bash_profile` (or `$HOME/.bashrc` or `$HOME/.profile`, whichever is present on your system).

```shell
# H3-CLI
export H3_CLI_HOME=/path/to/h3-cli
export PATH="$H3_CLI_HOME/bin:$PATH"
```

> Substitute `/path/to` with the actual path to h3-cli on your filesystem.

The `H3_CLI_HOME` environment variable is used by h3-cli to locate itself.  The `PATH` environment
variable is a list of directories (separated by `:`) that contain executable programs.  By adding
h3-cli to the `PATH`, you will be able to invoke h3-cli by simply typing `h3` at the command prompt.


## Getting started with h3-cli

### 1. Verify connectivity with the API

Run the [hello_world.graphql](queries/hello_world.graphql) query to verify connectivity with the API.

```shell
h3 hello_world
```

You should see the response:

```shell
{
  "data": {
    "hello": "world!"
  }
}
```

⚠️ If you are getting an error response, please contact H3 via the chat icon in the [Horizon3.ai Portal](https://portal.horizon3ai.com/).


### 2. Query the list of pentests in your account

The command below will return the list of pentests in your account, most recent first.

```shell
h3 pentests 
```

To filter for pentests that match a given search term, pass the search term as a parameter:

```shell
h3 pentests sample
```

### 3. Query a specific pentest from your account

To query the most recent pentest in your account:

```shell
h3 pentest
```

To query any pentest in your account, pass the `op_id` of the pentest as a parameter:

```shell
h3 pentest {op_id}
```

h3-cli will often use the most recent pentest as the default,
unless an `op_id` is passed as a parameter.

> The terms "op" and "pentest" are often used interchangeably.


### 4. Schedule a pentest

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
h3 schedule-pentest
```

The JSON response contains the details for the newly scheduled pentest.
You can verify the pentest is provisioning by checking your [Horizon3.ai Portal](https://portal.horizon3ai.com/pentests),
or by running `h3 pentest`.  

There are several ways to specify additional parameters when scheduling pentests. For more information see additional examples [here](#scheduling-pentests-with-h3-cli).

**WAIT! YOU'RE NOT DONE!**: For internal pentests (which are the default), additional steps are required before the pentest will begin running.
See the next section about downloading and running NodeZero in order to complete the initiation of your pentest.


### 5. Run NodeZero™

**⚠️ The following instructions apply to Internal Pentests only, _not_ External Pentests.**

After scheduling an *internal pentest*, you then have to run our NodeZero container on a Docker Host inside your network.
This is done by running the NodeZero Launch Script on your Docker Host.  

To run the NodeZero Launch Script for your most recently scheduled pentest:

```shell
h3 launch-nodezero
```

**YOUR PENTEST HAS BEEN LAUNCHED!**  Assuming all commands ran without error, then you have 
successfully scheduled and launched your pentest.  You should see output from the NodeZero Launch Script being logged
to the console.  The script will first verify your system is compatible with NodeZero before downloading and running it.
When the pentest is complete, NodeZero will automatically shut itself down.  

NodeZero is a Docker container.  You can view it using `docker ps`.  The container name will be of the form `n0-xxxx`.


## Going further 

In the above sections, we installed and configured h3-cli, verified connectivity with the API, listed the pentests in your account, 
scheduled a pentest, and launched NodeZero, all using h3-cli. 

To see the full list of h3-cli commands and options, run:

```shell
h3 help
```

You can also check out the [use cases](#use-cases) below to further explore the capabilities provided by h3-cli.


## Use cases

### Schedule recurring pentests

A common use case for h3-cli is running pentests automatically on a recurring basis, for example once a week.

See [this guide](guides/recurring-pentests.md) to learn how to set up recurring pentests using h3-cli.


### Monitoring pentests

See [this guide](guides/monitor-pentests.md) to learn how to monitor pentests using h3-cli.


### Paginating results

See [this guide](guides/paginate-results.md) to learn how to paginate through large result sets using h3-cli.


### Downloading pentest reports

See [this guide](guides/download-reports.md) to learn how to download pentest reports using h3-cli.



## Authentication

h3-cli uses your `H3_API_KEY` to authenticate to the Horizon3.ai API
and establish a session.  The session token (a JWT) is stored in `$HOME/.h3/jwt`.
The session expires after 1 hour, at which point h3-cli will
seamlessly and automatically re-authenticate and re-establish a session.

### Forcing re-authentication

If you wish to force h3-cli to re-authenticate, use the `auth` command:

```shell
h3 auth
```

This can be useful if you're switching from one `H3_API_KEY` to another and 
want to force authentcation against the new `H3_API_KEY`.


## Scheduling pentests with h3-cli

This section contains additional examples for scheduling pentests using h3-cli.

The simplest way to schedule a pentest is to use the default op template and _Intelligent Scope_:

```shell
h3 schedule-pentest
```

To schedule a pentest using a custom op template, specify it as a parameter to [schedule_op_template.graphql](queries/schedule_op_template.graphql):

```shell
h3 schedule-pentest '{"op_template_name":"your-op-template-here"}' 
```

To schedule a pentest using the default op template but assign it a name of your choosing, use the optional `op_name` parameter: 

```shell
h3 schedule-pentest '{"op_name":"your-op-name-here"}' 
```

To schedule a pentest using the default op template but specify its name and scope, use the optional `schedule_op_form` parameter:

```shell
h3 schedule-pentest '{"op_name":"your-op-name-here", "schedule_op_form":{"op_param_max_scope": "192.168.0.0/24"}}' 
```


