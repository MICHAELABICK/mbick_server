images: proxmox-images
proxmox-images:
	$(eval SERVICE := packer-master)
	docker-compose build $(SERVICE)
	docker-compose run --rm $(SERVICE) build ubuntu.json
qemu-images:
	$(eval SERVICE := packer-proxmox)
	docker-compose build $(SERVICE)
	docker-compose run --rm $(SERVICE) build ubuntu-bionic.json
