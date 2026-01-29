# Build stage
FROM debian:trixie-slim AS build
ARG VERSION

# Download server files
ENV SERVER_PATH=/terraria-server
ADD https://terraria.org/api/download/pc-dedicated-server/terraria-server-${VERSION}.zip /${SERVER_PATH}.zip

# Install unzip to extract server files
RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*

# Extract server files
RUN set -eux; \
    unzip "${SERVER_PATH}.zip" -d "${SERVER_PATH}"; \
    mkdir -p "/${SERVER_PATH}"; \
    mkdir -p "/${SERVER_PATH}/configs"; \
    mkdir -p "/${SERVER_PATH}/worlds"; \
    mv "${SERVER_PATH}/${VERSION}/Linux/"* "/${SERVER_PATH}/"; \
    mv "${SERVER_PATH}/${VERSION}/Windows/serverconfig.txt" "${SERVER_PATH}/configs/serverconfig.txt"; \
    chmod +x "${SERVER_PATH}/TerrariaServer"*

# Runtime stage
FROM debian:trixie-slim AS runtime
ARG TARGETARCH
ARG VERSION

ENV TARGETARCH=${TARGETARCH}
ENV SERVER_PATH=/terraria-server
ENV CONFIG_PATH=${SERVER_PATH}/configs
ENV WORLD_PATH=${SERVER_PATH}/worlds

# Terraria CLI environment variables
ENV TERRARIA_CONFIG=${CONFIG_PATH}/serverconfig.txt
ENV TERRARIA_PORT=
ENV TERRARIA_MAXPLAYERS=
ENV TERRARIA_MOTD=
ENV TERRARIA_WORLD=
ENV TERRARIA_AUTOCREATE=
ENV TERRARIA_BANLIST=
ENV TERRARIA_WORLDNAME=
ENV TERRARIA_SECURE=
ENV TERRARIA_NOUPNP=
ENV TERRARIA_IP=
ENV TERRARIA_FORCEPRIORITY=
ENV TERRARIA_DISABLEANNOUNCEMENTBOX=
ENV TERRARIA_ANNOUNCEMENTBOXRANGE=
ENV TERRARIA_SEED=
ENV TERRARIA_EXTRA_ARGS=

# Expose volumes and ports
VOLUME ["${WORLD_PATH}", "${CONFIG_PATH}"]
EXPOSE 7777/udp
EXPOSE 7777/tcp

# Metadata
LABEL org.opencontainers.image.authors="BrammyS"
LABEL org.opencontainers.image.url="https://github.com/BrammyS/Terraria"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.description="Vanilla Terraria v${VERSION} Server"

# Copy the downloaded server files from build stage
COPY --from=build /${SERVER_PATH} /${SERVER_PATH}

# Install mono-runtime when building for non-amd64 architectures
RUN if [ "${TARGETARCH}" != "amd64" ]; then \
        apt-get update && apt-get install -y ca-certificates mono-runtime && rm -rf /var/lib/apt/lists/*; \
        # Prevent version mismatch issues
        rm "${SERVER_PATH}/System*" \
        rm "${SERVER_PATH}/Mono*" \
        rm "${SERVER_PATH}/monoconfig" \
        rm "${SERVER_PATH}/mscorlib.dll" \
    fi

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set working directory and entrypoint
WORKDIR ${SERVER_PATH}
ENTRYPOINT [ "/entrypoint.sh" ]
