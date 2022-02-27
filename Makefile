.PHONY: build clean test update-version

build:
	dune build @install

test:
	dune runtest

install:
	dune install

uninstall:
	dune uninstall

clean:
	rm -rf _build *.install

fmt:
	dune build @fmt --auto-promote || echo "format has errors, ignoring"

.PHONY: endpoints

endpoints:
	dune exec endpoint-geendpoint-genn -- -i input/endpoints.json -o lib

# NOTE: This does not include aws-ec2, which is special-cased.
LIBRARIES := \
	aws-dynamodb \

.PHONY: $(LIBRARIES)
$(LIBRARIES): aws-%:
	dune exec aws-gen -- -i input/$*/latest/service-2.json -r input/$*/overrides.json -e input/errors.json -o libraries

update-version: VERSION=$(shell cat CHANGES.md | grep -E '^[0-9]' | head -n 1 | cut -f1 -d':' )
update-version:
	@echo "Set version to $(VERSION)"
	@gsed -i 's/^version: .*/version: "$(VERSION)"/' *.opam
	# @gsed -i 's/"\(aws-s3[-a-z]*\)"[ ]*{= .*}/"\1" {= "$(VERSION)" }/' *.opam
	@gsed -i 's/"\(aws-[-a-z]*\)"[ ]*{= .*}/"\1" {= "$(VERSION)" }/' *.opam
	@gsed -i 's/"\(aws[-a-z]*\)"[ ]*{= .*}/"\1" {= "$(VERSION)" }/' *.opam

update-version: VERSION=$(shell cat CHANGES.md | grep -E '^[0-9]' | head -n 1 | cut -f1 -d':' )
release: update-version
	opam publish

# TODO Test doc generation and publish to GH Pages
doc:
	dune build @doc

gh-pages: doc
	git clone `git config --get remote.upstream.url` .gh-pages --reference .
	git -C .gh-pages checkout --orphan gh-pages
	git -C .gh-pages reset
	git -C .gh-pages clean -dxf
	cp  -r _build/default/_doc/_html/* .gh-pages
	git -C .gh-pages add .
	git -C .gh-pages config user.email 'docs@ocaml-aws'
	git -C .gh-pages commit -m "Update documentation"
	git -C .gh-pages push origin gh-pages -f
	rm -rf .gh-pages
