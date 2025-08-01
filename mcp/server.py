# 
# H3 MCP server, built on top of h3-cli.
#
# The MCP server uses h3-cli commands to interact with the H3 GraphQL API.  
# You must have h3-cli installed locally and configured with your H3 API key.
#
# NOTE: the recommended way to run the MCP server is via the docker container.
#       See mcp/README.md for more details.
#
# See `h3 test-mcp help` for more details on how to run and test the MCP server.
#
# API Key Configuration:
# The server requires the H3_API_KEY environment variable to be set.
# This API key will be used for all h3-cli commands executed by the server.
#
# Requires the mcp package:
#   $ pip install fastmcp
#
# Usage: 
#   $ python3 server.py [mode]
#           mode: stdio (default) | streamable-http [port] | sse [port]
#
# VSCode: 
# To use this MCP server with VSCode+GitHub Co-Pilot, add the following to your settings.json.
# NOTE: update the path to server.py to match your local setup.
#
#   "mcp": {
#       "servers": {
#           "h3-mcp-server": {
#               "type": "stdio",
#               "command": "python",
#               "args": [
#                   "/easy/h3/h3-cli/mcp/server.py"
#               ],
#           }
#       }
#   }
#

from fastmcp import FastMCP
from typing import List, Dict, Any
import sys
import os
import subprocess
import tempfile
import json
import logging

# Configure logging to output to stderr for stdio compatibility
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stderr)]
)

logger = logging.getLogger(f"h3.mcp.server")

mcp = FastMCP("H3 MCP Server")

H3_CLI_BIN_PATH = os.environ.get(
    "H3_CLI_BIN_PATH", 
    os.path.dirname(__file__) + "/../bin"   # assumes this file is located at h3-cli/mcp/server.py
)


# :returns: the mode of the MCP server, either "stdio", "streamable-http", or "sse"
#           the mode is specified by the first command line argument.
#           defaults to stdio.
def get_mode() -> str:
    return sys.argv[1] if len(sys.argv) > 1 else "stdio"


# :returns: the version of the MCP server
def get_version() -> str:
    return "1.0.0"


# :returns: User-Agent string based on transport mode.
#           Format: h3-mcp-server/<version> (server:local; mode:<mode>)
def get_user_agent() -> str:
    return f"h3-mcp-server/{get_version()} (server:local; mode:{get_mode()})"


def run_h3_command_helper(tool_cmd: str, cmd: List[str]) -> Dict[str, Any]:
    h3_command: str = " ".join(cmd)

    # replace 'h3' with the full path to the h3 CLI binary
    h3_cmd: str = H3_CLI_BIN_PATH + "/h3"
    cmd[0] = h3_cmd

    # Set user agent for tracking MCP-initiated requests server-side
    env = os.environ.copy()
    env['H3_CLI_USER_AGENT'] = get_user_agent()
    try:
        # Execute the H3 command
        result = subprocess.run(
            cmd, 
            capture_output=True, 
            text=True, 
            check=True,
            env=env,
        )
        
        # Try to parse as JSON if possible
        try:
            output = json.loads(result.stdout)
        except json.JSONDecodeError:
            # If not valid JSON, return as plain text
            output = result.stdout
            
        response = {
            "status": "success",
            "output": output,
            "command": tool_cmd,
        }
        
    except subprocess.CalledProcessError as e:
        # Provide a more helpful error message
        error_message = e.stderr \
            if e.stderr \
            else e.stdout \
                if e.stdout \
                else f"No error output provided by the command. Error code: {e.returncode}"

        # If the error_message is JSON, parse it and return it in the output field.
        # It may be a GraphQL error response.
        try:
            output = json.loads(error_message)
        except json.JSONDecodeError:
            output = {'error': error_message}
 
        response = {
            "status": "error",
            "output": output,
            "command": tool_cmd,
        }
    except Exception as e:
        # Catch any other unexpected exceptions
        response = {
            "status": "error",
            "output": {'error': str(e)},
            "command": tool_cmd,
        }
    return response


