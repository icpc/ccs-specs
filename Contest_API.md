---
sort: 2
permalink: /contest_api
---
# Contest API

**This is the development draft for the Contest API.
See also [the version that will be used at WF 2020](https://clics.ecs.baylor.edu/index.php?title=Contest_API_2020).**

## Introduction

This page describes an API for accessing information provided by a
[Contest Control System](ccs_system_requirements) or
[Contest Data Server](https://tools.icpc.global/cds/).
Such an API can be used by a multitude of clients:

  - an external scoreboard
  - a scoreboard resolver application
  - contest analysis software, such as the
    [ICAT](https://clics.ecs.baylor.edu/index.php?title=ICAT) toolset
  - another "shadow" CCS, providing forwarding of submissions and all
    relevant information
  - internally, to interface between the CCS server and judging
    instances

This API is meant to be useful, not only at the ICPC World Finals, but
more generally in any ICPC-style contest setup. It is meant to
incorporate and supersede a number of
[deprecated or obsolete specifications](https://clics.ecs.baylor.edu/index.php?title=Main_Page#Deprecated.2C_Old.2C_and_Orphaned_Specifications) amongst which the *JSON Scoreboard*, the
*REST interface for source code fetching*
and the *Contest start interface*.

This REST interface is specified in conjunction with a new
[NDJSON event feed](#event-feed), which provides all changes to this
interface as CRUD-style events and is meant to supersede the old XML
*Event Feed*.

## General design principles

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in
[RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

The interface is implemented as a HTTP REST interface that outputs
information in [JSON](https://en.wikipedia.org/wiki/JSON) format
([RFC 7159](https://tools.ietf.org/html/rfc7159)). This REST interface
should be provided over HTTPS to guard against eavesdropping on
sensitive contest data and authentication credentials (see roles below).

### Endpoint URLs

The specific base URL of this API will be dependent on the server (e.g.
main CCS or CDS) providing the service; in the specification we only
indicate the relative paths of API endpoints with respect to a
**baseurl**. In all the examples below the baseurl is
<https://example.com/api>.

We follow standard REST practices so that a whole collection can be
requested, e.g. at the URL path

` GET https://example.com/api/contests/wf14/teams`

while an element with specific ID is requested as

` GET https://example.com/api/contests/wf14/teams/10`

A collection is always returned as a JSON list of objects. Every object
in the list represents a single element (and always includes the ID).
When requesting a single element the exact same object is returned. E.g.
the URL path

`GET baseurl/collection`

returns

```json
[ { "id":<id1>, <element specific data for id1> },
  { "id":<id2>, <element specific data for id2> },
     ...
]
```

while the URL path

`GET baseurl/<collection>/<id1>`

returns

`{ "id":<id1>, <element specific data for id1> }`

### HTTP headers

A server should allow cross-origin requests by setting the
`Access-Control-Allow-Origin` HTTP header:

`Access-Control-Allow-Origin: *`

A server should specify how clients should cache file downloads by
setting the `Cache-Control` or `Expires` HTTP headers:

`Cache-Control: public, max-age=3600, s-maxage=18000`

`Expires: Wed, 18 Jul 2018 07:28:00 GMT`

### HTTP methods

The current version of this specification only requires support for the
`GET` method, unless explicitly specified otherwise in an endpoint
below (see [PATCH start\_time](#patch-starttime)). However,
for future compatibility below are already listed other methods with
their expected behavior, if implemented.

  - `GET`
    Read data. This method is idempotent and does not modify any data.
    It can be used to request a whole collection or a specific element.
  - `POST`
    Create a new element. This can only be called on a collection
    endpoint. No `id` attribute should be specified as it is up to the
    server to assign one, which is returned in the location header.
  - `PUT`
    Replaces a specific element. This method is idempotent and can only
    be called on a specific element and replaces its contents with the
    data provided. The payload data must be complete, i.e. no partial
    updates are allowed. The `id` attribute cannot be changed: it does
    not need to be specified (other than in the URL) and if specified
    different from in the URL, a `409 Conflict` HTTP code should be
    returned.
  - `PATCH`
    Updates/modifies a specific element. Similar to `PUT` but allows
    partial updates by providing only that data, for example:
    `PATCH  https://example.com/api/contests/wf14/teams/10`
    with JSON contents
    `{"name":"Our cool new team name"}`
    No updates of the `id` attribute are allowed either.
  - `DELETE`
    Delete a specific element. Idempotent, but may return a 404 status
    code when repeated. Any provided data is ignored. Example:
    `DELETE  https://example.com/api/contests/wf14/teams/8`
    Note that deletes must keep [referential
    integrity](#referential-integrity) intact.

Standard [HTTP status
codes](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes) are
returned to indicate success or failure. When there is a failure, the
response message body must include a JSON element that contains the attributes 'code' and 'message' with further information suitable for the user making the
request, as per the following example:

```json
{"code":"400",
 "message":"Teams cannot send clarifications to another team"}
 ```

### Roles

Access to this API is controlled via user roles. The API provider must
require authentication to access each role except for optionally the
public role. The API provider must support [HTTP basic
authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
([RFC](https://tools.ietf.org/html/rfc7617)). This provides a standard
and flexible method; besides HTTP basic auth, other forms of
authentication can be offered as well.

Each provider must support at least the following roles, although
additional roles may be supported for specific uses:

  - public (default role: contest data that's available to everyone)
  - admin (data or capability only available to contest administrators)

Role-based access may completely hide some objects from the user, may
omit certain attributes, or may embargo or omit objects based on the
current contest time. By default, the public user has read-only access
(no `POST`, `PUT`, `PATCH` or `DELETE` methods allowed) and does
not have access to judgements and runs from submissions made after the
contest freeze time.

### Referential integrity

Some attributes in elements are references to IDs of other elements.
When such an attribute has a non-`null` value, then the referenced
element must exist. That is, the full set of data exposed by the API
must at all times be referentially intact. This implies for example that
before creating a [team](#teams) with an `organization_id`,
the [organization](#organizations) must already exist. In
reverse, that organization can only be deleted after the team is
deleted, or alternatively, the team's `organization_id` is set to
`null`.

Furthermore, the ID attribute (see below) of elements are not allowed to
change. However, note that a particular ID might be reused by first
deleting an element and then creating a new element with the same ID.

### JSON attribute types

Attribute types are specified as one of the standard JSON types, or one of the
more specific types defined below. Implementations must be consistent with
respect to the optional parts of each type, e.g. if the optional .uuu is
included in any absolute timestamp it must be included when outputting all
absolute timestamps.

  - Strings (type **`string`** in the specification) are built-in JSON strings.
  - Numbers (type **`number`** in the specification) are built-in JSON numbers.
  - Booleans (type **`boolean`** in the specification) are built-in JSON booleans.
  - Integers
    (type **`integer`** in the specification) are JSON numbers that are
    restricted to be integer. They should be represented in standard
    integer representation `(-)?[0-9]+`.
  - Fixed point numbers
    (type **`decimal`** in the specification) are JSON numbers that are
    expected to take non-integer values. They must be in decimal
    (non-scientific) representation and have at most 3 decimals. That
    is, they must be a integer multiple of 0.001.
  - Absolute timestamps
    (type **`TIME`** in the specification) are strings containing
    human-readable timestamps, given in
    [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) extended combined
    date/time format with timezone:
    `yyyy-mm-ddThh:mm:ss(.uuu)?[+-]zz(:mm)?` (or timezone `Z` for UTC).
  - Relative times
    (type **`RELTIME`** in the specification) are strings containing
    human-readable time durations, given in a slight modification of the
    [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) extended time
    format: `(-)?(h)*h:mm:ss(.uuu)?`
  - Identifiers
    (type **`ID`** in the specification) are given as string consisting
    of characters `[a-zA-Z0-9_.-]` of length at most 36 and not starting
    with a `-` (dash) or `.` (dot) or ending with a `.` (dot). IDs are
    unique within each endpoint. IDs are assigned by the person or system
    that is the source of the object, and must be maintained by downstream
    systems. For example, the person configuring a contest on disk will
    typically define the ID for each team, and any CCS or CDS that exposes
    the team must use the same ID.
    Some IDs are also used as identifiable labels and are marked below
    along with the recommended format. These IDs should be meaningful
    for human communication (e.g. team "43", problem "A") and are as
    short as reasonable but not more than 10 characters. IDs not marked
    as labels may be random characters and cannot be assumed to be
    suitable for display purposes.
  - Ordinals
    (type **`ORDINAL`** in the specification) are used to give an
    explicit order to a list of objects. Ordinal attributes are integers
    and must be non-negative and unique in a list of objects, and they
    should typically be low numbers starting from zero. However, clients
    must not assume that the ordinals start at zero nor that they are
    sequential. Instead the ordinal values should be used to sort the
    list of objects.
  - File references
    (types **`IMAGE`**, **`VIDEO`**, **`ARCHIVE`** and **`STREAM`** in
    the specification) are represented as a JSON object with elements as
    defined below.
  - Arrays (type **`array of <type>`** in the specification) are built-in JSON
    arrays of some type defined above.

Element for file reference objects:

| Name   | Type    | Nullable?          | Description                                                                                                                                                                                                                                          |
| ------ | ------- | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| href   | string  | no                 | URL where the resource can be found. Relative URLs are relative to the `baseurl`. Must point to a file of intended mime-type. Resource must be accessible using the exact same (possibly none) authentication as the call that returned this data. |
| mime   | string  | no                 | Mime type of resource.                                                                                                                                                                                                                               |
| width  | integer | no for **`IMAGE`** | Width of the image, video or stream in pixels. Should not be used for **`ARCHIVE`**.                                                                                                                                                                 |
| height | integer | no for **`IMAGE`** | Height of the image, video or stream in pixels. Should not be used for **`ARCHIVE`**.                                                                                                                                                                |

The `href` attributes may be [absolute or relative
URLs](https://tools.ietf.org/html/rfc3986); relative URLs must be
interpreted relative to the `baseurl` of the API. For example, if
`baseurl` is <https://example.com/api>, then the following are
equivalent JSON response snippets pointing to the same location:

```json
  "href":"https://example.com/api/contests/wf14/submissions/187/files"
  "href":"contests/wf14/submissions/187/files"
```

For images, the supported mime types are image/png and image/jpeg.

If implementing support for uploading files pointed to by resource
links, substitute the href element with a data element with a base64
encoded string of the associated file contents as the value.

For example

`   POST https://example.com/api/contests/wf14/organizations`

with JSON data

```json
{ "id":"inst105",
  "name":"Carnegie Mellon University",
  ...
  "logo": [{"data": "<base64 string>", "width": 160, "height": 160}]
}
```

### Extensibility

This specification is meant to cover the basic data of contests, with
the idea that server/client implementations can extend this with more
data and/or roles. In particular, this specification already lists some
endpoints or specific attributes as optional. The following guidelines
are meant to ease extensibility.

  - Clients should accept extra attributes in endpoints, that are not
    specified here.
  - Servers should not expect clients to recognize more than the basic,
    required specification.
  - In this specification and extensions, an attribute with value `null`
    may be left out by the server (i.e. not be present). A client must
    treat an attribute with value `null` equivalently as that attribute
    not being present.

## Interface specification

The following list of API endpoints should be supported. Note that
`state`, `scoreboard` and `event-feed` are singular nouns and indeed
contain only a single element.

All endpoints should support `GET`; specific details on other methods
are mentioned below.

### Types of endpoints

The endpoints can be categorized into 3 groups as follows:

  - Configuration: contests, judgement-types, languages, problems,
    groups, organizations, teams, team-members;
  - Live data: state, submissions, judgements, runs, clarifications,
    awards;
  - Aggregate data: scoreboard, event-feed.

Configuration is normally set before contest start. Is not expected to,
but could occasionally be updated during a contest. It does not have
associated timestamp/contest time attributes. Updates are notified via
the event feed.

Live data is generated during the contest and new elements are expected.
Data is immutable though: only inserts, no updates or deletes of
elements. It does have associated timestamp/contest time attributes.
Inserts and deletes are notified via the event feed. **Note**:
judgements are the exception to immutability in a weak sense: they get
updated once with the final verdict.

Aggregate data: Only `GET` makes sense. These are not included in the
event feed, also note that these should not be considered proper REST
endpoints, and that the `event-feed` endpoint is a streaming feed in
NDJSON format.

### Table column description

In the tables below, the columns are:

  - Name: Attribute name; object sub-attributes are indicated as
    `object.attribute`.
  - Type: Data type of the attribute; one of the
    [types listed above](#json-attribute-types).
  - Required?: Whether this is a required attribute that **must** be
    implemented to conform to this specification.
  - Nullable?: Whether the attribute might be `null` (and thus
    implicitly can also not be present in that case).
  - Description: Description of the meaning of the attribute and any
    special considerations.

Note that attributes with `null` value may be left out by the server.
Furthermore, optional attributes must still be consistently implemented
(or not) \*within\* each contest. This implies the following for
attributes that are:

  - Required and not nullable: The attribute must always be present with
    a value.
  - Required and nullable: The attribute may be `null`, and only in that
    case it may be left out.
  - Optional and not nullable: The attribute may not be implemented, but
    that implies that no element of the endpoint has the attribute set.
    If one element has this attribute present, then it must be not
    `null` and the same must be true for all same type elements within
    the contest.
  - Optional and nullable: The attribute may be `null` or not present.
    In the latter case that can either be because it was a left out
    `null` value or because it was not implemented.

### Contests

Provides information on the current contest.

The following endpoint is associated with contest:

| Endpoint         | Mime-type        | Required? | Description
| :--------------- | :--------------- | :-------- | :----------
| `/contests`      | application/json | yes       | JSON array of all contests with elements as defined in the table below.
| `/contests/<id>` | application/json | yes       | JSON object of a single contest with elements as defined in the table below.

JSON elements of contest objects:

| Name                         | Type           | Required? | Nullable? | Description
| :--------------------------- | :------------- | :-------- | :-------- | :----------
| id                           | ID             | yes       | no        | Identifier of the current contest.
| name                         | string         | yes       | no        | Short display name of the contest.
| formal\_name                 | string         | no        | no        | Full name of the contest.
| start\_time                  | TIME           | yes       | yes       | The scheduled start time of the contest, may be `null` if the start time is unknown or the countdown is paused.
| countdown\_pause\_time       | RELTIME        | no        | yes       | The amount of seconds left when countdown to contest start is paused. At no time may both `start_time` and `countdown_pause_time` be non-`null`.
| duration                     | RELTIME        | yes       | no        | Length of the contest.
| scoreboard\_freeze\_duration | RELTIME        | no        | yes       | How long the scoreboard is frozen before the end of the contest.
| penalty\_time                | integer        | no        | no        | Penalty time for a wrong submission, in minutes.
| banner                       | array of IMAGE | no        | yes       | Banner for this contest, intended to be an image with a large aspect ratio around 8:1.
| logo                         | array of IMAGE | no        | yes       | Logo for this contest, intended to be an image with aspect ratio near 1:1.

The expected/typical use of `countdown_pause_time` is that once a
`start_time` is defined and close, the countdown may be paused due to
unforeseen delays. In this case, `start_time` should be set to `null`
and `countdown_pause_time` to the number of seconds left to count down.
The `countdown_pause_time` may change to indicate approximate delay.
Countdown is resumed by setting a new `start_time` and resetting
`countdown_pause_time` to `null`.

#### PATCH start\_time

To replace the *Contest Start Interface*, at the ICPC World
Finals, an API provided by a CCS or CDS implementing this specification
must have a role that has the ability to clear or set the contest start
time via a PATCH method.

The PATCH must include a valid JSON element with only two or three
attributes allowed: the contest id (used for verification), a
start\_time (a `<TIME>` value or `null`), and an optional
countdown\_pause\_time (`<RELTIME>`). As above, countdown\_pause\_time
can only be non-null when start time is null.

The request should fail with a 401 if the user does not have sufficient
access rights, or a 403 if the contest is started or within 30s of
starting, or if the new start time is in the past or within 30s.

#### Examples

Request:

` GET https://example.com/api/contests/wf2014`

Returned data:

```json
{
   "id": "wf2014",
   "name": "2014 ICPC World Finals",
   "formal_name": "38th Annual World Finals of the ACM International Collegiate Programming Contest",
   "start_time": "2014-06-25T10:00:00+01",
   "duration": "5:00:00",
   "scoreboard_freeze_duration": "1:00:00",
   "penalty_time": 20,
   "banner": [{
       "href": "https://example.com/api/contests/wf2014/banner",
       "width": 1920,
       "height": 240
   }]
}
```

Request:

` GET https://example.com/api/contests/dress2016`

Returned data:

```json
{
   "id": "dress2016",
   "name": "2016 ICPC World Finals Dress Rehearsal",
   "start_time": null,
   "countdown_pause_time": "0:03:38.749",
   "duration": "2:30:00"
}
```

Request:

` PATCH https://example.com/api/contests/wf2014`

Request data:

```json
{
   "id": "wf2014",
   "start_time": "2014-06-25T10:00:00+01"
}
```

Request:

` PATCH https://example.com/api/contests/wf2016`

Request data:

```json
{
   "id": "wf2016",
   "start_time": null
}
```

### Judgement Types

Judgement types are the possible responses from the system when judging
a submission.

The following endpoints are associated with judgement types:

| Endpoint                              | Mime-type        | Required? | Description
| :------------------------------------ | :--------------- | :-------- | :----------
| `/contests/<id>/judgement-types`      | application/json | yes       | JSON array of all judgement types with elements as defined in the table below.
| `/contests/<id>/judgement-types/<id>` | application/json | yes       | JSON object of a single judgement type with elements as defined in the table below.

JSON elements of judgement type objects:

| Name    | Type    | Required? | Nullable? | Description
| :------ | :------ | :-------- | :-------- | :----------
| id      | ID      | yes       | no        | Identifier of the judgement type, a 2-3 letter capitalized shorthand, see table below.
| name    | string  | yes       | no        | Name of the judgement. (might not match table below, e.g. if localized).
| penalty | boolean | depends   | no        | Whether this judgement causes penalty time; must be present if and only if contest:penalty\_time is present.
| solved  | boolean | yes       | no        | Whether this judgement is considered correct.

#### Known judgement types

The list below contains standardized identifiers for known judgement types.
These identifiers should be used by a server. Please create a pull request at
<https://github.com/icpc/ccs-specs> when there are judgement types missing.

The column **Big 5** lists the "big 5" equivalents, if any. A `*` in
the column means that the judgement is one of the "big 5".

The **Translation** column lists other judgements the judgement can
safely be translated to, if a system does not support it.

| ID  | Name                                     | A.k.a.                                                   | Big 5 | Translation       | Description                                               |
| :-- | :--------------------------------------- | :------------------------------------------------------- | :---- | :---------------- | :-------------------------------------------------------- |
| AC  | Accepted                                 | Correct, Yes (YES)                                       | \*    | \-                | Solves the problem                                        |
| RE  | Rejected                                 | Incorrect, No (NO)                                       | WA?   | \-                | Does not solve the problem                                |
| WA  | Wrong Answer                             |                                                          | \*    | RE                | Output is not correct                                     |
| TLE | Time Limit Exceeded                      |                                                          | \*    | RE                | Too slow                                                  |
| RTE | Run-Time Error                           |                                                          | \*    | RE                | Crashes                                                   |
| CE  | Compile Error                            |                                                          | \*    | RE                | Does not compile                                          |
| APE | Accepted - Presentation Error            | Presentation Error, also see AC, PE, and IOF             | AC    | AC                | Solves the problem, although formatting is wrong          |
| OLE | Output Limit Exceeded                    |                                                          | WA    | WA, RE            | Output is larger than allowed                             |
| PE  | Presentation Error                       | Output Format Error (OFE), Incorrect Output Format (IOF) | WA    | WA, RE            | Data in output is correct, but formatting is wrong        |
| EO  | Excessive Output                         |                                                          | WA    | WA, RE            | A correct output is produced, but also additional output  |
| IO  | Incomplete Output                        |                                                          | WA    | WA, RE            | Parts, but not all, of a correct output is produced       |
| NO  | No Output                                |                                                          | WA    | IO, WA, RE        | There is no output                                        |
| WTL | Wallclock Time Limit Exceeded            |                                                          | TLE   | TLE, RE           | CPU time limit is not exceeded, but wallclock is          |
| ILE | Idleness Limit Exceeded                  |                                                          | TLE   | WTL, TLE, RE      | No CPU time used for too long                             |
| TCO | Time Limit Exceeded - Correct Output     |                                                          | TLE   | TLE, RE           | Too slow but producing correct output                     |
| TWA | Time Limit Exceeded - Wrong Answer       |                                                          | TLE   | TLE, RE           | Too slow and also incorrect output                        |
| TPE | Time Limit Exceeded - Presentation Error |                                                          | TLE   | TWA, TLE, RE      | Too slow and also presentation error                      |
| TEO | Time Limit Exceeded - Excessive Output   |                                                          | TLE   | TWA, TLE, RE      | Too slow and also excessive output                        |
| TIO | Time Limit Exceeded - Incomplete Output  |                                                          | TLE   | TWA, TLE, RE      | Too slow and also incomplete output                       |
| TNO | Time Limit Exceeded - No Output          |                                                          | TLE   | TIO, TWA, TLE, RE | Too slow and also no output                               |
| MLE | Memory Limit Exceeded                    |                                                          | RTE   | RTE, RE           | Uses too much memory                                      |
| SV  | Security Violation                       | Illegal Function (IF), Restricted Function               | RTE   | RTE, RE           | Uses some functionality that is not allowed by the system |
| IF  | Illegal Function                         | Illegal Function (IF), Restricted Function               | RTE   | SV, RTE, RE       | Calls a function that is not allowed by the system        |
| RCO | Run-Time Error - Correct Output          |                                                          | RTE   | RTE, RE           | Crashing but producing correct output                     |
| RWA | Run-Time Error - Wrong Answer            |                                                          | RTE   | RTE, RE           | Crashing and also incorrect output                        |
| RPE | Run-Time Error - Presentation Error      |                                                          | RTE   | RWA, RTE, RE      | Crashing and also presentation error                      |
| REO | Run-Time Error - Excessive Output        |                                                          | RTE   | RWA, RTE, RE      | Crashing and also excessive output                        |
| RIO | Run-Time Error - Incomplete Output       |                                                          | RTE   | RWA, RTE, RE      | Crashing and also incomplete output                       |
| RNO | Run-Time Error - No Output               |                                                          | RTE   | RIO, RWA, RTE, RE | Crashing and also no output                               |
| CTL | Compile Time Limit Exceeded              |                                                          | CE    | CE, RE            | Compilation took too long                                 |
| JE  | Judging Error                            |                                                          | \-    | \-                | Something went wrong with the system                      |
| SE  | Submission Error                         |                                                          | \-    | \-                | Something went wrong with the submission                  |
| CS  | Contact Staff                            | Other                                                    | \-    | \-                | Something went wrong                                      |

#### Examples

Request:

` GET https://example.com/api/contests/wf14/judgement-types`

Returned data:

```json
[{
   "id": "CE",
   "name": "Compiler Error",
   "penalty": false,
   "solved": false
}, {
   "id": "AC",
   "name": "Accepted",
   "penalty": false,
   "solved": true
}]
```

Request:

` GET https://example.com/api/contests/wf14/judgement-types/AC`

Returned data:

```json
{
   "id": "AC",
   "name": "Accepted",
   "penalty": false,
   "solved": true
}
```

### Languages

Languages that are available for submission at the contest.

The following endpoints are associated with languages:

| Endpoint                        | Mime-type        | Required? | Description
| :------------------------------ | :--------------- | :-------- | :----------
| `/contests/<id>/languages`      | application/json | yes       | JSON array of all languages with elements as defined in the table below.
| `/contests/<id>/languages/<id>` | application/json | yes       | JSON object of a single language with elements as defined in the table below.

JSON elements of language objects:

| Name                 | Type            | Required? | Nullable? | Description
| :------------------- | :-------------- | :-------- | :-------- | :----------
| id                   | ID              | yes       | no        | Identifier of the language from table below.
| name                 | string          | yes       | no        | Name of the language (might not match table below, e.g. if localized).

#### Known languages

Below is a list of standardized identifiers for known languages. When
providing one of these languages, the corresponding identifier should be
used. The language name may be adapted e.g. for localization or to
indicate a particular version of the language. In case multiple versions
of a language are provided, those must have separate, unique
identifiers. It is recommended to choose new identifiers with a suffix
appended to an existing one. For example `cpp17` to specify the ISO 2017
version of C++.

| ID         | Name        |
| :--------- | :---------- |
| ada        | Ada         |
| c          | C           |
| cpp        | C++         |
| csharp     | C\#         |
| go         | Go          |
| haskell    | Haskell     |
| java       | Java        |
| javascript | JavaScript  |
| kotlin     | Kotlin      |
| objectivec | Objective-C |
| pascal     | Pascal      |
| php        | PHP         |
| prolog     | Prolog      |
| python2    | Python 2    |
| python3    | Python 3    |
| ruby       | Ruby        |
| rust       | Rust        |
| scala      | Scala       |

#### Examples

Request:

` GET https://example.com/api/contests/wf14/languages`

Returned data:

```json
[{
   "id": "java",
   "name": "Java"
}, {
   "id": "cpp",
   "name": "GNU C++"
}, {
   "id": "python2",
   "name": "Python 2"
}]
```

### Problems

The problems to be solved in the contest

The following endpoints are associated with problems:

| Endpoint                       | Mime-type        | Required? | Description
| :----------------------------- | :--------------- | :-------- | :----------
| `/contests/<id>/problems`      | application/json | yes       | JSON array of all problems with elements as defined in the table below.
| `/contests/<id>/problems/<id>` | application/json | yes       | JSON object of a single problem with elements as defined in the table below.

JSON elements of problem objects:

| Name              | Type    | Required? | Nullable? | Description
| :---------------- | :------ | :-------- | :-------- | :----------
| id                | ID      | yes       | no        | Identifier of the problem, at the WFs the directory name of the problem archive.
| label             | string  | yes       | no        | Label of the problem on the scoreboard, typically a single capitalized letter.
| name              | string  | yes       | no        | Name of the problem.
| ordinal           | ORDINAL | yes       | no        | Ordering of problems on the scoreboard.
| rgb               | string  | no        | no        | Hexadecimal RGB value of problem color as specified in [HTML hexadecimal colors](https://en.wikipedia.org/wiki/Web_colors#Hex_triplet), e.g. `#AC00FF` or `#fff`.
| color             | string  | no        | no        | Human readable color description associated to the RGB value.
| time\_limit       | decimal | no        | no        | Time limit in seconds per test data set (i.e. per single run). Should be an integer multiple of `0.001`.
| test\_data\_count | integer | yes       | no        | Number of test data sets.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/problems`

Returned data:

```json
[{"id":"asteroids","label":"A","name":"Asteroid Rangers","ordinal":1,"color":"blue","rgb":"#00f","time_limit":2,"test_data_count":10},
 {"id":"bottles","label":"B","name":"Curvy Little Bottles","ordinal":2,"color":"gray","rgb":"#808080","time_limit":3.5,"test_data_count":15}
]
```

Request:

` GET https://example.com/api/contests/wf14/problems/asteroids`

Returned data:

```json
{"id":"asteroids","label":"A","name":"Asteroid Rangers","ordinal":1,"color":"blue","rgb":"#00f","time_limit":2,"test_data_count":10}
```

### Groups

Grouping of teams. At the World Finals these are the super regions; at other contests these
may be the different sites, divisions, or types of contestants.

Teams may belong to multiple groups. For instance, there may be a group for each site, a group for
university teams, a group for corporate teams, and a group for ICPC-eligible teams. Teams could
belong to two or three of these.
When there are different kinds of groups for different purposes (e.g. sites vs divisions), each
group or set of groups should have a different type attribute
(e.g. `"type":"site"` and `"type":"division"`).

The following endpoints are associated with groups:

| Endpoint                     | Mime-type        | Required? | Description
| :--------------------------- | :--------------- | :-------- | :----------
| `/contests/<id>/groups`      | application/json | no        | JSON array of all groups with elements as defined in the table below.
| `/contests/<id>/groups/<id>` | application/json | no        | JSON object of a single group with elements as defined in the table below.

Note that these endpoints must be provided if groups are used. If they
are not provided no other endpoint may refer to groups (i.e. return any
group\_ids).

JSON elements of group objects:

| Name     | Type    | Required? | Nullable? | Description
| :------- | :------ | :-------- | :-------- | :----------
| id       | ID      | yes       | no        | Identifier of the group.
| icpc\_id | string  | no        | yes       | External identifier from ICPC CMS.
| name     | string  | yes       | no        | Name of the group.
| type     | string  | no        | yes       | Type of this group.
| hidden   | boolean | no        | yes       | If group should be hidden from scoreboard. Defaults to false if missing.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/groups`

Returned data:

```json
[
  {"id":"asia-74324325532","icpc_id":"7593","name":"Asia"}
]
```

Request:

` GET https://example.com/api/contests/wf14/groups`

Returned data:

```json
[
  {"id":"42425","name":"Division 2","type":"division"}
]
```

### Organizations

Teams can be associated with organizations which will have some
associated information, e.g. a logo. Typically organizations will be
universities.

The following endpoints are associated with organizations:

| Endpoint                            | Type             | Required? | Description
| :---------------------------------- | :--------------- | :-------- | :----------
| `/contests/<id>/organizations`      | application/json | no        | JSON array of all organizations with elements as defined in the table below.
| `/contests/<id>/organizations/<id>` | application/json | no        | JSON object of a single organization with elements as defined in the table below.

Note that the first two endpoints must be provided if organizations are
used. If they are not provided no other endpoint may refer to
organizations (i.e. return any organization\_ids).

JSON elements of organization objects:

| Name               | Type           | Required? | Nullable? | Description
| :----------------- | :------------- | :-------- | :-------- | :----------
| id                 | ID             | yes       | no        | Identifier of the organization.
| icpc\_id           | string         | no        | yes       | External identifier from ICPC CMS.
| name               | string         | yes       | no        | Short display name of the organization.
| formal\_name       | string         | no        | yes       | Full organization name if too long for normal display purposes.
| country            | string         | no        | yes       | [ISO 3166-1 alpha-3 code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) of the organization's country.
| url                | string         | no        | yes       | URL to organization's website.
| twitter\_hashtag   | string         | no        | yes       | Organization hashtag.
| location           | object         | no        | yes       | JSON object as specified in the rows below.
| location.latitude  | number         | depends   | no        | Latitude in degrees. Required iff location is present.
| location.longitude | number         | depends   | no        | Longitude in degrees. Required iff location is present.
| logo               | array of IMAGE | no        | yes       | Logo of the organization. A server must provide logos of size 56x56 and 160x160 but may provide other sizes as well.

#### Examples

Request:

` GET https://example.com/api/contests/<id>/organizations`

Returned data:

```json
[{"id":"inst123","icpc_id":"433","name":"Shanghai Jiao Tong U.","formal_name":"Shanghai Jiao Tong University"},
 {"id":"inst105","name":"Carnegie Mellon University","country":"USA",
  "logo":[{"href":"http://example.com/api/contests/wf14/organizations/inst105/logo/56px","width":56,"height":56},
          {"href":"http://example.com/api/contests/wf14/organizations/inst105/logo/160px","width":160,"height":160}]
 }
]
```

### Teams

Teams competing in the contest.

The following endpoints are associated with teams:

| Endpoint                     | Mime-type        | Required? | Description
| :--------------------------- | :--------------- | :-------- | :----------
| `/contests/<id>/teams`       | application/json | yes       | JSON array of all teams with elements as defined in the table below.
| `/contests/<id>/teams/id>`   | application/json | yes       | JSON object of a single team with elements as defined in the table below.

JSON elements of team objects:

| Name              | Type             | Required? | Nullable? | Description
| :---------------- | :--------------- | :-------- | :-------- | :----------
| id                | ID               | yes       | no        | Identifier of the team. Usable as a label, at WFs normally the team seat number.
| icpc\_id          | string           | no        | yes       | External identifier from ICPC CMS.
| name              | string           | yes       | no        | Name of the team.
| display\_name     | string           | no        | yes       | Display name of the team. If not set, a client should revert to using the name instead.
| organization\_id  | ID               | no        | yes       | Identifier of the [ organization](#organizations) (e.g. university or other entity) that this team is affiliated to.
| group\_ids        | array of ID      | no        | no        | Identifiers of the [ group(s)](#groups) this team is part of (at ICPC WFs these are the super-regions). No meaning must be implied or inferred from the order of IDs. The array may be empty.
| location          | object           | no        | no        | JSON object as specified in the rows below.
| location.x        | number           | depends   | no        | Team's x position in meters. Required iff location is present.
| location.y        | number           | depends   | no        | Team's y position in meters. Required iff location is present.
| location.rotation | number           | depends   | no        | Team's rotation in degrees. Required iff location is present.
| photo             | array of IMAGE   | no        | yes       | Registration photo of the team.
| video             | array of VIDEO   | no        | yes       | Registration video of the team.
| backup            | array of ARCHIVE | no        | yes       | Latest file backup of the team machine. Only allowed mime type is application/zip.
| key\_log          | array of FILE    | no        | yes       | Latest key log file from the team machine. Only allowed mime type is text/plain.
| tool\_data        | array of FILE    | no        | yes       | Latest tool data usage file from the team machine. Only allowed mime type is text/plain.
| desktop           | array of STREAM  | no        | yes       | Streaming video of the team desktop.
| webcam            | array of STREAM  | no        | yes       | Streaming video of the team webcam.
| audio             | array of STREAM  | no        | yes       | Streaming team audio.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/teams`

Returned data:

```json
[{"id":"11","icpc_id":"201433","name":"Shanghai Tigers","organization_id":"inst123","group_ids":["asia-74324325532"]},
 {"id":"123","name":"CMU1","organization_id":"inst105","group_ids":["8","11"]}
]
```

### Team members

Team members of teams in the contest.

The following endpoints are associated with languages:

| Endpoint                           | Mime-type        | Required? | Description
| :--------------------------------- | :--------------- | :-------- | :----------
| `/contests/<id>/team-members`      | application/json | no        | JSON array of all team members with elements as defined in the table below.
| `/contests/<id>/team-members/<id>` | application/json | no        | JSON object of a single team member with elements as defined in the table below.

JSON elements of team member objects:

| Name        | Type           | Required? | Nullable? | Description
| :---------- | :------------- | :-------- | :-------- | :----------
| id          | ID             | yes       | no        | Identifier of the team-member.
| icpc\_id    | string         | no        | yes       | External identifier from ICPC CMS.
| team\_id    | ID             | yes       | no        | [Team](#teams) of this team member.
| first\_name | string         | yes       | no        | First name of team member.
| last\_name  | string         | yes       | no        | Last name of team member.
| sex         | string         | no        | yes       | Either `male` or `female`, or possibly `null`.
| role        | string         | yes       | no        | One of `contestant` or `coach`.
| photo       | array of IMAGE | no        | yes       | Registration photo of the team member.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/team-members`

Returned data:

```json
[{"id":"john-smith","team_id":"43","icpc_id":"32442","first_name":"John","last_name":"Smith","sex":"male","role":"contestant"},
 {"id":"osten-umlautsen","team_id":"43","icpc_id":null,"first_name":"Östen","last_name":"Ümlautsen","sex":null,"role":"coach"}
]
```

### Contest state

Current state of the contest, specifying whether it's running, the
scoreboard is frozen or results are final.

The following endpoints are associated with state:

| Endpoint               | Type             | Required? | Description
| :--------------------- | :--------------- | :-------- | :----------
| `/contests/<id>/state` | application/json | yes       | JSON object of the current contest state with elements as defined in the table below.

JSON elements of state objects:

| Name             | Type | Required? | Nullable? | Description
| :--------------- | :--- | :-------- | :-------- | :----------
| started          | TIME | yes       | yes       | Time when the contest actually started, or `null` if the contest has not started yet. When set, this time must be equal to the [contest](#contests) `start_time`.
| frozen           | TIME | depends   | yes       | Time when the scoreboard was frozen, or `null` if the scoreboard has not been frozen. Required iff `scoreboard_freeze_duration` is present in the [contest](#contests) endpoint.
| ended            | TIME | yes       | yes       | Time when the contest ended, or `null` if the contest has not ended. Must not be set if started is `null`.
| thawed           | TIME | depends   | yes       | Time when the scoreboard was thawed (that is, unfrozen again), or `null` if the scoreboard has not been thawed. Required iff `scoreboard_freeze_duration` is present in the [contest](#contests) endpoint. Must not be set if frozen is `null`.
| finalized        | TIME | yes       | yes       | Time when the results were finalized, or `null` if results have not been finalized. Must not be set if ended is `null`.
| end\_of\_updates | TIME | yes       | yes       | Time after last update to the contest occurred, or `null` if more updates are still to come. Setting this to non-`null` must be the very last change in the contest.

These state changes must occur in the order listed in the table above,
as far as they do occur, except that `thawed` and `finalized` may occur
in any order. For example, the contest may never be frozen and hence not
thawed either, or, it may be finalized before it is thawed. That, is the
following sequence of inequalities must hold:

```
started < frozen < ended < thawed    < end_of_updates,
                   ended < finalized < end_of_updates.
```

A contest that has ended, has been thawed (or was never frozen) and is
finalized must not change. Thus, `end_of_updates` can be set once both
`finalized` is set and `thawed` is set if the contest was frozen.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/state`

Returned data:

```json
{
  "started": "2014-06-25T10:00:00+01",
  "ended": null,
  "frozen": "2014-06-25T14:00:00+01",
  "thawed": null,
  "finalized": null,
  "end_of_updates": null
}
```

### Submissions

Submissions, a.k.a. attempts to solve problems in the contest.

The following endpoints are associated with submissions:

| Endpoint                          | Type             | Required? | Description
| :-------------------------------- | :--------------- | :-------- | :----------
| `/contests/<id>/submissions`      | application/json | yes       | JSON array of all submissions with elements as defined in the table below      |
| `/contests/<id>/submissions/<id>` | application/json | yes       | JSON object of a single submission with elements as defined in the table below |

JSON elements of submission objects:

| Name          | Type             | Required? | Nullable? | Description
| :------------ | :--------------- | :-------- | :-------- | :----------
| id            | ID               | yes       | no        | Identifier of the submission. Usable as a label, typically a low incrementing number.
| language\_id  | ID               | yes       | no        | Identifier of the [ language](#languages) submitted for.
| problem\_id   | ID               | yes       | no        | Identifier of the [ problem](#problems) submitted for.
| team\_id      | ID               | yes       | no        | Identifier of the [ team](#teams) that made the submission.
| time          | TIME             | yes       | no        | Timestamp of when the submission was made.
| contest\_time | RELTIME          | yes       | no        | Contest relative time when the submission was made.
| entry\_point  | string           | yes       | yes       | Code entry point for specific languages.
| files         | array of ARCHIVE | yes       | no        | Submission files, contained at the root of the archive. Only allowed mime type is application/zip. Only exactly one archive is allowed.
| reaction      | array of VIDEO   | no        | yes       | Reaction video from team's webcam.

The `entry_point` attribute must be included for submissions in
languages which do not have a single, unambiguous entry point to run the
code. In general the entry point is the string that needs to be
specified to point to the code to be executed. Specifically, for Python
it is the file name that should be run, and for Java and Kotlin it is
the fully qualified class name (that is, with any package name included,
e.g. `com.example.myclass` for a class in the package `com.example` in
Java). For C and C++ no entry point is required and it must therefore be
`null`.

The `files` attribute provides the file(s) of a given submission as a
zip archive. These must be stored directly from the root of the zip
file, i.e. there must not be extra directories (or files) added unless
these are explicitly part of the submission content. For `POST`,
`PUT` and `PATCH` methods, the `files` attribute must contain the
base64-encoded string of the zip archive.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/submissions`

Returned data:

```json
[{"id":"187","team_id":"123","problem_id":"10-asteroids",
  "language_id":"1-java","time":"2014-06-25T11:22:05.034+01","contest_time":"1:22:05.034","entry_point":"Main",
  "files":[{"href":"contests/wf14/submissions/187/files","mime":"application/zip"}]}
]
```

Note that the relative link for `files` points to the location
<https://example.com/api/contests/wf14/submissions/187/files> since the
base URL for the API is <https://example.com/api>.

### Judgements

Judgements for submissions in the contest.

The following endpoints are associated with judgements:

| Endpoint                         | Mime-type        | Required? | Description
| :------------------------------- | :--------------- | :-------- | :----------
| `/contests/<id>/judgements`      | application/json | yes       | JSON array of all judgements with elements as defined in the table below.
| `/contests/<id>/judgements/<id>` | application/json | yes       | JSON object of a single judgement with elements as defined in the table below.

JSON elements of judgement objects:

| Name                 | Type    | Required? | Nullable? | Description
| :------------------- | :------ | :-------- | :-------- | :----------
| id                   | ID      | yes       | no        | Identifier of the judgement.
| submission\_id       | ID      | yes       | no        | Identifier of the [ submission](#submissions) judged.
| judgement\_type\_id  | ID      | yes       | yes       | The [ verdict](#judgement-types) of this judgement.
| start\_time          | TIME    | yes       | no        | Absolute time when judgement started.
| start\_contest\_time | RELTIME | yes       | no        | Contest relative time when judgement started.
| end\_time            | TIME    | yes       | yes       | Absolute time when judgement completed.
| end\_contest\_time   | RELTIME | yes       | yes       | Contest relative time when judgement completed.
| max\_run\_time       | decimal | no        | yes       | Maximum run time in seconds for any test case. Should be an integer multiple of `0.001`.

When a judgement is started, each of `judgement_type_id`, `end_time` and
`end_contest_time` will be `null` (or missing). These are set when the
judgement is completed.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/judgements`

Returned data:

```json
[{"id":"189549","submission_id":"wf2017-32163123xz3132yy","judgement_type_id":"CE","start_time":"2014-06-25T11:22:48.427+01",
  "start_contest_time":"1:22:48.427","end_time":"2014-06-25T11:23:32.481+01","end_contest_time":"1:23:32.481"},
 {"id":"189550","submission_id":"wf2017-32163123xz3133ub","judgement_type_id":null,"start_time":"2014-06-25T11:24:03.921+01",
  "start_contest_time":"1:24:03.921","end_time":null,"end_contest_time":null}
]
```

### Runs

Runs are judgements of individual test cases of a submission.

The following endpoints are associated with runs:

| Endpoint                   | Mime-type        | Required? | Description
| :------------------------- | :--------------- | :-------- | :----------
| `/contests/<id>/runs`      | application/json | yes       | JSON array of all runs with elements as defined in the table below.
| `/contests/<id>/runs/<id>` | application/json | yes       | JSON object of a single run with elements as defined in the table below.

JSON elements of run objects:

| Name                | Type    | Required? | Nullable? | Description
| :------------------ | :------ | :-------- | :-------- | :----------
| id                  | ID      | yes       | no        | Identifier of the run.
| judgement\_id       | ID      | yes       | no        | Identifier of the [ judgement](#judgements) this is part of.
| ordinal             | ORDINAL | yes       | no        | Ordering of runs in the judgement. Must be different for every run in a judgement. Runs for the same test case must have the same ordinal. Must be between 1 and `problem:test_data_count`.
| judgement\_type\_id | ID      | yes       | no        | The [ verdict](#judgement-types) of this judgement (i.e. a judgement type).
| time                | TIME    | yes       | no        | Absolute time when run completed.
| contest\_time       | RELTIME | yes       | no        | Contest relative time when run completed.
| run\_time           | decimal | no        | no        | Run time in seconds. Should be an integer multiple of `0.001`.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/runs`

Returned data:

```json
[{"id":"1312","judgement_id":"189549","ordinal":28,"judgement_type_id":"TLE",
  "time":"2014-06-25T11:22:42.420+01","contest_time":"1:22:42.420"}
]
```

### Clarifications

Clarification message sent between teams and judges, a.k.a.
clarification requests (questions from teams) and clarifications
(answers from judges).

The following endpoints are associated with clarification messages:

| Endpoint                             | Mime-type        | Required? | Description
| :----------------------------------- | :--------------- | :-------- | :----------
| `/contests/<id>/clarifications`      | application/json | yes       | JSON array of all clarification messages with elements as defined in the table below.
| `/contests/<id>/clarifications/<id>` | application/json | yes       | JSON object of a single clarification message with elements as defined in the table below.

JSON elements of clarification message objects:

| Name           | Type    | Required? | Nullable? | Description
| :------------- | :------ | :-------- | :-------- | :----------
| id             | ID      | yes       | no        | Identifier of the clarification.
| from\_team\_id | ID      | yes       | yes       | Identifier of [ team](#teams) sending this clarification request, `null` if a clarification sent by jury.
| to\_team\_id   | ID      | yes       | yes       | Identifier of the [ team](#teams) receiving this reply, `null` if a reply to all teams or a request sent by a team.
| reply\_to\_id  | ID      | yes       | yes       | Identifier of clarification this is in response to, otherwise `null`.
| problem\_id    | ID      | yes       | yes       | Identifier of associated [ problem](#problems), `null` if not associated to a problem.
| text           | string  | yes       | no        | Question or reply text.
| time           | TIME    | yes       | no        | Time of the question/reply.
| contest\_time  | RELTIME | yes       | no        | Contest time of the question/reply.

Note that at least one of `from_team_id` and `to_team_id` has to be
`null`. That is, teams cannot send messages to other teams.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/clarifications`

Returned data:

```json
[{"id":"wf2017-1","from_team_id":null,"to_team_id":null,"reply_to_id":null,"problem_id":null,
  "text":"Do not touch anything before the contest starts!","time":"2014-06-25T11:59:27.543+01","contest_time":"-0:15:32.457"}
]
```

Request:

` GET https://example.com/api/contests/wf14/clarifications`

Returned data:

```json
[{"id":"1","from_team_id":"34","to_team_id":null,"reply_to_id":null,"problem_id":null,
  "text":"May I ask a question?","time":"2017-06-25T11:59:27.543+01","contest_time":"1:59:27.543"},
 {"id":"2","from_team_id":null,"to_team_id":"34","reply_to_id":"1","problem_id":null,
  "text":"Yes you may!","time":"2017-06-25T11:59:47.543+01","contest_time":"1:59:47.543"}
]
```

Request:

` GET https://example.com/api/contests/wf14/clarifications`

Returned data:

```json
[{"id":"1","from_team_id":"34","text":"May I ask a question?","time":"2017-06-25T11:59:27.543+01","contest_time":"1:59:27.543"},
 {"id":"2","to_team_id":"34","reply_to_id":"1","text":"Yes you may!","time":"2017-06-25T11:59:47.543+01","contest_time":"1:59:47.543"}
]
```

### Awards

Awards such as medals, first to solve, etc.

The following endpoints are associated with awards:

| Endpoint                     | Mime-type        | Required? | Description
| :--------------------------- | :--------------- | :-------- | :----------
| `/contests/<id>/awards`      | application/json | no        | JSON array of all awards with elements as defined in the table below.
| `/contests/<id>/awards/<id>` | application/json | no        | JSON object of a single award with elements as defined in the table below.

JSON elements of award objects:

| Name      | Type        | Required? | Nullable? | Description
| :-------- | :---------- | :-------- | :-------- | :----------
| id        | ID          | yes       | no        | Identifier of the award.
| citation  | string      | yes       | no        | Award citation, e.g. "Gold medal winner".
| team\_ids | array of ID | yes       | no        | JSON array of [ team](#teams) ids receiving this award. No meaning must be implied or inferred from the order of IDs. The array may be empty.

#### Semantics

  - Awards are not final until the contest is.
  - An award does not have to be present during the contest. However, if
    it is present, then it must be kept up to date during the contest.
    E.g. if "winner" will not be updated with the current leader during
    the contest, it must not be **create**d until the award **is**
    awarded.
  - If an award is present during the contest this means that if the
    contest would end immediately and then become final, that award
    would be final. E.g. the "winner" during the contest should be the
    current leader. This is of course subject to what data the client
    can see; the public role's winner may not change during the
    scoreboard freeze but an admin could see the true current winner.

#### Known awards

For some common award cases the following IDs should be used.

| ID                        | Meaning during contest                                                                                                     | Meaning when contest is final      | Comment
| :------------------------ | :------------------------------------------------------------------------------------------------------------------------- | :--------------------------------- | :------
| winner                    | Current leader(s). Empty if no team has scored.                                                                            | Winner(s) of the contest.          |
| gold-medal                | Teams currently placed to receive a gold medal. Empty if no team has scored.                                               | Teams being awarded gold medals.   |
| silver-medal              | Teams currently placed to receive a silver medal. Empty if no team has scored.                                             | Teams being awarded silver medals. |
| bronze-medal              | Teams currently placed to receive a bronze medal, assuming no extra bronze are awarded. Empty if no team has scored.       | Teams being awarded bronze medals. |
| rank-\<rank>              | Teams currently placed to receive rank \<rank>. Empty if no team has scored.                                               | Teams being awarded rank \<rank>.  | Only useful in contests where the final ranking awarded is different from the default ranking of the scoreboard. E.g. at the WF teams *not* getting medals are only ranked based on number of problems solved, and not total penalty time accrued nor time of last score improvement, and teams solving strictly fewer problems than the median team are not ranked at all.
| honorable-mention         | Teams currently placed to receive an honorable mention.                                                                    | Teams being awarded an honorable mention.         |
| first-to-solve-\<id>      | The team(s), if any, that was first to solve problem \<id>. This implies that no unjudged submission made earlier remains. | Same.                              | Must never change once set, except if there are rejudgements.
| group-winner-\<id>        | Current leader(s) in group \<id>. Empty if no team has scored.                                                             | Winner(s) of group \<id>.          |
| organization-winner-\<id> | Current leader(s) of organization \<id>. Empty if no team has scored.                                                      | Winner(s) of organization \<id>.   | Not useful in contest with only one team per organization (e.g. the WF).

#### Examples

Request:

` GET https://example.com/api/contests/wf14/awards`

Returned data:

```json
[{"id":"gold-medal","citation":"Gold medal winner","team_ids":["54","23","1","45"]},
 {"id":"first-to-solve-a","citation":"First to solve problem A","team_ids":["45"]},
 {"id":"first-to-solve-b","citation":"First to solve problem B","team_ids":[]}
]
```

### Scoreboard

Scoreboard of the contest.

Since this is generated data, only the `GET` method is allowed here,
irrespective of role.

The following endpoint is associated with the scoreboard:

| Endpoint                    | Mime-type        | Required? | Description
| :-------------------------- | :--------------- | :-------- | :----------
| `/contests/<id>/scoreboard` | application/json | yes       | JSON object with scoreboard data as defined in the table below.

#### Scoreboard request options

The following options can be passed to the scoreboard endpoint.

##### Scoreboard at the time of a given event

By passing an [ event](#event-feed) ID with the
`after_event_id` URL argument, the scoreboard can be requested as it
was directly after the specified event:

`/scoreboard?after_event_id=xy1234`

This makes it possible for a client to get the scoreboard information
that is guaranteed to match a certain contest event. In case no
`after_event_id` argument is provided, the current scoreboard will be
returned. The request will fail with a 400 error if the id is invalid.

A suggested efficient server-side implementation to provide this, is to
store with each event that changes the scoreboard, the new team
scoreboard row.

#### Scoreboard format

JSON elements of the scoreboard object.

| Name          | Type                       | Required? | Nullable? | Description
| :------------ | :------------------------- | :-------- | :-------- | :----------
| event\_id     | ID                         | yes       | no        | Identifier of the [ event](#event-feed) after which this scoreboard was generated. This must be identical to the argument `after_event_id`, if specified.
| time          | TIME                       | yes       | no        | Time contained in the associated event. Implementation defined if the event has no associated time.
| contest\_time | RELTIME                    | yes       | no        | Contest time contained in the associated event. Implementation defined if the event has no associated contest time.
| state         | object                     | yes       | no        | Identical data as returned by the [ contest state](#contest-state) endpoint. This is provided here for ease of use and to guarantee the data is synchronized.
| rows          | JSON array of JSON objects | yes       | no        | A list of rows of team with their associated scores.

The scoreboard `rows` array is sorted according to rank and alphabetical
on team name within identically ranked teams. Here alphabetical ordering
means according to the [Unicode Collation
Algorithm](https://www.unicode.org/reports/tr10/), by default using the
`en-US` locale.

Each JSON object in the rows array consists of:

| Name              | Type             | Required? | Nullable? | Description
| :---------------- | :--------------- | :-------- | :-------- | :----------
| rank              | integer          | yes       | no        | Rank of this team, 1-based and duplicate in case of ties.
| team\_id          | ID               | yes       | no        | Identifier of the [ team](#teams).
| score             | object           | yes       | no        | JSON object as specified in the rows below (for possible extension to other scoring methods).
| score.num\_solved | integer          | depends   | no        | Number of problems solved by the team.
| score.total\_time | integer          | depends   | no        | Total penalty time accrued by the team.
| problems          | array of objects | yes       | no        | JSON array of problems with scoring data, see below for the specification of each element.

Each problem object within the scoreboard consists of:

| Name         | Type    | Required? | Nullable? | Description
| :----------- | :------ | :-------- | :-------- | :----------
| problem\_id  | ID      | yes       | no        | Identifier of the [ problem](#problems).
| num\_judged  | integer | yes       | no        | Number of judged submissions (up to and including the first correct one),
| num\_pending | integer | yes       | no        | Number of pending submissions (either queued or due to freeze).
| solved       | boolean | depends   | yes       | Whether the team solved this problem.
| time         | integer | depends   | no        | Minutes into the contest when this problem was solved by the team. Required iff `solved=true`.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/scoreboard`

Returned data:

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
  "rows": [
    {"rank":1,"team_id":"123","score":{"num_solved":3,"total_time":340},"problems":[
      {"problem_id":"1","num_judged":3,"num_pending":1,"solved":false},
      {"problem_id":"2","num_judged":1,"num_pending":0,"solved":true,"time":20},
      {"problem_id":"3","num_judged":2,"num_pending":0,"solved":true,"time":55},
      {"problem_id":"4","num_judged":0,"num_pending":0,"solved":false},
      {"problem_id":"5","num_judged":3,"num_pending":0,"solved":true,"time":205}
    ]}
  ]
}
```

### Event feed

Provides the event (notification) feed for the current contest. This is
effectively a changelog of create, update, or delete events that have
occurred in the REST endpoints. Some endpoints (specifically the
[Scoreboard](#scoreboard) and the Event feed itself) are
aggregated data, and so these will only ever update due to some other
REST endpoint updating. For this reason there is no explicit event for
these, since there will always be another event sent. This can also be
seen by the fact that there is no scoreboard event in the table of
events below.

Since this is generated data, only the `GET` method is allowed here,
irrespective of role.

The following endpoint is associated with the event feed:

| Endpoint                    | Mime-type            | Required? | Description
| :-------------------------- | :------------------- | :-------- | :----------
| `/contests/<id>/event-feed` | application/x-ndjson | yes       | NDJSON feed of events as defined below.

Multiple requests of the event feed must return the exact same events in
the exact same order, except that events filtered out by the feed
options must be left out and new elements, if any, are added in later
requests.

The event feed is a streaming endpoint that does not terminate under
normal circumstances. To ensure keep alive, if no event is sent in 120
seconds, a newline must be sent.


#### Feed options

There are options for filtering based on events and starting the feed at
a specified event. Any combination of these may be specified.

##### Filtering events

If a client only wants some types of events the feed can be filtered
with the "types" URL argument:

```
/event-feed?types=submissions,teams
```

If not specified all events will be sent. If specified only events of
the (comma separated) listed types will be sent.

##### Feed starting point

If a client wants data from some point in time this can be done with the
"since_id" URL argument:

```
/event-feed?since_id=dj593
```

If specified the event feed will include all events strictly after the
specified id. If a client copies the id of an event and uses that for
the id URL argument it will get all events after that event. This is
useful e.g. if a client is disconnected and wants to continue where it
left off.

If the id is not specified the event feed will include all events from
the beginning of the feed. The request will fail with a 400 error if the
id is invalid.

#### Feed format

The feed is served as JSON objects, with every event corresponding to a
change in a single object (submission, judgement, language, team, etc.)
The general format for events is:

```json
{"type": "<event type>", "id": "<event ID>", "op": "<operation>", "data": <JSON data for element> }
```

| Name        | Type   | Required? | Nullable? | Description
| :---------- | :----- | :-------- | :-------- | :----------
| type        | string | yes       | no        | Type of event, one of the events in the table below. Can be used for filtering.
| id          | ID     | yes       | no        | Unique identifier for the event.
| op          | string | yes       | no        | Type of operation, one of **create**, **update**, **delete**.
| data        | object | yes       | no        | For **create** and **update**, the object that would be returned if calling the corresponding API endpoint at this time. For delete an object with only the id attribute with value the identifier of the deleted element.

All event types have a corresponding API endpoint, as specified in the table below.

| Event           | API Endpoint                          |
| :-------------- | :------------------------------------ |
| contests        | `/contests/<id>`                      |
| judgement-types | `/contests/<id>/judgement-types/<id>` |
| languages       | `/contests/<id>/languages/<id>`       |
| problems        | `/contests/<id>/problems/<id>`        |
| groups          | `/contests/<id>/groups/<id>`          |
| organizations   | `/contests/<id>/organizations/<id>`   |
| teams           | `/contests/<id>/teams/<id>`           |
| team-members    | `/contests/<id>/team-members/<id>`    |
| state           | `/contests/<id>/state`                |
| submissions     | `/contests/<id>/submissions/<id>`     |
| judgements      | `/contests/<id>/judgements/<id>`      |
| runs            | `/contests/<id>/runs/<id>`            |
| clarifications  | `/contests/<id>/clarifications/<id>`  |
| awards          | `/contests/<id>/awards/<id>`          |

#### General requirements

The event responses and `data` objects contained in it must observe
the same restrictions as those of the respective endpoints they
represent. This means that attributes inside the `data` element will
be present if and only if the client has access to those at the
respective endpoint. The client only receives create, update and delete
events of elements it has (partial) access to. When time-based access is
granted or revoked, create or delete events are dispatched for each
affected entity.

Referential integrity must be strictly adhered to for new objects. i.e.
if there is a new object that refers to another object (e.g. a
submission for a team) then the referenced object must already exist and
have been notified. There is no such guarantee for deletion: if an
object that is referred to is deleted then by definition all of the
child objects will be deleted, but the events may not arrive in strict
referential order:

  - If an object, A, refers to another object, B, then the event that
    shows that A has been created or updated to refer to B **must** come
    after the event that shows that B has been created.
  - If some data is only available after a specific state change, then
    the event showing the state change **must** come before any update
    events making that data available. E.g. problems are only available
    after contest start for the public role, so the state event showing
    that the contest has started **must** come before the problem events
    creating the problems.
  - Since nothing must change after the contest has ended, thawed (or
    never been frozen), and been finalized, only the `end_of_updates`
    event may come after the state event showing that.

##### Examples

Request:

` GET https://example.com/api/contests/wf14/event-feed`

Returned data:

```json
 {"type":"teams","id":"k-2435","op":"create","data":{"id":"11","icpc_id":"201433","name":"Shanghai Tigers","organization_id":"inst123","group_id":"asia"}}
 {"type":"teams","id":"k-2436","op":"update","data":{"id":"11","icpc_id":"201433","name":"The Shanghai Tigers","organization_id":"inst123","group_id":"asia"}}
 {"type":"teams","id":"k-2437","op":"delete","data":{"id":"11"}}
```
