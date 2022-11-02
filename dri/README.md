
## Using h3-cli to run multiple pentests consecutively 

Prepared for Desert Research Institute. 


### 1. Unzip this package

Unzip this package on the system where you intend to run NodeZero. 

This package includes h3-cli, a command-line utility for accessing the Horizon3.ai API.
It is recommended (though not required) to walk through the h3-cli [Getting Started](../README.md#getting-started)
documentation to familiarize yourself with the tool. 


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

An API key is required to access the H3 API.  Keep your API key safely secured as anyone with your API key
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

Run the [hello_world.graphql](../queries/hello_world.graphql) query to verify connectivity with the API.

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


### 6. Set up the list of pentests to run

Configure the list of pentests to run in [dri.input.txt](dri.input.txt).  This file has already been pre-populated with 
pentest configurations pulled from your account.  

The file includes a new option, `network_interface`, where you can specify the network interface you want NodeZero to use
(for multi-homed Docker Hosts).  You will likely need to update the option in the input file as they all default to `network_interface: "eth0"`.


### 7. Run the list of pentests 

Invoke [run_pentests.sh](run_pentests.sh) and pass the list of pentests to run:

```shell
$H3_CLI_HOME/dri/run_pentests.sh $H3_CLI_HOME/dri/dri.input.txt
```

This will run each pentest in the list, consecutively (one after another, not all at once).  The script schedules 
each pentest, launches NodeZero for it, then waits for the pentest to complete before moving on to the next
pentest in the list.