FROM hashicorp/packer:light
ARG TEMPLATE_DIR
ENV TEMPLATES=$TEMPLATE_DIR

RUN apk add --update qemu qemu-system-x86_64 qemu-img

RUN mkdir -p $TEMPLATES
WORKDIR $TEMPLATES
