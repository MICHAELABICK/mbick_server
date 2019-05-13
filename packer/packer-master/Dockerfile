FROM golang:alpine as builder

ENV PACKER_DEV=1

RUN apk add --update git bash openssl
# RUN go get github.com/mitchellh/gox

ENV PACKER_WS=/packer_ws
RUN mkdir $PACKER_WS
WORKDIR $PACKER_WS

RUN go mod init . \
    && go get -d github.com/hashicorp/packer@master

RUN go build -o /bin/packer github.com/hashicorp/packer

WORKDIR $GOPATH


FROM alpine as packer
COPY --from=builder /bin/packer /bin


FROM williamyeh/ansible:alpine3-onbuild as ansible


FROM packer
ENTRYPOINT ["/bin/packer"]
