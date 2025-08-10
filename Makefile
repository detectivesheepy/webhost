all: build.sh
	./build.sh

publish: publish.sh
	./publish.sh

clean: out
	rm -rf ./out
