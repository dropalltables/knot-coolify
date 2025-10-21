# Knot Docker

> **IMPORTANT**
> This is a community maintained repository, support is not guaranteed.

Docker container and compose setup to run a [Tangled](https://tangled.org) knot
and host your own repository data.

## Pre-built Images

There is a [repository](https://hub.docker.com/r/hqnna/knot) of pre-built images
for tags starting at `v1.4.0-alpha` if you prefer.

```
docker pull hqnna/knot:v1.4.0-alpha
```

Note that these are *not* official images, you use them at your own risk.

## Building The Image

By default the `Dockerfile` will build the latest tag, but you can change it
with the `TAG` build argument.

```sh
docker build -t knot:latest --build-arg TAG=master .
```

The command above for example will build the latest commit on the `master`
branch.

<hr style="margin-bottom: 20px; margin-top: 10px" />

When using compose, it can be specified as a build argument which will be
passed to the builder.

```yaml
build:
  context: .
  args: { TAG: master }
```

This will for example tell docker to build it using the `master` branch like
the command.

## Setting Up The Image

The simplest way to set up your own knot is to use the provided compose file
and run the following:

```sh
export KNOT_SERVER_HOSTNAME=example.com
export KNOT_SERVER_OWNER=did:plc:yourdidgoeshere
export KNOT_SERVER_PORT=443
docker compose up -d
```

This will setup everything for you including a reverse proxy.
