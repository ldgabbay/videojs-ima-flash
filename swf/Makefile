BUILD_DIR=build
SRC_DIR=src
TARGET=$(BUILD_DIR)/widget.swf

.PHONY: clean

$(TARGET): Makefile $(BUILD_DIR) $(shell find $(SRC_DIR) -type f)
	mxmlc \
	    -compiler.source-path=$(SRC_DIR) \
	    -static-link-runtime-shared-libraries=true \
	    -output $(TARGET) \
	    -target-player=10.1 \
	    $(SRC_DIR)/Widget.as

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
