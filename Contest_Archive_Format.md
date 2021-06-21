---
sort: 3
permalink: /contest_archive_format
---
# Contest Archive Format

This page describes the archive format for a contest. It is developed in
parallel with, and makes heavy use of, the [Contest API](contest_api).

There are several reasons that contest information will be stored on
disk, including:

  - As configuration used to initialize a CCS
  - As an archive of what happened in a contest
  - As an archive for replaying a contest, either for testing contest
    tools or for teams to compete against live data
  - As a base for offline analysis

This standard lays out the relative location and format of each type of
contest-related information when reading or writing to disk. The top
level structure is inspired by the [Contest API](contest_api) structure.

## Archive contents

There are four top level directories:

* `config` - configuration and setup
* `registration` - information about particpants
* `events` - detailed information about what happened during the contest
* `results` - end results (this is typically an aggregate of the events)

All JSON and NDJSON files and file directories map to endpoints of the
[Contest API](contest_api) in the following way.

The format of the JSON returned from `<endpoint>` is accepted as the
contents of `<endpoint>`.json (or .ndjson in the case of
`event-feed.ndjson`). Some fields that are required in the contest API
are optional in this file format, to support some non-contest use cases.

Also, all files referenced from the JSON of endpoints are stored in the
`<endpoint>` directory. As such the file reference fields are not
required. They are allowed to be included, so that post processing of
API output is not needed, even if the URIs contained may not work after
a contest (e.g. because they refer to resources on a local network that
is no longer available).

In summary, if a system supports the Contest API it is very simple to
export a correct archive, but it is not required to support the contest
API to be able to use this archive forrmat.

The problem package is not available from the contest API but is stored
using a similar naming convention.

