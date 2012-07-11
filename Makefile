VERSION=$(shell git describe)

all: scout
scout: header.sh scout.sh
	cat header.sh > $@
	sed -e 's/@VERSION@/$(VERSION)/' scout.sh | bzip2 -9c >> $@
	chmod +x $@

.PHONY: clean
clean:
	rm -f scout
