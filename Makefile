.PHONY: all

all:
	make -C js
	make -C swf
	cp js/build/dist/videojs.ima_flash.js testsite/
	cp swf/build/videojs.ima_flash.swf testsite/
	aws --profile queue s3 --cache-control="max-age=0" sync testsite/ s3://tout.queuecontinuum.com/
