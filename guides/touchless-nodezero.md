
## h3-cli: Touchless NodeZero deployment using the h3-cli agent

You can now deploy NodeZero automatically on your Docker Host using the h3-cli agent.

All _internal_ pentests require that you deploy NodeZero on a Docker Host inside your network.
This is normally done by manually copy+pasting the NodeZero Launch Command curl script 
and running it on your machine.

To launch NodeZero automatically, you first spin up an agent process on your Docker Host, using the h3-cli.
The h3-cli agent is a long-lived daemon process that periodically polls the H3 API and launches NodeZero 
automatically on the local machine when a new pentest is created and assigned to that agent.

**NOTE:** If you are running _external_ pentests, NodeZero is deployed automatically to the H3 cloud
and the h3-cli agent is not required.


### 1. Spin up an agent (_internal_ pentests only)

The command below will spin up an agent named `my-agent` on the local machine, and log its
output to `/tmp/my-agent.log`:

```shell
h3 start-agent my-agent /tmp/my-agent.log
```

To verify the agent has registered itself with H3, run the command below:

```shell
h3 agents
```

You should see an entry for the agent `my-agent` that you just started.

Verify agent connectivity by sending it a "hello world":

```shell
h3 hello-agent my-agent 
tail -f /tmp/my-agent.log
```

You should see the following hello world message received by your agent in the log.
It might take a minute for the message to appear.

```
[Mon Feb  6 01:38:13 EST 2023] [agent: my-agent] Received agent command: {
  "uuid": "aca96d72-13a2-487e-b6f1-fda2860e4aee",
  "agent_uuid": "8c53d4e7-32a4-4d26-a02e-b83bb5770c19/my-agent",
  "command": "hello-world",
  "received_at": "2023-02-06T06:38:13.387793",
  "row_created_at": "2023-02-06T06:38:06.553829"
}
[Mon Feb  6 01:38:13 EST 2023] [agent: my-agent] Running command in a separate process: hello-world
[Mon Feb  6 01:38:13 EST 2023] [agent: my-agent] Sleeping for 60 seconds
{
  "data": {
    "hello": "world!"
  }
}
```


### 2. Schedule a pentest and assign it to the agent 

To create a pentest and assign it to an agent, use the `agent_name` parameter:

```shell
h3 schedule-pentest '{"agent_name": "my-agent", "op_name": "Scheduled via CLI and launched by agent"}'
```

Note in this case we're using `h3 schedule-pentest` as opposed to `h3 run-pentest`, because `run-pentest`
would automatically download and run NodeZero itself, whereas `schedule-pentest` only
creates the pentest, thereby letting the agent be the one to download and run NodeZero.

In a minute or so you should see the agent kick off the NodeZero Launch Script for the newly
created pentest. You can monitor the agent process by tailing the log:

```shell
tail -f /tmp/my-agent.log
```

The NodeZero Launch Script will download and run the NodeZero Docker container
on the local machine, just as if you had copy+pasted the `curl` command from the Web Portal.

You can view the newly created pentest via:

```shell
h3 pentest 
```


### 3. Useful agent commands


You can list your registered agents via:

```shell
h3 agents
```

You can show any active agent processes on the local machine via:

```shell
h3 ps-agent 
```

Finally you can kill all agent processes on the local machine via:

```shell
h3 stop-agent
```

