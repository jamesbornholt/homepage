.PHONY: clean site deploy

HOST := bornholt@recycle.cs.washington.edu
RSYNC_ARGS := --compress --recursive --checksum --itemize-changes --delete --filter='- .DS_Store' -e ssh
HUGO_ARGS := --config=config.toml

clean:
	rm -rf public

site:
	hugo

deploy: clean
	hugo $(HUGO_ARGS)
	rsync $(RSYNC_ARGS) public/ $(HOST):public_html/website
	hugo $(HUGO_ARGS) --buildDrafts
	rsync $(RSYNC_ARGS) public/post $(HOST):public_html/website/
	hugo $(HUGO_ARGS)
