.PHONY: build clean distclean

build: node_modules build/filelist.json
	npm run build

node_modules: package.json
	npm install

build/filelist.json: src/main.js $(shell bin/get_required_files.py -m src/main.js)
	mkdir -p build
	bin/get_required_files.py -j src/main.js > build/filelist.json

clean:
	rm -rf build

distclean: clean
	for package in `ls node_modules`; do npm uninstall $$package; done
	rmdir node_modules/.bin node_modules
