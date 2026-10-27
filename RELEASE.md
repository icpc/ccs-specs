# Release guide

This is a guide for maintainers of this repository on how to release a
new version of the [Contest API](contest_api) and related specifications.

1. Create a new branch named `<yyyy>-<mm>`, using the (approximate) current
   year and month to version this release.
2. On this branch, replace the draft version `<xxxx>-<ll>-next` by
   `<yyyy>-<mm>` in all relevant places. This includes at least:
   - The default in the [API information](json_format#api-information) object and the example.
   - The `API_VERSION` variable in the `check_api.sh` script.
   - The constant in `json-schema/api_information.json`.
   See for example [this commit](https://github.com/icpc/ccs-specs/commit/3f2a5a15cc4ce1089d291fff7bf13e550f92b7a1),
   but note that this from was before the renaming of `draft` to `<yyyy>-<mm>-next`.
3. Push this branch with these changes.
   To do so, either temporarily disable [branch protection](https://github.com/icpc/ccs-specs/settings/branches)
   or create a PR targeting this new branch `<yyyy>-<mm>`.
4. On the `master` branch, empty the "Changes compared to" section in `README.md`
   and update the version to `<yyyy>-<mm>`.
   See for example [this commit](https://github.com/icpc/ccs-specs/commit/f839b1a4e4334515fd9b28bb804bb572fa96df7b).
5. Switch to the `gh-pages` branch and update `README.md`, `versions.json`
   and the relevant files `configs/*.yml`.
   See for example [this commit](https://github.com/icpc/ccs-specs/commit/70574e091fab5b9e5897c5a14b8f58f12208fef1).
6. publish the changes to <https://ccs-specs.icpc.io/> by running
   ```bash
   ./update-docs.sh
   ```
   and then verify and push the commit the script made.
   See also `dev-notes.md` in this branch for a _few_ more details.
