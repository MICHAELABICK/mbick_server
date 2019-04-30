FROM ubuntu:18.04
RUN apt-get update && apt-get install -y \
    cloud-utils \
    && rm -rf /var/lib/apt/lists/*

CMD ["cloud-localds", "/tmp/host/cloud.img", "/tmp/host/cloud.cfg"]
