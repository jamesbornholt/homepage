.PHONY: clean site deploy

HOST := bornholt@tricycle.cs.washington.edu
ROOT := public_html/website/
RSYNC_ARGS := --compress --recursive --checksum --itemize-changes --delete --filter='- .DS_Store' -e ssh

clean:
	rm -rf _site

site:
	bundle exec jekyll build

deploy: clean
	bundle exec jekyll build
	rsync $(RSYNC_ARGS) _site/ $(HOST):$(ROOT)
