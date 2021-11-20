#!/bin/sh -e

TMPDIR=$(mktemp -d -t 'gen-gh-pages-XXXXXX')

REPO_DIR="$TMPDIR/ccs-specs"
MY_DIR=$(realpath $(dirname $0))

mkdir -p "$REPO_DIR"
rsync -a "$MY_DIR/" "$REPO_DIR/"

rm -rf _site/

bundle exec jekyll build

for version in $(cat versions.json | jq -r -c '.[]'); do
    mkdir -p "_site/$version"
    ( cd "$REPO_DIR" && git checkout "${version}" )
	ln -sf "$MY_DIR/_layouts" "$REPO_DIR"
    bundle exec jekyll build --config _config.yml -b "/${version}" \
        -s "$REPO_DIR" -d "_site/${version}/"
done

rm -rf "$TMPDIR"
