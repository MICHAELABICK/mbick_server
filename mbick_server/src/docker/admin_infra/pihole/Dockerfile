ARG PIHOLE_VERSION
FROM pihole/pihole:$PIHOLE_VERSION AS pihole

FROM pihole
COPY domains.conf /etc/dnsmasq.d/02-domains.conf