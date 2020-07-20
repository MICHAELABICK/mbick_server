ARG WG_ACCESS_SERVER_VERSION
FROM place1/wg-access-server:$WG_ACCESS_SERVER_VERSION AS wg-access-server

FROM wg-access-server
COPY config.yaml /config.yaml