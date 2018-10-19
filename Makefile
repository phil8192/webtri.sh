doc:
	tomdoc.sh -m -a "Public" webtri.sh > docs.md

test:
	bats test/test_webtrish.bats