@mcp.tool()
def fetch_h3_graphql_docs(id: str) -> Dict[str, Any]:
    """
    Fetch GraphQL documentation for a given API within the GraphQL schema.  
    
    Use this tool if you're trying to construct a GraphQL request that you 
    want to run using the run_h3_graphql_request tool, and you need information 
    about the GraphQL schema in order to construct the request.

    The API id can be one of:

    - a type, eg. Query, Mutation, Weakness, etc.
    - a field, eg. Query.pentests_page, Mutation.run_pentest, etc.
    - an enum type, eg. AuthzRole, PortalOpState, etc.
    - an enum value, eg. AuthzRole.ORG_ADMIN, PortalOpState.running, etc.

    Args:
        id (str): the API id to fetch documentation for.
        
    Returns:
        Dict with command output and status.  The output field contains the 
        response from the GraphQL server. The GraphQL type of the result 
        is GraphQLDef.  You can get further details about the type, including 
        its fields, by using this tool and passing the id GraphQLDef.
        
    Note:
        To get started, we recommend fetching the documentation for the Query type 
        or Mutation type, depending on the type of request you wish to make.  The 
        response will include a list of all the available queries or mutations.  
        Once you find the one(s) you want to use, you can fetch its documentation
        using this tool and passing the id.  For example if you want to fetch documentation
        about the weaknesses_page query, you can use the id Query.weaknesses_page.
        The id for each API is included in the response payload.

        Whenever you fetch a type, the response will include details about the type along with 
        a list of all the fields in the type.

        Whenever you fetch a field, the response will include details about the field along with
        all types related to that field.  If the field takes arguments, the response will include 
        the list of args and all of their types.
    """
    tool_cmd: str = f"fetch_h3_graphql_docs({id})"
    return run_h3_command_helper(tool_cmd, ['h3', 'gql-def', id])


# NOTE: can't pass dict arg, nor can you pass a JSON string.
# on the vscode side, it fails to validate with this:
#   Failed to validate tool a06_run_h3_graphql_request: TypeError: Cannot use 'in' operator to search for 'type' in true
# if i convert the arg to a str and try to provide JSON input, it fails on the fastmcp side with this:
#   Input should be a valid string [type=string_type, input_value={'pageInput': {'page_num': 1, 'page_size': 5}}, input_type=dict]
# ie it auto-converts the json string to a dict, then fails to validate it. 
# 
# workaround: embed query variables in the graphql_query string itself.
@mcp.tool()
def run_h3_graphql_request(graphql_query: str) -> Dict[str, Any]:
    """
    Run a GraphQL request against the H3 API.  Use this tool to fetch data about 
    pentests, weaknesses, impacts, attack paths, credentials, op templates, NodeZero runners, 
    and other pentesting-related data in your Horizon3.ai (H3) account.

    The GraphQL request is passed in via the `graphql_query` argument.  
    If the query has variables, you'll need to define them inline in the query itself.
    This tool does NOT support passing a separate variables JSON object.

    Please ensure that the GraphQL request is valid and conforms to the
    H3 GraphQL API schema.  You can use the `fetch_h3_graphql_docs` tool to get
    documentation for the GraphQL schema, including available queries, mutations,
    types, and fields.  
  
    Args:
        graphql_query (str): The GraphQL query to execute.  
        
    Returns:
        Dict with output and status.  The "output" field contains the GraphQL response.

    Errors:
        If you receive an error like "Cannot query field 'bar' on type 'Foo'", it means the 
        GraphQL request is invalid because it is trying to fetch fields that are not available
        in the H3 GraphQL API.  You can use the `fetch_h3_graphql_docs` tool to get schema 
        documentation for any GraphQL type or field within the H3 GraphQL API.  This helps 
        discover which types and fields are available for constructing valid GraphQL requests.
    """
    tool_cmd: str = f"run_h3_graphql_request"
    # Write the query to a temporary file
    with tempfile.NamedTemporaryFile(
        mode='w+t',
        prefix='h3-cli-mcp-gql-query-',
        suffix='.graphql',
        delete=True # whether to delete file after closing
    ) as tmp:
        tmp.write(graphql_query)
        tmp.flush()
        return run_h3_command_helper(
            tool_cmd, 
            [
                'h3', 
                'gql', 
                tmp.name, 
                # -rx- json.dumps(vars) if vars else '{}'
            ]
        )


# run the server (uses stdio JSON-RPC transport by default)
# usage: python3 server.py [mode]
#           mode: stdio | streamable-http [port] | sse [port]  
#           port: defaults to 8000    
def main():
    mode:str = get_mode()
    logger.info(f"Starting H3 MCP server in {mode} mode ...")
 
    if not mode or mode == 'stdio':
        mcp.run()
    elif mode == 'streamable-http':
        # Streamable HTTP: Recommended for web deployments.
        port: int = int(sys.argv[2] if len(sys.argv) > 2 else "8000")
        mcp.run(transport="streamable-http", host="0.0.0.0", port=port, path="/mcp")
    elif mode == 'sse':
        # SSE: For compatibility with existing SSE clients.
        port: int = int(sys.argv[2] if len(sys.argv) > 2 else "8000")
        mcp.run(transport="sse", host="0.0.0.0", port=port, path="/sse")
    else:
        logger.error(f'Unknown mode: {mode}; Valid modes: stdio, streamable-http, sse')
        sys.exit(1)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.exception(f"Failed to start server: {e}")
        sys.exit(1)


