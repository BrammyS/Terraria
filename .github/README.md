[![Docker Image Size](https://img.shields.io/docker/image-size/brammys/terraria/latest)](https://hub.docker.com/r/brammys/terraria)

# Terraria Server

This image runs the official **Vanilla Terraria** dedicated server inside a container. The image is built for x64 and arm64 and is fully configurable via environment variables. The server also includes a graceful shutdown to prevent data loss on stopping the container.

## Available tags

The images are available on [Docker Hub](https://hub.docker.com/r/brammys/terraria) and [ghcr.io](https://github.com/BrammyS/Terraria/pkgs/container/terraria).
The tags following pattern is used:
- `terraria:latest` - Latest release version
- `terraria:<MAJOR>.<MINOR>.<PATCH>` - Release version (e.g. `terraria:1.4.5`)
- `terraria:<MAJOR>.<MINOR>.<PATCH>.<BUILD>` - Specific build version (e.g. `terraria:1.4.5.1`)

## Environment variables

All of the following environment variables are supported by the image entrypoint (they map directly to Terraria server CLI flags).

| Environment variable | Default | Notes |
|---|---|---|
| `TERRARIA_CONFIG` | `/configs/serverconfig.txt` | Specifies a configuration file to use |
| `TERRARIA_PORT` |  | Specifies the port to listen on |
| `TERRARIA_IP` |  | Bind IP address |
| `TERRARIA_PASSWORD` |  | Server password (masked in logs) |
| `TERRARIA_SECURE` | `0` | Enable by setting to `1` |
| `TERRARIA_NOUPNP` | `0` | Disable UPnP by setting to `1` |
| `TERRARIA_MAXPLAYERS` |  |  |
| `TERRARIA_MOTD` |  |  |
| `TERRARIA_FORCEPRIORITY` |  |  |
| `TERRARIA_WORLD` |  | Load a world and automatically start the server |
| `TERRARIA_AUTOCREATE` |  | `1`=small, `2`=medium, `3`=large |
| `TERRARIA_SEED` |  | Specifies the world seed when using -autocreate |
| `TERRARIA_BANLIST` |  |  |
| `TERRARIA_DISABLEANNOUNCEMENTBOX` | `0` | Enable by setting to `1` |
| `TERRARIA_ANNOUNCEMENTBOXRANGE` |  | Sets the announcement box text messaging range in pixels, -1 for serverwide announcements. |
| `TERRARIA_EXTRA_ARGS` |  | Appended verbatim to the server command |

## Volumes

The image uses the following paths for persistent data:

- Worlds: `/worlds`
- Configs: `/configs`

The image uses the config file at `/configs/serverconfig.txt` by default. It will be created automatically if it does not exist yet.`

## Examples

### Minimal (named volumes)

```bash
docker run -it --name terraria \
  -p 7777:7777/tcp -p 7777:7777/udp \
  -v terraria_worlds:/worlds \
  -v terraria_configs:/configs \
  brammys/terraria
```

### Autocreate a world (named volumes)

```bash
docker run -it --name terraria \
  -p 7777:7777/tcp -p 7777:7777/udp \
  -v terraria_worlds:/worlds \
  -v terraria_configs:/configs \
  -e TERRARIA_AUTOCREATE=2 \
  -e TERRARIA_WORLD=testing \
  -e TERRARIA_SEED=testing \
  brammys/terraria
```

### Use a specific world file path

```bash
docker run -it --name terraria \
  -p 7777:7777/tcp -p 7777:7777/udp \
  -v ./terraria_worlds:/worlds \
  -v ./terraria_configs:/configs \
  -e TERRARIA_WORLD=your_own_world \
  brammys/terraria
```

## docker-compose

Create a `docker-compose.yml`:

```yaml
services:
  terraria:
    image: brammys/terraria
    container_name: terraria
    restart: unless-stopped
    tty: true
    stdin_open: true
    ports:
      - "7777:7777/tcp"
      - "7777:7777/udp"
    environment:
      # Examples (optional):
      # TERRARIA_AUTOCREATE: "2"
      # TERRARIA_SEED: "testing_123"
      # TERRARIA_WORLD: "testing_world"
      # TERRARIA_MAXPLAYERS: "16"
      # TERRARIA_MOTD: "Welcome!"
      # TERRARIA_PASSWORD: "changeme"
      # TERRARIA_SECURE: "1"
      # TERRARIA_NOUPNP: "1"
    volumes:
      - terraria_worlds:/worlds
      - terraria_configs:/configs

volumes:
  terraria_worlds:
  terraria_configs:
```

The start the container:

```bash
docker compose up -d
```

Use the following command to attach to the running container in order to run server commands:

```bash
docker compose attach terraria
```

## Updating the server

Pull the new image and recreate the container. Your worlds and configs will be preserved if you mounted the volumes correctly.

When running the container via `docker run`:
```bash
docker pull brammys/terraria:latest
docker stop terraria
docker rm terraria
docker run ... (same parameters as before)
```

When using `docker-compose`:
```bash
docker compose pull
docker compose up -d
```

## Building the image locally

To build the image locally, run:

```bash
git clone https://github.com/BrammyS/Terraria.git
cd ./Terraria/vanilla
docker build --build-arg VERSION=1452 --build-arg TARGETARCH=amd64 -t terraria:local .
```

Replace `1452` with the desired version number and `amd64` with `arm64` for ARM builds.
