#!/bin/sh -e

TMPDIR=$(mktemp -d -t 'gen-gh-pages-XXXXXX')

REPO_DIR="$TMPDIR/ccs-specs"
MY_DIR=$(realpath $(dirname $0))

git clone "$MY_DIR" "$REPO_DIR"

for version in $(cat versions.json | jq -r -c '.[]'); do
	rm -rf "$version/"
	mkdir -p "$version"
	(
		cd "$REPO_DIR"
		git checkout -b "${version}" -t "origin/${version}"
		bundle exec jekyll build -d "$MY_DIR/${version}/"
	)
done

rm -rf "$TMPDIR"
