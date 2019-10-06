SRC_DIR := src
BUILD_DIR := build
TEMPLATE_DIR := $(SRC_DIR)/templates
TEMPLATE_BUILD_DIR := $(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(TEMPLATE_DIR))
PACKER_DEV_BUILDERS := virtualbox-iso

local_host_ip := $(shell ifconfig `route get 192.168.11.1 | grep "interface: " | sed "s/[^:]*: \(.*\)/\1/"` | grep "inet " | sed "s/.*inet \([0-9.]*\) .*/\1/")

templates := $(wildcard $(TEMPLATE_DIR)/**/*.json)
templates_build := $(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(templates))

# TODO: implement passing images as an argument to Make,
#   by overriding the "images" variable
images := $(templates)
bake := $(patsubst %.json,%.bake,$(images))
validate := $(patsubst %.json,%.validate,$(images))


all: images
# we force and rely on rsync for only touching updated files
copy: FORCE
	rsync -aR \
		$(SRC_DIR)/./scripts \
		$(SRC_DIR)/./templates/*/http \
		$(BUILD_DIR)/
build: $(templates_build) copy $(BUILD_DIR)/defaults.json
images: $(bake)
validate: $(validate)
clean: FORCE
	rm -rf $(BUILD_DIR)
clean-all: clean
	rm -rf packer_cache
# we must force, because we don't take into account
# dependencies on provisioners and scripts
# TODO: include script dependencies
$(TEMPLATE_DIR)/%.bake: $(TEMPLATE_BUILD_DIR)/%.json copy $(BUILD_DIR)/defaults.json FORCE
	packer build \
		-var-file=$(BUILD_DIR)/defaults.json \
		-var 'local_host_ip=${local_host_ip}' \
		$(PACKER_EXTRA_ARGS) \
		$<
# this is forced, because we always want to validate
# even if dependencies have not changed
$(TEMPLATE_DIR)/%.validate: $(TEMPLATE_BUILD_DIR)/%.json copy $(BUILD_DIR)/defaults.json FORCE
	packer validate \
		-var-file=$(BUILD_DIR)/defaults.json \
		-var 'local_host_ip=${local_host_ip}' \
		$(PACKER_EXTRA_ARGS) \
		$<
$(BUILD_DIR)/%.json: $(SRC_DIR)/%.json scripts/flatten_arrays.py
	mkdir -p $(dir $@)
	python scripts/flatten_arrays.py \
		-o $@ \
		$<
# TODO: use 'dhall resolve --transitive-dependencies'
#   in the future, so that we dont have to FORCE
# TODO: implement touching output file
#   only if output changes
$(BUILD_DIR)/%.json: $(SRC_DIR)/%.json.dhall FORCE
	mkdir -p $(dir $@)
	dhall-to-json --pretty --file $< --output $@
FORCE:
.PHONY: build images validate clean clean-all
