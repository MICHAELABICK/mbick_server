include ../common.env
export

BUILD_DIR := build
TEMPLATE_DIR := templates

proxmox_host_ip := $(shell ifconfig `route get 192.168.11.1 | grep "interface: " | sed "s/[^:]*: \(.*\)/\1/"` | grep "inet " | sed "s/.*inet \([0-9.]*\) .*/\1/")

templates := $(wildcard $(TEMPLATE_DIR)/*/*.json)
config_scripts := $(filter-out $(templates),$(shell find templates -type f -not -path '*/\.*'))

templates_build := $(patsubst $(TEMPLATE_DIR)/%,$(BUILD_DIR)/%,$(templates))
config_scripts_build := $(patsubst $(TEMPLATE_DIR)/%,$(BUILD_DIR)/%,$(config_scripts))

images: new-proxmox-images
new-proxmox-images: build
	packer build \
		-var-file=defaults.json \
		-var 'proxmox_api_url=${PROXMOX_API_URL}' \
		-var 'proxmox_host_ip=${proxmox_host_ip}' \
		$(PACKER_EXTRA_ARGS) \
		$(BUILD_DIR)/ubuntu/ubuntu.json
proxmox-images:
	$(eval SERVICE := packer-master)
	docker-compose build $(SERVICE)
	docker-compose run --rm $(SERVICE) build ubuntu.json
build validate: $(templates_build) $(config_scripts_build)
validate:
	packer validate \
		-var-file=defaults.json \
		-var 'proxmox_api_url=${PROXMOX_API_URL}' \
		-var 'proxmox_host_ip=${proxmox_host_ip}' \
		$(BUILD_DIR)/ubuntu/ubuntu.json
clean:
	rm -rf $(BUILD_DIR)
clean-all: clean
	rm -rf packer_cache
.SECONDEXPANSION:
$(templates_build): $$(patsubst $$(BUILD_DIR)/%,$$(TEMPLATE_DIR)/%,$$@)
	mkdir -p $(dir $@)
	python scripts/flatten_arrays.py \
		-o $@ \
		$<
$(config_scripts_build): $$(patsubst $$(BUILD_DIR)/%,$$(TEMPLATE_DIR)/%,$$@)
	mkdir -p $(dir $@)
	rsync -ah $< $@

