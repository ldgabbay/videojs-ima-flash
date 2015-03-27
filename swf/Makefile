BUILD_DIR=build
SRC_DIR=src
TARGET=$(BUILD_DIR)/videojs.ima_flash.swf

.PHONY: clean

$(TARGET): Makefile $(BUILD_DIR) $(shell find $(SRC_DIR) -type f)
	mxmlc \
	    -compiler.source-path=$(SRC_DIR) \
	    -library-path+=lib/ima_lib_as3.swc \
	    -static-link-runtime-shared-libraries=true \
	    -output $(TARGET) \
	    -target-player=10.1 \
	    $(SRC_DIR)/VideojsImaFlash.as

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
