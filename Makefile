.PHONY: all

all:
	make -C js
	make -C swf
	cp js/build/dist/videojs.ima_flash.js ../videojs-test/
	cp swf/build/videojs.ima_flash.swf ../videojs-test/
	aws --profile queue s3 --cache-control="max-age=0" sync ../videojs-test/ s3://tout.queuecontinuum.com/