| File name                             | Format | Description | Required |
| :------------------------------------ | :----- | :---------- | :------- |
| `config/contest.json`                 | JSON   | [Contest object](#contest-object). | No |
| `config/contest`                      | Directory | [Contest files](#contest-files). | No |
| `config/judgement-types.json`         | JSON   | Array of [judgement type objects](#judgement-type-object). | Yes |
| `config/languages.json`               | JSON   | Array of [langauge objects](#language-object). | Yes |
| `config/problems.json`                | JSON   | Array of [problem objects](#problem-object). | Yes |
| `config/problems/<problem-ID>[.kpp]`  | [KPP](https://www.kattis.com/problem-package-format/) | [Problem package](#problem-package) | No |
| `registration/groups.json`            | JSON   | Array of [group objects](#group-object). | No |
| `registration/organizations.json`     | JSON   | Array of [organization objects](#organization-object). | No |
| `registration/organizations/<organization-ID>` | Directory | [Organization files](#organization-files).| No |
| `registration/teams.json`             | JSON   | Array of [team objects](#team-object). | Yes |
| `registration/teams/<team-ID>`        | Directory | [Team files](#team-files). | No |
| `registration/team-members.json`      | JSON   | Array of [team member objects](#team-member-object). | No |
| `registration/team-members/<team-member-ID>` | Directory | [Team member files](#team-member-files). | No |
| `events/submissions.json`             | JSON   | Array of [submission objects](#submission-object). | No |
| `events/submissions/<submission-ID>`  | Directory | [Submission files](#submission-files). | No |
| `events/judgements[.<system>].json`   | JSON   | Array of [judgement objects](#judgement-object). | No |
| `events/runs[.<system>].json`         | JSON   | Array of [run objects](#run-object). | No |
| `events/clarifications.json`          | JSON   | Array of [clarification objects](#clarification-object). | No |
| `events/event-feed[.<system>].ndjson` | [NDJSON](http://ndjson.org/) | [Event feed objects](#event-feed-object). | No |
| `results/awards.json`                 | JSON   | Array of [awards objects](#award-object). | No |
| `results/scoreboard.json`             | JSON   | [Scoreboard object](#scoreboard-object). | No |

## JSON objects

JSON objects may contain additional fields not described below. Systems
that do not recognize such additional fields should ignore them.
Specifically, the endpoints defined in the [Contest API](contest_api)
contains file references. These files are contained in file packages in
this standard and are thus not contained in the corresponding JSON
objects, but a system may keep those file reference fields in JSON
exported into a contest archive.

### JSON types

The following JSON types are used.

| Name              | Description |
| :---------------- | :---------- |
| string            | Built-in.   |
| number            | Bulit-in.   |
| integer           | Built-in.   |
| boolean           | Built-in.   |
| ID                | A `string` consisting of characters `[a-zA-Z0-9_-]` of length at most 36 and not starting with a `-` (dash). IDs must be unique within arrays of JSON objects of its type. |
| TIME              | A `string` containing human-readable timestamps, given in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) extended combined date/time format with timezone: `yyyy-mm-ddThh:mm:ss(.uuu)?[+-]zz(:mm)?` (or timezone Z for UTC). |
| RELTIME           | A `string` containing human-readable time durations, given in a slight modification of the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) extended time format: `(-)?(h)*h:mm:ss(.uuu)?`. |
| `<name>` object   | JSON object specified below. |
| JSON object       | Some other (unspecified) JSON object. |
| array of `<type>` | JSON array of `<type>` |

### Contest object

| Name         | Type    | Required | Description |
| :----------- | :------ | :------- | :---------- |
| id           | ID      | yes      | Identifier of the current contest. |
| name         | string  | yes      | Display name of the contest. |
| formal_name  | string  | no       | Full name of the contest. |
| start_time   | TIME    | yes      | the scheduled start time of the contest, may be null if the start time is unknown or the countdown is paused. |
| duration     | RELTIME | yes      | Length of the contest. |
| scoreboard_freeze_duration |  RELTIME | no | How long the scoreboard is frozen before the end of the contest. |
| penalty_time | integer | no       | Penalty time for a wrong submission, in minutes. |

#### Differences from Contest API

- The `countdown_pause_time` is not included. It is allowed but the information should be ignored.
- The `banner` and `logo` elements are not included. They are allowed but the information may be ignored. These files are instead found as `banner[.<size>].<format>` and `logo[.<size>].<format>` in the same directory as the JSON file.

#### Examples

```json
{
   "id": "wf2014",
   "name": "2014 ICPC World Finals",
   "formal_name": "38th Annual World Finals of the ACM International Collegiate Programming Contest",
   "start_time": "2014-06-25T10:00:00+01",
   "duration": "5:00:00",
   "scoreboard_freeze_duration": "1:00:00",
   "penalty_time": 20,
}
```

### Judgement type object

| Name    | Type    | Required | Description |
| :------ | :------ | :------- | :---------- |
| id      | ID      | yes      | iIdentifier of the judgement type. Must be one of the IDs specified in the [Contest API](contest_api#known-judgement-types). |
| name    | string  | yes      | Name of the judgement. (might not match table linked above, e.g. if localised). |
| penalty | boolean | depends  | Whether this judgement causes penalty time; must be present if and only if `penalty_time` is present in `config/contest.json`. |
| solved  | boolean | yes      | Whether this judgement is considered correct. |

#### Differences from Contest API

None.

#### Examples

```json
{
   "id": "AC",
   "name": "Accepted",
   "penalty": false,
   "solved": true
}
```

### Language object

| Name     | Type           | Required | Description |
| :------- | :------------- | :------- | :---------- |
| id       | ID             | yes      | Identifier of the language. Should be one of the IDs specified in the [Contest API](contest_api#known-languages). |
| name     | string         | yes      | Name of the language (might not match table below, e.g. if localised). |
| compiler | Command object | no       | Command to use for compiling submissions. |
| runner   | Command object | no       | Command to use for running submissions. Relevant e.g. for interpreted languages and languages running on a VM. |

#### Differences from Contest API

- Includes `compiler` and `runner` that contains the commands to use for compiling and running respectively. 

#### Examples

```json
{
  "id": "cpp",
  "name": "C++",
  "compiler": {
    "command": "gcc",
    "args": "-O2 -Wall -o a.out -static {files}",
    "version": "gcc (Ubuntu 8.3.0-6ubuntu1) 8.3.0"
  }
}
```

```json
{
  "id": "java",
  "name": "Java",
  "compiler": {
    "command": "javac",
    "args": "-O {files}",
    "version": "javac 11.0.4",
    "version-command": "javac --version"
  },
  "runner": {
    "command": "java",
    "version": "openjdk version \"11.0.4\" 2019-07-16"
  }
}
```

### Command object

| Name            | Type   | Required | Description |
| :-------------- | :----- | :------- | :---------- |
| command         | string | yes      | Command to run.                                              |
| args            | string | no       | Argument list for command. {files} denotes where to include the file list. |
| version         | string | no       | Expected output from running the version-command.            |
| version-command | string | no       | Command to run to get the version. Defaults to `<command> --version` if not specified. |

#### Examples

```json
{
  "command": "gcc",
  "args": "-O2 -Wall -o a.out -static {files}",
  "version": "gcc (Ubuntu 8.3.0-6ubuntu1) 8.3.0"
}
```

```json
{
  "command": "javac",
  "args": "-O {files}",
  "version": "javac 11.0.4",
  "version-command": "javac --version"
}
```

```json
{
  "command": "java",
  "version": "openjdk version \"11.0.4\" 2019-07-16"
}
```

### Problem object

| Name            | Type    | Required | Description |
| :-------------- | :------ | :------- | :---------- |
| id              | string  | yes      | Identifier of the problem. Must match problem package name if present. |
| uuid            | string  | depends  | UUID of the problem. Must be present if problem package is not present. |
| label           | string  | no       | Label of the problem on the scoreboard, typically a single capitalized letter. |
| name            | string  | no       | Name of the problem. |
| ordinal         | integer | no       | Ordering of problems on the scoreboard. |
| rgb             | string  | no       | Hexadecimal RGB value of problem color as specified in [HTML hexadecimal colors](http://en.wikipedia.org/wiki/Web_colors#Hex_triplet), e.g. '#AC00FF' or '#fff'. |
| color           | string  | no       | Human readable color description associated to the RGB value. |
| time_limit      | number  | no       | Time limit in seconds per test data set (i.e. per single run). |
| test_data_count | integer | no       | Number of test data sets. |

#### Differences from Contest API

- The `time_limit` element is required to be a `number` that is an
  integer multiple of `0.001` in the Contest API. 
- The `uuid` element is not defined in the Contest API.

#### Examples

```json
{
  "id": "asteroids",
  "uuid": "cb1c4b77-b203-4943-a13f-9b89dec1ac11",
  "label": "A",
  "name": "Asteroid Rangers",
  "ordinal": 1,
  "rgb":"#00f",
  "color": "blue",
  "time_limit": 2,
  "test_data_count": 10
}
```

### Group object

| Name    | Type    | Required | Description |
| :------ | :------ | :------- | :---------- |
| id      | ID      | yes      | Identifier of the group. |
| icpc_id | string  | no       | External identifier from ICPC CMS. |
| name    | string  | yes      | Name of the group. |
| type    | string  | no       | Type of this group. |
| hidden  | boolean | no       | If group should be hidden from scoreboard. Defaults to false if missing. |

#### Differences from Contest API

None.

#### Examples

```json
{
  "id": "asia",
  "icpc_id": "7593",
  "name": "Asia"
}
```

```json
{
  "id": "42425",
  "name": "Division 2",
  "type": "division"
}
```

```json
{
  "id": "ziqkpexycy",
  "name": "Sponsors",
  "type": "sponsors",
  "hidden": true
}
```

### Organization object

| Name            | Type            | Required | Description |
| :-------------- | :-------------- | :------- | :---------- |
| id              | ID              | yes      | Identifier of the organization |
| icpc_id         | string          | no       | External identifier (institution ID) from ICPC CMS |
| name            | string          | yes      | Display name of the organization |
| formal_name     | string          | no       | Full organization name if too long for normal display purposes. |
| country         | string          | no       | [ISO 3166-1 alpha-3 code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) of the organization's country |
| url             | string          | no       | URL to organization's website |
| twitter_hashtag | string          | no       | Organization Twitter hashtag |
| location        | Location object | no       | Latitude and longitude |

#### Differences from Contest API

- The `logo` element is not included. It is allowed but the information
  may be ignored. These files are instead found as
  `logo[.<size>].<format>` in the same directory as the JSON file.

#### Examples

```json
{
  "id": "kth.se",
  "icpc_ic": "INST-1039",
  "name": "KTH Royal Institute of Technology",
  "country":"SWE",
  "url": "http://www.kth.se/",
  "location": {
    "latitude": "59.347222",
    "longitude": "18.072778"
  }
 }
```

```json
{
  "id": "sjtu.edu.cn",
  "icpc_ic": "INST-1663",
  "name": "Shanghai Jiao Tong U.",
  "formal_name": "Shanghai Jiao Tong University",
  "country":"CHN",
  "url": "http://en.sjtu.edu.cn/",
  "twitter_hashtag": "#SJTU",
  "location": {
    "latitude": "31.200833",
    "longitude": "121.429722"
  }
}
```

### Location object 

| Name      | Type   | Required | Description |
| :-------- | :----- | :------- | :---------- |
| latitude  | number |  yes     | Latitude in degrees. |
| longitude | number |  yes     | Longitude in degrees. |

#### Examples

```json
{
  "latitude": "59.347222",
  "longitude": "18.072778"
}
```

### Team object

| Name            | Type        | Required | Description |
| :-------------- | :---------- | :------- | :---------- |
| id              | ID          | yes      | Identifier of the team. |
| icpc_id         | string      | no       | External identifier from ICPC CMS. |
| name            | string      | yes      | Name of the team. |
| display_name    | string      | no       | Display name of team. If missing clients should use `name`. |
| organization_id | ID          | no       | Identifier of the organization that this team is affiliated to. | 
| group_ids       | array of ID | no       | Identifiers of the group(s) this team is part of. No meaning must be implied or inferred from the order of IDs. The array may be empty. |
| location        | [Position object](#position-object) | no | Position and rotation of team on contest floor. |

#### Differences from Contest API

- The `photo`, `video`, `backup`, `key_log`, `tool_data`, `desktop`, and
  `webcam`, `audio` elements are not included. They are allowed but the
  information may be ignored. These files are instead found in the same
  directory as the JSON file.

#### Examples

```json
{
  "id": "11",
  "icpc_id": "201433",
  "name": "Shanghai Tigers",
  "organization_id": "sjtu.edu.cn",
  "group_ids": [
    "asia",
    "asia-east"
  ],
  "location": {
    "x": 10.25,
    "y": 2.4,
    "rotation": 90
  }
}
```

### Position object 

| Name     | Type   | Required | Description |
| :------- | :----- | :------- | :---------- |
| x        | number | yes      | Team's x position in meters. |
| y        | number | yes      | Team's y position in meters. |
| rotation | number | yes      | Team's rotation in degrees. |

#### Examples

```json
{
  "x": 10.25,
  "y": 2.4,
  "rotation": 90
}
```


### Team member object

| Name       | Type   | Required | Description |
| :--------- | :----- | :------- | :---------- |
| id         | ID     | yes      | Identifier of the team-member. |
| icpc_id    | string | no       | External identifier from ICPC CMS. |
| team_id    | ID     | yes      | Team of this team member. |
| first_name | string | yes      | First name of team member. |
| last_name  | string | yes      | Last name of team member. |
| sex        | string | no       | Either `male` or `female`, or possibly `null`. |
| role       | string | yes      | One of `contestant` or `coach`. |

#### Differences from Contest API

- The `photo` element is not included. It is allowed but the information
  may be ignored. These files are instead found as
  `photo[.<size>].<format>` in the same directory as the JSON file.

#### Examples

```json
{
  "id": "john-smith",
  "icpc_id": "32442",
  "team_id": "43",
  "first_name": "John",
  "last_name": "Smith",
  "sex": "male",
  "role": "contestant"
}
```

```json
 {
  "id":"osten-umlautsen",
  "team_id": "43",
  "first_name": "Östen",
  "last_name": "Ümlautsen",
  "sex": null,
  "role": "coach"
}
```

### Submission object

| Name         | Type    | Required | Description |
| :----------- | :------ | :------- | :---------- |
| id           | ID      | yes      | Identifier of the submission. Usable as a label, typically a low incrementing number. |
| language_id  | ID      | yes      | Identifier of the language submitted for. |
| problem_id   | ID      | yes      | Identifier of the problem submitted for. |
| team_id      | ID      | yes      | Identifier of the team that made the submission. |
| time         | TIME    | yes      | Timestamp of when the submission was made. |
| contest_time | RELTIME | yes      | Contest relative time when the submission was made. |
| entry_point  | string  | no       | Code entry point for languages needing it. |

#### Differences from Contest API

- The `files` and `reaction` elements are not included. They are allowed
  but the information may be ignored. These files are instead found in 
  the same directory as the JSON file.

#### Examples

```json
{
  "id": "187",
  "team_id": "11",
  "problem_id": "asteroids",
  "language_id": "java",
  "time": "2014-06-25T11:22:05.034+01",
  "contest_time": "1:22:05.034",
  "entry_point": "Main"
}
```

### Judgement object

| Name               | Type    | Required | Description |
| :----------------- | :------ | :------- | :---------- |
| id                 | ID      | yes      | Identifier of the judgement. |
| submission_id      | ID      | yes      | Identifier of the submission judged. |
| judgement_type_id  | ID      | yes      | The verdict of this judgement. |
| start_time         | TIME    | yes      | Absolute time when judgement started. |
| start_contest_time | RELTIME | yes      | Contest relative time when judgement started. |
| end_time           | TIME    | yes      | Absolute time when judgement completed. |
| end_contest_time   | RELTIME | yes      | Contest relative time when judgement completed. |
| max_run_time       | number  | no       | Maximum run time in seconds for any test case. |

#### Differences from Contest API

- The `max_run_time` element is required to be a `number` that is an
  integer multiple of `0.001` in the Contest API.

#### Examples

```json
{
  "id": "189549",
  "submission_id": "wf2017-32163123xz3132yy",
  "judgement_type_id": "WA",
  "start_time": "2014-06-25T11:22:48.427+01",
  "start_contest_time": "1:22:48.427",
  "end_time": "2014-06-25T11:23:32.481+01",
  "end_contest_time": "1:23:32.481",
  "max_run_time": "2.23"
}
```

### Run object

| Name              | Type    | Required | Description |
| :---------------- | :------ | :------- | :---------- |
| id                | ID      | yes      | Identifier of the run. |
| judgement_id      | ID      | yes      | Identifier of the judgement this is part of. |
| ordinal           | integer | yes      | Ordering of runs in the judgement. Must be different for every run in a judgement. Runs for the same test case must have the same ordinal. Must be between 1 and `test_data_count`, inclusive, for the problem referred to by the submission referred to by the judgement reffered to by this run. |
| judgement_type_id | ID      | yes      | The verdict of this judgement. |
| time              | TIME    | yes      | Absolute time when run completed. |
| contest_time      | RELTIME | yes      | Contest relative time when run completed. |
| run_time          | number  | no       | Run time in seconds. |

#### Differences from Contest API

- The `run_time` element is required to be a `number` that is an integer 
  multiple of `0.001` in the Contest API.

#### Examples

```json
{
  "id": "1312",
  "judgement_id": "189549",
  "ordinal": 28,
  "judgement_type_id": "AC",
  "time":"2014-06-25T11:22:42.420+01",
  "contest_time": "1:22:42.420",
  "run_time": "0.76"
}
```

### Clarification object

| Name         | Type    | Required | Description |
| :----------- | :------ | :------- | :---------- |
| id           | ID      | yes      | Identifier of the clarification|
| from_team_id | ID      | yes      | Identifier of team sending this clarification request, `null` if a clarification sent by judges. |
| to_team_id   | ID      | yes      | Identifier of the team receiving this reply, `null` if a reply to all teams or a request sent by a team. |
| reply_to_id  | ID      | yes      | Identifier of clarification this is in response to, otherwise `null`. |
| problem_id   | ID      | yes      | Identifier of associated problem, null if not associated to a problem. |
| text         | string  | yes      | Text of the question/reply. |
| time         | TIME    | yes      | Time of the question/reply. |
| contest_time | RELTIME | yes      | Contest time of the question/reply. |

#### Differences from Contest API

None.

#### Examples

```json
{
  "id": "wf2017-1",
  "from_team_id": null,
  "to_team_id": null,
  "reply_to_id": null,
  "problem_id": null,
  "text": "Do not touch anything before the contest starts!",
  "time": "2014-06-25T11:59:27.543+01",
  "contest_time": "-0:15:32.457"
}
```

### Event feed object

| Name | Type        | Required | Description |
| :--- | :---------- | :------- | :---------- |
| type | string      | yes      | Type of event. One of: `contests`, `judgement-type`, `languages`, `problems`, `groups`, `organizations`, `teams`, `team-members`, `state`, `submissions`, `judgements`, `runs`, `clarifications` or `awards` |
| id   | ID          | yes      | Unique identifier for the event.|
| op   | string      | yes      | Type of operation. One of `create`, `update` or `delete`. |
| data | JSON object | yes      | Event payload. |

#### Differences from Contest API

No difference from old event feed model. Several differences from new webhook based model.

#### Examples

```json
{
  "type": "submissions",
  "id": "593",
  "op": "create",
  "data": {
    "id": "187",
    "team_id": "11",
    "problem_id": "asteroids",
    "language_id": "java",
    "time": "2014-06-25T11:22:05.034+01",
    "contest_time": "1:22:05.034",
    "entry_point": "Main",
    "files": [{
        "href": "contests/wf14/submissions/187/files",
        "mime": "application/zip"
      }]
  }
}
```

### Award object

| Name     | Type        | Required | Description |
| :------- | :---------- | :------- | :---------- |
| id       | ID          | yes      | Identifier of the award. |
| citation | string      | yes      | Award citation, e.g. "Gold medal winner". |
| team_ids | array of ID | yes      | IDs of teams receiving this award. No meaning must be implied or inferred from the order of IDs. The array may be empty. |

#### Differences from Contest API

None.

#### Examples

```json
{
  "id": "gold-medal",
  "citation": "Gold medal winner",
  "team_ids": ["54", "23", "1", "45"]
}
```

### Scoreboard object

Exactly as defiend in the [Contest API](contest_api#scoreboard-format)

#### Differences from Contest API

None.

#### Examples

```json
{
  "event_id": "xy1234",
  "time": "2014-06-25T14:13:07.832+01",
  "contest_time": "4:13:07.832",
  "state": {
    "started": "2014-06-25T10:00:00+01",
    "ended": null,
    "frozen": "2014-06-25T14:00:00+01",
    "thawed": null,
    "finalized": null,
    "end_of_updates": null
  },
  "rows": [{
    "rank": 1,
    "team_id": "123",
    "score": {"num_solved":3,"total_time":340},
    "problems": [
      {"problem_id":"1","num_judged":3,"num_pending":1,"solved":false},
      {"problem_id":"2","num_judged":1,"num_pending":0,"solved":true,"time":20},
      {"problem_id":"3","num_judged":2,"num_pending":0,"solved":true,"time":55},
      {"problem_id":"4","num_judged":0,"num_pending":0,"solved":false},
      {"problem_id":"5","num_judged":3,"num_pending":0,"solved":true,"time":205}
    ]
  }]
}
```

## Binary files

Binary files realted to certain object types are stored in a single
parent directory with the same name as the object type and
subdirectories with the same ID as en element of that object type. The
JSON file with the same base name as the parent directory is the parent
JSON file of the files. The name of the subdirectories must match an ID
in the parent JSON file.

If there are no files for some organization (i.e. if a directory would
be empty) it should be omitted.

The naming scheme used for all files is
`<basename>.[.<specifier>].<extension>`. If there are multiple files
with any given basename in a single directory, a specifier must be used
for all except at most one.

For files that are referred to in the Contest API, the file extension
for each file reference should match the mime type in the file reference
object using the following mapping:

| Mime type         | File extension |
| :---------------- | :------------- |
| `image/png`       | `.png`         |
| `image/jpeg`      | `.jpg`         |
| `application/zip` | `.zip`         |
| `text/plain`      | `.txt`         |

### Problem package

Problems packages are strored in a single directory, or alternatively in
a ZIP compressed archive using the file extension `.kpp`, according to
the [Kattis Problem Package
Format](https://www.kattis.com/problem-package-format/) specification.

Problem packages may be left out if (and only if) `config/problems.json`
contains `uuid` for those problems. This assumes that the problems are
stored elsewhere and can be found by macthing by the uuid, and this
should be checked when verifying a contest archive.

### Contest files

The organization directories contain all binary files related to a
single organization in it's parent JSON file. 

The following files could be in the organization directories:

| Basename | Specifier          | Mime type   | File extension | Description | 
| :------- | :----------------- | :---------- | :------------- | :---------- |
| banner   | `<width>x<height>` | `image/png` | `.png`         | Banner for this contest, intended to be an image with a large aspect ratio around 8:1. |
| logo     | `<width>x<height>` | `image/png` | `.png`         | Logo for this contest, intended to be an image with aspect ratio near 1:1. |

### Organization files

The organization directories contain all binary files related to a
single organization in it's parent JSON file. 

The following files could be in the organization directories:

| Basename | Specifier          | Mime type   | File extension | Description | 
| :------- | :----------------- | :---------- | :------------- | :---------- |
| logo     | `<width>x<height>` | `image/png` | `.png`         | Logo of the organization. |

### Team files

The team directories contain all binary files related to a single team
in it's parent JSON file. 

The following files could be in the team directories:

| Basename  | Specifier          | Mime type   | File extension | Description | 
| :-------- | :----------------- | :---------- | :------------- | :---------- |
| photo     | `<width>x<height>` | `image/png` or `image/jpeg`| `.png` | Registration photo of the team. |
| video     | `<width>x<height>` | `video/*`   | varies | Registration video of the team. |
| backup    | none               | `application/zip` | `.zip`   | Latest file backup of the team machine. |
| key_log   | none               | `text/plain` | `.txt`        | Latest key log file from the team machine. |
| tool_data | none               | `text/plain` | `.txt`        | Latest tool data usage file from the team machine. |
| desktop   | `<width>x<height>` | `video/*  ` | varies         | Video of the team desktop. |
| webcam    | `<width>x<height>` | `video/*  ` | varies         | Video from the team webcam. |
| audio     | none               | `audio/*`   | varies         | Team audio. |

### Team member files

The team member directories contain all binary files related to a single
team member in it's parent JSON file. 

The following files could be in the team member directories:

| Basename  | Specifier          | Mime type   | File extension | Description | 
| :-------- | :----------------- | :---------- | :------------- | :---------- |
| photo     | `<width>x<height>` | `image/png` or `image/jpeg`| `.png` | Registration photo of the team member. |


### Submission files

The submission directories contain all binary files related to a single
submission in it's parent JSON file. 

The following files could be in the submission directories:

| Basename  | Specifier          | Mime type   | File extension | Description | 
| :-------- | :----------------- | :---------- | :------------- | :---------- |
| files     | none               | `application/zip` | `.zip`   | Submission files. |
| reaction  | `<width>x<height>` | `video/*  ` | varies         | Reaction video from team's webcam. |
