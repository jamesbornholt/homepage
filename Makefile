.PHONY: clean site deploy

HOST := bornholt@recycle.cs.washington.edu

clean:
	rm -rf public

site:
	hugo

deploy: clean site
	rsync --compress --recursive --checksum --itemize-changes --delete --filter='- .DS_Store' -e ssh public/ $(HOST):public_html/website
