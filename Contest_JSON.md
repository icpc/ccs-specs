---
sort: 2
permalink: /contest_model
---
# Contest JSON

## Introduction (copy)

This page describes several JSON objects that can be used for communicating 
contest information to or from a 
[Contest Control System](ccs_system_requirements) (CCS) or 
[Contest Data Server](https://tools.icpc.global/cds/), or other contest-related
tools.

- an external scoreboard
- a scoreboard resolver application
- contest analysis software, such as the ICAT toolset
- another "shadow" CCS, providing forwarding of submissions and all relevant
  information
- internally, to interface between the CCS server and judging instances

This API is meant to be useful, not only at the ICPC World Finals, but more
generally in any ICPC-style contest setup. It is meant to incorporate and
supersede a number of deprecated or obsolete specifications amongst which the
*JSON Scoreboard*, the *REST interface for source code fetching* and the
*Contest start interface*.

This REST interface is specified in conjunction with a new
[NDJSON event feed](#event-feed), which provides all changes to this
interface as CRUD-style events and is meant to supersede the old XML
*Event Feed*.

## General design principles (copy)

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in
[RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

The interface is implemented as a HTTP REST interface that outputs
information in [JSON](https://en.wikipedia.org/wiki/JSON) format
([RFC 7159](https://tools.ietf.org/html/rfc7159)). All access to the API
must be provided over HTTPS to guard against eavesdropping on
sensitive contest data and [authentication](#authentication) credentials.

### Referential integrity (copy)

Some properties in an object are references to IDs of other objects.
When such a property has a non-`null` value, then the referenced
object must exist. That is, the full set of data exposed by the API
must at all times be referentially intact. This implies for example that
before creating a [team](#teams) with an `organization_id`,
the [organization](#organizations) must already exist. In
reverse, that organization can only be deleted after the team is
deleted, or alternatively, the team's `organization_id` is set to
`null`.

Furthermore, the ID property (see below) of objects are not allowed to
change. However, note that a particular ID might be reused by first
deleting an object and then creating a new object with the same ID.

### JSON property types

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
- Identifiers (type **`ID`** in the specification) are given as string
  consisting of characters `[a-zA-Z0-9_.-]` of length at most 36 and not
  starting with a `-` (dash) or `.` (dot) or ending with a `.` (dot). IDs are
  unique within each endpoint. IDs are assigned by the person or system that is
  the source of the object, and must be maintained by downstream systems. For
  example, the person configuring a contest on disk will typically define the
  ID for each team, and any CCS or CDS that exposes the team must use the same
  ID. Some IDs are also used as identifiable labels and are marked below along
  with the recommended format. These IDs should be meaningful for human
  communication (e.g. team "43", problem "A") and are as short as reasonable
  but not more than 10 characters. IDs not marked as labels may be random
  characters and cannot be assumed to be suitable for display purposes.
- File references (type **`FILE`** in the specification) are represented as a
  JSON object with properties as defined below.
- Arrays (type **`array of <type>`** in the specification) are built-in JSON
  arrays of some type defined above.
- Nullable types (type **`<type> ?`** in the specification) are either a value
  of a type defined above, or `null`.

Properties for file reference objects:

| Name     | Type      | Description
| -------- | --------- | -----------
| href     | string ?  | URL where the resource can be found. Relative URLs are relative to the `baseurl`. Must point to a file of intended mime-type. Resource must be accessible using the exact same (possibly none) authentication as the call that returned this data.
| filename | string    | POSIX compliant filename. Filenames must be unique within the endpoint object where they are used. I.e. an organization can have (multiple) `logo` and `country_flag` file references, they must all have a different filename, but different organizations may have files with the same filename.
| hash     | string ?  | MD5 hash of the file referenced.
| mime     | string    | Mime type of resource.
| width    | integer ? | Width of the image. Required for files with mime type image/*.
| height   | integer ? | Height of the image. Required for files with mime type image/*.

The `href` property may be an [absolute or relative
URL](https://tools.ietf.org/html/rfc3986); relative URLs must be
interpreted relative to the `baseurl` of the API. For example, if
`baseurl` is <https://example.com/api>, then the following are
equivalent JSON response snippets pointing to the same location:

```json
  "href":"https://example.com/api/contests/wf14/submissions/187/files"
  "href":"contests/wf14/submissions/187/files"
```

For images, the supported mime types are image/png, image/jpeg, and image/svg+xml.

For images in SVG format, i.e. those having a mime type of image/svg+xml,
the values of `width` and `height` should be the viewport width and height in pixels
when possible, but otherwise the actual values don't matter as long as they
are positive and represent the correct aspect ratio.

If implementing support for uploading files pointed to by resource
links, substitute the href property with a data property with a base64
encoded string of the associated file contents as the value.

For example

`   PUT https://example.com/api/contests/wf14/organizations/inst105`

with JSON data

```json
{ "id":"inst105",
  "name":"Carnegie Mellon University",
  ...
  "logo": [{"data": "<base64 string>", "width": 160, "height": 160}]
}
```

### Capabilities (copy)

The API specifies several
capabilities that define behaviors that clients can expect and
actions they can perform. For instance, a team account will typically
have access to a "team_submit" capability that allows a team to perform
POST operations on the submissions endpoint, but doesn't allow it to
set the submission id or timestamp; an administrator may have access
to a "contest_start" capability that allows it to PATCH the start
time of the contest. These coarse-grained capabilities allow more
flexibility for contest administrators and tools to define capabilities
that match the requirements of a specific contest, e.g. whether teams
can submit clarifications or not.

All capabilities are listed in the table below, and are defined
inline with each endpoint. Clients can use
the [Access](#access) endpoint to see which capabilities they have
access to.

| Capability                                | Description
| :---------------------------------------- | :----------
| [contest_start](#modifying-contests)      | Control the contest's start time
| [team_submit](#modifying-submissions)     | Submit as a team
| [team_clar](#modifying-clarifications)    | Submit clarifications as a team
| [proxy_submit](#modifying-submissions)    | Submit as a shared team proxy
| [proxy_clar](#modifying-clarifications)   | Submit clarifications as a shared team proxy
| [admin_submit](#modifying-submissions)    | Submit as an admin
| [admin_clar](#modifying-clarifications)   | Submit clarifications as an admin

TODO - add capabilities related to team view, awards, and freeze time.