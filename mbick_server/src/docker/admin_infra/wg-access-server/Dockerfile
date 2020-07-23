ARG WG_ACCESS_SERVER_TAG
ARG VAULT_TAG

FROM place1/wg-access-server:${WG_ACCESS_SERVER_TAG} as wg-access-server

FROM hashicorp/vault:${VAULT_TAG} as vault

FROM wg-access-server
COPY --from=vault /bin/vault /bin/vault
ENV CONFIG=/config.yml
COPY config.yml ${CONFIG}

CMD WIREGUARD_PRIVATE_KEY=$(VAULT_TOKEN=${VAULT_TOKEN} \
  vault kv get \
  -address=${VAULT_ADDR} \
  -field=wireguard_private_key \
  secret/wg_access_server) \
  /server