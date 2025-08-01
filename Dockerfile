#
# Dockerfile for the publicly available H3 MCP Server Docker image.
# See .gitlab-ci.yml for CI/CD job that builds and pushes this Docker image.
# 
# Example build command:
#   $ docker build -t my-h3-mcp-server .
#
# Example run command:
#   $ docker run -it --rm \
#     --pull always \
#     -p 8002:8002 \
#     -e H3_API_KEY=$H3_API_KEY \
#     -e H3_GQL_URL=$H3_GQL_URL \
#     -e H3_AUTH_URL=$H3_AUTH_URL \
#     my-h3-mcp-server sse 8002
#

FROM cgr.dev/chainguard/wolfi-base

RUN apk update && apk add --no-cache curl python3 py3-pip jq bash
    
WORKDIR /app

# Copy the h3-cli binaries to the container
COPY ./bin /app/h3-cli/bin
COPY ./filters /app/h3-cli/filters
COPY ./mcp /app/h3-cli/mcp
COPY ./queries /app/h3-cli/queries

RUN chmod -R a+x /app/h3-cli/bin

# when building the container locally, you may have jq in the h3-cli/bin directory.
# remove it to avoid conflicts with the system jq stored via apt-get.
RUN rm -f /app/h3-cli/bin/jq       

USER nonroot

# Create an empty profile file (otherwise h3-cli will complain).
# All the profile settings, eg. H3_API_KEY, will be provided via env vars when the container is started.
RUN mkdir -p /home/nonroot/.h3
RUN touch /home/nonroot/.h3/default.env

ENV H3_CLI_HOME=/app/h3-cli
ENV PATH="$H3_CLI_HOME/bin:$PATH"

# Install Python dependencies
RUN pip install --no-cache-dir -r /app/h3-cli/mcp/requirements.txt

USER root
# Clean up packages and remove busybox and apk-tools to reduce image size
RUN apk del --no-cache apk-tools busybox && \
    rm -rf /var/cache/apk/* /var/tmp/* && \
    rm -f /bin/ps /usr/bin/ps /bin/top /usr/bin/top /bin/kill /usr/bin/kill \
          /bin/killall /usr/bin/killall /sbin/apk /usr/sbin/apk \
          /bin/su /usr/bin/su /sbin/su /usr/sbin/su && \
    find /usr/lib/python3* -name "*.pyc" -delete && \
    find /usr/lib/python3* -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true && \
    rm -rf /usr/lib/python3*/test /usr/lib/python3*/unittest \
           /usr/lib/python3*/tkinter /usr/lib/python3*/turtle.py \
           /usr/lib/python3*/turtledemo /usr/lib/python3*/idlelib

USER nonroot

ENTRYPOINT ["python", "/app/h3-cli/mcp/server.py"]