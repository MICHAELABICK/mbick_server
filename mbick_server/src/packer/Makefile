SRC_DIR := .
BUILD_DIR := build
TEMPLATE_SRC_DIR := $(SRC_DIR)/templates
TEMPLATE_BUILD_DIR := $(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(TEMPLATE_SRC_DIR))

vault_address := $(shell dhall-to-bash <<< 'let packages =./packages.dhall in packages.networking.HostURL.show packages.mbick-server.config.vault_api.address')
local_host_ip := $(shell ifconfig `route get 192.168.11.1 | grep "interface: " | sed "s/[^:]*: \(.*\)/\1/"` | grep "inet " | sed "s/.*inet \([0-9.]*\) .*/\1/")

# dhall_src := $(wildcard $(TEMPLATE_SRC_DIR)/*.dhall)
dhall_src := $(shell find $(TEMPLATE_SRC_DIR) -type f -name '*.dhall')
dhall_build := $(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(dhall_src))
json_build := $(patsubst %.json.dhall,%.json,$(dhall_build))
misc_src = $(filter-out $(dhall_src),$(shell find $(TEMPLATE_SRC_DIR) -type f -name '*'))
misc_build := $(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(misc_src))

# TODO: implement passing images as an argument to Make,
#   by overriding the "images" variable
images := $(json_build)
bake := $(patsubst %.json,%.bake,$(images))
validate := $(patsubst %.json,%.validate,$(images))


.PHONY: all build images validate clean clean-all FORCE
all: images
build: $(images)
images: $(bake)
validate: $(validate)
clean:
	rm -rf $(BUILD_DIR)
clean-all: clean
	rm -rf packer_cache
# we must force, because we don't take into account
# dependencies on provisioners and scripts
# TODO: include script dependencies
$(TEMPLATE_BUILD_DIR)/%.bake: $(TEMPLATE_BUILD_DIR)/%.json $(misc_build) FORCE
	mkdir -p $(TEMPLATE_BUILD_DIR)
	VAULT_ADDR=$(vault_address) \
	VAULT_TOKEN=$$(cat ~/.vault-token) \
		packer build \
		-var 'local_host_ip=${local_host_ip}' \
		$(PACKER_EXTRA_ARGS) \
		$<
# this is forced, because we always want to validate
# even if dependencies have not changed
$(TEMPLATE_BUILD_DIR)/%.validate: $(TEMPLATE_BUILD_DIR)/%.json FORCE
	mkdir -p $(TEMPLATE_BUILD_DIR)
	VAULT_ADDR=$(vault_address) \
	VAULT_TOKEN=$$(cat ~/.vault-token) \
		packer validate \
		-var 'local_host_ip=${local_host_ip}' \
		$(PACKER_EXTRA_ARGS) \
		$<
# TODO: use 'dhall resolve --transitive-dependencies'
#   in the future, so that we dont have to FORCE
# TODO: implement touching output file
#   only if output changes
$(TEMPLATE_BUILD_DIR)/%.json: $(TEMPLATE_SRC_DIR)/%.json.dhall FORCE
	mkdir -p $(dir $@)
	dhall-to-json --file $< --output $@
$(TEMPLATE_BUILD_DIR)/%: $(TEMPLATE_SRC_DIR)/%
	mkdir -p $(dir $@)
	cp $< $@
FORCE:
