
## Using h3-cli to automatically run a set of pentests consecutively 

Prepared for Desert Research Institute. 


#### 1. Unzip this package

Unzip this package on the system where you intend to run NodeZero. 

This package includes h3-cli, the command-line utility for accessing the Horizon3.ai API.
It is recommended (though not required) to walk through the h3-cli [Getting Started](../README.md#getting-started)
documentation to familiarize yourself with the tool. 


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

Set the following environment variables in your shell environment:

```shell
export H3_API_KEY="your-key-here"
export H3_CLI_HOME=/path/to/h3-cli
```

> Substitute `/path/to` in all examples with the actual path in your filesystem.

#### 5. Run hello_world.graphql to verify connectivity

Run the [hello_world.graphql](../queries/hello_world.graphql) query to verify connectivity with the API.

```shell
$H3_CLI_HOME/h3.sh $H3_CLI_HOME/queries/hello_world.graphql 
```

#### 6. Set up the list of pentests to run

Configure the list of pentests to run in [dri.input.txt](dri.input.txt).  This file has already been prepared with 
pentest configurations pulled from your account. 

#### 7. Run the list of pentests 

Invoke [run_pentests.sh](run_pentests.sh) and pass the list of pentests to run:

```shell
/path/to/run_pentests.sh /path/to/dri.input.txt
```

This will run each pentest in the list, consecutively (one after another, not all at once).  The script schedules 
each pentest, launches NodeZero for it, then waits for the pentest to complete before moving on to the next
pentest in the list.