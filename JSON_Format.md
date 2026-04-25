---
sort: 2
permalink: /json_format
---
# JSON Format

## Introduction

This document specifies the JSON format used to represent contest data. This
format is used by the [Contest API](contest_api) and the
[Contest Package Format](contest_package).

## General design principles

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in
[RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## JSON property types

Property types are specified as one of the standard JSON types, or one of the
more specific types defined below. Implementations must be consistent with
respect to the optional parts of each type, e.g. if the optional .uuu is
included in any absolute timestamp it must be included when outputting all
absolute timestamps.

- Strings (type **`string`** in the specification) are built-in JSON strings.
- Numbers (type **`number`** in the specification) are built-in JSON numbers.
- Booleans (type **`boolean`** in the specification) are built-in JSON
  booleans.
- Integers (type **`integer`** in the specification) are JSON numbers that are
  restricted to be integer. They should be represented in standard integer
  representation `(-)?[0-9]+`.
- Absolute timestamps (type **`TIME`** in the specification) are strings
  containing human-readable timestamps, given in
  [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) extended combined date/time
  format with timezone: `yyyy-mm-ddThh:mm:ss(.uuu)?[+-]zz(:mm)?` (or timezone
  `Z` for UTC).
- Relative times (type **`RELTIME`** in the specification) are strings
  containing human-readable time durations, given in a slight modification of
  the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) extended time format:
  `(-)?(h)*h:mm:ss(.uuu)?`
- Identifiers (type **`ID`** in the specification) are given as strings
  consisting of characters `[a-zA-Z0-9_.-]` of length at most 36 and not
  starting with a `-` (dash) or `.` (dot) or ending with a `.` (dot). IDs are
  unique within each endpoint. IDs are assigned by the person or system that is
  the source of the object, and must be maintained by downstream systems. For
  example, the person configuring a contest on disk will typically define the
  ID for each team, and any CCS or CDS that exposes the team must use the same
  ID.
