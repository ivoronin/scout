VERSION=$(shell git describe)

all: scout
scout: scout.sh .git/index
	bash -n scout.sh
	sed -e 's/@VERSION@/$(VERSION)/' scout.sh > $@
	chmod 755 $@

.PHONY: clean dist
clean:
	rm -f scout scout-$(VERSION).tbz

dist: scout
	fakeroot tar cjf scout-$(VERSION).tbz scout
