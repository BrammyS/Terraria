# Terraria Server

This image runs the official **Vanilla Terraria** dedicated server inside a container. The image is built for multiple architectures (amd64, arm64, arm) and is fully configurable via environment variables.

## Available tags

The images are available on [Docker Hub](https://hub.docker.com/r/brammys/terraria) and [ghcr.io](https://github.com/BrammyS/Terraria/pkgs/container/terraria).
The tags following pattern is used:
- `terraria:latest` - Latest release version
- `terraria:<MAJOR>.<MINOR>.<PATCH>` - Release version (e.g. `terraria:1.4.5`)
- `terraria:<MAJOR>.<MINOR>.<PATCH>.<BUILD>` - Specific build version (e.g. `terraria:1.4.5.1`)

## Environment variables

All of the following environment variables are supported by the image entrypoint (they map directly to Terraria server CLI flags).

| Category | Environment variable | Default | Terraria CLI flag | Notes |
|---|---|---|---|---|
| Config | `TERRARIA_CONFIG` | `/terraria-server/configs/serverconfig.txt` | `-config <path>` | Config file path |
| Network | `TERRARIA_PORT` |  | `-port <port>` | Publish the same port on TCP and UDP |
| Network | `TERRARIA_IP` |  | `-ip <ip>` | Bind IP address |
| Access | `TERRARIA_PASSWORD` |  | `-password <password>` | Server password (masked in logs) |
| Access | `TERRARIA_SECURE` | `0` | `-secure` | Enable by setting to `1` |
| Network | `TERRARIA_NOUPNP` | `0` | `-noupnp` | Disable UPnP by setting to `1` |
| Server | `TERRARIA_MAXPLAYERS` |  | `-maxplayers <number>` |  |
| Server | `TERRARIA_MOTD` |  | `-motd <text>` |  |
| Server | `TERRARIA_FORCEPRIORITY` |  | `-forcepriority <value>` |  |
| World | `TERRARIA_WORLD` |  | `-world <path>` | World file path |
| World | `TERRARIA_WORLDNAME` |  | `-worldname <name>` | Used when creating a new world |
| World | `TERRARIA_AUTOCREATE` |  | `-autocreate <size>` | `1`=small, `2`=medium, `3`=large |
| World | `TERRARIA_SEED` |  | `-seed <seed>` | Used when creating a new world |
| Moderation | `TERRARIA_BANLIST` |  | `-banlist <path>` |  |
| UI | `TERRARIA_DISABLEANNOUNCEMENTBOX` | `0` | `-disableannouncementbox` | Enable by setting to `1` |
| UI | `TERRARIA_ANNOUNCEMENTBOXRANGE` |  | `-announcementboxrange <number>` |  |
| Advanced | `TERRARIA_EXTRA_ARGS` |  | (appended) | Appended verbatim to the server command |

## Volumes

The image uses the following paths for persistent data:

- Worlds: `/terraria-server/worlds`
- Configs: `/terraria-server/configs`

The image includes a default config file at:

- `/terraria-server/configs/serverconfig.txt`

## Examples

### Minimal (named volumes)

```bash
docker run -it --name terraria \
  -p 7777:7777/tcp -p 7777:7777/udp \
  -v terraria_worlds:/terraria-server/worlds \
  -v terraria_configs:/terraria-server/configs \
  brammys/terraria
```

### Autocreate a world (named volumes)

```bash
docker run -it --name terraria \
  -p 7777:7777/tcp -p 7777:7777/udp \
  -v terraria_worlds:/terraria-server/worlds \
  -v terraria_configs:/terraria-server/configs \
  -e TERRARIA_AUTOCREATE=2 \
  -e TERRARIA_WORLDNAME=testing \
  -e TERRARIA_SEED=testing \
  brammys/terraria
```

### Use a specific world file path

```bash
docker run -it --name terraria \
  -p 7777:7777/tcp -p 7777:7777/udp \
  -v ./terraria_worlds:/terraria-server/worlds \
  -v ./terraria_configs:/terraria-server/configs \
  -e TERRARIA_WORLD=/terraria-server/worlds/your_own_world.wld \
  brammys/terraria
```

## docker-compose

Create a `docker-compose.yml` like this:

```yaml
services:
  terraria:
    image: terraria:vanilla
    container_name: terraria
    restart: unless-stopped
    ports:
      - "7777:7777/tcp"
      - "7777:7777/udp"
    environment:
      # Examples (optional):
      # TERRARIA_AUTOCREATE: "2"
      # TERRARIA_WORLDNAME: "testing"
      # TERRARIA_SEED: "testing"
      # TERRARIA_WORLD: "/terraria-server/worlds/testing.wld"
      # TERRARIA_MAXPLAYERS: "16"
      # TERRARIA_MOTD: "Welcome!"
      # TERRARIA_PASSWORD: "changeme"
      # TERRARIA_SECURE: "1"
      # TERRARIA_NOUPNP: "1"
      # TERRARIA_EXTRA_ARGS: "-logfile /terraria-server/configs/server.log"
    volumes:
      - terraria_worlds:/terraria-server/worlds
      - terraria_configs:/terraria-server/configs

volumes:
  terraria_worlds:
  terraria_configs:
```

Start it:

```bash
docker compose up -d
```

## Build

The image downloads the dedicated server ZIP from Terraria’s official endpoint:

- `https://terraria.org/api/download/pc-dedicated-server/terraria-server-${VERSION}.zip`

Build from the `vanilla/` folder:

```bash
docker build -t terraria:vanilla --build-arg VERSION=<VERSION> .
```

Notes:
- `<VERSION>` must match the version identifier used by the Terraria download endpoint.
- The entrypoint chooses `./TerrariaServer` on `amd64` and `mono ./TerrariaServer.exe` on other architectures.
