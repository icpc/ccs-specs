---
sort: 3
permalink: /contest_archive_format
---
# Contest Archive Format

This page describes the archive format for a contest. It describes how to
store the information available through the [Contest API](contest_api) on
disk.

There are several reasons that contest information will be stored on
disk, including:

  - As configuration used to initialize a CCS
  - As an archive of what happened in a contest
  - As an archive for replaying a contest, either for testing contest
    tools or for teams to compete against live data
  - As a base for offline analysis

## Archive contents

The package consists of a single directory containing files as described
below, or alternatively, a ZIP compressed archive of the directory. It is
strongly recommended that the name of the directory or the base name of the
archive match the contest ID, if a contest ID is specified. 

A package contains information regarding a single contest (corresponding to
the `/contests/<id>/*` endpoints of the API). The API can contain information
for several contests, to store the information for multiple contests a
package per contest would be needed.

Information in the API is always either in JSON format, [NDJSON](contest_api#event-feed)
format, or linked using a [file reference](contest_api#json-attribute-types)
JSON object.

- The JSON returned from the endpoint `/` is stored as
  `api.json`.
- The JSON returned from the endpoint `/contests/<id>` is stored as
  `contest.json`. (Notice the singular form).
- The JSON returned from the endpoint `/contests/<id>/<endpoint>` is stored as
  `<endpoint>.json`.
- The NDJSON returned from the endpoint `/contests/<id>/<endpoint>` is stored as
  `<endpoint>.ndjson`. (The only such endpoint is `event-feed`.)


Files referenced in `contest.json` are stored as `contest/<filename>`, and
files referenced in `<endpoint>.json` are stored as
`<endpoint>/<id>/<filename>`, where:
- `<id>` is the ID of the endpoint object the reference is in.
- `<filename>` is the filename specified in the file reference object.

Note that the API specification requires that filenames are unique within
endpoint objects, so this is always possible.

It is not required that a URL specified in an href is always valid.
Specifically, in many cases the contest is running in a local network that is
taken down after the contest, and in this case the URL would definitely not
still be working. To keep the archiving process as simple as possible, stale
URLs do not have to be removed from the data, but due to this the URLs should
be ignored and the file stored as specified above should be used instead.

Optionally one could create a Shallow Archive by not storing the files, in
which case the URLs must be valid. This could be useful in some cases where
the size of the archive matters.

In some cases it could make sense to merge multiple API sources (of the same
contest) in a single archive. One example of this would be a contest that was
running with a primary and [shadow](ccs_system_requirements#shadow-mode) CCS.
Typically in such cases, most of the data is identical (or at least the
differences are irrelevant), so only the data that differs (in relevant ways)
needs to be stored. If there is an additonal source for `<endpoint>` it is
stored as above, but wherever `<endpoint>` is used in the path, instead use
`<endpoint>_<system>` where `<system>` is a unique name for the additional
source.

## Example uses

The rest of the document describes use cases for the Archive Format, listing
which data would be required for that use case.

### CCS configuration

Used for configuring a CCS (primary or shadow) before a contest. Suitable for
download from a registration system or similar tool.

Required endpoints:
- api
- contests
- languages
- problems
- teams
- accounts

Optional endpoints:
- judgement-types
- groups
- organizations
- people

#### Example file listing

```
api.json
contest.json
contest/banner.png
contest/logo.png
judgement-types.json
languages.json
problems.json
problems/problemA/problemA.zip
problems/problemA/problemA.pdf
problems/problemB/problemB.zip
problems/problemB/problemB.pdf
...
groups.json
organizations.json
organizations/kth.se/logo56x56.png
organizations/kth.se/logo160x160.png
organizations/baylor.edu/logo56x56.png
organizations/baylor.edu/logo160x160.png
...
teams.json
teams/team-001/photo.jpg
teams/team-002/photo.jpg
teams/team-003/photo.jpg
...
people.json
people/john-smith/photo.jpg
people/jane-doe/photo.jpg
...
accounts.json
```

### Registration upload

Used for uploading local registration data to a central registration system
(such as the ICPC CMS).

Required endpoints:
- api
- organizations
- teams
- people

#### Example file listing

```
api.json
organizations.json
organizations/kth.se/logo56x56.png
organizations/kth.se/logo160x160.png
organizations/baylor.edu/logo56x56.png
organizations/baylor.edu/logo160x160.png
...
teams.json
teams/team-001/photo.jpg
teams/team-002/photo.jpg
teams/team-003/photo.jpg
...
people.json
people/john-smith/photo.jpg
people/jane-doe/photo.jpg
...
```

### Results upload

Used for uploading results from a finished contest to a central repository
(such as the ICPC CMS).

Required endpoints:
- api
- teams
- scoreboard

Optional endpoints:
- awards

#### Example file listing

```
api.json
teams.json
scoreboard.json
awards.json
```
