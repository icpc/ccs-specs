#!/bin/sh -e

TMPDIR=$(mktemp -d -t 'gen-gh-pages-XXXXXX')

MY_DIR=$(realpath "$(dirname "$0")")

cd "$MY_DIR"
if [ -n "$(git status --porcelain)" ]; then
	echo "Repository has local changes and/or untracked files."
	echo "Commit or stash these before running this script."
	exit 1
fi

# Debian's readthedocs theme.css (from sphinx_rtd_theme) references
# its fonts as url("../fonts/<Name>"), i.e. a fonts/ directory beside
# css/, using CamelCase names, but the package actually ships them
# inside css/fonts/ under different names (lato-normal.woff2 for
# Lato-Regular.woff2, Roboto-Slab-*.woff2 for RobotoSlab-*.woff2).
# Populate the fonts/ directory theme.css expects, then fail loudly
# if theme.css still references a missing file, so a future font rename
# in the package surfaces here as a build error, not a silent 404.
fix_theme_fonts() {
	src="$1/css/fonts"
	dst="$1/fonts"
	[ -d "$src" ] || return 0
	mkdir -p "$dst"
	# FontAwesome ships under the names theme.css expects: copy as-is.
	cp "$src"/fontawesome-webfont.* "$dst/"
	# Lato and Roboto Slab are renamed: map shipped name -> expected name.
	for pair in \
		lato-normal:Lato-Regular \
		lato-bold:Lato-Bold \
		lato-normal-italic:Lato-Italic \
		lato-bold-italic:Lato-BoldItalic \
		Roboto-Slab-Regular:RobotoSlab-Regular \
		Roboto-Slab-Bold:RobotoSlab-Bold
	do
		s="${pair%%:*}"
		d="${pair##*:}"
		for ext in woff2 woff; do
			[ -f "$src/$s.$ext" ] && cp "$src/$s.$ext" "$dst/$d.$ext"
		done
	done
	missing=$(grep -o 'url("\.\./fonts/[^"?)]*\.woff2' "$1/css/theme.css" \
		| sed 's#url("\.\./fonts/##' | sort -u \
		| while read -r n; do [ -e "$dst/$n" ] || echo "$n"; done)
	if [ -n "$missing" ]; then
		echo "ERROR: theme.css references font files absent after fixup:" >&2
		echo "$missing" >&2
		exit 1
	fi
}

# Build a tree laid out as $TMPDIR/<name>/{mkdocs.yml,docs/}.
# The markdown must already be present in .../docs/; this adds the
# config and shared assets and builds.
#   $1 = tree name under $TMPDIR
#   $2 = config file
#   $3 = output directory
build_tree() {
	cp "$2" "$TMPDIR/$1/mkdocs.yml"
	cp "$MY_DIR/configs/base.yml" "$TMPDIR/$1/base.yml"
	cp "$MY_DIR/configs/hooks.py" "$TMPDIR/$1/hooks.py"
	cp -r "$MY_DIR/assets" "$TMPDIR/$1/docs/assets"
	mkdocs build -q -f "$TMPDIR/$1/mkdocs.yml" -d "$3"
	fix_theme_fonts "$3"
}

rm -rf docs/

# Home page at the site root.
mkdir -p "$TMPDIR/home/docs"
cp "$MY_DIR/README.md" "$TMPDIR/home/docs/index.md"
cp "$MY_DIR/dev-notes.md" "$TMPDIR/home/docs/dev-notes.md"
build_tree home "$MY_DIR/configs/home.yml" "$MY_DIR/docs"
cp "$MY_DIR/CNAME" "$MY_DIR/versions.json" "$MY_DIR/docs/"

commits=''
for version in $(cat versions.json | jq -r -c '.[]'); do
	branch="${version}"
	[ "$version" = "draft" ] && branch="master"

	commitsha=$(git rev-parse --short=10 "$branch")
	commits="${commits}
- ${version} generated from ${commitsha}"

	mkdir -p "$TMPDIR/$version/docs"
	git archive "$branch" | tar -x -C "$TMPDIR/$version/docs"
	build_tree "$version" "$MY_DIR/configs/$version.yml" "$MY_DIR/docs/$version"
done

git add --all
git commit -a -m "Automatically rebuild docs:
${commits}"

rm -rf "$TMPDIR"
