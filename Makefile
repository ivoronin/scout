VERSION=$(shell git describe)

all: scout
scout: header.sh scout.sh
	cat header.sh > $@
	bash -n scout.sh
	sed -e 's/@VERSION@/$(VERSION)/' scout.sh | bzip2 -9c >> $@
	chmod +x $@

.PHONY: clean dist
clean:
	rm -f scout scout-$(VERSION).tbz

dist: scout
	fakeroot tar cjf scout-$(VERSION).tbz scout
