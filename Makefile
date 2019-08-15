.PHONY: clean site deploy

JEKYLL := bundle exec jekyll
HOST := bornholt@linux.cs.utexas.edu
ROOT := public_html/homepage/
RSYNC_ARGS := --compress --recursive --checksum --itemize-changes --delete --filter='- .DS_Store' -e ssh

clean:
	rm -rf _site

site:
	$(JEKYLL) build

deploy: clean
	$(JEKYLL) build
	rsync $(RSYNC_ARGS) _site/ $(HOST):$(ROOT)


CHROME := /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome

cv:
	$(JEKYLL) build -b $(shell pwd)/_site
	$(CHROME) --headless --print-to-pdf=files/cv.pdf _site/cv.html