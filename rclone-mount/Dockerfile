FROM alpine AS mbick-base
# Install su-exec
RUN apk add --no-cache \
    ca-certificates \
    su-exec \
    && rm -rf /tmp/* /var/cache/apk/* /var/lib/apk/lists/*

FROM alpine AS entrypoint

COPY entrypoint.sh /entrypoint.sh

FROM golang:alpine AS builder
RUN apk add --no-cache --update \
    git \
    && rm -rf /tmp/* /var/cache/apk/* /var/lib/apk/lists/*

ENV RCLONE_VERSION="v1.43.1"
ENV GOPATH="/go"

# RUN git clone https://github.com/ncw/rclone.git
# WORKDIR rclone
# RUN go install \
#     && rclone version

RUN go get -u -v github.com/ncw/rclone
WORKDIR $GOPATH/src/github.com/ncw/rclone
RUN git checkout $RCLONE_VERSION \
    && go install \
    && rclone version


FROM mbick-base AS base
RUN apk add --no-cache --update \
    fuse \
    fuse-dev \
    && rm -rf /tmp/* /var/cache/apk/* /var/lib/apk/lists/*
COPY --from=builder /go/bin/rclone /usr/sbin

ENV CONFIG_NAME=rclone.conf
ENV CONFIG_PATH=/config/$CONFIG_NAME

ENV MOUNT_POINT=/data
#     MountCommands="--allow-other --allow-non-empty" \
#     UnmountCommands="-u -z"

VOLUME /config
COPY ./config /config

COPY --from=entrypoint /entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["sh","/usr/local/bin/entrypoint.sh"]
CMD rclone mount --config="$CONFIG_PATH" $RCLONE_REMOTE_MOUNT $MOUNT_POINT

FROM base AS dev

# FROM base AS prod
# COPY ./config/rclone /config
