BUILD_DIR=build

.PHONY: clean FORCE

clean:
	rm -rf $(BUILD_DIR)

$(BUILD_DIR)/%/main.tf.json: %/main.tf.json.dhall FORCE
	mkdir -p $(dir $@)
	cd $(dir $<) && dhall-to-json --file $(notdir $<) --output $(abspath $@)

FORCE:
