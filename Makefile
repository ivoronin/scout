all: scout
scout: header.sh scout.sh
	cat header.sh > $@
	bzip2 -9c scout.sh >> $@
	chmod +x $@

.PHONY: clean
clean:
	rm -f scout
