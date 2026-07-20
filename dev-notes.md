# Development notes

This documentation is built with the script `update_docs.sh` from this
`gh-pages` branch. That script builds the documentation from each
relevant branch and commits it to the `gh-pages` branch for publication.
The site is generated with [MkDocs](https://www.mkdocs.org/) and its
built-in `readthedocs` theme.

The version branches keep their original Jekyll-flavoured markdown (YAML front
matter with `permalink:`/`sort:`, extensionless internal links) and are never
modified. All the machinery lives here on `gh-pages`:

- `configs/<version>.yml` — one MkDocs config per version (nav, site name).
- `configs/home.yml` — config for the site-root page.
- `configs/hooks.py` — a MkDocs build hook that reproduces the Jekyll
  conventions at build time: it maps each page's `permalink:` to its public
  URL, rewrites the extensionless internal links, and applies a couple of
  CommonMark-compatibility fixups (closing code-fence indentation, and the
  blank line Python-Markdown needs before a list that interrupts a paragraph).
- `assets/version-switch.js` and `assets/version-switch.css` — the version
  switcher, copied into every build tree.

To run `update_docs.sh`, you need the following (on Debian/Ubuntu):
```
apt install mkdocs jq
```

Then run `./update_docs.sh` from the root of this repository in the
`gh-pages` branch. That should update the documentation, which you can
then push.

To preview the generated site locally, run
```
cd docs && python3 -m http.server 8000
```
and browse to <http://localhost:8000/>.
