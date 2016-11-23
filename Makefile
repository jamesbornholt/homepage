.PHONY: clean site deploy

HOST := bornholt@recycle.cs.washington.edu
ROOT := public_html/website/
RSYNC_ARGS := --compress --recursive --checksum --itemize-changes --filter='- .DS_Store' -e ssh

clean:
	rm -rf _site

site:
	jekyll build

deploy: clean
	jekyll build
	rsync $(RSYNC_ARGS) _site/ $(HOST):$(ROOT)
