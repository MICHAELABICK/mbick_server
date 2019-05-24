host_ip := $(shell ifconfig `route get 192.168.11.1 | grep "interface: " | sed "s/[^:]*: \(.*\)/\1/"` | grep "inet " | sed "s/.*inet \([0-9.]*\) .*/\1/")

images: new-proxmox-images
new-proxmox-images:
	packer build \
		-var-file=defaults.json \
		-var 'host_ip=${host_ip}' \
		templates/ubuntu/ubuntu.json
proxmox-images:
	$(eval SERVICE := packer-master)
	docker-compose build $(SERVICE)
	docker-compose run --rm $(SERVICE) build ubuntu.json
