.PHONY: clean site deploy

HOST := recycle.cs.washington.edu

clean:
	rm -rf public

site:
	hugo

deploy: clean site
	rsync --compress --recursive --checksum --itemize-changes --delete -e ssh public/ $(HOST):public_html/website
