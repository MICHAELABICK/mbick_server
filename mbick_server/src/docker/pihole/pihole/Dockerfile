ARG PIHOLE_TAG
FROM pihole/pihole:${PIHOLE_TAG} AS pihole

FROM pihole
COPY domains.conf /etc/dnsmasq.d/02-domains.conf