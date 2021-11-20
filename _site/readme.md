# CCS specifications

Multiple versions of the CCS specifications are available from this
documentation site.

Stable versions will use the naming scheme `<yyyy>-<mm>`. These will
not change, except for trivial changes such as fixing spelling and
grammar, as well as adding improved examples or explanations.

Draft versions will either be named `<yyyy>-<mm>-draft` if there is a
target release date, or simply `draft` for the most bleeding edge (and
least stable) version, corresponding to the `master` branch in the
repository. These drafts can change in any way at any time.

Select a version to browse from the left navigation bar.

## References

* Website: <https://ccs-specs.icpc.io>
* Github: <https://github.com/icpc/ccs-specs>

The problem package format specification can be found at: <https://icpc.io/problem-package-format/>

## Development notes

This documentation is build with the script `update_docs.sh` from this
`gh-pages` branch. That script builds the documentation from each
relevant branches and writes it to the `gh-pages` branch for publication.

To be able to run `update_docs.sh`, you need the following:

* Install Ruby and `bundle` and `jekyll`, see <https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/testing-your-github-pages-site-locally-with-jekyll#prerequisites>.
* Make sure you have `rsync` and `jq` installed.

Then run `./update_docs.sh` from the root of this repository in the
`gh-pages` branch. That should update the documentation, which you can
then commit and push.
