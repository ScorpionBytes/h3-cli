
## H3-INTERNAL: Using h3-cli in develop, stage, and sandbox environments

By default h3-cli will target our production API.  If you want to use it in our develop
or stage environment, you need to set additional environment variables to redirect the 
h3-cli to the appropriate GraphQL and auth services for that environment.


### Using h3-cli in the develop environment

To set up a separate h3-cli profile for the develop environment, first generate an API key
in that environment, then use the following command to create the h3-cli profile:

```shell
h3 save-profile dev {api-key}
```

This will create a new file `~/.h3/dev.env`, and store your API key in it.  Next, open the file
and add the following lines:

```shell
H3_GQL_URL=https://api.develop.h3ai.io/v1/graphql
H3_AUTH_URL=https://api.develop.h3ai.io/v1/auth
```

Now activate the profile with the following command (note the leading dot `.`):

```shell
. h3 profile dev
```

This will activate the profile named `dev` in your current shell session. You can verify by running
some h3 commands, for example:

```shell
h3 whoami
h3 pentest
```


### Using h3-cli in the stage environment

To set up a separate h3-cli profile for the stage environment, first generate an API key
in that environment, then use the following command to create the h3-cli profile:

```shell
h3 save-profile stage {api-key}
```

This will create a new file `~/.h3/stage.env`, and store your API key in it.  Next, open the file
and add the following lines:

```shell
H3_GQL_URL=https://api.stage.h3ai.io/v1/graphql
H3_AUTH_URL=https://api.stage.h3ai.io/v1/auth
```

Now activate the profile with the following command (note the leading dot `.`):

```shell
. h3 profile stage
```

This will activate the profile named `stage` in your current shell session. You can verify by running
some h3 commands, for example:

```shell
h3 whoami
h3 pentest
```


### Using h3-cli in a local sandbox environment

If you're running an h3-gql service locally for local development, you can configure
the h3-cli to use it by setting up a special h3-cli profile for local dev.


```shell
h3 save-profile sandbox sandbox
```

This will create a new file `~/.h3/sandbox.env`.  Next, open the file
and add the following lines:

```shell
H3_GQL_URL=http://127.0.0.1:8000/graphql
H3_AUTH_URL=sandbox
```

Now activate the profile with the following command (note the leading dot `.`):

```shell
. h3 profile sandbox
```

This will activate the profile named `sandbox` in your current shell session. You can verify by running
some h3 commands, for example:

```shell
h3 whoami
h3 pentest
```


