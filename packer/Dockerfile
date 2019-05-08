FROM hashicorp/packer:light as packer

FROM packer as packer-qemu
ARG TEMPLATE_DIR
ENV TEMPLATES=$TEMPLATE_DIR

RUN apk add --update qemu qemu-system-x86_64 qemu-img

FROM pve-template-upload
RUN mkdir -p $TEMPLATES
WORKDIR $TEMPLATES


