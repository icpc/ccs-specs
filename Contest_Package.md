---
sort: 4
permalink: /contest_package
---
# Contest Package Format

This page describes the format of a contest package. It describes how to store
the information available through the [Contest API](contest_api) on disk.

There are several reasons that contest information will be stored on disk,
including:

- As configuration used to initialize a CCS
- As an archive of what happened in a contest
- As an archive for replaying a contest, either for testing contest tools or for
  teams to compete against live data
- As a base for offline analysis

## Package contents

The package consists of a single directory containing files as described below,
or alternatively, a ZIP compressed archive of the directory. It is strongly
recommended that the name of the directory or the base name of the archive
match the contest ID, if a contest ID is specified. 

A package contains information regarding a single contest (corresponding to the
`/contests/<id>/*` endpoints of the API). The API can contain information for
several contests, to store the information for multiple contests a package per
contest would be needed.

Information in the API is always either in JSON format, 
[NDJSON](contest_api#event-feed) format, or linked using a 
[file reference](contest_api#json-attribute-types) JSON object.

- The JSON returned from the endpoint `/` is stored as `api.json`.
- The JSON returned from the endpoint `/contests/<id>` is stored as
  `contest.json`. (Notice the singular form).
- The JSON returned from the endpoint `/contests/<id>/<endpoint>` is stored as
  `<endpoint>.json`.
- The NDJSON returned from the endpoint `/contests/<id>/<endpoint>` is stored as
  `<endpoint>.ndjson`. (The only such endpoint is `event-feed`.)


Files referenced in `api.json` and `contest.json` are stored as `api/<filename>`
and `contest/<filename>` respectively, and files referenced in
`<endpoint>.json` are stored as `<endpoint>/<id>/<filename>`, where:

- `<id>` is the ID of the endpoint object the reference is in.
- `<filename>` is the filename specified in the file reference object.

Some of these API endpoints are often written by humans in a package. For this
reason, those files can also be written in YAML instead of JSON. This holds for
the following files:

- `contest.json`, which then becomes `contest.yaml`.
- `problems.json`, which then becomes `problems.yaml`.
- `accounts.json`, which then becomes `accounts.yaml`.

The section [Example YAML files](#example-yaml-files) list example YAML files.

Note that the API specification requires that filenames are unique within
endpoint objects, so this is always possible.

It is not required that a URL specified in an href is always valid.
Specifically, in many cases the contest is running in a local network that is
taken down after the contest, and in this case the URL would definitely not
still be working. To keep the archiving process as simple as possible, stale
URLs do not have to be removed from the data, but due to this the URLs should
be ignored and the file stored as specified above should be used instead.

Optionally one could create a Shallow Package by not storing the files, in which
case the URLs must be valid. This could be useful in some cases where the size
of the package matters.

### Multiple systems

Some contests are run with multiple systems that provide a Contest API. One
example of this is a contest run with a primary and
[shadow](ccs_system_requirements#shadow-mode) CCS. Typically in these cases
there is relationship between the systems or a lot of common data, so it makes
sense to merge the data into a single package.

Data from the primary system (usually the primary CCS) should continue to be
stored as described in this document. Each additional system should store its
data using the same format but in a unique sub-folder `other-systems/<system>`,
named after the system that produced it. Using this pattern means that tools
that work against a contest package can be run without change on either the
primary contest package or the packages of any of the other systems.

When there is duplicate data (or the differences between systems are
irrelevant), a system's data can be deleted and replaced with symlinks to the
data from the primary system. Using this method reduces the overall size of the
package while still maintaining a valid contest package (the system's view of
the contest) for each system.

## Example uses

The next part of this document describes use cases for a Contest Package,
listing which data would be required for that use case.

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
- persons

#### Example file listing

```
api.json
api/logo.png
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
persons.json
persons/john-smith/photo.jpg
persons/jane-doe/photo.jpg
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
- persons

#### Example file listing

```
api.json
api/logo.png
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
persons.json
persons/john-smith/photo.jpg
persons/jane-doe/photo.jpg
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
api/logo.png
teams.json
scoreboard.json
awards.json
```

## Example YAML files

This part of this document list YAML alternatives for the files supporting it.
Each section contains an example JSON with its corresponding YAML equivalent.

### contest.yaml

Original `contest.json` content:

```json
{
   "id": "wf2014",
   "name": "2014 ICPC World Finals",
   "formal_name": "38th Annual World Finals of the ACM International Collegiate Programming Contest",
   "start_time": "2014-06-25T10:00:00+01",
   "duration": "5:00:00",
   "scoreboard_freeze_duration": "1:00:00",
   "scoreboard_type": "pass-fail",
   "penalty_time": 20,
   "banner": [{
       "href": "https://example.com/api/contests/wf2014/banner",
       "filename": "banner.png",
       "mime": "image/png",
       "width": 1920,
       "height": 240
   }]
}
```

Equivalent `contest.yaml` representation:

```yaml
id: wf2014
name: 2014 ICPC World Finals
formal_name: 38th Annual World Finals of the ACM International Collegiate Programming Contest
start_time: 2014-06-25T10:00:00+01
duration: 5:00:00
scoreboard_freeze_duration: 1:00:00
scoreboard_type: pass-fail
penalty_time: 20
banner:
- href: https://example.com/api/contests/wf2014/banner
  filename: banner.png
  mime: image/png
  width: 1920
  height: 240
```

### problems.yaml

Original `problems.json` content:

```json
[
    {
        "id": "asteroids",
        "label": "A",
        "name": "Asteroid Rangers",
        "ordinal": 1,
        "color": "blue",
        "rgb": "#00f",
        "time_limit": 2,
        "test_data_count": 10
    },
    {
        "id": "bottles",
        "label": "B",
        "name": "Curvy Little Bottles",
        "ordinal": 2,
        "color": "gray",
        "rgb": "#808080",
        "time_limit": 3.5,
        "test_data_count": 15
    }
]
```

Equivalent `problems.yaml` representation:

```yaml
- id: asteroids
  label: A
  name: Asteroid Rangers
  ordinal: 1
  color: blue
  rgb: '#00f'
  time_limit: 2
  test_data_count: 10
- id: bottles
  label: B
  name: Curvy Little Bottles
  ordinal: 2
  color: gray
  rgb: '#808080'
  time_limit: 3.5
  test_data_count: 15
```

### accounts.yaml

Original `accounts.json` content:

```json
[
    {
        "id": "stephan",
        "username": "stephan",
        "password": "supersecretpassword",
        "type": "judge",
        "ip": "10.0.0.1"
    },
    {
        "id": "team45",
        "username": "team45",
        "password": "till-wise-under",
        "type": "team",
        "ip": "10.1.1.45",
        "team_id": "45"
    }
]
```

Equivalent `accounts.yaml` representation:

```yaml
- id: stephan
  username: stephan
  password: supersecretpassword
  type: judge
  ip: 10.0.0.1
- id: team45
  username: team45
  password: till-wise-under
  type: team
  ip: 10.1.1.45
  team_id: '45'
```
