.PHONY: clean site deploy

HOST := bornholt@recycle.cs.washington.edu
ROOT := public_html/website/
RSYNC_ARGS := --compress --recursive --checksum --itemize-changes --filter='- .DS_Store' -e ssh
HUGO_ARGS := --config=config.toml

clean:
	rm -rf public

site:
	hugo

deploy: clean
	hugo $(HUGO_ARGS) --buildDrafts
	rsync $(RSYNC_ARGS) public/ $(HOST):$(ROOT)
	hugo $(HUGO_ARGS)
	rsync $(RSYNC_ARGS) public/ $(HOST):$(ROOT)
