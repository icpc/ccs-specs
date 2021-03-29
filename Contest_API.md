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

This REST interface is specified in conjunction with a new [NDJSON event
feed](#event-feed---draft), which provides all changes to this
interface as CRUD-style events and is meant to supersede the old XML
*Event Feed*.

## General design principles

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in
[RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

The interface is implemented as a HTTP REST interface that outputs
information in [JSON](https://en.wikipedia.org/wiki/JSON) format
([RFC](https://tools.ietf.org/html/rfc7159)). This REST interface should
be provided over HTTPS to guard against eavesdropping on sensitive
contest data and authentication credentials (see roles below).

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
[ { "id":<id1>, <element specific data for id1>},
  { "id":<id2>, <element specific data for id2>},
     ...
]
```

while the URL path

`GET baseurl/<collection>/<id1>`

returns

`{ "id":<id1>, <element specific data for id1>}`

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
returned to indicate success or failure.

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

Attribute types are specified as one of the [standard JSON
types](https://en.wikipedia.org/wiki/JSON#Data_types.2C_syntax_and_example),
or one of the more specific types below. Implementations must be
consistent with respect to the optional parts of each type, e.g. if the
optional .uuu is included in any absolute timestamp it must be included
when outputting all absolute timestamps.

  - Integers
    (type **`integer`** in the specification) are JSON numbers that are
    restricted to be integer. They should be represented in standard
    integer representation `(-)?[0-9]+`.
  - Floating point numbers
    (type **`float`** in the specification) are arbitrary JSON numbers
    that are expected to take non-integer values. It is recommended to
    use a decimal representation.
  - Fixed point numbers
    (type **`decimal`** in the specification) are JSON numbers that are
    expected to take non-integer values. They must be in decimal
    (non-scientific) representation and have at most 3 decimals. That
    is, they must be a integer multiple of `0.001`.
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
    of characters `[a-zA-Z0-9_-]` of length at most 36 and not starting
    with a `-` (dash). IDs are unique within each endpoint.
    IDs are assigned by the person or system that is the source of the
    object, and must be maintained by downstream systems. For example,
    the person configuring a contest on disk will typically define the
    ID for each team, and any CCS or CDS that exposes the team must use
    the same ID.
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
    awards, commentary;
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
  - Type: Data type of the attribute; either a [JSON
    type](https://en.wikipedia.org/wiki/JSON#Data_types.2C_syntax_and_example)
    or [a type defined above](#json-attribute-types).
  - Required?: Whether this is a required attribute that **must** be
    implemented to conform to this specification.
  - Nullable?: Whether the attribute might be `null` (and thus
    implicitly can also not be present in that case).
  - Source @WF: Specifies whether this attribute is implemented at the
    ICPC World Finals and by whom.
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

| Endpoint         | Mime-type        | Required? | Source @WF | Description                                                                 |
| ---------------- | ---------------- | --------- | ---------- | --------------------------------------------------------------------------- |
| `/contests`      | application/json | yes       | CDS        | JSON array of all contests with elements as defined in the table below      |
| `/contests/<id>` | application/json | yes       | CCS        | JSON object of a single contest with elements as defined in the table below |

Returns a JSON object with the elements below. If there is no current
(this may include about to start or just finished) contest, a 404 error
is returned.

| Name                         | Type           | Required? | Nullable? | Source @WF | Description                                                                                                                                      |
| ---------------------------- | -------------- | --------- | --------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| id                           | ID             | yes       | no        | CCS        | identifier of the current contest                                                                                                                |
| name                         | string         | yes       | no        | CCS        | short display name of the contest                                                                                                                |
| formal\_name                 | string         | no        | no        | CCS        | full name of the contest                                                                                                                         |
| start\_time                  | TIME           | yes       | yes       | CCS        | the scheduled start time of the contest, may be `null` if the start time is unknown or the countdown is paused                                   |
| countdown\_pause\_time       | RELTIME        | no        | yes       | CDS        | The amount of seconds left when countdown to contest start is paused. At no time may both `start_time` and `countdown_pause_time` be non-`null`. |
| duration                     | RELTIME        | yes       | no        | CCS        | length of the contest                                                                                                                            |
| scoreboard\_freeze\_duration | RELTIME        | no        | yes       | CCS        | how long the scoreboard is frozen before the end of the contest                                                                                  |
| penalty\_time                | integer        | no        | no        | CCS        | penalty time for a wrong submission, in minutes                                                                                                  |
| banner                       | array of IMAGE | no        | yes       | CDS        | banner for this contest, intended to be an image with a large aspect ratio around 8:1. Only allowed mime type is image/png.                      |
| logo                         | array of IMAGE | no        | yes       | CDS        | logo for this contest, intended to be an image with aspect ratio near 1:1. Only allowed mime type is image/png.                                  |

The expected/typical use of `countdown_pause_time` is that once a
`start_time` is defined and close, the countdown may be paused due to
unforeseen delays. In this case, `start_time` should be set to `null`
and `countdown_pause_time` to the number of seconds left to count down.
The `countdown_pause_time` may change to indicate approximate delay.
Countdown is resumed by setting a new `start_time` and resetting
`countdown_pause_time` to `null`.

#### Access restrictions at WF

No access restrictions apply to a GET on this endpoint.

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

#### Example

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

| Endpoint                              | Mime-type        | Required? | Source @WF | Description                                                                        |
| ------------------------------------- | ---------------- | --------- | ---------- | ---------------------------------------------------------------------------------- |
| `/contests/<id>/judgement-types`      | application/json | yes       | CCS        | JSON array of all judgement types with elements as defined in the table below      |
| `/contests/<id>/judgement-types/<id>` | application/json | yes       | CCS        | JSON object of a single judgement type with elements as defined in the table below |

JSON elements of judgement type objects:

| Name    | Type    | Required? | Nullable? | Source @WF | Description                                                                                                 |
| ------- | ------- | --------- | --------- | ---------- | ----------------------------------------------------------------------------------------------------------- |
| id      | ID      | yes       | no        | CCS        | identifier of the judgement type, a 2-3 letter capitalized shorthand, see table below                       |
| name    | string  | yes       | no        | CCS        | name of the judgement. (might not match table below, e.g. if localized)                                     |
| penalty | boolean | depends   | no        | CCS        | whether this judgement causes penalty time; must be present if and only if contest:penalty\_time is present |
| solved  | boolean | yes       | no        | CCS        | whether this judgement is considered correct                                                                |

#### Access restrictions at WF

No access restrictions apply to a GET on this endpoint.

#### Known judgement types

The list below contains standardized identifiers for known judgement
types. These identifiers should be used by a server. Please send an
email to <cliccs@ecs.csus.edu> or create a pull request at
<https://github.com/icpc/ccs-specs> when there are judgement types missing.

The column **Big 5** lists the "big 5" equivalents, if any. A `*` in
the column means that the judgement is one of the "big 5".

The **Translation** column lists other judgements the judgement can
safely be translated to, if a system does not support it.

| ID  | Name                                     | A.k.a.                                                   | Big 5 | Translation       | Description                                               |
| --- | ---------------------------------------- | -------------------------------------------------------- | ----- | ----------------- | --------------------------------------------------------- |
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

| Endpoint                        | Mime-type        | Required? | Source @WF | Description                                                                  |
| ------------------------------- | ---------------- | --------- | ---------- | ---------------------------------------------------------------------------- |
| `/contests/<id>/languages`      | application/json | yes       | CCS        | JSON array of all languages with elements as defined in the table below      |
| `/contests/<id>/languages/<id>` | application/json | yes       | CCS        | JSON object of a single language with elements as defined in the table below |

JSON elements of language objects:

| Name | Type   | Required? | Nullable? | Source @WF | Description                                                           |
| ---- | ------ | --------- | --------- | ---------- | --------------------------------------------------------------------- |
| id   | ID     | yes       | no        | CCS        | identifier of the language from table below                           |
| name | string | yes       | no        | CCS        | name of the language (might not match table below, e.g. if localized) |

#### Access restrictions at WF

No access restrictions apply to a GET on this endpoint.

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
| ---------- | ----------- |
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

#### Example

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

| Endpoint                       | Mime-type        | Required? | Source @WF | Description                                                                 |
| ------------------------------ | ---------------- | --------- | ---------- | --------------------------------------------------------------------------- |
| `/contests/<id>/problems`      | application/json | yes       | CCS        | JSON array of all problems with elements as defined in the table below      |
| `/contests/<id>/problems/<id>` | application/json | yes       | CCS        | JSON object of a single problem with elements as defined in the table below |

JSON elements of problem objects:

| Name              | Type    | Required? | Nullable? | Source @WF | Description                                                                                                                                                       |
| ----------------- | ------- | --------- | --------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| id                | ID      | yes       | no        | CCS        | identifier of the problem, at the WFs the directory name of the problem archive                                                                                   |
| label             | string  | yes       | no        | CCS        | label of the problem on the scoreboard, typically a single capitalized letter                                                                                     |
| name              | string  | yes       | no        | CCS        | name of the problem                                                                                                                                               |
| ordinal           | ORDINAL | yes       | no        | CCS        | ordering of problems on the scoreboard                                                                                                                            |
| rgb               | string  | no        | no        | CCS        | hexadecimal RGB value of problem color as specified in [HTML hexadecimal colors](https://en.wikipedia.org/wiki/Web_colors#Hex_triplet), e.g. `#AC00FF` or `#fff` |
| color             | string  | no        | no        | CCS        | human readable color description associated to the RGB value                                                                                                      |
| time\_limit       | decimal | no        | no        | CCS        | time limit in seconds per test data set (i.e. per single run)                                                                                                     |
| test\_data\_count | integer | yes       | no        | CCS        | number of test data sets                                                                                                                                          |

#### Access restrictions at WF

The `public` role can only access these problems after the contest
started. That is, before contest start this endpoint returns an empty
array for clients with the `public` role.

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

Grouping of teams. At the World Finals these are the super regions, at
regionals these are often different sites.

The following endpoints are associated with groups:

| Endpoint                     | Mime-type        | Required? | Source @WF | Description                                                               |
| ---------------------------- | ---------------- | --------- | ---------- | ------------------------------------------------------------------------- |
| `/contests/<id>/groups`      | application/json | no        | CCS        | JSON array of all groups with elements as defined in the table below      |
| `/contests/<id>/groups/<id>` | application/json | no        | CCS        | JSON object of a single group with elements as defined in the table below |

Note that these endpoints must be provided if groups are used. If they
are not provided no other endpoint may refer to groups (i.e. return any
group\_ids).

JSON elements of group objects:

| Name     | Type    | Required? | Nullable? | Source @WF | Description                                                              |
| -------- | ------- | --------- | --------- | ---------- | ------------------------------------------------------------------------ |
| id       | ID      | yes       | no        | CCS        | identifier of the group                                                  |
| icpc\_id | string  | no        | yes       | CCS        | external identifier from ICPC CMS                                        |
| name     | string  | yes       | no        | CCS        | name of the group                                                        |
| type     | string  | no        | yes       | CCS        | type of this group                                                       |
| hidden   | boolean | no        | yes       | CCS        | if group should be hidden from scoreboard. Defaults to false if missing. |

#### Access restrictions at WF

No access restrictions apply to a GET on this endpoint.

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

| Endpoint                            | Type             | Required? | Source @WF | Description                                                                      |
| ----------------------------------- | ---------------- | --------- | ---------- | -------------------------------------------------------------------------------- |
| `/contests/<id>/organizations`      | application/json | no        | CCS & CDS  | JSON array of all organizations with elements as defined in the table below      |
| `/contests/<id>/organizations/<id>` | application/json | no        | CCS & CDS  | JSON object of a single organization with elements as defined in the table below |

Note that the first two endpoints must be provided if organizations are
used. If they are not provided no other endpoint may refer to
organizations (i.e. return any organization\_ids).

JSON elements of organization objects:

| Name               | Type           | Required? | Nullable? | Source @WF | Description                                                                                                                                               |
| ------------------ | -------------- | --------- | --------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| id                 | ID             | yes       | no        | CCS        | identifier of the organization                                                                                                                            |
| icpc\_id           | string         | no        | yes       | CCS        | external identifier from ICPC CMS                                                                                                                         |
| name               | string         | yes       | no        | CCS        | short display name of the organization                                                                                                                    |
| formal\_name       | string         | no        | yes       | CCS        | full organization name if too long for normal display purposes.                                                                                           |
| country            | string         | no        | yes       | not used   | [ISO 3-letter code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) of the organization's country                                                       |
| url                | string         | no        | yes       | CDS        | URL to organization's website                                                                                                                             |
| twitter\_hashtag   | string         | no        | yes       | CDS        | organization hashtag                                                                                                                                      |
| location           | object         | no        | yes       | CDS        | JSON object as specified in the rows below                                                                                                                |
| location.latitude  | float          | depends   | no        | CDS        | Latitude in degrees. Required iff location is present.                                                                                                    |
| location.longitude | float          | depends   | no        | CDS        | Longitude in degrees. Required iff location is present.                                                                                                   |
| logo               | array of IMAGE | no        | yes       | CDS        | logo of the organization. Only allowed mime type is image/png. A server must provide logos of size 56x56 and 160x160 but may provide other sizes as well. |

#### Access restrictions at WF

No access restrictions apply to a GET on organizations endpoints.

#### Example

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

| Endpoint                    | Mime-type        | Required? | Source @WF | Description                                                              |
| --------------------------- | ---------------- | --------- | ---------- | ------------------------------------------------------------------------ |
| `/contests/id>/teams`      | application/json | yes       | CCS & CDS  | JSON array of all teams with elements as defined in the table below      |
| `/contests/id>/teams/id>` | application/json | yes       | CCS & CDS  | JSON object of a single team with elements as defined in the table below |

JSON elements of team objects:

| Name              | Type             | Required? | Nullable? | Source @WF | Description                                                                                                                                                                                              |
| ----------------- | ---------------- | --------- | --------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| id                | ID               | yes       | no        | CCS        | identifier of the team. Usable as a label, at WFs normally the team seat number                                                                                                                          |
| icpc\_id          | string           | no        | yes       | CCS        | external identifier from ICPC CMS                                                                                                                                                                        |
| name              | string           | yes       | no        | CCS        | name of the team                                                                                                                                                                                         |
| display\_name     | string           | no        | yes       | CCS        | display name of the team. If not set, a client should revert to using the name instead.                                                                                                                  |
| organization\_id  | ID               | no        | yes       | CCS        | identifier of the [ organization](#organizations) (e.g. university or other entity) that this team is affiliated to                                                                           |
| group\_ids        | array of ID      | no        | no        | CCS        | identifiers of the [ group(s)](#groups) this team is part of (at ICPC WFs these are the super-regions). No meaning must be implied or inferred from the order of IDs. The array may be empty. |
| location          | object           | no        | no        | CDS        | JSON object as specified in the rows below                                                                                                                                                               |
| location.x        | float            | depends   | no        | CDS        | Team's x position in meters. Required iff location is present.                                                                                                                                           |
| location.y        | float            | depends   | no        | CDS        | Team's y position in meters. Required iff location is present.                                                                                                                                           |
| location.rotation | float            | depends   | no        | CDS        | Team's rotation in degrees. Required iff location is present.                                                                                                                                            |
| photo             | array of IMAGE   | no        | yes       | CDS        | registration photo of the team. Only allowed mime types are image/jpeg and image/png.                                                                                                                    |
| video             | array of VIDEO   | no        | yes       | CDS        | registration video of the team.                                                                                                                                                                          |
| backup            | array of ARCHIVE | no        | yes       | CDS        | latest file backup of the team machine. Only allowed mime type is application/zip.                                                                                                                       |
| key\_log          | array of FILE    | no        | yes       | CDS        | latest key log file from the team machine. Only allowed mime type is text/plain.                                                                                                                         |
| tool\_data        | array of FILE    | no        | yes       | CDS        | latest tool data usage file from the team machine. Only allowed mime type is text/plain.                                                                                                                 |
| desktop           | array of STREAM  | no        | yes       | CDS        | streaming video of the team desktop.                                                                                                                                                                     |
| webcam            | array of STREAM  | no        | yes       | CDS        | streaming video of the team webcam.                                                                                                                                                                      |
| audio             | array of STREAM  | no        | yes       | CDS        | streaming team audio.                                                                                                                                                                                    |

#### Access restrictions at WF

The following access restrictions apply to a GET on this endpoint:

  - the `backup` attribute requires the `admin` or `analyst` role for access,
  - the `desktop` and `webcam` attributes are available for the
    `public` role only when the scoreboard is not frozen.

#### Example

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

| Endpoint                           | Mime-type        | Required? | Source @WF | Description                                                                     |
| ---------------------------------- | ---------------- | --------- | ---------- | ------------------------------------------------------------------------------- |
| `/contests/<id>/team-members`      | application/json | no        | CDS        | JSON array of all team members with elements as defined in the table below      |
| `/contests/<id>/team-members/<id>` | application/json | no        | CDS        | JSON object of a single team member with elements as defined in the table below |

JSON elements of team member objects:

| Name        | Type           | Required? | Nullable? | Source @WF | Description                                                                                  |
| ----------- | -------------- | --------- | --------- | ---------- | -------------------------------------------------------------------------------------------- |
| id          | ID             | yes       | no        | CDS        | identifier of the team-member                                                                |
| icpc\_id    | string         | no        | yes       | CDS        | external identifier from ICPC CMS                                                            |
| team\_id    | ID             | yes       | no        | CDS        | [ team](#teams) of this team member                                               |
| first\_name | string         | yes       | no        | CDS        | first name of team member                                                                    |
| last\_name  | string         | yes       | no        | CDS        | last name of team member                                                                     |
| sex         | string         | no        | yes       | CDS        | either `male` or `female`, or possibly `null`                                            |
| role        | string         | yes       | no        | CDS        | one of `contestant` or `coach`                                                           |
| photo       | array of IMAGE | no        | yes       | CDS        | registration photo of the team member. Only allowed mime types are image/jpeg and image/png. |

#### Access restrictions at WF

No access restrictions apply to a GET on this endpoint.

#### Example

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

| Endpoint               | Type             | Required? | Source @WF | Description                                                                          |
| ---------------------- | ---------------- | --------- | ---------- | ------------------------------------------------------------------------------------ |
| `/contests/<id>/state` | application/json | yes       | CCS        | JSON object of the current contest state with elements as defined in the table below |

JSON elements of state objects:

| Name             | Type | Required? | Nullable? | Source @WF | Description                                                                                                                                                                                                                                                |
| ---------------- | ---- | --------- | --------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| started          | TIME | yes       | yes       | CCS        | Time when the contest actually started, or `null` if the contest has not started yet. When set, this time must be equal to the [contest](#contests) `start_time`.                                                                               |
| frozen           | TIME | depends   | yes       | CCS        | Time when the scoreboard was frozen, or `null` if the scoreboard has not been frozen. Required iff `scoreboard_freeze_duration` is present in the [contest](#contests) endpoint.                                                                |
| ended            | TIME | yes       | yes       | CCS        | Time when the contest ended, or `null` if the contest has not ended. Must not be set if started is `null`.                                                                                                                                                 |
| thawed           | TIME | depends   | yes       | CCS        | Time when the scoreboard was thawed (that is, unfrozen again), or `null` if the scoreboard has not been thawed. Required iff `scoreboard_freeze_duration` is present in the [contest](#Contests) endpoint. Must not be set if frozen is `null`. |
| finalized        | TIME | yes       | yes       | CCS        | Time when the results were finalized, or `null` if results have not been finalized. Must not be set if ended is `null`.                                                                                                                                    |
| end\_of\_updates | TIME | yes       | yes       | CCS        | Time after last update to the contest occurred, or `null` if more updates are still to come. Setting this to non-`null` must be the very last change in the contest.                                                                                       |

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

#### Access restrictions at WF

No access restrictions apply to a GET on this endpoint, but note that
when the `frozen` state is set, but `thawed` not yet, then this implies
access restrictions for non-privileged users to other endpoints.

#### Example

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

| Endpoint                          | Type             | Required? | Source @WF | Description                                                                    |
| --------------------------------- | ---------------- | --------- | ---------- | ------------------------------------------------------------------------------ |
| `/contests/<id>/submissions`      | application/json | yes       | CCS        | JSON array of all submissions with elements as defined in the table below      |
| `/contests/<id>/submissions/<id>` | application/json | yes       | CCS        | JSON object of a single submission with elements as defined in the table below |

JSON elements of submission objects:

| Name          | Type             | Required? | Nullable? | Source @WF | Description                                                                                                                             |
| ------------- | ---------------- | --------- | --------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| id            | ID               | yes       | no        | CCS        | identifier of the submission. Usable as a label, typically a low incrementing number                                                    |
| language\_id  | ID               | yes       | no        | CCS        | identifier of the [ language](#languages) submitted for                                                                                 |
| problem\_id   | ID               | yes       | no        | CCS        | identifier of the [ problem](#problems) submitted for                                                                                   |
| team\_id      | ID               | yes       | no        | CCS        | identifier of the [ team](#teams) that made the submission                                                                              |
| time          | TIME             | yes       | no        | CCS        | timestamp of when the submission was made                                                                                               |
| contest\_time | RELTIME          | yes       | no        | CCS        | contest relative time when the submission was made                                                                                      |
| entry\_point  | string           | yes       | yes       | CCS        | code entry point for specific languages                                                                                                 |
| files         | array of ARCHIVE | yes       | no        | CCS        | submission files, contained at the root of the archive. Only allowed mime type is application/zip. Only exactly one archive is allowed. |
| reaction      | array of VIDEO   | no        | yes       | CDS        | reaction video from team's webcam.                                                                                                      |

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
these are explicitly part of the submission content.

#### Access restrictions at WF

The `entry_point` and `files` attribute are accessible only for
clients with `admin` or `analyst` role. The `reaction` attribute
is available to clients with `public` role only when the contest is
not frozen.

#### POST submissions

To add a submission one can use the `POST` method on the submissions endpoint.
The `POST` must include a valid JSON object with the same attributes the submission
endpoint returns with a `GET` request with the following exceptions:

* The attributes `id`, `team_id`, `time`, and `contest_time` are
  optional. However, depending on the use case (see below) the server
  may require attributes to either be absent or present, and should
  respond with a 400 error code in such cases.
* Since `files` only supports `application/zip`, providing the `mime` field is
  optional.
* `reaction` may be provided but a CCS does not have to honour it.
* The `time` attribute is optional. If not provided (or `null`) it will default
  to the current time as determined by the server.
* If the CCS supports a `team` role, `time` and `id`
  must not be provided when using this role. `team_id` may be provided but then
  must match the ID of the team associated with the request. `time` will then always
  use the current time as determined by the server. The CCS will determine an `id`.
* If an `id` is supplied, the client should make sure it is unique, i.e. not used
  yet on the CCS. The client should normally not supply `id`, but let it be determined
  by the server. However, for example in a setup with a central CCS with satellite sites
  where teams submit to a proxy CCS that forwards to the central CCS, this might be
  useful to make sure that the proxy CCS can accept submissions even when the connection
  to the central CCS is down. The proxy can then forward these submissions later, when
  the connection is restored again.

The request must fail with a 400 error code if any of the following happens:

* A required attribute is missing.
* An attribute that must not be provided is provided.
* The supplied problem, team or language can not be found.
* An entrypoint is required for the given language, but not supplied.
* The mime field in `files` is set but invalid.
* Something is wrong with the submission file. For example it contains too many
  files, it is too big, etc.
* The provided `id` already exists or is otherwise not acceptable.

The response will be the ID of the newly added submission.

Performing a `POST` by any other roles than `admin` and `team` is not supported.

#### Use cases for POSTing submissions

The `POST submissions` endpoint can be used for a variety of reasons,
and depending on the use case, the server might require different
fields to be present. A number of common scenarios are described here
for informational purposes only.

##### Team client submitting to CCS

The most obvious and probably most common case is where a team
directly submits to the CCS, e.g. with a command-line submit client.

In this case the client has the `team` role and a specific `team_id`
already associated with it. The attributes `id`, `team_id`, `time`,
and `contest_time` should not be specified; the server will
determine these attributes and should reject submissions specifying
them, or may ignore a `team_id` that is identical to the one that the
client has authenticated as.

##### A proxy server forwarding to a CCS

A proxy server may receive submissions from team clients (like above)
and forward these to a CCS. This might be useful, for example, in a
multi-site contest setup, where each site runs a proxy that would
still be reachable if connectivity with the central CCS is lost, or
where the proxy forwards the submission to multiple CCS's that run in
parallel (like the shadowing setup at the ICPC World Finals).

In such a scenario, the proxy server would timestamp the submissions
and authenticate the submitting team, and then forward the submission
to the upstream CCS using the `admin` role. The proxy would provide
`team_id` and `time` attributes and the CCS should then accept and use
these.

To allow the proxy to return a submission `id` during connectivity
loss, each site could be assigned a unique prefix such that the proxy
server itself can generate unique `id`s and then submit to the central
CCS with the `id` attribute included. The central CCS should then
accept and use that `id` attribute.

##### Further potential extensions

To allow for any further use cases, the specification is deliberately
flexible in how the server can handle optional attributes.

* The `contest_time` attribute should normally not be specified when
  `time` is already specified as it can be calculated from `time` and
  the wallclock time is unambiguously defined without reference to
  contest start time. However, in a case where one would want to
  support a multi-site contest where the sites run out of sync, the
  use of `contest_time` might be considered.

#### Example

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

Request:

` POST https://example.com/api/contests/wf14/submissions`

Request data:

```json
{
   "language_id": "1-java",
   "problem_id": "10-asteroids",
   "team_id": "123",
   "time": "2014-06-25T11:22:05.034+01",
   "entry_point": "Main",
   "files": [{"data": "<base64 string>"}]
}
```

Returned data:

```json
"187"
```

### Judgements

Judgements for submissions in the contest.

The following endpoints are associated with judgements:

| Endpoint                         | Mime-type        | Required? | Source @WF | Description                                                                   |
| -------------------------------- | ---------------- | --------- | ---------- | ----------------------------------------------------------------------------- |
| `/contests/<id>/judgements`      | application/json | yes       | CCS        | JSON array of all judgements with elements as defined in the table below      |
| `/contests/<id>/judgements/<id>` | application/json | yes       | CCS        | JSON object of a single judgement with elements as defined in the table below |

JSON elements of judgement objects:

| Name                 | Type    | Required? | Nullable? | Source @WF | Description                                                     |
| -------------------- | ------- | --------- | --------- | ---------- | --------------------------------------------------------------- |
| id                   | ID      | yes       | no        | CCS        | identifier of the judgement                                     |
| submission\_id       | ID      | yes       | no        | CCS        | identifier of the [ submission](#submissions) judged |
| judgement\_type\_id  | ID      | yes       | yes       | CCS        | the [ verdict](#judgement-types) of this judgement   |
| start\_time          | TIME    | yes       | no        | CCS        | absolute time when judgement started                            |
| start\_contest\_time | RELTIME | yes       | no        | CCS        | contest relative time when judgement started                    |
| end\_time            | TIME    | yes       | yes       | CCS        | absolute time when judgement completed                          |
| end\_contest\_time   | RELTIME | yes       | yes       | CCS        | contest relative time when judgement completed                  |
| max\_run\_time       | decimal | no        | yes       | CCS        | maximum run time in seconds for any test case                   |

When a judgement is started, each of `judgement_type_id`, `end_time` and
`end_contest_time` will be `null` (or missing). These are set when the
judgement is completed.

#### Access restrictions at WF

For clients with the `public` role, judgements will not be included
for submissions received while the scoreboard is frozen. This means that
all judgements for submissions received before the scoreboard has been
frozen will be sent immediately, and all judgements for submissions
received after the scoreboard has been frozen will be sent immediately
after the scoreboard has been thawed.

#### Example

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

| Endpoint                   | Mime-type        | Required? | Source @WF | Description                                                             |
| -------------------------- | ---------------- | --------- | ---------- | ----------------------------------------------------------------------- |
| `/contests/<id>/runs`      | application/json | yes       | CCS        | JSON array of all runs with elements as defined in the table below      |
| `/contests/<id>/runs/<id>` | application/json | yes       | CCS        | JSON object of a single run with elements as defined in the table below |

JSON elements of run objects:

| Name                | Type    | Required? | Nullable? | Source @WF | Description                                                                                                                                                                                 |
| ------------------- | ------- | --------- | --------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| id                  | ID      | yes       | no        | CCS        | identifier of the run                                                                                                                                                                       |
| judgement\_id       | ID      | yes       | no        | CCS        | identifier of the [ judgement](#judgements) this is part of                                                                                                                      |
| ordinal             | ORDINAL | yes       | no        | CCS        | ordering of runs in the judgement. Must be different for every run in a judgement. Runs for the same test case must have the same ordinal. Must be between 1 and `problem:test_data_count`. |
| judgement\_type\_id | ID      | yes       | no        | CCS        | the [ verdict](#judgement-types) of this judgement (i.e. a judgement type)                                                                                                       |
| time                | TIME    | yes       | no        | CCS        | absolute time when run completed                                                                                                                                                            |
| contest\_time       | RELTIME | yes       | no        | CCS        | contest relative time when run completed                                                                                                                                                    |
| run\_time           | decimal | no        | no        | CCS        | run time in seconds                                                                                                                                                                         |

#### Access restrictions at WF

For clients with the `public` role, runs will not be included for
submissions received while the scoreboard is frozen. This means that all
runs for submissions received before the scoreboard has been frozen will
be sent immediately, and all runs for submissions received after the
scoreboard has been frozen will be sent immediately after the scoreboard
has been thawed.

#### Example

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

| Endpoint                             | Mime-type        | Required? | Source @WF | Description                                                                               |
| ------------------------------------ | ---------------- | --------- | ---------- | ----------------------------------------------------------------------------------------- |
| `/contests/<id>/clarifications`      | application/json | yes       | CCS        | JSON array of all clarification messages with elements as defined in the table below      |
| `/contests/<id>/clarifications/<id>` | application/json | yes       | CCS        | JSON object of a single clarification message with elements as defined in the table below |

JSON elements of clarification message objects:

| Name           | Type    | Required? | Nullable? | Source @WF | Description                                                                                                                   |
| -------------- | ------- | --------- | --------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| id             | ID      | yes       | no        | CCS        | identifier of the clarification                                                                                               |
| from\_team\_id | ID      | yes       | yes       | CCS        | identifier of [ team](#teams) sending this clarification request, `null` if a clarification sent by jury           |
| to\_team\_id   | ID      | yes       | yes       | CCS        | identifier of the [ team](#teams) receiving this reply, `null` if a reply to all teams or a request sent by a team |
| reply\_to\_id  | ID      | yes       | yes       | CCS        | identifier of clarification this is in response to, otherwise `null`                                                          |
| problem\_id    | ID      | yes       | yes       | CCS        | identifier of associated [ problem](#problems), `null` if not associated to a problem                              |
| text           | string  | yes       | no        | CCS        | question or reply text                                                                                                        |
| time           | TIME    | yes       | no        | CCS        | time of the question/reply                                                                                                    |
| contest\_time  | RELTIME | yes       | no        | CCS        | contest time of the question/reply                                                                                            |

Note that at least one of `from_team_id` and `to_team_id` has to be
`null`. That is, teams cannot send messages to other teams.

#### Access restrictions at WF

Clients with the `public` role can only view clarifications replies
from the jury to all teams, that is, messages where both `from_team_id`
and `to_team_id` are `null`. Clients with the `team` role can only view
their own clarifications (sent or received) and public clarifications.

#### POST clarifications

To add a clarification one can use the `POST` method on the clarifications endpoint.
The `POST` must include a valid JSON object with the same attributes the clarification
endpoint returns with a `GET` request with the following exceptions:

* When an attribute value would be null it is optional - you do not need to include it.
  e.g. if a clarification is not related to a problem you can chose to include or
  exclude the `problem_id`.
* When submitting using a `team` role, `id`, `to_team_id`, `time`, and
  `contest_time` must not be provided. `from_team_id` may be provided but then
  must match the ID of the team associated with the request. The server will determine
  an `id` and the current `time` and `contest_time`.
* When submitting using an `admin` role, `id`, `time`, and `contest_time` may be
  required to either be absent or present depending on the use case, e.g.
  whether the server is the CCS, is acting as a proxy, or a caching
  proxy. See notes under the submission interface for more detail. In cases where
  these attributes are not allowed the server will respond with a 400 error code.

The request must fail with a 400 error code if any of the following happens:

* A required attribute is missing.
* An attribute that must not be provided is provided.
* The supplied problem, from_team, to_team, or reply_to cannot be found or are not
  visible to the role that's submitting.
* The provided `id` already exists or is otherwise not acceptable.

The response will be the ID of the newly added clarification.

Performing a `POST` by any roles other than `admin` and `team` is not supported.

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

Request:

` POST https://example.com/api/contests/wf14/clarifications`

Request data:

```json
{
   "problem_id": "10-asteroids",
   "from_team_id": "34",
   "text": "Can I assume the asteroids are round?"
}
```

Returned data:

```json
"187"
```
### Awards

Awards such as medals, first to solve, etc.

The following endpoints are associated with awards:

| Endpoint                     | Mime-type        | Required? | Source @WF | Description                                                               |
| ---------------------------- | ---------------- | --------- | ---------- | ------------------------------------------------------------------------- |
| `/contests/<id>/awards`      | application/json | no        | CCS        | JSON array of all awards with elements as defined in the table below      |
| `/contests/<id>/awards/<id>` | application/json | no        | CCS        | JSON object of a single award with elements as defined in the table below |

JSON elements of award objects:

| Name      | Type        | Required? | Nullable? | Source @WF | Description                                                                                                                                              |
| --------- | ----------- | --------- | --------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| id        | ID          | yes       | no        | CCS        | identifier of the award.                                                                                                                                 |
| citation  | string      | yes       | no        | CCS        | award citation, e.g. "Gold medal winner"                                                                                                                 |
| team\_ids | array of ID | yes       | no        | CCS        | JSON array of [ team](#teams) ids receiving this award. No meaning must be implied or inferred from the order of IDs. The array may be empty. |

#### Access restrictions at WF

For clients with the `public` role, awards will not include
information from judgements of submissions received after the scoreboard
freeze until it has been unfrozen.

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

For some common award cases the following IDs should be used.

| ID                        | Meaning during contest                                                                                                     | Meaning when contest is final     | Comment                                                                 |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------- | --------------------------------- | ----------------------------------------------------------------------- |
| winner                    | Current leader(s). Empty if no team has scored.                                                                            | Winner(s) of the contest          |                                                                         |
| gold-medal                | Teams currently placed to receive a gold medal. Empty if no team has scored.                                               | Teams being awarded gold medals   |                                                                         |
| silver-medal              | Teams currently placed to receive a silver medal. Empty if no team has scored.                                             | Teams being awarded silver medals |                                                                         |
| bronze-medal              | Teams currently placed to receive a bronze medal, assuming no extra bronze are awarded. Empty if no team has scored.       | Teams being awarded bronze medals |                                                                         |
| first-to-solve-\<id>      | The team(s), if any, that was first to solve problem \<id>. This implies that no unjudged submission made earlier remains. | Same.                             | Must never change once set, except if there are rejudgements.           |
| group-winner-\<id>        | Current leader(s) in group \<id>. Empty if no team has scored.                                                             | Winner(s) of group \<id>          |                                                                         |
| organization-winner-\<id> | Current leader(s) of organization \<id>. Empty if no team has scored.                                                      | Winner(s) of organization \<id>   | Not useful in contest with only one team per organization (e.g. the WF) |

#### Example

Request:

` GET https://example.com/api/contests/wf14/awards`

Returned data:

```json
[{"id":"gold-medal","citation":"Gold medal winner","team_ids":["54","23","1","45"]},
 {"id":"first-to-solve-a","citation":"First to solve problem A","team_ids":["45"]},
 {"id":"first-to-solve-b","citation":"First to solve problem B","team_ids":[]}
]
```

### Commentary

Commentary on events happening in the contest

The following endpoints are associated with commentary:

| Endpoint                         | Mime-type        | Required? | Source @WF | Description                                                                    |
| -------------------------------- | ---------------- | --------- | ---------- | ------------------------------------------------------------------------------ |
| `/contests/<id>/commentary`      | application/json | no        | not used   | JSON array of all commentary with elements as defined in the table below       |
| `/contests/<id>/commentary/<id>` | application/json | no        | not used   | JSON object of a single commentary with elements as defined in the table below |

JSON elements of award objects:

| Name          | Type        | Required? | Nullable? | Source @WF | Description |
| ------------- | ----------- | --------- | --------- | ---------- | ----------- |
| id            | ID          | yes       | no        | not used   | identifier of the commentary. |
| time          | TIME        | yes       | no        | not used   | time of the commentary message. |
| contest\_time | RELTIME     | yes       | no        | not used   | contest time of the commentary message. |  
| message       | string      | yes       | no        | not used   | commentary message text. May contain special tags for [teams](#teams) and [problems](#problems) on the format `#t<team ID>` and `#p<problem ID>` respectively.|
| team\_ids     | array of ID | yes       | yes       | not used   | JSON array of [team](#teams) IDs the message is related to.
| problem\_ids  | array of ID | yes       | yes       | not used   | JSON array of [problem](#problems) IDs the message is related to.

#### Example

Request:

` GET https://example.com/api/contests/wf14/commentary`

Returned data:

```json
[{"id":"143730", "time":"2021-03-06T19:02:02.328+00", "contest_time":"0:02:02.328", "message": "#t20 made a submission for #panttyping. If correct, they will solve the first problem and take the lead", "team_ids": ["314089"], "problem_ids": ["anttyping"]}, 
 {"id": "143736", "time": "2021-03-06T19:02:10.858+00", "contest_time": "0:02:10.858", "message": "#t20 fails its first attempt on #panttyping due to WA", "team_ids": ["314089"], "problem_ids": ["anttyping"]}, 
 {"id": "143764", "time": "2021-03-06T19:03:07.517+00", "contest_time": "0:03:07.517", "message": "#t24 made a submission for #pmarch6. If correct, they will solve the first problem and take the lead", "team_ids": ["314115"], "problem_ids": ["magictrick"]}
]
```

### Scoreboard

Scoreboard of the contest.

Since this is generated data, only the `GET` method is allowed here,
irrespective of role.

The following endpoint is associated with the scoreboard:

| Endpoint                    | Mime-type        | Required? | Source @WF | Description                                                    |
| --------------------------- | ---------------- | --------- | ---------- | -------------------------------------------------------------- |
| `/contests/<id>/scoreboard` | application/json | yes       | CCS        | JSON object with scoreboard data as defined in the table below |

#### Scoreboard request options

The following options can be passed to the scoreboard endpoint.

##### Scoreboard at the time of a given event

By passing an [ event](#event-feed---draft) ID with the
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

| Name          | Type                       | Required? | Nullable? | Source @WF | Description                                                                                                                                                              |
| ------------- | -------------------------- | --------- | --------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| event\_id     | ID                         | yes       | no        | CCS        | Identifier of the [ event](#event_feed) after which this scoreboard was generated. This must be identical to the argument `after_event_id`, if specified.     |
| time          | TIME                       | yes       | no        | CCS        | Time contained in the associated event. Implementation defined if the event has no associated time.                                                                      |
| contest\_time | RELTIME                    | yes       | no        | CCS        | Contest time contained in the associated event. Implementation defined if the event has no associated contest time.                                                      |
| state         | object                     | yes       | no        | CCS        | Identical data as returned by the [ contest state](#contest-state) endpoint. This is provided here for ease of use and to guarantee the data is synchronized. |
| rows          | JSON array of JSON objects | yes       | no        | CCS        | A list of rows of team with their associated scores.                                                                                                                     |

The scoreboard `rows` array is sorted according to rank and alphabetical
on team name within identically ranked teams. Here alphabetical ordering
means according to the [Unicode Collation
Algorithm](https://www.unicode.org/reports/tr10/), by default using the
`en-US` locale.

Each JSON object in the rows array consists of:

| Name              | Type             | Required? | Nullable? | Source @WF | Description                                                                                  |
| ----------------- | ---------------- | --------- | --------- | ---------- | -------------------------------------------------------------------------------------------- |
| rank              | integer          | yes       | no        | CCS        | rank of this team, 1-based and duplicate in case of ties                                     |
| team\_id          | ID               | yes       | no        | CCS        | identifier of the [ team](#teams)                                                 |
| score             | object           | yes       | no        | CCS        | JSON object as specified in the rows below (for possible extension to other scoring methods) |
| score.num\_solved | integer          | yes       | no        | CCS        | number of problems solved by the team                                                        |
| score.total\_time | integer          | yes       | no        | CCS        | total penalty time accrued by the team                                                       |
| problems          | array of objects | yes       | no        | CCS        | JSON array of problems with scoring data, see below for the specification of each element    |

Each problem object within the scoreboard consists of:

| Name         | Type    | Required? | Nullable? | Source @WF | Description                                                                                   |
| ------------ | ------- | --------- | --------- | ---------- | --------------------------------------------------------------------------------------------- |
| problem\_id  | ID      | yes       | no        | CCS        | identifier of the [ problem](#problems)                                            |
| num\_judged  | integer | yes       | no        | CCS        | number of judged submissions (up to and including the first correct one)                      |
| num\_pending | integer | yes       | no        | CCS        | number of pending submissions (either queued or due to freeze)                                |
| solved       | boolean | yes       | no        | CCS        | whether the team solved this problem                                                          |
| time         | integer | depends   | no        | CCS        | minutes into the contest when this problem was solved by the team. Required iff `solved=true` |

#### Access restrictions at WF

For clients with the `public` role, the scoreboard will not include
information from judgements of submissions received after the scoreboard
has been frozen until it has been thawed.

#### Example

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

### Event feed - DRAFT

Provides the event (notification) feed for the current contest. This is
effectively a changelog of create, update, or delete events that have
occurred in the REST endpoints. Some endpoints (specifically the [
Scoreboard](#scoreboard) and the Event feed itself) are
aggregated data, and so these will only ever update due to some other
REST endpoint updating. For this reason there is no explicit event for
these, since there will always be another event sent. This can also be
seen by the fact that there is no scoreboard event in the table of
events below.

Every notification provides the current state of a single contest
object. There is no guarantee on order of events (except for general
requirements below), whether two consecutive changes cause one or two
events, duplicate events, or even that different clients will receive
the same order or set of events. The only guarantee is that when an
object changes one or more times you'll receive an event, and the latest
event received for any object is the correct and current state of that
object (e.g. if an object was created and deleted you'll always receive
a delete event last).

As a concrete example, judgement events are usually fired when judging
is started, and fired again when the final judgement is available. If a
client connects after the judgement, or a client was disconnected during
the judgement, they will typically only receive the final (complete)
judgement.

There are two mechanisms that clients can use to receive events: a
webhook, or a streaming HTTP feed. Both mechanisms have the same format
(payload) and events, but different benefits, drawbacks, and ways to
register. Webhooks are better for internet-scale, asynchronous
processing, and disconnected systems; the HTTP feed is better for
browser-based applications and onsite contests.

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
    never been frozen), and been finalized, no event may come after the
    state event showing that.

#### Feed format

The feed is served as JSON objects, with every event corresponding to a
change in a single object (submission, judgement, language, team, etc.)
or full endpoint. The general format for events is:

```json
{"contest_id": "<id>", "endpoint": "<endpoint>", "id": "<id>", "data": <JSON data for element> }
```

| Name        | Type   | Required? | Nullable? | Description                                                                                                                                |
| ----------- | ------ | --------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| contest\_id | string | yes       | no        | The contest id.                                                                                                                            |
| endpoint    | string | yes       | yes       | The API endpoint, i.e. type of contest object above. Can be used for filtering                                                             |
| id          | string | yes       | yes       | The id of the object that changed                                                                                                          |
| data        | object | yes       | yes       | The data is the object that would be returned if calling the corresponding API endpoint at this time, i.e. an object or null for deletions |

##### Filtering

TODO - filter by contest id and/or endpoint

##### Examples

The following are examples of contest events:

```json
{"contest_id":"finals","endpoint":"problems","id":null,"data":[
   {"id":"asteroids","label":"A","name":"Asteroid Rangers","ordinal":1,"color":"blue","rgb":"#00f","time_limit":2,"test_data_count":10},
   {"id":"bottles","label":"B","name":"Curvy Little Bottles","ordinal":2,"color":"gray","rgb":"#808080","time_limit":3.5,"test_data_count":15}]}
```

```json
{"contest_id":"finals","endpoint":"state","id":null,"data":{
   "started": "2014-06-25T10:00:00+01",
   "ended": null,
   "frozen": "2014-06-25T14:00:00+01",
   "thawed": null,
   "finalized": null,
   "end_of_updates": null}}
```

```json
{"contest_id":"finals","endpoint":"teams","id":"11","data":{"id":"11","icpc_id":"201433","name":"Shanghai Tigers","organization_id":"inst123","group_id":"asia"}}
```

```json
{"contest_id":"finals","endpoint":"teams","id":"11","data":{"id":"11","icpc_id":"201433","name":"The Shanghai Tigers","organization_id":"inst123","group_id":"asia"}}
```

```json
{"contest_id":"finals","endpoint":"teams","id":"11","data":null}
```

TODO: data is object or array - is that too ugly?

#### Webhook

A webhook allows you to receive HTTP callbacks whenever there is a
change to the contest. Clients are only notified of future changes; they
are expected to use other mechanisms if they need to determine the
current state of the contest. Every callback will contain one JSON
object as specified above.

Responding to each event with a 2xx response code indicates successful
receipt and ensures that the events in the payload are never sent again.
If the client responds with anything other than 2xx, the server will
continue to periodically try again, potentially with different payloads
(e.g. as new events accumulate). Callbacks to each client are always
sent synchronously and in order; clients do not need to worry about
getting callbacks out of order and should always process each callback
fully before processing the next one.

If the client fails to respond to multiple requests over a period of
time (configured for each contest), it will be assumed deactivated and
automatically removed from future callbacks.

The following endpoint is associated with the webhook:

| Endpoint   | Mime-type        | Required? | Source @WF | Description                            |
| ---------- | ---------------- | --------- | ---------- | -------------------------------------- |
| `/webhook` | application/json | yes       | CCS        | List or register for webhook callbacks |

JSON elements of webhook objects:

| Name | Type   | Required? | Nullable? | Description           |
| ---- | ------ | --------- | --------- | --------------------- |
| url  | string | yes       | no        | The url for callbacks |

TODO: include filter details?

##### Adding a webhook

To register a webhook, you need to post your server's callback url. The
general format to register a webhook is:

```json
{"url": "<callback url>", "auth": ... }
```

| Name | Type   | Required? | Nullable? | Description           |
| ---- | ------ | --------- | --------- | --------------------- |
| url  | string | yes       | no        | The url for callbacks |
| auth | string | yes       | no        | TODO                  |

##### Example

Request:

` POST https://example.com/api/webhook`

Payload:

```json
{"url": "https://myurl", "auth": ... }
```

Request:

` GET https://example.com/api/webhook`

Returned data:

```json
[{"url":"https://myurl"},{"url":"https://myotherurl"}]
```

Future payload posted to url:

` POST https://myurl`

Payload:

```json
{"contest_id":"finals","endpoint":"teams","id":"11","data":{"id":"11","icpc_id":"201433","name":"The Shanghai Tigers","organization_id":"inst123","group_id":"asia"}}
```

#### HTTP Feed

The HTTP event feed is a streaming HTTP endpoint that allows connected
clients to receive contest events. The feed is a complete log of contest
objects that starts 'at the beginning of time' so all existing objects
will be sent upon initial connection, but apart from referential
integrity requirements they may appear in any order (e.g. teams or
problems first).

Each line is an NDJSON formatted contest event as specified above. The
feed does not terminate under normal circumstances, so to ensure keep
alive a newline must be sent if there has been no event within 120
seconds.

Since this is generated data, only the `GET` method is allowed here,
irrespective of role.

The following endpoint is associated with the event feed:

| Endpoint                    | Mime-type            | Required? | Source @WF | Description                            |
| --------------------------- | -------------------- | --------- | ---------- | -------------------------------------- |
| `/contests/<id>/event-feed` | application/x-ndjson | yes       | CCS        | NDJSON feed of events as defined below |

##### Reconnection

If a client loses connection or needs to reconnect after a brief
disconnect (e.g. client restart), it can use the 'time' argument to
specify the last event it received:

`/event-feed?time=xx`

If specified, the server will attempt to start sending events around the
given time to reduce the volume of events and required reconciliation.
If the time passed is too large or the server does not support this
attribute, all objects will be sent. There is no guarantee that all
updates (e.g. a team name correction, which is not time-based) that
occurred during the time the client was disconnected will be reflected.
