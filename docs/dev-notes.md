# Development notes

This documentation is build with the script `update_docs.sh` from this
`gh-pages` branch. That script builds the documentation from each
relevant branches and commits it to the `gh-pages` branch for publication.

To be able to run `update_docs.sh`, you need the following:

* Install Ruby and `bundle` and `jekyll`, see <https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/testing-your-github-pages-site-locally-with-jekyll#prerequisites>.
* Make sure you have `rsync` and `jq` installed.

Then run `./update_docs.sh` from the root of this repository in the
`gh-pages` branch. That should update the documentation, which you can
then push.
