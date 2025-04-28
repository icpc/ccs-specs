#!/bin/sh -e

TMPDIR=$(mktemp -d -t 'gen-gh-pages-XXXXXX')

REPO_DIR="$TMPDIR/ccs-specs"
MY_DIR=$(realpath $(dirname $0))

mkdir -p "$REPO_DIR"
rsync -a "$MY_DIR/" "$REPO_DIR/"

cd "$MY_DIR"
if [ -n "$(git status --porcelain)" ]; then
	echo "Repository has local changes and/or untracked files."
	echo "Commit or stash these before running this script."
	exit 1
fi

rm -rf docs

bundle exec jekyll build -d docs/

commits=''
for version in $(cat versions.json | jq -r -c '.[]'); do
	branch="${version}"
	if [ "${version}" = "draft" ];
	then
		branch="master"
	fi
	cd "$REPO_DIR"
	git checkout "${branch}"
	commitsha=$(git rev-parse --short=10 HEAD)
	commits="${commits}
- ${version} generated from ${commitsha}"
	cd -

	ln -sf "$MY_DIR/_layouts" "$REPO_DIR"
	# Needs to be a copy since symlinks are outside the project
	cp -Rf "$MY_DIR/_includes" "$REPO_DIR"
	echo "version: ${version}" > "$TMPDIR/version.yml"
	bundle exec jekyll build --config _config.yml,"$TMPDIR/version.yml" \
		-b "/${version}" -s "$REPO_DIR" -d "docs/${version}/"
done

git add --all
git commit -a -m "Automatically rebuild docs:
${commits}"

rm -rf "$TMPDIR"