- File references (type **`FILE`** in the specification) are represented as a
  JSON object; see [File](#file-reference) under Object definitions below.
- Geographic locations (type **`LOCATION`** in the specification) are
  represented as a JSON object; see [Location](#location) under Object
  definitions below.
- Arrays (type **`array of <type>`** in the specification) are built-in JSON
  arrays of some type defined above. Unless specifically mentioned, no meaning
  is implied or can be inferred from the order of objects in an array.
- Nullable types (type **`<type> ?`** in the specification) are either a value
  of a type defined above, or `null`.

## Object definitions

This section defines the contest data model — the JSON objects used throughout
this suite of specifications.

### Table column description

In the tables below, the columns are:

- Name: Property name; object sub-properties are indicated as
  `property.subproperty`.
- Type: Data type of the property; one of the
  [types listed above](#json-property-types).
- Description: Description of the meaning of the property and any special
  considerations. Required means that the property must be present and must not
  be `null`. Default values specify how missing or `null` values should be
  interpreted.

### Referential integrity

Some properties in objects are references to the `id` of other objects (type
`ID` or `array of ID`). When such a property has a non-`null` value, the
referenced object must exist. How this constraint is enforced in practice is
context-specific: see the [Contest API](contest_api#referential-integrity) and
[Contest Package Format](contest_package) specifications.

### File reference

A file reference object has the following properties:

| Name     | Type            | Description
| :------- | :-------------- | :----------
| href     | string ?        | URL where the resource can or could be found. Must point to a file of the intended mime-type. In Contest API responses `href` is required; in Contest Packages `href` may be omitted when the file is stored locally. See the [Contest API](contest_api#file-references) and [Contest Package Format](contest_package#file-references) for details.
| filename | string          | POSIX compliant filename. Filenames must be unique within the endpoint object where they are used. I.e. an organization can have (multiple) `logo` and `country_flag` file references, they must all have a different filename, but different organizations may have files with the same filename.
| hash     | string ?        | MD5 hash of the file referenced.
| mime     | string          | Mime type of resource.
| width    | integer ?       | Width of the image. Required for files with mime type image/\*.
| height   | integer ?       | Height of the image. Required for files with mime type image/\*.
| tag      | array of string | Intended usage hints (e.g. `light`, `dark` for images). No meaning must be implied or inferred from the order of the elements.

For images, the supported mime types are image/png, image/jpeg, and image/svg+xml.

For images in SVG format, i.e. those having a mime type of image/svg+xml,
the values of `width` and `height` should be the viewport width and height in pixels
when possible, but otherwise the actual values don't matter as long as they
are positive and represent the correct aspect ratio.

Known values of tags include:

- `light`: an image suitable for use on white or light backgrounds.
- `dark`: an image suitable for use on black or dark backgrounds.
- `desktop`: a screenshot or capture of a team's desktop.
- `webcam`: a capture from a team's webcam.

An image should list both values if it is suitable for multiple contexts.

#### Examples

```json
{"href":"https://example.com/api/contests/wf14/organizations/inst105/logo/56px","filename":"logo.56x56.png","mime":"image/png","width":56,"height":56}
```

```json
{"href":"contests/wf14/problems/asteroids/statement","filename":"A.pdf","mime":"application/pdf"}
```

```json
{"filename":"logo.dark.svg","mime":"image/svg+xml","width":48,"height":48,"tag":["dark"]}
```

### Location

Geographic location objects have the following properties:

| Name      | Type   | Description
| :-------- | :----- | :----------
| latitude  | number | Latitude in degrees with value between -90 and 90.
| longitude | number | Longitude in degrees with value between -180 and 180.

#### Examples

```json
{"latitude":59.3471,"longitude":18.0721}
```

### Notification

A notification object is used to communicate changes to contest data. It is
delivered via the [Contest API event feed and webhooks](contest_api#notification-format)
and stored on disk in the [Contest Package Format](contest_package) as
`event-feed.ndjson`.

The general format for notification objects is:

```json
{"type": "<type>", "id": "<id>", "data": <JSON data for object> }
```

| Name        | Type              | Description
| :---------- | :---------------- | :----------
| type        | string            | The type of contest object that changed. Can be used for filtering.
| id          | ID ?              | The id of the object that changed, or null for the entire collection/singleton.
| data        | array or object ? | The updated value, i.e. what would be returned if calling the corresponding API endpoint at this time: an array, object, or null for deletions.
| token       | string ?          | An optional token used to identify this notification. For one use see event feed [Reconnection](contest_api#reconnection).

The known notification types are:
`contest`, `judgement-types`, `languages`, `problems`, `groups`,
`organizations`, `teams`, `persons`, `accounts`, `state`, `submissions`,
`judgements`, `runs`, `clarifications`, `awards`, `commentary`.

Each notification object signals that an object or a collection has changed
(and hence the contents of the corresponding endpoint) to `data`.

If `type` is `contest`, then `id` must be null.

If `id` is not null, then the notification concerns the object of the given
type with that id.

If `id` is null, then the notification concerns the entire collection of the
given type.

#### Examples

Event:
```json
{
   "type": "contest",
   "data": {
      "id": "dress2016",
      "name": "2016 ICPC World Finals Dress Rehearsal",
      "start_time": null,
      "countdown_pause_time": "0:03:38.749",
      "duration": "2:30:00"
  }
}
```

Means that the contest object with id `dress2016` has been updated to the
given data.

Event:
```json
{
   "type": "problems",
   "data": [
      {"id":"asteroids","label":"A","name":"Asteroid Rangers","ordinal":1,"color":"blue","rgb":"#00f","time_limit":2,"test_data_count":10},
      {"id":"bottles","label":"B","name":"Curvy Little Bottles","ordinal":2,"color":"gray","rgb":"#808080","time_limit":3.5,"test_data_count":15}
   ]
}
```

Means that endpoint `contests/<contest_id>/problems` has been updated to:
```json
[
   {"id":"asteroids","label":"A","name":"Asteroid Rangers","ordinal":1,"color":"blue","rgb":"#00f","time_limit":2,"test_data_count":10},
   {"id":"bottles","label":"B","name":"Curvy Little Bottles","ordinal":2,"color":"gray","rgb":"#808080","time_limit":3.5,"test_data_count":15}
]
```
and the child endpoints `contests/<contest_id>/problems/asteroids` and `contests/<contest_id>/problems/bottles` are updated accordingly.

Event:
```json
{
   "type": "submissions",
   "id": "187",
   "data": {
      "id": "187",
      "team_id": "123",
      "problem_id": "10-asteroids",
      "language_id": "1-java",
      "time": "2014-06-25T11:22:05.034+01",
      "contest_time": "1:22:05.034",
      "entry_point": "Main",
      "files": [{"href":"contests/wf14/submissions/187/files","filename":"files.zip","mime":"application/zip"}]   
   }
}
```

Means that the submission object with id `187` has been updated to the given
data.

### API information

The API information object provides metadata about the API and the data
provider.

Properties of an API information object:

| Name         | Type              | Description
| :----------- | :---------------- | :----------
| version      | string            | Version of the API. For this version must be the string `draft`. Will be of the form `<yyyy>-<mm>`, `<yyyy>-<mm>-draft`, or simply `draft`.
| version\_url | string            | Link to documentation for this version of the API.
| provider     | provider object ? | Information about the data provider.

Properties of the provider object:

| Name         | Type            | Description
| :----------- | :-------------- | :----------
| name         | string          | Name of this data provider.
| version      | string ?        | Provider's application version string.
| logo         | array of FILE ? | Logo for this data provider, intended to be an image with aspect ratio near 1:1. Only allowed mime types are image/\*. The different files in the array should be different file formats and/or sizes of the same image.

#### Examples

```json
{
   "version": "draft",
   "version_url": "https://ccs-specs.icpc.io/draft/contest_api",
   "provider" : {
      "name": "DOMjudge",
      "version" : "8.3.0DEV/4ac31de71",
      "logo": [{
         "href": "/api/logo",
         "hash": "36dcf7975b179447783cdfc857ce9ae0",
         "filename": "logo.png",
         "mime": "image/png",
         "width": 600,
         "height": 600
      }]
   }
}
```

### Access

The access object describes which endpoints and properties are visible to the
current client, and what [capabilities](contest_api#capabilities) the client
has. It is only available via the Contest API; the corresponding file does not
appear in a [Contest Package](contest_package).

Properties of an access object:

| Name         | Type                      | Description
| :----------- | :------------------------ | :----------
| capabilities | array of string           | An array of [capabilities](contest_api#capabilities) that the current client has. The array may be empty.
| endpoints    | array of endpoint objects | An array of endpoint objects that are visible to the current client, as described below. The array may be empty.

Properties of an endpoint object:

| Name         | Type            | Description
| :----------- | :-------------- | :----------
| type         | string          | The type of the endpoint, e.g. "problems". See [Notification](#notification) for the list of types.
| properties   | array of string | An array of supported properties that the current client has visibility to. The array must not be empty. If the array would be empty, the endpoint object should instead not be included in the endpoints array.

#### Examples

```json
{
   "capabilities": ["contest_start"],
   "endpoints": [
     { "type": "contest", "properties": ["id","name","formal_name",...]},
     { "type": "problems", "properties": ["id","label",...]},
     { "type": "submissions", "properties": ["id","language_id","reaction",...]}
     ...
   ]
}
```

or:

```json
{
   "capabilities": ["team_submit"],
   "endpoints": [
     { "type": "contest", "properties": ["id","name","formal_name",...]},
     { "type": "problems", "properties": ["id","label",...]},
     { "type": "submissions", "properties": ["id","language_id",...]},
     ...
   ]
}
```

### Contest

Properties of a contest object:

| Name                         | Type            | Description
| :--------------------------- | :-------------- | :----------
| id                           | ID              | Identifier of the current contest.
| name                         | string          | Short display name of the contest.
| formal\_name                 | string ?        | Full name of the contest. Defaults to value of `name`.
| start\_time                  | TIME ?          | The scheduled start time of the contest, may be `null` if the start time is unknown or the countdown is paused.
| countdown\_pause\_time       | RELTIME ?       | The amount of time left when the countdown to the contest start was paused, if the contest countdown is paused, otherwise `null`.
| duration                     | RELTIME         | Length of the contest.
| scoreboard\_freeze\_duration | RELTIME ?       | How long the scoreboard is frozen before the end of the contest. Defaults to `0:00:00`.
| scoreboard\_thaw\_time       | TIME ?          | The scheduled thaw time of the contest, may be `null` if the thaw time is unknown or not set.
| scoreboard\_type             | string          | What type of scoreboard is used for the contest. Must be either `pass-fail` or `score`.
| main\_scoreboard\_group\_id  | ID ?            | Identifier of the group that represents the main scoreboard. If `null`, the main scoreboard contains all teams (even if there is no group containing all teams).
| penalty\_time                | RELTIME         | Penalty time for a wrong submission. Only relevant if scoreboard\_type is `pass-fail`.
| banner                       | array of FILE ? | Banner for this contest, intended to be an image with a large aspect ratio around 8:1. Only allowed mime types are image/\*.
| logo                         | array of FILE ? | Logo for this contest, intended to be an image with aspect ratio near 1:1. Only allowed mime types are image/\*.
| location                     | LOCATION ?      | Location where the contest is held.

The typical use of `countdown_pause_time` is when a contest director wishes to pause the countdown to the start of a contest.  For example, this may occur because of technical
issues or to make an announcement.  When the contest countdown is paused, the value of `countdown_pause_time` should be set to the expected time remaining before the start of the contest after the pause is lifted.
If `countdown_pause_time` is set, then the `start_time` must be set to `null`, thereby, setting an undefined `start_time` (the `start_time` is undefined since
the length of the pause may be unknown).
The `countdown_pause_time` may be changed to indicate the approximate delay until the contest starts.
Countdown is resumed by setting a new `start_time` and resetting
`countdown_pause_time` to `null`.

#### Examples

```json
{
   "id": "wf2014",
   "name": "2014 ICPC World Finals",
   "formal_name": "38th Annual World Finals of the ACM International Collegiate Programming Contest",
   "start_time": "2014-06-25T10:00:00+01",
   "duration": "5:00:00",
   "scoreboard_freeze_duration": "1:00:00",
   "scoreboard_type": "pass-fail",
   "penalty_time": "0:20:00",
   "banner": [{
       "href": "https://example.com/api/contests/wf2014/banner",
       "filename": "banner.png",
       "mime": "image/png",
       "width": 1920,
       "height": 240
   }]
}
```

```json
{
   "id": "dress2016",
   "name": "2016 ICPC World Finals Dress Rehearsal",
   "start_time": null,
   "countdown_pause_time": "0:03:38.749",
   "duration": "2:30:00",
   "scoreboard_type": "pass-fail",
   "penalty_time": "0:20:00"
}
```

### Judgement Type

A judgement type is one of the possible responses from the system when judging
a submission.

Properties of a judgement type object:

| Name                            | Type      | Description
| :------------------------------ | :-------- | :----------
| id                              | ID        | Identifier of the judgement type, a 2-3 letter capitalized shorthand, see table below.
| name                            | string    | Name of the judgement. (might not match table below, e.g. if localized).
| penalty                         | boolean   | Whether this judgement causes penalty time. Required iff contest:penalty\_time is present.
| solved                          | boolean   | Whether this judgement is considered correct.
| simplified\_judgement\_type\_id | ID ?      | Identifier of this type's simplified judgement type.

#### Known judgement types

The list below contains standardized identifiers for known judgement types.
These identifiers should be used by a server. Please create a pull request at
<https://github.com/icpc/ccs-specs> when there are judgement types missing.

The column **Big 5** lists the "big 5" equivalents, if any. A `*` in
the column means that the judgement is one of the "big 5".

The **Translation** column lists other judgements the judgement can
safely be translated to, if a system does not support it.

| ID  | Name                                     | A.k.a.                                                   | Big 5 | Translation       | Description
| :-- | :--------------------------------------- | :------------------------------------------------------- | :---- | :---------------- | :----------
| AC  | Accepted                                 | Correct, Yes (YES)                                       | \*    | \-                | Solves the problem
| RE  | Rejected                                 | Incorrect, No (NO)                                       | WA?   | \-                | Does not solve the problem
| WA  | Wrong Answer                             |                                                          | \*    | RE                | Output is not correct
| TLE | Time Limit Exceeded                      |                                                          | \*    | RE                | Too slow
| RTE | Run-Time Error                           |                                                          | \*    | RE                | Crashes
| CE  | Compile Error                            |                                                          | \*    | RE                | Does not compile
| APE | Accepted - Presentation Error            | Presentation Error, also see AC, PE, and IOF             | AC    | AC                | Solves the problem, although formatting is wrong
| OLE | Output Limit Exceeded                    |                                                          | WA    | WA, RE            | Output is larger than allowed
| PE  | Presentation Error                       | Output Format Error (OFE), Incorrect Output Format (IOF) | WA    | WA, RE            | Data in output is correct, but formatting is wrong
| EO  | Excessive Output                         |                                                          | WA    | WA, RE            | A correct output is produced, but also additional output
| IO  | Incomplete Output                        |                                                          | WA    | WA, RE            | Parts, but not all, of a correct output is produced
| NO  | No Output                                |                                                          | WA    | IO, WA, RE        | There is no output
| WTL | Wallclock Time Limit Exceeded            |                                                          | TLE   | TLE, RE           | CPU time limit is not exceeded, but wallclock is
| ILE | Idleness Limit Exceeded                  |                                                          | TLE   | WTL, TLE, RE      | No CPU time used for too long
| TCO | Time Limit Exceeded - Correct Output     |                                                          | TLE   | TLE, RE           | Too slow but producing correct output
| TWA | Time Limit Exceeded - Wrong Answer       |                                                          | TLE   | TLE, RE           | Too slow and also incorrect output
| TPE | Time Limit Exceeded - Presentation Error |                                                          | TLE   | TWA, TLE, RE      | Too slow and also presentation error
| TEO | Time Limit Exceeded - Excessive Output   |                                                          | TLE   | TWA, TLE, RE      | Too slow and also excessive output
| TIO | Time Limit Exceeded - Incomplete Output  |                                                          | TLE   | TWA, TLE, RE      | Too slow and also incomplete output
| TNO | Time Limit Exceeded - No Output          |                                                          | TLE   | TIO, TWA, TLE, RE | Too slow and also no output
| MLE | Memory Limit Exceeded                    |                                                          | RTE   | RTE, RE           | Uses too much memory
| SV  | Security Violation                       |                                                          | RTE   | IF, RTE, RE       | Uses some functionality that is not allowed by the system
| IF  | Illegal Function                         | Restricted Function                                      | RTE   | SV, RTE, RE       | Calls a function that is not allowed by the system
| RCO | Run-Time Error - Correct Output          |                                                          | RTE   | RTE, RE           | Crashing but producing correct output
| RWA | Run-Time Error - Wrong Answer            |                                                          | RTE   | RTE, RE           | Crashing and also incorrect output
| RPE | Run-Time Error - Presentation Error      |                                                          | RTE   | RWA, RTE, RE      | Crashing and also presentation error
| REO | Run-Time Error - Excessive Output        |                                                          | RTE   | RWA, RTE, RE      | Crashing and also excessive output
| RIO | Run-Time Error - Incomplete Output       |                                                          | RTE   | RWA, RTE, RE      | Crashing and also incomplete output
| RNO | Run-Time Error - No Output               |                                                          | RTE   | RIO, RWA, RTE, RE | Crashing and also no output
| CTL | Compile Time Limit Exceeded              |                                                          | CE    | CE, RE            | Compilation took too long
| JE  | Judging Error                            |                                                          | \-    | \-                | Something went wrong with the system
| SE  | Submission Error                         |                                                          | \-    | \-                | Something went wrong with the submission
| CS  | Contact Staff                            | Other                                                    | \-    | \-                | Something went wrong

#### Simplified judgement types

In contests with limited visibility or access rules, a simplified judgement type ID defines how each judgement type
will be simplified for users without access.

For instance, in a contest where teams cannot see the specific reason another team's submission was rejected, teams
might see their own judgement types, but judgements from other teams would return the corresponding simplified judgement
type instead.

If not using simplified judgements, the property `simplified_judgement_type_id` must not be set.

A judgement type may be used both as original and simplified judgement type, but must then simplify to itself and have
`simplified_judgement_type_id` equal to `id`.
For example, `AC` (aka correct) would typically map to `AC` also as simplified judgement type.

If a system is interested in finding the set of judgement types that are only original judgement types, only simplified
judgement types or both, one can use this logic:

- The set of original judgement types are the ones that have `simplified_judgement_type_id` set.
- The set of simplified judgement types are the ones that appear in `simplified_judgement_type_id`.
- The set of judgement types that are both is the intersection of these two sets.

This assumes the system is using simplified judgement types. If it is not (i.e. if `simplified_judgement_type_id` is not set
for any judgement type), all judgement types are original only.

#### Examples

```json
[{
   "id": "RE",
   "name": "Rejected",
   "penalty": true,
   "solved": false
}, {
   "id": "TLE",
   "name": "Time Limit Exceeded",
   "penalty": true,
   "solved": false,
   "simplified_judgement_type_id": "RE"
}, {
   "id": "WA",
   "name": "Wrong Answer",
   "penalty": true,
   "solved": false,
   "simplified_judgement_type_id": "RE"
}, {
   "id": "CE",
   "name": "Compiler Error",
   "penalty": false,
   "solved": false,
   "simplified_judgement_type_id": "CE"
}, {
   "id": "AC",
   "name": "Accepted",
   "penalty": false,
   "solved": true,
   "simplified_judgement_type_id": "AC"
}]
```

```json
{
   "id": "AC",
   "name": "Accepted",
   "penalty": false,
   "solved": true,
   "simplified_judgement_type_id": "AC"
}
```

### Language

A language available for submission at the contest.

Properties of a language object:

| Name                   | Type             | Description
| :--------------------- | :--------------- | :----------
| id                     | ID               | Identifier of the language from table below.
| name                   | string           | Name of the language (might not match table below, e.g. if localized).
| entry\_point\_required | boolean          | Whether the language requires an entry point.
| entry\_point\_name     | string ?         | The name of the type of entry point, such as "Main class" or "Main file". Required iff entry_point_required is `true`.
| extensions             | array of string  | File extensions for the language.
| compiler               | Command object   | Command used for compiling submissions.
| runner                 | Command object   | Command used for running submissions. Relevant e.g. for interpreted languages and languages running on a VM.

Properties of a Command object:

| Name             | Type     | Description
| :--------------- | :------- | :----------
| command          | string   | Command to run.
| args             | string ? | Argument list for command. `{files}` denotes where to include the file list. Defaults to empty string.
| version          | string ? | Expected output from running the version command. Defaults to empty string.
| version\_command | string ? | Command to run to get the version. Defaults to `<command> --version`.

The compiler and runner objects are intended for informational purposes. It is not expected that systems will synchronize compiler and runner settings via this interface.

#### Known languages

Below is a list of standardized identifiers for known languages with their
name, extensions and entry point name (if any). When providing one of these
languages, the corresponding identifier should be used. The language name
and entry point name may be adapted e.g. for localization or to
indicate a particular version of the language. In case multiple versions
of a language are provided, those must have separate, unique
identifiers. It is recommended to choose new identifiers with a suffix
appended to an existing one. For example `cpp17` to specify the ISO 2017
version of C++.

| ID         | Name        | Extensions           | Entry point name
| :--------- | :---------- | :------------------- | :---------------
| ada        | Ada         | adb, ads             |
| c          | C           | c                    |
| cpp        | C++         | cc, cpp, cxx, c++, C |
| csharp     | C\#         | cs                   |
| go         | Go          | go                   |
| haskell    | Haskell     | hs                   |
| java       | Java        | java                 | Main class
| javascript | JavaScript  | js                   | Main file
| kotlin     | Kotlin      | kt                   | Main class
| objectivec | Objective-C | m                    |
| pascal     | Pascal      | pas                  |
| php        | PHP         | php                  | Main file
| prolog     | Prolog      | pl                   |
| python2    | Python 2    | py                   | Main file
| python3    | Python 3    | py                   | Main file
| ruby       | Ruby        | rb                   |
| rust       | Rust        | rs                   |
| scala      | Scala       | scala                |

#### Examples

```json
[{
   "id": "java",
   "name": "Java",
   "entry_point_required": true,
   "entry_point_name": "Main class",
   "extensions": ["java"],
   "compiler": {
      "command": "javac",
      "args": "-O {files}",
      "version": "javac 11.0.4",
      "version_command": "javac --version"
   },
   "runner": {
      "command": "java",
      "version": "openjdk version \"11.0.4\" 2019-07-16"
   }
}, {
   "id": "cpp",
   "name": "GNU C++",
   "compiler": {
      "command": "gcc",
      "args": "-O2 -Wall -static {files}",
      "version": "gcc (Ubuntu 8.3.0-6ubuntu1) 8.3.0"
   },
   "entry_point_required": false,
   "extensions": ["cc", "cpp", "cxx", "c++", "C"]
}, {
   "id": "python3",
   "name": "Python 3",
   "entry_point_required": true,
   "entry_point_name": "Main file",
   "extensions": ["py"]
}]
```

### Problem

A problem to be solved in the contest.

Properties of a problem object:

| Name              | Type            | Description
| :---------------- | :-------------- | :----------
| id                | ID              | Identifier of the problem, at the WFs the directory name of the problem package.
| uuid              | string ?        | UUID of the problem, as defined in the problem package.
| label             | string          | Label of the problem on the scoreboard, typically a single capitalized letter.
| name              | string          | Name of the problem.
| ordinal           | integer         | A unique number that determines the order of the problems, e.g. on the scoreboard.
| rgb               | string ?        | Hexadecimal RGB value of problem color as specified in [HTML hexadecimal colors](https://en.wikipedia.org/wiki/Web_colors#Hex_triplet) with no alpha channel, e.g. `#AC00FF` or `#fff`.
| color             | string ?        | Human readable color description associated to the RGB value.
| time\_limit       | number          | Time limit in seconds per test data set (i.e. per single run). Should be a non-negative integer multiple of `0.001`. The reason for this is to not have rounding ambiguities while still using the natural unit of seconds.
| memory\_limit     | integer         | Memory limit in MiB enforced on a submission.
| output\_limit     | integer         | Limit in MiB on what the submission can write both to `stdout` and `stderr`. If a submission produces more output, a CCS should fail the submission or ignore output beyond this limit.
| code\_limit       | integer         | Limit in KiB on submissions for this problem. Submissions that are larger should be rejected by a CCS.
| test\_data\_count | integer         | Number of test data sets.
| max\_score        | number ?        | Maximum score. Typically used to determine scoreboard cell color. Only applicable when contest:scoreboard\_type is `score`; if `null`, the score is unbounded.
| package           | array of FILE ? | [Problem package](https://www.kattis.com/problem-package-format/). Expected mime type is application/zip. Only exactly one package is allowed. Not expected to actually contain href for package during the contest, but used for configuration and archiving.
| statement         | array of FILE ? | Problem statement. Expected mime type is application/pdf.
| attachments       | array of FILE ? | Problem attachments. These are files made available to teams other than the problem statement and sample test data. Filenames are expected to match the filename mentioned in the problem statement, if any.

#### Examples

```json
[{"id":"asteroids","label":"A","name":"Asteroid Rangers","ordinal":1,"color":"blue","rgb":"#00f","time_limit":2,"memory_limit":2048,"output_limit":8,"code_limit":128,"test_data_count":10,"statement":[{"href":"contests/wf14/problems/asteroids/statement","mime":"application/pdf","filename":"A.pdf"}],"attachments":[{"href":"contests/wf14/problems/asteroids/attachments/testing_tool.py","mime":"text/x-python","filename":"testing_tool.py"}]},
 {"id":"bottles","label":"B","name":"Curvy Little Bottles","ordinal":2,"color":"gray","rgb":"#808080","time_limit":3.5,"memory_limit":1024,"output_limit":8,"code_limit":128,"test_data_count":15}
]
```

```json
{"id":"asteroids","label":"A","name":"Asteroid Rangers","ordinal":1,"color":"blue","rgb":"#00f","time_limit":2,"memory_limit":2048,"output_limit":8,"code_limit":128,"test_data_count":10,"statement":[{"href":"contests/wf14/problems/asteroids/statement","mime":"application/pdf","filename":"A.pdf"}],"attachments":[{"href":"contests/wf14/problems/asteroids/attachments/testing_tool.py","mime":"text/x-python","filename":"testing_tool.py"}]}
```

### Group

A grouping of teams. At the World Finals these are the super regions; at other contests these
may be the different sites, divisions, or types of contestants.

Teams may belong to multiple groups. For instance, there may be a group for each site, a group for
university teams, a group for corporate teams, and a group for ICPC-eligible teams. Teams could
belong to two or three of these.
When there are different kinds of groups for different purposes (e.g. sites vs divisions), each
group or set of groups should have a different type property
(e.g. `"type":"site"` and `"type":"division"`).

Groups must exist for any combination of teams that must be ranked on a
[group scoreboard](contest_api#group-scoreboard), which means groups may be created for combinations of
other groups. For instance, if there is a requirement to show a scoreboard for teams in each of `D`
divisions at every one of `S` sites, then in addition to the `D` + `S` groups there will also be
`D`x`S` combined/product groups. It is recommended that these groups have a type like
`"type":"<group1>-<group2>"`, e.g. `"type":"site-division"`.

Properties of a group object:

| Name      | Type       | Description
| :-------- | :--------- | :----------
| id        | ID         | Identifier of the group.
| icpc\_id  | string ?   | External identifier from ICPC CMS.
| name      | string     | Name of the group.
| type      | string ?   | Type of the group.
| location  | LOCATION ? | A center location of this group.

#### Known group types

The list below contains standardized identifiers for known group
types. These identifiers should be used when the purpose
of a group matches.

| Type  | Description
| :---- | :----------
| site  | A physical location where teams are competing, e.g. the "Hawaii site". Teams generally should not be in more than one group of this type.

#### Examples

```json
[
  {"id":"asia-74324325532","icpc_id":"7593","name":"Asia"}
]
```

```json
[
  {"id":"42425","name":"Division 2","type":"division"}
]
```

### Organization

An organization that a team can be associated with, which may have
associated information, e.g. a logo. Typically organizations will be
universities.

Properties of an organization object:

| Name                       | Type            | Description
| :------------------------- | :-------------- | :----------
| id                         | ID              | Identifier of the organization.
| icpc\_id                   | string ?        | External identifier from ICPC CMS.
| name                       | string          | Short display name of the organization.
| formal\_name               | string ?        | Full organization name if too long for normal display purposes.
| country                    | string ?        | [ISO 3166-1 alpha-3 code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) of the organization's country.
| country\_flag              | array of FILE ? | Flag of the country. A server is recommended to provide flags of size around 56x56 and 160x160. Only allowed mime types are image/\*.
| country\_subdivision       | string ?        | [ISO 3166-2 code](https://en.wikipedia.org/wiki/ISO_3166-2) of the organization's country subdivision (e.g. province or state).
| country\_subdivision\_flag | array of FILE ? | Flag of the country subdivision. A server is recommended to provide flags of size around 56x56 and 160x160. Only allowed mime types are image/\*.
| url                        | string ?        | URL to organization's website.
| twitter\_hashtag           | string ?        | Organization Twitter hashtag.
| twitter\_account           | string ?        | Organization Twitter account.
| location                   | LOCATION ?      | Location where this organization is based.
| logo                       | array of FILE ? | Logo of the organization. A server must provide logos of size 56x56 and 160x160 but may provide other sizes as well. Only allowed mime types are image/\*.

#### Examples

```json
[{"id":"inst123","icpc_id":"433","name":"Shanghai Jiao Tong U.","formal_name":"Shanghai Jiao Tong University"},
 {"id":"inst105","name":"Carnegie Mellon University","country":"USA","country_subdivision":"US-PA",
  "country_flag":[{"href":"http://example.com/api/contests/wf14/flags/USA/56px","filename":"56px.png","mime":"image/png","width":56,"height":56},
          {"href":"http://example.com/api/contests/wf14/flags/USA/160px","filename":"160px.png","mime":"image/png","width":160,"height":160}],
  "country_subdivision_flag":[{"href":"http://example.com/api/contests/wf14/flags/US-PA/56px","filename":"56px.png","mime":"image/png","width":56,"height":56},
          {"href":"http://example.com/api/contests/wf14/flags/US-PA/160px","filename":"160px.png","mime":"image/png","width":160,"height":160}],
  "logo":[{"href":"http://example.com/api/contests/wf14/organizations/inst105/logo/56px","filename":"56px.png","mime":"image/png","width":56,"height":56},
          {"href":"http://example.com/api/contests/wf14/organizations/inst105/logo/160px","filename":"160px.png","mime":"image/png","width":160,"height":160}]
 }
]
```

### Team

A team competing in the contest.

Properties of a team object:

| Name             | Type                   | Description
| :--------------- | :--------------------- | :----------
| id               | ID                     | Identifier of the team.
| icpc\_id         | string ?               | External identifier from ICPC CMS.
| name             | string                 | Name of the team.
| label            | string                 | Label of the team, at WFs normally the team seat number.
| display\_name    | string ?               | Display name of the team. If not set, a client should revert to using the name instead.
| organization\_id | ID ?                   | Identifier of the [organization](#organization) (e.g. university or other entity) that this team is affiliated to.
| group\_ids       | array of ID ?          | Identifiers of the [group(s)](#group) this team is part of (at ICPC WFs these are the super-regions). The array may be empty. Required iff groups endpoint is available.
| location         | team location object ? | Position of team on the contest floor. See below for the specification of this object.
| photo            | array of FILE ?        | Registration photo of the team. Only allowed mime types are image/\*.
| video            | array of FILE ?        | Registration video of the team. Only allowed mime types are video/\* or application/vnd.apple.mpegurl.
| backup           | array of FILE ?        | Latest file backup of the team machine. Only allowed mime type is application/zip.
| key\_log         | array of FILE ?        | Latest key log file from the team machine. Only allowed mime type is text/plain.
| tool\_data       | array of FILE ?        | Latest tool data usage file from the team machine. Only allowed mime type is text/plain.
| desktop          | array of FILE ?        | Streaming video of the team desktop. Only allowed mime types are video/\* or application/vnd.apple.mpegurl.
| webcam           | array of FILE ?        | Streaming video of the team webcam. Only allowed mime types are video/\* or application/vnd.apple.mpegurl.
| audio            | array of FILE ?        | Streaming team audio.
| primary\_rgb     | string ?               | Hexadecimal RGB value of the team's primary color as specified in [HTML hexadecimal colors](https://en.wikipedia.org/wiki/Web_colors#Hex_triplet) with no alpha channel, e.g. `#AC00FF` or `#fff`.
| primary\_color   | string ?               | Human readable body color description associated to the RGB value.
| secondary\_rgb   | string ?               | Hexadecimal RGB value of the team's secondary color as specified in [HTML hexadecimal colors](https://en.wikipedia.org/wiki/Web_colors#Hex_triplet) with no alpha channel, e.g. `#AC00FF` or `#fff`.
| secondary\_color | string ?               | Human readable text color description associated to the RGB value.

Properties of a team location object:

| Name     | Type   | Description
| :------- | :----- | :----------
| x        | number | Team's x position in meters.
| y        | number | Team's y position in meters.
| rotation | number | Team's rotation in degrees.

#### Examples

```json
[{"id":"team11","icpc_id":"201433","label":"11","name":"Shanghai Tigers","organization_id":"inst123","group_ids":["asia-74324325532"],"primary_rgb":"#0033A0","primary_color":"blue","secondary_rgb":"#FFFFFF","secondary_color":"white"},
 {"id":"team123","label":"123","name":"CMU1","organization_id":"inst105","group_ids":["8","11"]}
]
```

### Person

A person involved in the contest.

Properties of a person object:

| Name        | Type            | Description
| :---------- | :-------------- | :----------
| id          | ID              | Identifier of the person.
| icpc\_id    | string ?        | External identifier from ICPC CMS.
| name        | string          | Name of the person.
| email       | string ?        | Email of the person.
| sex         | string ?        | Either `male` or `female`, or possibly `null`.
| roles       | array of ROLE   | Roles of this person in the contest. Must not be empty.
| photo       | array of FILE ? | Registration photo of the person. Only allowed mime types are image/\*.

Properties of role objects (ROLE):

| Name        | Type     | Description
| :---------- | :------- | :----------
| type        | string   | One of `contestant`, `coach`, `staff`, or `other`.
| title       | string ? | Title for this role, e.g. "Co-Coach" or "Technical director".
| team\_id    | ID ?     | [Team](#teams) this role applies to. Required iff `type` is `contestant` or `coach`.

#### Examples

```json
[{"id":"john-smith","icpc_id":"32442","name":"John Smith","email":"john.smith@kmail.com","sex":"male",
  "roles":[{"type":"contestant","team_id":"43"}]},
 {"id":"osten-umlautsen","icpc_id":null,"name":"Östen Ümlautsen","sex":null,
  "roles":[{"type":"coach","team_id":"43"},{"type":"coach","title":"Co-Coach","team_id":"44"}]},
 {"id":"bill","name":"Bill Farrell","sex":"male",
  "roles":[{"type":"staff","title":"Executive Director"}]},
 {"id":"jane-doe","name":"Jane Doe",
  "roles":[{"type":"coach","team_id":"44"},{"type":"staff"}]}
]
```

### Account

An account used for accessing the contest, as well as information about the
account currently accessing the API. Note that the
[Contest API](contest_api#account) also provides a `contests/<id>/account`
endpoint (singular) which returns the account of the currently authenticated
client; this endpoint does not appear in a Contest Package.

Properties of an account object:

| Name              | Type      | Description
| :---------------- | :-------- | :----------
| id                | ID        | Identifier of the account.
| username          | string    | The account username.
| password          | string ?  | The account password.
| name              | string ?  | The name of the account.
| type              | string    | The type of account, e.g. `team`, `coach`, `judge`, `admin`, `analyst`, `staff`.
| ip                | string ?  | IP address associated with this account, used for auto-login.
| team\_id          | ID ?      | The team that this account is for. Required iff type is `team`.
| person\_id        | ID ?      | The person that this account is for, if the account is only for one person.

Accounts exist in the API primarily for configuration from a contest package, or an administrator comparing one CCS to another. It is
expected that non-admin clients never see passwords, and typically do not see accounts other than their own.

#### Examples

```json
[{"id":"stephan","username":"stephan","name":"Stephan's home account","type":"judge","ip":"10.0.0.1"},
 {"id":"team45","username":"team45","type":"team","ip":"10.1.1.45","team_id":"45"},
 {"id":"coach45","username":"coach45","type":"coach"}
]
```

```json
{"id":"nicky","username":"nicky","type":"admin"}
```

### Contest state

Current state of the contest, specifying whether it's running, the
scoreboard is frozen or results are final.

Properties of a state object:

| Name                 | Type   | Description
| :------------------- | :----- | :----------
| started              | TIME ? | Time when the contest actually started, or `null` if the contest has not started yet. When set, this time must be equal to the [contest](#contest) `start_time`.
| frozen               | TIME ? | Time when the scoreboard was frozen, or `null` if the scoreboard has not been frozen. Required iff `scoreboard_freeze_duration` is present in the [contest](#contest) endpoint.
| ended                | TIME ? | Time when the contest ended, or `null` if the contest has not ended. Must not be set if started is `null`.
| thawed               | TIME ? | Time when the scoreboard was thawed (that is, unfrozen again), or `null` if the scoreboard has not been thawed. Required iff `scoreboard_freeze_duration` is present in the [contest](#contest) endpoint. Must not be set if frozen is `null`.
| finalized            | TIME ? | Time when the results were finalized, or `null` if results have not been finalized. Must not be set if ended is `null`.
| end\_of\_updates     | TIME ? | Time after last update to the contest occurred, or `null` if more updates are still to come. Setting this to non-`null` must be the very last change in the contest.
| removed\_intervals   | array of removed interval objects ? | Time intervals that are disregarded for the purpose of scoring. See below.

Properties of removed interval objects:

| Name           | Type     | Description
| :------------- | :------- | :----------
| start          | TIME     | Wall-clock time when the interval starts.
| end            | TIME ?   | Wall-clock time when the interval ends, or `null` if the interval is still ongoing.
| contest\_time  | RELTIME  | Contest time at the start of the interval.

The `removed_intervals` array must be sorted by `start` and intervals must not overlap.

Events happening during a removed interval all receive the same contest time (equal to the `contest_time` of that interval). The contest time of all events after an interval is shifted back by the total duration of all removed intervals preceding them.

These state changes must occur in the order listed in the table above,
as far as they do occur, except that `thawed` and `finalized` may occur
in any order. For example, the contest may never be frozen and hence not
thawed either, or, it may be finalized before it is thawed. I.e., the
following sequence of inequalities must hold:

```
started < frozen < ended < thawed    < end_of_updates,
                   ended < finalized < end_of_updates.
```

A contest that has ended, been thawed (or was never frozen) and is finalized 
must not change. Thus, `end_of_updates` can be set once both `finalized` is set 
and `thawed` is set if the contest was frozen.

#### Examples

```json
{
  "started": "2014-06-25T10:00:00+01",
  "ended": null,
  "frozen": "2014-06-25T14:00:00+01",
  "thawed": null,
  "finalized": null,
  "end_of_updates": null,
  "removed_intervals": [
    {"start":"2014-06-25T11:30:00+01","end":"2014-06-25T11:45:00+01","contest_time":"1:30:00"},
    {"start":"2014-06-25T13:00:00+01","end":null,"contest_time":"2:45:00"}
  ]
}
```

### Submission

A submission, a.k.a. an attempt to solve a problem in the contest.

Properties of a submission object:

| Name          | Type            | Description
| :------------ | :-------------- | :----------
| id            | ID              | Identifier of the submission. Usable as a label, typically a low incrementing number to make it easier to validate submissions or compare submissions with a Shadow CCS.
| language\_id  | ID              | Identifier of the [language](#language) submitted for.
| problem\_id   | ID              | Identifier of the [problem](#problem) submitted for.
| team\_id      | ID ?            | Identifier of the [team](#team) that made the submission. Submissions without a `team_id` cannot affect the scoreboard.
| account\_id   | ID ?            | Identifier of the [account](#account) that made the submission.
| time          | TIME            | Timestamp of when the submission was made.
| contest\_time | RELTIME         | Contest relative time when the submission was made.
| entry\_point  | string ?        | Code entry point for specific languages.
| files         | array of FILE   | Submission files, contained at the root of the archive. Only allowed mime type is application/zip. Only exactly one archive is allowed.
| reaction      | array of FILE ? | Reaction video from team's webcam. Only allowed mime types are video/\* or application/vnd.apple.mpegurl.

The `entry_point` property must be included for submissions in
languages which do not have a single, unambiguous entry point to run the
code. In general the entry point is the string that needs to be
specified to point to the code to be executed. Specifically, for Python
it is the file name that should be run, and for Java and Kotlin it is
the fully qualified class name (that is, with any package name included,
e.g. `com.example.myclass` for a class in the package `com.example` in
Java). For C and C++ no entry point is required and it must therefore be
`null`.

The `files` property provides the file(s) of a given submission as a
zip archive. These must be stored directly from the root of the zip
file, i.e. there must not be extra directories (or files) added unless
these are explicitly part of the submission content.

#### Examples

```json
[{"id":"187","team_id":"123","problem_id":"10-asteroids",
  "language_id":"1-java","time":"2014-06-25T11:22:05.034+01","contest_time":"1:22:05.034","entry_point":"Main",
  "files":[{"href":"contests/wf14/submissions/187/files","filename":"files.zip","mime":"application/zip"}]}
]
```

Note that the relative link for `files` points to the location
<https://example.com/api/contests/wf14/submissions/187/files> since the
base URL for the API is <https://example.com/api/>.

### Judgement

A judgement for a submission in the contest.

Properties of a judgement object:

| Name                            | Type      | Description
| :------------------------------ | :-------- | :----------
| id                              | ID        | Identifier of the judgement.
| submission\_id                  | ID        | Identifier of the [submission](#submission) judged.
| judgement\_type\_id             | ID ?      | The [verdict](#judgement-type) of this judgement. 
| simplified\_judgement\_type\_id | ID ?      | The [simplified verdict](#judgement-type) of this judgement. 
| score                           | number    | Score for this judgement, between `0` and the problem's `max_score`. Required iff contest:scoreboard\_type is `score`.
| current                         | boolean ? | `true` if this is the current judgement. Defaults to `true`. At any time, there must be at most one judgement per submission for which this is `true` or unset (and thus defaulting to `true`).
| start\_time                     | TIME      | Absolute time when judgement started.
| end\_time                       | TIME ?    | Absolute time when judgement completed. Required iff judgement\_type\_id is present.
| max\_run\_time                  | number ?  | Maximum run time in seconds for any test case. Should be a non-negative integer multiple of `0.001`. The reason for this is to not have rounding ambiguities while still using the natural unit of seconds.

A judgement must have at least one of `judgement_type_id` or `simplified_judgement_type_id` specified iff it is completed.
If both `judgement_type_id` and `simplified_judgement_type_id` are present, they should be consistent with
the simplification rules specified in the `judgement-types` endpoint. 

When a judgement is started, each of `judgement_type_id` and `end_time`
will be `null` (or missing). These are set when the
judgement is completed.

#### Examples

```json
[{"id":"189549","submission_id":"wf2017-32163123xz3132yy","judgement_type_id":"CE","start_time":"2014-06-25T11:22:48.427+01",
  "end_time":"2014-06-25T11:23:32.481+01"},
 {"id":"189550","submission_id":"wf2017-32163123xz3133ub","judgement_type_id":null,"start_time":"2014-06-25T11:24:03.921+01",
  "end_time":null}
]
```

### Run

A run is a judgement of an individual test case of a submission.
This is intended to provide (among other things) live updates of judging progress.

Properties of a run object:

| Name                | Type    | Description
| :------------------ | :------ | :----------
| id                  | ID      | Identifier of the run.
| judgement\_id       | ID      | Identifier of the [judgement](#judgement) this is part of.
| ordinal             | integer | Ordering of runs in the judgement. Must be different for every run in a judgement. Runs for the same test case must have the same ordinal. Must be between 1 and `problem:test_data_count`.
| judgement\_type\_id | ID      | The [verdict](#judgement-type) of this run (i.e. a judgement type).
| time                | TIME    | Absolute time when run completed.
| run\_time           | number  | Run time in seconds. Should be a non-negative integer multiple of `0.001`. The reason for this is to not have rounding ambiguities while still using the natural unit of seconds.
| score               | number ?| Score for this run. Only applicable when contest:scoreboard\_type is `score`. The meaning of this score is problem dependent; do not assume the final submission score is the minimum, maximum, or sum of the run scores. Note that a per-run score is not well-defined for most runs of most problems. Servers should omit `score` when it is not meaningful for the given problem.

#### Examples

```json
[{"id":"1312","judgement_id":"189549","ordinal":28,"judgement_type_id":"TLE",
  "time":"2014-06-25T11:22:42.420+01","run_time":0.123},
 {"id":"1313","judgement_id":"189550","ordinal":1,"judgement_type_id":"AC",
  "time":"2014-06-25T11:23:10.000+01","run_time":0.456,"score":42.5}
]
```

### Clarification

A clarification message sent between teams and judges, a.k.a.
a clarification request (question from a team) or clarification
(answer from judges).

Properties of a clarification message object:

| Name           | Type             | Description
| :------------- | :--------------- | :----------
| id             | ID               | Identifier of the clarification.
| from\_team\_id | ID ?             | Identifier of the [team](#team) sending this clarification request, `null` iff a clarification is sent by the judges.
| to\_team\_ids  | array of ID ?    | Identifiers of the [team(s)](#team) receiving this reply, `null` iff a reply to all teams or a request sent by a team.
| to\_group\_ids | array of ID ?    | Identifiers of the [group(s)](#group) receiving this reply, `null` iff a reply to all teams or a request sent by a team.
| reply\_to\_id  | ID ?             | Identifier of clarification this is in response to, otherwise `null`.
| problem\_id    | ID ?             | Identifier of associated [problem](#problem), `null` iff not associated to a problem.
| text           | string           | Question or reply text.
| time           | TIME             | Time of the question/reply.
| contest\_time  | RELTIME          | Contest time of the question/reply.

The recipients of a clarification are the union of `to_team_ids` and `to_group_ids`.  A clarification is sent to all teams if `from_team_id`, `to_team_ids` and `to_group_ids` are null.  Note that if `from_team_id` is not `null`, then both `to_team_ids` and `to_group_ids` must be `null`. That is, teams cannot send messages to other teams or groups.

Clarifications between a team and the judges are typically private. If the judges replies to a clarification and chooses to include additional recipients,
then in order to preserve referential integrity the `reply_to_id` should be removed for everyone who couldn't see the original message.

#### Examples

```json
[{"id":"wf2017-1","from_team_id":null,"to_team_ids":null,"to_group_ids":null,"reply_to_id":null,"problem_id":null,
  "text":"Do not touch anything before the contest starts!","time":"2014-06-25T11:59:27.543+01","contest_time":"-0:15:32.457"}
]
```

```json
[{"id":"1","from_team_id":"34","to_team_ids":null,"to_group_ids":null,"reply_to_id":null,"problem_id":null,
  "text":"May I ask a question?","time":"2017-06-25T11:59:27.543+01","contest_time":"1:59:27.543"},
 {"id":"2","from_team_id":null,"to_team_ids":["34"],"reply_to_id":"1","problem_id":null,
  "text":"Yes you may!","time":"2017-06-25T11:59:47.543+01","contest_time":"1:59:47.543"}
]
```

```json
[{"id":"1","from_team_id":"34","text":"May I ask a question?","time":"2017-06-25T11:59:27.543+01","contest_time":"1:59:27.543"},
 {"id":"2","to_team_ids":["34","57","69"],"to_group_ids":["1336"], "reply_to_id":"1","text":"Yes you may!","time":"2017-06-25T11:59:47.543+01","contest_time":"1:59:47.543"}
]
```

### Award

An award such as a medal, first to solve, etc.

Properties of an award object:

| Name      | Type          | Description
| :-------- | :------------ | :----------
| id        | ID            | Identifier of the award.
| citation  | string        | Award citation, e.g. "Gold medal winner".
| team\_ids | array of ID ? | JSON array of [team](#team) ids receiving this award. If the value is null this means that the award is not currently being updated. If the value is the empty array this means that the award **is** being updated, but no team has been awarded the award at this time.

#### Semantics

- Awards are not final until the contest is.
- An award may be created at any time, although it is recommended that a system
  creates the awards it intends to award before the contest starts.
- If an award has a non-null `team_ids`, then it must be kept up to date during
  the contest. E.g. if "winner" will not be updated with the current leader
  during the contest, it must be null until the award **is** updated.
- If an award is present during the contest this means that if the contest would
  end immediately and then become final, that award would be final. E.g.
  the "winner" during the contest should be the current leader. This is of
  course subject to what data the client can see; the public client's winner
  may not change during the scoreboard freeze but an admin could see the true
  current winner.

#### Known awards

For some common award cases the following IDs should be used.

| ID                        | Meaning during contest                                                                                                     | Meaning when contest is final                | Comment
| :------------------------ | :------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------- | :------
| winner                    | Current leader(s). Empty if no team has scored.                                                                            | Winner(s) of the contest.                    |
| gold-medal                | Teams currently placed to receive a gold medal. Empty if no team has scored.                                               | Teams being awarded gold medals.             |
| silver-medal              | Teams currently placed to receive a silver medal. Empty if no team has scored.                                             | Teams being awarded silver medals.           |
| bronze-medal              | Teams currently placed to receive a bronze medal, assuming no extra bronze are awarded. Empty if no team has scored.       | Teams being awarded bronze medals.           |
| rank-\<rank>              | Teams currently placed to receive rank \<rank>. Empty if no team has scored.                                               | Teams being awarded rank \<rank>.            | Only useful in contests where the final ranking awarded is different from the default ranking of the scoreboard. E.g. at the WF teams *not* getting medals are only ranked based on number of problems solved, and not total penalty time accrued nor time of last score improvement, and teams solving strictly fewer problems than the median team are not ranked at all.  
| honorable-mention         | Teams currently placed to receive an honorable mention.                                                                    | Teams being awarded an honorable mention.    |
| honors                    | Teams currently placed to receive an honors award.                                                                         | Teams being awarded an honors award.         |
| high-honors               | Teams currently placed to receive an high honors award.                                                                    | Teams being awarded an high honors award.    |
| highest-honors            | Teams currently placed to receive an highest honors award.                                                                 | Teams being awarded an highest honors award. |
| first-to-solve-\<id>      | The team(s), if any, that was first to solve problem \<id>. This implies that no unjudged submission made earlier remains. | Same.                                        | Must never change once set, except if there are rejudgements.
| group-winner-\<id>        | Current leader(s) in group \<id>. Empty if no team has scored.                                                             | Winner(s) of group \<id>.                    |
| organization-winner-\<id> | Current leader(s) of organization \<id>. Empty if no team has scored.                                                      | Winner(s) of organization \<id>.             | Not useful in contest with only one team per organization (e.g. the WF).

#### Examples

```json
[{"id":"gold-medal","citation":"Gold medal winner","team_ids":["54","23","1","45"]},
 {"id":"first-to-solve-a","citation":"First to solve problem A","team_ids":["45"]},
 {"id":"first-to-solve-b","citation":"First to solve problem B","team_ids":[]}
]
```

### Commentary

Commentary on events happening in the contest.

Properties of a commentary object:

| Name            | Type            | Description
| :-------------- | :-------------- | :----------
| id              | ID              | Identifier of the commentary.
| time            | TIME            | Time of the commentary message.
| contest\_time   | RELTIME         | Contest time of the commentary message.
| message         | string          | Commentary message text. May contain special tags referring to endpoint objects using the format `{<endpoint>:<object ID>}`. This is most commonly used for references to [teams](#team) and [problems](#problem) as `{teams:<team ID>}` and `{problems:<problem ID>}` respectively.
| tags            | array of string | JSON array of tags describing the message.
| source\_id      | ID ?            | Source [person](#person) of the commentary message.
| team\_ids       | array of ID ?   | JSON array of [team](#team) IDs the message is related to.
| problem\_ids    | array of ID ?   | JSON array of [problem](#problem) IDs the message is related to.
| submission\_ids | array of ID ?   | JSON array of [submission](#submission) IDs the message is related to.

For the message, if a literal `{` is needed, `\{` must be used. Similarly for a literal `\`, `\\` must be used.

#### Known tags

Below is a list of known tags. If any of the tags below are used, they must
have the corresponding meaning. If any of the meanings below are needed,
the corresponding tag should be used. There is no requirement that any of the
tags below are used.

| Tag                     | Meaning
| :---------------------- | :------
| submission              | A submission was made.
| submission-medal        | A submission was made that if accepted would change the set of teams awarded a medal.
| submission-gold-medal   | A submission was made that if accepted would change the set of teams awarded a gold medal.
| submission-silver-medal | A submission was made that if accepted would change the set of teams awarded a silver medal.
| submission-bronze-medal | A submission was made that if accepted would change the set of teams awarded a bronze medal.
| submission-winner       | A submission was made that if accepted would change the set of teams currently in the lead.
| submission-\<award>     | A submission was made that if accepted would change the set of teams awarded \<award>. Note that the above 4 are special cases of this.
| rejected                | A submission was rejected.
| accepted                | A submission was accepted.
| accepted-medal          | A submission was accepted that changed the set of teams awarded a medal.
| accepted-gold-medal     | A submission was accepted that changed the set of teams awarded a gold medal.
| accepted-silver-medal   | A submission was accepted that changed the set of teams awarded a silver medal.
| accepted-bronze-medal   | A submission was accepted that changed the set of teams awarded a bronze medal.
| accepted-winner         | A submission was accepted that changed the set of teams currently in the lead.
| accepted-\<award>       | A submission was accepted that changed the set of teams awarded \<award>. Note that the above 4 are special cases of this.

#### Examples

```json
[{"id":"143730", "time":"2021-03-06T19:02:02.328+00", "contest_time":"0:02:02.328", "message": "{t:314089} made a submission for {p:anttyping}. If correct, they will solve the first problem and take the lead", "team_ids": ["314089"], "problem_ids": ["anttyping"]}, 
 {"id": "143736", "time": "2021-03-06T19:02:10.858+00", "contest_time": "0:02:10.858", "message": "{t:314089} fails its first attempt on {p:anttyping} due to WA", "team_ids": ["314089"], "problem_ids": ["anttyping"]}, 
 {"id": "143764", "time": "2021-03-06T19:03:07.517+00", "contest_time": "0:03:07.517", "message": "{t:314115} made a submission for {p:march6}. If correct, they will solve the first problem and take the lead", "team_ids": ["314115"], "problem_ids": ["march6"]}
]
```

### Scoreboard

Scoreboard of the contest.

Since this is generated data, only the `GET` method is allowed in the
[Contest API](contest_api#scoreboard), irrespective of role.

Properties of the scoreboard object:

| Name          | Type    | Description
| :------------ | :------ | :----------
| time          | TIME    | Time contained in the [event](#notification) after which this scoreboard was generated. Implementation defined if the event has no associated time.
| contest\_time | RELTIME | Contest time contained in the associated event. Implementation defined if the event has no associated contest time.
| state         | object  | Identical data as returned by the [contest state](#contest-state) endpoint. This is provided here for ease of use and to guarantee the data is synchronized.
| problems      | array of problem column objects ? | A list of columns of problems with their associated max scores. Required iff there are any required properties in it.
| rows          | array of scoreboard row objects   | A list of rows of teams with their associated scores.

The scoreboard `rows` array is sorted according to rank and alphabetical
on team name within identically ranked teams. Here alphabetical ordering
means according to the [Unicode Collation
Algorithm](https://www.unicode.org/reports/tr10/), by default using the
`en-US` locale.

Properties of a problem column object:

| Name        | Type   | Description
| :---------- | :----- | :----------
| problem\_id | ID     | Identifier of the [problem](#problem).
| max\_score  | number | Maximum score. Typically used to determine scoreboard cell color. Required iff contest:scoreboard_type is score and problem:max_score is `null` for the problem.

Properties of a scoreboard row object:

| Name              | Type      | Description
| :---------------- | :-------- | :----------
| rank              | integer   | Rank of this team, 1-based and duplicate in case of ties.
| team\_id          | ID        | Identifier of the [team](#team).
| score             | object    | JSON object as specified in the rows below (for possible extension to other scoring methods).
| score.num\_solved | integer   | Number of problems solved by the team. Required iff contest:scoreboard\_type is `pass-fail`.
| score.total\_time | RELTIME   | Total penalty time accrued by the team. Required iff contest:scoreboard\_type is `pass-fail`.
| score.score       | number    | Total score of problems by the team. Required iff contest:scoreboard\_type is `score`.
| score.time        | RELTIME ? | Time of last score improvement, used for tiebreaking purposes. Must be `null` iff `num_solved=0`.
| problems          | array of problem data objects ? | JSON array of problems with scoring data, see below for the specification of each object.

Properties of a problem data object:

| Name         | Type    | Description
| :----------- | :------ | :----------
| problem\_id  | ID      | Identifier of the [problem](#problem).
| num\_judged  | integer | Number of judged submissions (up to and including the first correct one),
| num\_pending | integer | Number of pending submissions (either queued or due to freeze).
| solved       | boolean | Required iff contest:scoreboard\_type is `pass-fail`.
| score        | number  | Required iff contest:scoreboard\_type is `score`.
| time         | RELTIME | Minutes into the contest when this problem was solved by the team. Required iff `solved=true` or `score>0`.

#### Examples

```json
{
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
  "rows": [
    {"rank":1,"team_id":"123","score":{"num_solved":3,"total_time":"5:40:00","time":"3:25:00"},"problems":[
      {"problem_id":"1","num_judged":3,"num_pending":1,"solved":false},
      {"problem_id":"2","num_judged":1,"num_pending":0,"solved":true,"time":"0:20:00"},
      {"problem_id":"3","num_judged":2,"num_pending":0,"solved":true,"time":"0:55:00"},
      {"problem_id":"4","num_judged":0,"num_pending":0,"solved":false},
      {"problem_id":"5","num_judged":3,"num_pending":0,"solved":true,"time":"3:25:00"}
    ]}
  ]
}
```

```json
{
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
  "problems": [
    {"problem_id":"1","max_score":100}
    {"problem_id":"2","max_score":100}
    {"problem_id":"3","max_score":100}
    {"problem_id":"4","max_score":100}
    {"problem_id":"5","max_score":127.34}
  ],
  "rows": [
    {"rank":1,"team_id":"123","score":{"score":277.34,"time":"3:25:00"},"problems":[
      {"problem_id":"1","num_judged":3,"num_pending":1,"score":0},
      {"problem_id":"2","num_judged":1,"num_pending":0,"score":100,"time":"0:20:00"},
      {"problem_id":"3","num_judged":2,"num_pending":0,"score":50,"time":"0:55:00"},
      {"problem_id":"4","num_judged":0,"num_pending":0,"score":0},
      {"problem_id":"5","num_judged":3,"num_pending":0,"score":127.34,"time":"3:25:00"}
    ]}
  ]
}

```
