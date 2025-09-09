---
sort: 2
permalink: /contest_api
---
# Contest API

## Introduction

This page describes an API for accessing information provided by a
[Contest Control System](ccs_system_requirements) (CCS) or
[Contest Data Server](https://tools.icpc.global/cds/).
Such an API can be used by a multitude of clients:

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

## General design principles

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in
[RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

The interface is implemented as a HTTP REST interface that outputs
information in [JSON](https://en.wikipedia.org/wiki/JSON) format
([RFC 7159](https://datatracker.ietf.org/doc/html/rfc7159)). All access to the API
must be provided over HTTPS to guard against eavesdropping on
sensitive contest data and [authentication](#authentication) credentials.

### Endpoint URLs

The specific base URL of this API will be dependent on the server (e.g.
main CCS or CDS) providing the service; in the specification we only
indicate the relative paths of API endpoints with respect to a
**baseurl**. In all the examples below the baseurl is
<https://example.com/api/>.

The baseurl must end in a slash so that relative URLs are resolved
correctly. If `baseurl` is <https://example.com/api/foobar>, then
per [RFC 3986](https://tools.ietf.org/html/rfc3986) the relative URL
`contests/wf14` resolves to `https://example.com/api/contests/wf14`,
*just* as it would with `baseurl` set to <https://example.com/api/>.
Below, any extra `/` between `baseurl` and the subsequent path is just
for clarity.

We follow standard REST practices so that a whole collection can be
requested, e.g. at the URL path

` GET https://example.com/api/contests/wf14/teams`

while an object with a specific ID is requested as

` GET https://example.com/api/contests/wf14/teams/10`

A collection is always returned as an array of JSON objects. Every item
in the array is a single object (and always includes the ID).
When requesting a single object the exact same object is returned. E.g.
the URL path

`GET baseurl/collection`

returns

```json
[ { "id":<id1>, <other properties for object id1> },
  { "id":<id2>, <other properties for object id2> },
     ...
]
```

while the URL path

`GET baseurl/<collection>/<id1>`

returns

```json
{ "id":<id1>, <other properties for object id1> }
```

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
below (see e.g. [PATCH start\_time](#modifying-contests)). However,
for future compatibility below are already listed other methods with
their expected behavior, if implemented.

- `GET`
  Read data. This method is idempotent and does not modify any data. It can be
  used to request a whole collection or a specific object.

- `POST`
  Create a new object. This can only be called on a collection endpoint, and
  the `id` property may not be specified as it is up to the server to assign
  one. If successful the response will contain a `Location` header pointing
  to the newly created object.

- `PUT`
  Creates or replaces a specific object. This method is idempotent, can only
  be called on a specific object, and replaces its contents with the data
  provided. The payload data must be complete, i.e. the `id` is required and
  no partial updates are allowed.

- `PATCH`
  Updates/modifies a specific object. This method is idempotent, can only be
  called on a specific object, and replaces the given properties with the
  data provided. For example
  `PATCH https://example.com/api/contests/wf14/teams/10` with JSON contents
  `{"name":"Our cool new team name"}`.

- `DELETE`
  Delete a specific object. Idempotent, but will return a `404` error code
  when repeated. Any provided data is ignored, and there is no response body
  if successful. Example:
  `DELETE https://example.com/api/contests/wf14/teams/8`. Note that deletes
  must keep [referential integrity](#referential-integrity) intact.

#### Success, Failure, and HTTP Responses

Standard [HTTP status codes](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes) are
returned to indicate success or failure. If successful DELETE will have no response body,
GET on a collection will return the collection, and every other method will contain the
current (updated) state of the object.

If a POST, PUT, PATCH would cause any of the following issues it must fail, in addition to any endpoint or type-specific requirements:

- A PATCH on an `id` that doesn't exist. Will return a 404 error code.
- A PUT or PATCH containing an id that does not match the URL. Will return a 409
  error code.
- A required property is missing.
- A property that must not be provided is provided.
- A property type that is incorrect or otherwise invalid (e.g. non-nullable
  property set to null).
- A reference to another object is invalid (to maintain
  [referential integrity](#referential-integrity)).

In addition to any endpoint or object-specific requirements, DELETE must fail if
the object `id` doesn't exist, and return a 404 error code. If the object being
deleted is referenced by another object, the server must either fail or
implement a cascading delete (to maintain
[referential integrity](#referential-integrity))

When there is a failure using any method the response message body must include
a JSON object that contains the properties 'code' (a number, identical to the
HTTP status code returned) and 'message' (a string) with further information
suitable for the client making the request, as per the following example:

```json
{"code":403,
 "message":"Teams cannot send clarifications to another team"}
 ```

### Authentication

The API provider may allow unauthenticated access to information
that is fully public, i.e. that may be visible to everyone including
spectators and teams. If provided this must be read-only access
(no `POST`, `PUT`, `PATCH` or `DELETE` methods allowed).

All other access to the API must be controlled via
authenticated accounts. The API provider must support [HTTP basic
authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
([RFC](https://datatracker.ietf.org/doc/html/rfc7617)). This provides a standard
and flexible method; besides HTTP basic auth, other forms of
authentication can be offered as well.

Depending on the client account's access, the API provider may completely
hide some objects from the client, may omit certain properties, or may embargo or
omit objects based on the current state of the contest.

### Referential integrity

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
- Identifiers (type **`ID`** in the specification) are given as strings
  consisting of characters `[a-zA-Z0-9_.-]` of length at most 36 and not
  starting with a `-` (dash) or `.` (dot) or ending with a `.` (dot). IDs are
  unique within each endpoint. IDs are assigned by the person or system that is
  the source of the object, and must be maintained by downstream systems. For
  example, the person configuring a contest on disk will typically define the
  ID for each team, and any CCS or CDS that exposes the team must use the same
  ID.
- Geographic locations (type **`LOCATION`** in the specification) are
  represented as a JSON object with properties as defined below.
- File references (type **`FILE`** in the specification) are represented as a
  JSON object with properties as defined below.
- Arrays (type **`array of <type>`** in the specification) are built-in JSON
  arrays of some type defined above.
- Nullable types (type **`<type> ?`** in the specification) are either a value
  of a type defined above, or `null`.

Properties for geographic location objects:

| Name      | Type      | Description
| --------- | --------- | -----------
| latitude  | number    | Latitude in degrees with value between -90 and 90.
| longitude | number    | Longitude in degrees with value between -180 and 180.

Properties for file reference objects:

| Name     | Type      | Description
| -------- | --------- | -----------
| href     | string    | URL where the resource can be found. Relative URLs are relative to the `baseurl`. Must point to a file of intended mime-type. Resource must be accessible using the exact same (possibly none) authentication as the call that returned this data. (Note: this is actually optional inside a [Contest Package](contest_package)).
| filename | string    | POSIX compliant filename. Filenames must be unique within the endpoint object where they are used. I.e. an organization can have (multiple) `logo` and `country_flag` file references, they must all have a different filename, but different organizations may have files with the same filename.
| hash     | string ?  | MD5 hash of the file referenced.
| mime     | string    | Mime type of resource.
| width    | integer ? | Width of the image. Required for files with mime type image/\*.
| height   | integer ? | Height of the image. Required for files with mime type image/\*.

The `href` property may be an [absolute or relative
URL](https://datatracker.ietf.org/doc/html/rfc3986); relative URLs must be
interpreted relative to the `baseurl` of the API. For example, if
`baseurl` is <https://example.com/api/>, then the following are
equivalent JSON response snippets pointing to the same location:

```json
  "href":"https://example.com/api/contests/wf14/submissions/187/files"
  "href":"contests/wf14/submissions/187/files"
  "href":"/api/contests/wf14/submissions/187/files"
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

### Capabilities

The API specifies several
capabilities that define behaviors that clients can expect and
actions they can perform. For instance, a team account will typically
have access to a "team\_submit" capability that allows a team to perform
POST operations on the submissions endpoint, but doesn't allow it to
set the submission id or timestamp; an administrator may have access
to a "contest\_start" capability that allows it to PATCH the start
time of the contest. These coarse-grained capabilities allow more
flexibility for contest administrators and tools to define capabilities
that match the requirements of a specific contest, e.g. whether teams
can submit clarifications or not.

All capabilities are listed in the table below, and are defined
inline with each endpoint. Clients can use
the [Access](#access) endpoint to see which capabilities they have
access to.

| Capability                                 | Description
| :----------------------------------------- | :----------
| [contest\_start](#modifying-contests)      | Control the contest's start time
| [contest\_thaw](#modifying-contests)       | Control the contest's thaw time
| [team\_submit](#modifying-submissions)     | Submit as a team
| [post\_clar](#modifying-clarifications)    | Submit clarifications
| [post\_comment](#modifying-commentary)     | Submit commentary
| [proxy\_submit](#modifying-submissions)    | Submit as a shared team proxy
| [proxy\_clar](#modifying-clarifications)   | Submit clarifications as a shared team proxy
| [admin\_submit](#modifying-submissions)    | Submit as an admin
| [admin\_clar](#modifying-clarifications)   | Submit clarifications as an admin

*Warning*: these capabilities are not well tested yet in practice and
might change in a backwards-incompatible way in next versions of this
specification.

### Notification format

There are two mechanisms that clients can use to receive notifications
of API updates (events): a webhook and a streaming HTTP feed. Both
mechanisms use the same payload format, but have different benefits,
drawbacks, and ways to access. Webhooks are typically better for
internet-scale, asynchronous processing, and disconnected systems; the
HTTP feed, on the other hand, might be better for browser-based
applications and onsite contests.

The notifications are effectively a changelog of create, update, or
delete events that have occurred in the REST endpoints. Some endpoints
(specifically the [Scoreboard](#scoreboard) and the Event feed)
are aggregated data, and so these will only ever update due to some
other REST endpoint updating. For this reason there is no explicit event
for these, since there will always be another event sent.

The events are served as JSON objects, with every event corresponding to
a change in a single object (submission, judgement, language, team,
etc.) or entire collection. The general format for events is:

```json
{"type": "<type>", "id": "<id>", "data": <JSON data for object> }
```

| Name        | Type              | Description
| :---------- | :---------------- | :----------
| type        | string            | The type of contest object that changed. Can be used for filtering.
| id          | ID ?              | The id of the object that changed, or null for the entire collection/singleton.
| data        | array or object ? | The updated value, i.e. what would be returned if calling the corresponding API endpoint at this time: an array, object, or null for deletions.
| token       | string ?          | An optional token used to identify this notification. For one use see event feed [Reconnection](#reconnection) below.

All event types correspond to an API endpoint, as specified in the table below.

| Type            | API Endpoint
| :-------------- | :-----------
| contest         | `contests/<id>`
| judgement-types | `contests/<id>/judgement-types/<id>`
| languages       | `contests/<id>/languages/<id>`
| problems        | `contests/<id>/problems/<id>`
| groups          | `contests/<id>/groups/<id>`
| organizations   | `contests/<id>/organizations/<id>`
| teams           | `contests/<id>/teams/<id>`
| persons         | `contests/<id>/persons/<id>`
| accounts        | `contests/<id>/accounts/<id>`
| state           | `contests/<id>/state`
| submissions     | `contests/<id>/submissions/<id>`
| judgements      | `contests/<id>/judgements/<id>`
| runs            | `contests/<id>/runs/<id>`
| clarifications  | `contests/<id>/clarifications/<id>`
| awards          | `contests/<id>/awards/<id>`
| commentary      | `contests/<id>/commentary/<id>`

Each event is a notification that an object or a collection has changed
(and hence the contents of the corresponding endpoint) to `data`.

If `type` is `contest`, then `id` must be null and the endpoint
`contests/<id>` will return the contents of `data`.

If `id` is not null, then the endpoint `contests/<contest_id>/<type>/<id>`
will return the contents of `data`.

If `id` is null, then the endpoint `contests/<contest_id>/<type>` will return
the contents of `data`.

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

Means that endpoint `contests/dress2016` has been updated to:
```json
{
   "id": "dress2016",
   "name": "2016 ICPC World Finals Dress Rehearsal",
   "start_time": null,
   "countdown_pause_time": "0:03:38.749",
   "duration": "2:30:00"
}
```

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

Means that endpoint `contests/<contest_id>/submissions/187` has been updated to:
```json
{
   "id": "187",
   "team_id": "123",
   "problem_id": "10-asteroids",
   "language_id": "1-java",
   "time": "2014-06-25T11:22:05.034+01",
   "contest_time": "1:22:05.034",
   "entry_point": "Main",
   "files": [{"href":"contests/wf14/submissions/187/files","filename":"files.zip","mime":"application/zip"}]
}
```

### Extensibility

This specification is meant to cover the basic data of contests, with
the idea that server/client implementations can extend this with more
endpoints, properties, and/or capabilities. The following requirements
are meant to ease extensibility:

- Clients should accept additional (unknown) event types in notifications.
- Clients should accept additional (unknown) properties in endpoints.
- Clients should accept additional (unknown) capabilities.
- Servers should not expect clients to recognize more than the basic, required
  specification.
- In this specification and extensions, a property with value `null` may be left
  out by the server (i.e. not be present). A client must treat a property with
  value `null` equivalently as that property not being present.

## Interface specification

The following list of API endpoints may be supported, as detailed below.
All endpoints should support `GET`; specific details on other methods
are mentioned below.

### Types of endpoints

The endpoints can be categorized into 4 types as follows:

- Metadata: api, access
- Configuration: accounts, contests, judgement-types, languages, problems,
  groups, organizations, persons, teams;
- Live data: state, submissions, judgements, runs, clarifications, awards,
  commentary;
- Aggregate data: scoreboard, event-feed.

The metadata endpoints contain data about the API, and are the only required API
endpoints. They are not included in the event feed. The access endpoint
specifies which other endpoints are offered by the API. That is, any endpoints
and their properties listed in `access` must be provided (possibly with a
`null` value when the property is optional), and only these endpoints and
properties. 

Configuration is normally set before contest start. Is not expected to,
but could occasionally be updated during a contest. It does not have
associated timestamp/contest time property. Updates are notified via
the event feed.

Live data is generated during the contest and new objects are expected.
Data is immutable though: only inserts, no updates or deletes of
objects. It does have associated timestamp/contest time property.
Inserts and deletes are notified via the event feed. **Note**:
judgements are the exception to immutability in a weak sense: they get
updated once with the final verdict, and the value for `current` may change.

Aggregate data: Only `GET` makes sense. These are not included in the
event feed, also note that these should not be considered proper REST
endpoints, and that the `event-feed` endpoint is a streaming feed in
NDJSON format.

Note that `api`, `access`, `account`, `state`, `scoreboard`, and `event-feed`
are singular nouns and indeed contain only a single object.

### Required and optional endpoints

The only required endpoints are metadata: `api` and `access`.
The only requirements for properties are that collections must have
an `id` property.
[Referential integrity](#referential-integrity) must also be kept
(for example, if a submission has a team\_id, then teams must be supported).

All other endpoints and properties are optional.
`access` exists so that you can discover which endpoints and properties
are supported by a given provider.

In practice there are different types of providers that will offer
similar sets of endpoints. Some examples:
 - A contest management system will support at least contests and
   teams, and may support other configuration endpoints.
 - A CCS will support at least submissions, judgements, and
   dependencies of these. It will likely support a scoreboard, and
   usually an event-feed.

Separate specifications (for example, the CCS System Requirements)
will provide more information on which endpoints and properties
can be expected, often in the form of a minimal `access` response.

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

Note that all results returned from endpoints:

- Must only have `null` values if the type of the property is `<type> ?`.
- Must contain all properties specified in the [Access](#access) endpoint that
  have non-`null` values.
- Should not contain any properties not specified in the [Access](#access)
  endpoint.

### Filtering

Endpoints that return a JSON array must allow filtering on any
property specified in the [Access](#access) endpoint with type `ID` or
`ID ?` (except the `id` property) by passing it as a query argument.
For example, clarifications can be filtered on the
sender by passing `from_team_id=X`. To filter on a `null` value,
pass an empty string, i.e. `from_team_id=`. It must be possible to
filter on multiple different properties simultaneously, with the
meaning that all conditions must be met (they are logically `AND`ed).
Note that filtering on any other property, including property with the type
array of ID, does not have to be supported.

### API information

Provides information about the API and the data provider.

The following endpoint is associated with API information:

| Endpoint | Mime-type        | Description
| :------- | :--------------- | :----------
| `.`      | application/json | JSON object representing information about the API with all properties defined in the table below.

Properties of version object:

| Name         | Type              | Description
| :----------- | :---------------- | :----------
| version      | string            | Version of the API. For this version must be the string `draft`. Will be of the form `<yyyy>-<mm>`, `<yyyy>-<mm>-draft`, or simply `draft`.
| version\_url | string            | Link to documentation for this version of the API.
| provider     | provider object ? | Information about the data provider

Properties of the provider object:

| Name         | Type            | Description
| :----------- | :-------------- | :----------
| name         | string          | Name of this data provider.
| version      | string ?        | Provider's application version string
| logo         | array of FILE ? | Logo for this data provider, intended to be an image with aspect ratio near 1:1. Only allowed mime types are image/\*. The different files in the array should be different file formats and/or sizes of the same image.

#### Examples

Request:

` GET https://example.com/api/`

Returned data:

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

Information on which endpoints and properties are visible to the current client, and what [capabilities](#capabilities)
this client has access to or can perform.

The following endpoint is associated with access:

| Endpoint                | Mime-type        | Description
| :---------------------- | :--------------- | :----------
| `contests/<id>/access`  | application/json | JSON object representing the current client's access with all properties defined in the table below.

Properties of access objects:

| Name         | Type                      | Description
| :----------- | :------------------------ | :----------
| capabilities | array of string           | An array of [capabilities](#capabilities) that the current client has. The array may be empty.
| endpoints    | array of endpoint objects | An array of endpoint objects that are visible to the current client, as described below. The array may be empty.

Properties of endpoint objects:

| Name         | Type            | Description
| :----------- | :-------------- | :----------
| type         | string          | The type of the endpoint, e.g. "problems". See table in [Notification format](#notification-format) for the list of types.
| properties   | array of string | An array of supported properties that the current client has visibility to. The array must not be empty. If the array would be empty, the endpoint object should instead not be included in the endpoints array.

This endpoint provides information about what is accessible to a specific
client in a live contest, and hence will not exist in a contest package.

The set of properties listed must always support 
[referential integrity](#referential-integrity), i.e. if a property with a ID 
value referring to some type of object is present the endpoint representing
that type of object (and its ID property) must also be present. E.g. if 
`group_ids` is listed among the properties in the `team` endpoint object, that
means that there must be an endpoint object with type `groups` containing at 
least `ID` in its properties.

This information is provided so that clients know what endpoints are available,
what notifications may happen, and what capabilities they have, regardless
of whether objects currently exist or the capability is currently active.
For instance, a client logged in with a team account would see the problems type and
team\_submit capability before a contest starts, even through they cannot
see any problems nor submit yet.
Clients are not expected to call this endpoint more than once
since the response should not normally change during a contest.

#### Examples

Request:

`GET https://example.com/api/contests/wf14/access`

Returned data:

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

### Contests

Provides information on the current contest.

The following endpoints are associated with contest:

| Endpoint        | Mime-type        | Description
| :-------------- | :--------------- | :----------
| `contests`      | application/json | JSON array of all contests with properties as specified by [access](#access).
| `contests/<id>` | application/json | JSON object representing a single contest with properties as specified by [access](#access).

Properties of contest objects:

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

#### Modifying contests

Clients with the `contest_start` [capability](#capabilities) have the ability to
set or clear the contest start time via a PATCH method.

The PATCH must include a valid JSON object with two or three
properties: the contest `id` (used for verification), a
`start_time` (a `<TIME>` value or `null`), and an optional
`countdown_pause_time` (`<RELTIME>`). As above, `countdown_pause_time`
can only be non-null when start time is null.

The request should fail with a 403 error code if the contest is started or within 30s of
starting, or if the new start time is in the past or within 30s.

Clients with the `contest_thaw` [capability](#capabilities) have the ability to
set a time when the contest will be thawed via a PATCH method.

The PATCH must include a valid JSON object with two properties:
the contest `id` (used for verification) and a `scoreboard_thaw_time`, a `<TIME>` value.

The request should succeed with a 204 response code with no body if the server changed the
thaw time to the time specified.

The server may also thaw the contest at the current server time if the provided `scoreboard_thaw_time`
is in the past. In that case the server must reply with a 200 response code and the modified contest
as body, so the client knows the server used a different thaw time.

The request should fail with a 403 error code if the contest can't be thawed at the given
time, for example because the thaw time is before the contest end, the contest is already thawed
or the server does not support setting this specific thaw time.

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

Request:

` GET https://example.com/api/contests/dress2016`

Returned data:

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

Request:

` PATCH https://example.com/api/contests/wf2014`

Request data:

```json
{
   "id": "wf2014",
   "scoreboard_thaw_time": "2014-06-25T19:30:00+01"
}
```

### Judgement Types

Judgement types are the possible responses from the system when judging
a submission.

The following endpoints are associated with judgement types:

| Endpoint                             | Mime-type        | Description
| :----------------------------------- | :--------------- | :----------
| `contests/<id>/judgement-types`      | application/json | JSON array of all judgement types with properties as specified by [access](#access).
| `contests/<id>/judgement-types/<id>` | application/json | JSON object representing a single judgement type with properties as specified by [access](#access).

Properties of judgement type objects:

| Name                             | Type      | Description
| :------------------------------- | :-------- | :----------
| id                               | ID        | Identifier of the judgement type, a 2-3 letter capitalized shorthand, see table below.
| name                             | string    | Name of the judgement. (might not match table below, e.g. if localized).
| penalty                          | boolean   | Whether this judgement causes penalty time. Required iff contest:penalty\_time is present.
| solved                           | boolean   | Whether this judgement is considered correct.
| simplified\_judgemment\_type\_id | ID?       | Identifier of this type's simplified judgement type, if one exists.

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
| SV  | Security Violation                       | Illegal Function (IF), Restricted Function               | RTE   | RTE, RE           | Uses some functionality that is not allowed by the system
| IF  | Illegal Function                         | Illegal Function (IF), Restricted Function               | RTE   | SV, RTE, RE       | Calls a function that is not allowed by the system
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

In contests with limited visibility or access rules, a simplified judgement type id defines how each judgement type
will be simplified for users without access.

For instance, in a contest where teams cannot see the specific reason another team's submission was rejected, teams
might see their own judgement types, but judgements from other teams would return the corresponding simplified judgement
type instead.

Simplified judgement types must not be chained and must not refer to their own id. They lead directly to the equivalent
simplfied judgement type, if one exists.

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

| Endpoint                       | Mime-type        | Description
| :----------------------------- | :--------------- | :----------
| `contests/<id>/languages`      | application/json | JSON array of all languages with properties as specified by [access](#access).
| `contests/<id>/languages/<id>` | application/json | JSON object representing a single language with properties as specified by [access](#access).

Properties of language objects:

| Name                   | Type             | Description
| :--------------------- | :--------------- | :----------
| id                     | ID               | Identifier of the language from table below.
| name                   | string           | Name of the language (might not match table below, e.g. if localized).
| entry\_point\_required | boolean          | Whether the language requires an entry point.
| entry\_point\_name     | string ?         | The name of the type of entry point, such as "Main class" or "Main file"). Required iff entry_point_required is `true`.
| extensions             | array of string  | File extensions for the language.
| compiler               | Command object   | Command used for compiling submissions.
| runner                 | Command object   | Command used for running submissions. Relevant e.g. for interpreted languages and languages running on a VM.

Properties of Command objects:

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

Request:

` GET https://example.com/api/contests/wf14/languages`

Returned data:

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

### Problems

The problems to be solved in the contest.

The following endpoints are associated with problems:

| Endpoint                      | Mime-type        | Description
| :---------------------------- | :--------------- | :----------
| `contests/<id>/problems`      | application/json | JSON array of all problems with properties as specified by [access](#access).
| `contests/<id>/problems/<id>` | application/json | JSON object representing a single problem with properties as specified by [access](#access).

Properties of problem objects:

| Name              | Type      | Description
| :---------------- | :-------- | :----------
| id                | ID        | Identifier of the problem, at the WFs the directory name of the problem package.
| uuid              | string ?  | UUID of the problem, as defined in the problem package.
| label             | string    | Label of the problem on the scoreboard, typically a single capitalized letter.
| name              | string    | Name of the problem.
| ordinal           | integer   | A unique number that determines the order the problems, e.g. on the scoreboard.
| rgb               | string ?  | Hexadecimal RGB value of problem color as specified in [HTML hexadecimal colors](https://en.wikipedia.org/wiki/Web_colors#Hex_triplet), e.g. `#AC00FF` or `#fff`.
| color             | string ?  | Human readable color description associated to the RGB value.
| time\_limit       | number    | Time limit in seconds per test data set (i.e. per single run). Should be a non-negative integer multiple of `0.001`. The reason for this is to not have rounding ambiguities while still using the natural unit of seconds.
| memory\_limit     | integer   | Memory limit in MiB enforced on a submission.
| output\_limit     | integer   | Limit in MiB on what the submission can write both to `stdout` and `stderr`. If a submission produces more output, a CCS should fail the submission or ignore output beyond this limit.
| code\_limit       | integer   | Limit in KiB on submissions for this problem. Submissions that are larger should be rejected by a CCS.
| test\_data\_count | integer   | Number of test data sets.
| max\_score        | number    | Maximum score. Typically used to determine scoreboard cell color. Required iff contest:scoreboard\_type is `score`.
| package           | array of FILE ? | [Problem package](https://www.kattis.com/problem-package-format/). Expected mime type is application/zip. Only exactly one package is allowed. Not expected to actually contain href for package during the contest, but used for configuration and archiving.
| statement         | array of FILE ? | Problem statement. Expected mime type is application/pdf. 

#### Examples

Request:

` GET https://example.com/api/contests/wf14/problems`

Returned data:

```json
[{"id":"asteroids","label":"A","name":"Asteroid Rangers","ordinal":1,"color":"blue","rgb":"#00f","time_limit":2,"memory_limit":2048,"output_limit":8,"code_limit":128,"test_data_count":10},
 {"id":"bottles","label":"B","name":"Curvy Little Bottles","ordinal":2,"color":"gray","rgb":"#808080","time_limit":3.5,"memory_limit":1024,"output_limit":8,"code_limit":128,"test_data_count":15}
]
```

Request:

` GET https://example.com/api/contests/wf14/problems/asteroids`

Returned data:

```json
{"id":"asteroids","label":"A","name":"Asteroid Rangers","ordinal":1,"color":"blue","rgb":"#00f","time_limit":2,"memory_limit":2048,"output_limit":8,"code_limit":128,"test_data_count":10}
```

### Groups

Grouping of teams. At the World Finals these are the super regions; at other contests these
may be the different sites, divisions, or types of contestants.

Teams may belong to multiple groups. For instance, there may be a group for each site, a group for
university teams, a group for corporate teams, and a group for ICPC-eligible teams. Teams could
belong to two or three of these.
When there are different kinds of groups for different purposes (e.g. sites vs divisions), each
group or set of groups should have a different type property
(e.g. `"type":"site"` and `"type":"division"`).

Groups must exist for any combination of teams that must be ranked on a
[group scoreboard](#group-scoreboard), which means groups may be created for combinations of
other groups. For instance, if there is a requirement to show a scoreboard for teams in each of `D`
divisions at every one of `S` sites, then in addition to the `D` + `S` groups there will also be
`D`x`S` combined/product groups. It is recommended that these groups have a type like
`"type":"<group1>-<group2>"`, e.g. `"type":"site-division"`.

The following endpoints are associated with groups:

| Endpoint                    | Mime-type        | Description
| :-------------------------- | :--------------- | :----------
| `contests/<id>/groups`      | application/json | JSON array of all groups with properties as specified by [access](#access).
| `contests/<id>/groups/<id>` | application/json | JSON object representing a single group with properties as specified by [access](#access).

Note that these endpoints must be provided if groups are used. If they
are not provided no other endpoint may refer to groups (i.e. return any
group\_ids).

Properties of group objects:

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

| Endpoint                           | Type             | Description
| :--------------------------------- | :--------------- | :----------
| `contests/<id>/organizations`      | application/json | JSON array of all organizations with properties as specified by [access](#access).
| `contests/<id>/organizations/<id>` | application/json | JSON object representing a single organization with properties as specified by [access](#access).

Note that the first two endpoints must be provided if organizations are
used. If they are not provided no other endpoint may refer to
organizations (i.e. return any organization\_ids).

Properties of organization objects:

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

Request:

` GET https://example.com/api/contests/<id>/organizations`

Returned data:

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

### Teams

Teams competing in the contest.

The following endpoints are associated with teams:

| Endpoint                    | Mime-type        | Description
| :-------------------------- | :--------------- | :----------
| `contests/<id>/teams`       | application/json | JSON array of all teams with properties as specified by [access](#access).
| `contests/<id>/teams/<id>`  | application/json | JSON object representing a single team with properties as specified by [access](#access).

Properties of team objects:

| Name             | Type                   | Description
| :--------------- | :--------------------- | :----------
| id               | ID                     | Identifier of the team.
| icpc\_id         | string ?               | External identifier from ICPC CMS.
| name             | string                 | Name of the team.
| label            | string                 | Label of the team, at WFs normally the team seat number.
| display\_name    | string ?               | Display name of the team. If not set, a client should revert to using the name instead.
| organization\_id | ID ?                   | Identifier of the [ organization](#organizations) (e.g. university or other entity) that this team is affiliated to.
| group\_ids       | array of ID ?          | Identifiers of the [ group(s)](#groups) this team is part of (at ICPC WFs these are the super-regions). No meaning must be implied or inferred from the order of IDs. The array may be empty. Required iff groups endpoint is available.
| hidden           | boolean ?              | If the team is to be excluded from the [scoreboard](#scoreboard). Defaults to `false`.
| location         | team location object ? | Position of team on the contest floor. See below for the specification of this object.
| photo            | array of FILE ?        | Registration photo of the team. Only allowed mime types are image/\*.
| video            | array of FILE ?        | Registration video of the team. Only allowed mime types are video/\* or application/vnd.apple.mpegurl.
| backup           | array of FILE ?        | Latest file backup of the team machine. Only allowed mime type is application/zip.
| key\_log         | array of FILE ?        | Latest key log file from the team machine. Only allowed mime type is text/plain.
| tool\_data       | array of FILE ?        | Latest tool data usage file from the team machine. Only allowed mime type is text/plain.
| desktop          | array of FILE ?        | Streaming video of the team desktop. Only allowed mime types are video/\* or application/vnd.apple.mpegurl.
| webcam           | array of FILE ?        | Streaming video of the team webcam. Only allowed mime types are video/\* or application/vnd.apple.mpegurl.
| audio            | array of FILE ?        | Streaming team audio.

Properties of team location objects:

| Name     | Type   | Description
| :------- | :----- | :----------
| x        | number | Team's x position in meters.
| y        | number | Team's y position in meters.
| rotation | number | Team's rotation in degrees.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/teams`

Returned data:

```json
[{"id":"team11","icpc_id":"201433","label":"11","name":"Shanghai Tigers","organization_id":"inst123","group_ids":["asia-74324325532"]},
 {"id":"team123","label":"123","name":"CMU1","organization_id":"inst105","group_ids":["8","11"]}
]
```

### Persons

Persons involved in the contest.

The following endpoints are associated with persons:

| Endpoint                     | Mime-type        | Description
| :--------------------------- | :--------------- | :----------
| `contests/<id>/persons`      | application/json | JSON array of all persons with properties as specified by [access](#access).
| `contests/<id>/persons/<id>` | application/json | JSON object representing a single person with properties as specified by [access](#access).

Properties of person objects:

| Name        | Type            | Description
| :---------- | :-------------- | :----------
| id          | ID              | Identifier of the person.
| icpc\_id    | string ?        | External identifier from ICPC CMS.
| team\_ids   | array of ID ?   | [Team](#teams) of this person. Required to be non-empty iff role is `contestant` or `coach`.
| name        | string          | Name of the person.
| title       | string ?        | Title of the person, e.g. "Technical director".
| email       | string ?        | Email of the person.
| sex         | string ?        | Either `male` or `female`, or possibly `null`.
| role        | string          | One of `contestant`, `coach`, `staff`, or `other`.
| photo       | array of FILE ? | Registration photo of the person. Only allowed mime types are image/\*.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/persons`

Returned data:

```json
[{"id":"john-smith","team_ids":["43"],"icpc_id":"32442","name":"John Smith","email":"john.smith@kmail.com","sex":"male","role":"contestant"},
 {"id":"osten-umlautsen","team_ids":["43","44"],"icpc_id":null,"name":"Östen Ümlautsen","sex":null,"role":"coach"},
 {"id":"bill","name":"Bill Farrell","sex":"male","title":"Executive Director","role":"staff"}
]
```

### Accounts

The accounts used for accessing the contest, as well as information about the account currently accessing the API.

The following endpoints are associated with accounts:

| Endpoint                      | Mime-type        | Description
| :---------------------------- | :--------------- | :----------
| `contests/<id>/accounts`      | application/json | JSON array of all accounts with properties as specified by [access](#access).
| `contests/<id>/accounts/<id>` | application/json | JSON object representing a single account with properties as specified by [access](#access).
| `contests/<id>/account`       | application/json | JSON object representing a single account of the client making the request, with properties as specified by [access](#access) for the account used.

Properties of account objects:

| Name              | Type      | Description
| :---------------- | :-------- | :----------
| id                | ID        | Identifier of the account.
| username          | string    | The account username.
| password          | string ?  | The account password.
| name              | string ?  | The name of the account.
| type              | string    | The type of account, e.g. `team`, `judge`, `admin`, `analyst`, `staff`.
| ip                | string ?  | IP address associated with this account, used for auto-login.
| team\_id          | ID ?      | The team that this account is for. Required iff type is `team`.
| person\_id        | ID ?      | The person that this account is for, if the account is only for one person.

Accounts exist in the API primarily for configuration from a contest package, or an administrator comparing one CCS to another. It is
expected that non-admin clients never see passwords, and typically do not see accounts other than their own.

The account endpoint exists so that the clients can tell which account (and hence which person or team) they are logged in as. It is not
expected to exist in a contest package, and will fail with a 404 error code if the client is not authenticated.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/accounts`

Returned data:

```json
[{"id":"stephan","username":"stephan","name":"Stephan's home account","type":"judge","ip":"10.0.0.1"},
 {"id":"team45","username":"team45","type":"team","ip":"10.1.1.45","team_id":"45"}
]
```

Request:

` GET https://example.com/api/contests/wf14/accounts/nicky`

Returned data:

```json
{"id":"nicky","username":"nicky","type":"admin"}
```

Request:

`GET https://example.com/api/contests/wf14/account`

Returned data:

```json
{"id":"nicky","username":"nicky","type":"admin"}
```

### Contest state

Current state of the contest, specifying whether it's running, the
scoreboard is frozen or results are final.

The following endpoints are associated with state:

| Endpoint              | Type             | Description
| :-------------------- | :--------------- | :----------
| `contests/<id>/state` | application/json | JSON object representing the current contest state with properties as specified by [access](#access).

Properties of state objects:

| Name             | Type   | Description
| :--------------- | :----- | :----------
| started          | TIME ? | Time when the contest actually started, or `null` if the contest has not started yet. When set, this time must be equal to the [contest](#contests) `start_time`.
| frozen           | TIME ? | Time when the scoreboard was frozen, or `null` if the scoreboard has not been frozen. Required iff `scoreboard_freeze_duration` is present in the [contest](#contests) endpoint.
| ended            | TIME ? | Time when the contest ended, or `null` if the contest has not ended. Must not be set if started is `null`.
| thawed           | TIME ? | Time when the scoreboard was thawed (that is, unfrozen again), or `null` if the scoreboard has not been thawed. Required iff `scoreboard_freeze_duration` is present in the [contest](#contests) endpoint. Must not be set if frozen is `null`.
| finalized        | TIME ? | Time when the results were finalized, or `null` if results have not been finalized. Must not be set if ended is `null`.
| end\_of\_updates | TIME ? | Time after last update to the contest occurred, or `null` if more updates are still to come. Setting this to non-`null` must be the very last change in the contest.

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

| Endpoint                         | Type             | Description
| :------------------------------- | :--------------- | :----------
| `contests/<id>/submissions`      | application/json | JSON array of all submissions with properties as specified by [access](#access).
| `contests/<id>/submissions/<id>` | application/json | JSON object representing a single submission with properties as specified by [access](#access).

Properties of submission objects:

| Name          | Type            | Description
| :------------ | :-------------- | :----------
| id            | ID              | Identifier of the submission. Usable as a label, typically a low incrementing number to make it easier to validate submissions or compare submissions with a Shadow CCS.
| language\_id  | ID              | Identifier of the [language](#languages) submitted for.
| problem\_id   | ID              | Identifier of the [problem](#problems) submitted for.
| team\_id      | ID              | Identifier of the [team](#teams) that made the submission.
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

#### Modifying submissions

To add a submission, clients can use the `POST` method on the submissions endpoint or the
`PUT` method directly on an object url. One of the following [capabilities](#capabilities)
is required to add submissions, with descriptions below:

| Name               | Description
| :----------------- | :----------
| team\_submit       | POST a submission as a team
| proxy\_submit      | POST a submission as a proxy (able to submit on behalf of team(s))
| admin\_submit      | POST or PUT a submission as an admin

All requests must include a valid JSON object with the same properties as the submissions
endpoint returns from a `GET` request with the following exceptions:

- The property `team_id`, `time`, and `contest_time` are optional depending on
  the use case (see below). The server may require properties to either be
  absent or present, and should respond with a 4xx error code in such cases.
- Since `files` only supports `application/zip`, providing the `mime` property
  is optional.
- `reaction` may be provided but a CCS does not have to honour it.
- The `team_submit` capability only has access to `POST`. `time` must not be
  provided and will always be set to the current time as determined by the
  server. `team_id` may be provided but then must match the ID of the team
  associated with the request.
- The `proxy_submit` capability only has access to `POST`. `time` must not be
  provided and will always be set to the current time as determined by the
  server. `team_id` must be provided.
- For more advanced scenarios the `admin_submit` capability may use a `POST`
  (must not include an `id`) or `PUT` (client is required to include a unique
  `id`). In both cases `time` is required. For example in a setup with a
  central CCS with satellite sites where teams submit to a proxy CCS that
  forwards to the central CCS, this might be useful to make sure that the proxy
  CCS can accept submissions even when the connection to the central CCS is
  down. The proxy can then forward these submissions later, when the connection
  is restored again.

The request must fail with a 4xx error code if any of the following happens:

- A required property is missing.
- A property that must not be provided is provided.
- The supplied problem, team or language can not be found.
- An entry point is required for the given language, but not supplied.
- The mime property in `files` is set but invalid.
- Something is wrong with the submission file. For example it contains too many
  files, it is too big, etc.
- The provided `id` already exists or is otherwise not acceptable.

The response will contain a `Location` header pointing to the newly created submission
and the response body will contain the initial state of the submission.

Performing a `POST` or `PUT` is not supported when these capabilities are not available.

#### Use cases for POSTing and PUTting submissions

The POST and PUT submissions endpoint can be used for a variety of reasons,
and depending on the use case, the server might require different
properties to be present. A number of common scenarios are described here
for informational purposes only.

##### Team client submitting to CCS

The most obvious and probably most common case is where a team
directly submits to the CCS, e.g. with a command-line submit client.

In this case the client has the `team_submit` capability and a specific `team_id`
already associated with it. POST must be used and the properties `id`,
`team_id`, `time`, and `contest_time` should not be specified; the server will
determine these properties and should reject submissions specifying
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
to the upstream CCS using the `proxy_submit` capability. The proxy would provide
`team_id` and `time` properties and the CCS should then accept and use
these.

To allow the proxy to return a submission `id` during connectivity
loss, the `admin_submit` capability would be required and each site
could be assigned a unique prefix such that the proxy
server itself can generate unique `id`s and then submit a PUT to the central
CCS with the `id` property included. The central CCS should then
accept and use that `id` property.

##### Further potential extensions

To allow for any further use cases, the specification is deliberately
flexible in how the server can handle optional properties.

- The `contest_time` property should normally not be specified when `time` is
  already specified as it can be calculated from `time` and the wallclock time
  is unambiguously defined without reference to contest start time. However, in
  a case where one would want to support a multi-site contest where the sites
  run out of sync, the use of `contest_time` might be considered.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/submissions`

Returned data:

```json
[{"id":"187","team_id":"123","problem_id":"10-asteroids",
  "language_id":"1-java","time":"2014-06-25T11:22:05.034+01","contest_time":"1:22:05.034","entry_point":"Main",
  "files":[{"href":"contests/wf14/submissions/187/files","filename":"files.zip","mime":"application/zip"}]}
]
```

Note that the relative link for `files` points to the location
<https://example.com/api/contests/wf14/submissions/187/files> since the
base URL for the API is <https://example.com/api/>.

Request:

` POST https://example.com/api/contests/wf14/submissions`

Request data:

```json
{
   "language_id":"1-java",
   "problem_id":"10-asteroids",
   "team_id":"123",
   "time":"2014-06-25T11:22:05.034+01",
   "entry_point":"Main",
   "files":[{"data": "<base64 string>"}]
}
```

Returned data:

```json
{
   "id":"187",
   "language_id":"1-java",
   "problem_id":"10-asteroids",
   "team_id":"123",
   "time":"2014-06-25T11:22:05.034+01",
   "contest_time":"1:22:05.034",
   "entry_point":"Main",
   "files":[{"href":"contests/wf14/submissions/187/files","filename":"files.zip","mime":"application/zip"}]
}
```

### Judgements

Judgements for submissions in the contest.

The following endpoints are associated with judgements:

| Endpoint                        | Mime-type        | Description
| :------------------------------ | :--------------- | :----------
| `contests/<id>/judgements`      | application/json | JSON array of all judgements with properties as specified by [access](#access).
| `contests/<id>/judgements/<id>` | application/json | JSON object representing a single judgement with properties as specified by [access](#access).

Properties of judgement objects:

| Name                 | Type      | Description
| :------------------- | :-------- | :----------
| id                   | ID        | Identifier of the judgement.
| submission\_id       | ID        | Identifier of the [submission](#submissions) judged.
| judgement\_type\_id  | ID ?      | The [verdict](#judgement-types) of this judgement. Required iff judgement has completed.
| score                | number    | Score for this judgement, between `0` and the problem's `max_score`. Required iff contest:scoreboard\_type is `score`.
| current              | boolean ? | `true` if this is the current judgement. Defaults to `true`. At any time, there must be at most one judgement per submission for which this `true` or unset (and thus defaulting to `true`).
| start\_time          | TIME      | Absolute time when judgement started.
| start\_contest\_time | RELTIME   | Contest relative time when judgement started.
| end\_time            | TIME ?    | Absolute time when judgement completed. Required iff judgement\_type\_id is present.
| end\_contest\_time   | RELTIME ? | Contest relative time when judgement completed. Required iff judgement\_type\_id is present.
| max\_run\_time       | number ?  | Maximum run time in seconds for any test case. Should be a non-negative integer multiple of `0.001`. The reason for this is to not have rounding ambiguities while still using the natural unit of seconds.

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

| Endpoint                  | Mime-type        | Description
| :------------------------ | :--------------- | :----------
| `contests/<id>/runs`      | application/json | JSON array of all runs with properties as specified by [access](#access).
| `contests/<id>/runs/<id>` | application/json | JSON object representing a single run with properties as specified by [access](#access).

Properties of run objects:

| Name                | Type    | Description
| :------------------ | :------ | :----------
| id                  | ID      | Identifier of the run.
| judgement\_id       | ID      | Identifier of the [judgement](#judgements) this is part of.
| ordinal             | number  | Ordering of runs in the judgement. Must be different for every run in a judgement. Runs for the same test case must have the same ordinal. Must be between 1 and `problem:test_data_count`.
| judgement\_type\_id | ID      | The [verdict](#judgement-types) of this run (i.e. a judgement type).
| time                | TIME    | Absolute time when run completed.
| contest\_time       | RELTIME | Contest relative time when run completed.
| run\_time           | number  | Run time in seconds. Should be a non-negative integer multiple of `0.001`. The reason for this is to not have rounding ambiguities while still using the natural unit of seconds.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/runs`

Returned data:

```json
[{"id":"1312","judgement_id":"189549","ordinal":28,"judgement_type_id":"TLE",
  "time":"2014-06-25T11:22:42.420+01","contest_time":"1:22:42.420","run_time":0.123}
]
```

### Clarifications

Clarification message sent between teams and judges, a.k.a.
clarification requests (questions from teams) and clarifications
(answers from judges).

The following endpoints are associated with clarification messages:

| Endpoint                            | Mime-type        | Description
| :---------------------------------- | :--------------- | :----------
| `contests/<id>/clarifications`      | application/json | JSON array of all clarifications with properties as specified by [access](#access).
| `contests/<id>/clarifications/<id>` | application/json | JSON object representing a single clarification with properties as specified by [access](#access).

Properties of clarification message objects:

| Name           | Type             | Description
| :------------- | :--------------- | :----------
| id             | ID               | Identifier of the clarification.
| from\_team\_id | ID ?             | Identifier of the [team](#teams) sending this clarification request, `null` iff a clarification is sent by the jury.
| to\_team\_ids  | array of ID ?    | Identifiers of the [team(s)](#teams) receiving this reply, `null` iff a reply to all teams or a request sent by a team.
| to\_group\_ids | array of ID ?    | Identifiers of the [group(s)](#groups) receiving this reply, `null` iff a reply to all teams or a request sent by a team.
| reply\_to\_id  | ID ?             | Identifier of clarification this is in response to, otherwise `null`.
| problem\_id    | ID ?             | Identifier of associated [problem](#problems), `null` iff not associated to a problem.
| text           | string           | Question or reply text.
| time           | TIME             | Time of the question/reply.
| contest\_time  | RELTIME          | Contest time of the question/reply.

The recipients of a clarification are the union of `to_team_ids` and `to_group_ids`.  A clarification is sent to all teams if `from_team_id`, `to_team_ids` and `to_group_ids` are null.  Note that if `from_team_id` is not `null`, then both `to_team_ids` and `to_group_ids` must be `null`. That is, teams cannot send messages to other teams or groups.

#### Modifying clarifications

To add a clarification, clients can use the `POST` method on the clarifications endpoint or the
`PUT` method directly on an object url. One of the following [capabilities](#capabilities)
is required to add clarifications, with descriptions below:

| Name               | Description
| :----------------- | :----------
| post\_clar         | POST a clarification
| proxy\_clar        | POST a clarification as a proxy (able to submit on behalf of team(s))
| admin\_clar        | POST or PUT a clarification as an admin

All requests must include a valid JSON object with the same properties as the
clarifications endpoint returns from a `GET` request with the following
exceptions:

- When a property value would be null it is optional - you do not need to
  include it. e.g. if a clarification is not related to a problem you can
  choose to include or exclude the `problem_id`.
- The `post_clar` capability only has access to `POST`. `id`,
  `time`, and `contest_time` must not be provided. When submitting from a
  team account, `to_team_ids` and `to_group_ids` must not be provided; `from_team_id` may be
  provided but then must match the ID of the team associated with the request.
  When submitting from a judge account, `from_team_id` must not be provided.
  In either case the server will determine an `id` and the current `time` and
  `contest_time`.
- The `proxy_clar` capability only has access to `POST`. `id`, `to_team_ids`, `to_group_ids`,
  `time`, and `contest_time` must not be provided. `from_team_id` must be
  provided. The server will determine an `id` and the current `time` and
  `contest_time`.
- The `admin_clar` capability may use a `POST` (must not include an `id`) or
  `PUT` (client is required to include a unique `id`). In both cases `time` is
  required.

The request must fail with a 4xx error code if any of the following happens:

- A required property is missing.
- A property that must not be provided is provided.
- The supplied problem, `from_team`, `to_team_ids`, `to_group_ids`, or `reply_to` cannot be found or are
  not visible to the client that's submitting.
- The provided `id` already exists or is otherwise not acceptable.

The response will contain a `Location` header pointing to the newly created clarification
and the response body will contain the initial state of the clarification.

Performing a `POST` or `PUT` is not supported when these capabilities are not available.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/clarifications`

Returned data:

```json
[{"id":"wf2017-1","from_team_id":null,"to_team_ids":null,"to_group_ids":null,"reply_to_id":null,"problem_id":null,
  "text":"Do not touch anything before the contest starts!","time":"2014-06-25T11:59:27.543+01","contest_time":"-0:15:32.457"}
]
```

Request:

` GET https://example.com/api/contests/wf14/clarifications`

Returned data:

```json
[{"id":"1","from_team_id":"34","to_team_ids":null,"to_group_ids":null,"reply_to_id":null,"problem_id":null,
  "text":"May I ask a question?","time":"2017-06-25T11:59:27.543+01","contest_time":"1:59:27.543"},
 {"id":"2","from_team_id":null,"to_team_ids":["34"],"reply_to_id":"1","problem_id":null,
  "text":"Yes you may!","time":"2017-06-25T11:59:47.543+01","contest_time":"1:59:47.543"}
]
```

Request:

` GET https://example.com/api/contests/wf14/clarifications`

Returned data:

```json
[{"id":"1","from_team_id":"34","text":"May I ask a question?","time":"2017-06-25T11:59:27.543+01","contest_time":"1:59:27.543"},
 {"id":"2","to_team_ids":["34","57","69"],"to_group_ids":["1336"], "reply_to_id":"1","text":"Yes you may!","time":"2017-06-25T11:59:47.543+01","contest_time":"1:59:47.543"}
]
```

Request:

` POST https://example.com/api/contests/wf14/clarifications`

Request data:

```json
{
   "problem_id":"10-asteroids",
   "from_team_id":"34",
   "text":"Can I assume the asteroids are round?"
}
```

Returned data:

```json
{
   "id":"clar-43",
   "problem_id":"10-asteroids",
   "from_team_id":"34",
   "text":"Can I assume the asteroids are round?",
   "time":"2017-06-25T11:59:47.543+01",
   "contest_time":"1:59:47.543"
}
```
### Awards

Awards such as medals, first to solve, etc.

The following endpoints are associated with awards:

| Endpoint                    | Mime-type        | Description
| :-------------------------- | :--------------- | :----------
| `contests/<id>/awards`      | application/json | JSON array of all awards with properties as specified by [access](#access).
| `contests/<id>/awards/<id>` | application/json | JSON object representing a single award with properties as specified by [access](#access).

Properties of award objects:

| Name      | Type          | Description
| :-------- | :------------ | :----------
| id        | ID            | Identifier of the award.
| citation  | string        | Award citation, e.g. "Gold medal winner".
| team\_ids | array of ID ? | JSON array of [team](#teams) ids receiving this award. No meaning must be implied or inferred from the order of IDs. If the value is null this means that the award is not currently being updated. If the value is the empty array this means that the award **is** being updated, but no team has been awarded the award at this time.

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

#### POST, PUT, PATCH, and DELETE awards

Clients with the `admin` role may make changes to awards using the
normal [HTTP methods](#http-methods) as specified above. Specifically,
they can POST new awards, create or replace one with a known id via PUT,
PATCH one or more properties, or DELETE an existing award.

The server may be configured to manage (assign or update) some award
ids, and may block clients from modifying them. However, if a client is
able to modify an award it must assume that it is responsible for
managing that award id unless and until it sees an indication that
something else is now managing that award - either a change that it did
not request, or a future modification fails.

For example, the server may be configured to assign the `winner` award
and not allow any client to modify it. The same server may assign
`*-medal` awards by default, but allow clients to modify them. Once a
client modifies any of the `*-medal` awards, it is responsible for
updating it if anything changes. Likewise, the client could add any
arbitrary awards like `first-submission-for-country-*` and would be
responsible for managing these.

The server should create all the awards it is configured to manage 
before the start of the contest, so that clients can know which awards 
are already handled.

The request must fail with a 4xx error code if any of the following
happens:

- A POST that includes an id.
- A PATCH, or DELETE on an award that doesn't exist.
- A POST or PUT that is missing one of the required properties (`citation` and
  `team_ids`).
- A PATCH that contains an invalid property (e.g. null `citation` or
  `team_ids`).
- A PUT or PATCH that includes an award id that doesn't match the id in the
  url.
- A POST, PUT, PATCH, or DELETE on an award id that the server is configured to
  manage exclusively.

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

Request:

` POST https://example.com/api/contests/wf14/awards`

Request data:

```json
{"citation":"Best team costumes","team_ids":["42"]}
```

Response data:

```json
{"id":"best-costume","citation":"Best team costumes","team_ids":["42"]}
```

Request:

` PUT https://example.com/api/contests/wf14/awards/best-costume`

Request data:

```json
{"id":"best-costume","citation":"Best team costumes","team_ids":["24"]}
```

Request:

` PATCH https://example.com/api/contests/wf14/awards/best-costume`

Request data:

```json
{"citation":"Best team cosplay"}
```

Request:

` DELETE https://example.com/api/contests/wf14/awards/best-costume`

### Commentary

Commentary on events happening in the contest.

The following endpoints are associated with commentary:

| Endpoint                        | Mime-type        | Description
| :------------------------------ | :--------------- | :----------
| `contests/<id>/commentary`      | application/json | JSON array of all commentary with properties as specified by [access](#access).
| `contests/<id>/commentary/<id>` | application/json | JSON object representing a single commentary with properties as specified by [access](#access).

Properties of commentary objects:

| Name            | Type            | Description
| :-------------- | :-------------- | :----------
| id              | ID              | Identifier of the commentary.
| time            | TIME            | Time of the commentary message.
| contest\_time   | RELTIME         | Contest time of the commentary message.
| message         | string          | Commentary message text. May contain special tags referring to endpoint objects using the format `{<endpoint>:<object ID>}`. This is most commonly used for references to [teams](#teams) and [problems](#problems) as `{teams:<team ID>}` and `{problems:<problem ID>}` respectively.
| tags            | array of string | JSON array of tags describing the message.
| source\_id      | ID ?            | Source [person](#persons) of the commentary message.
| team\_ids       | array of ID ?   | JSON array of [team](#teams) IDs the message is related to.
| problem\_ids    | array of ID ?   | JSON array of [problem](#problems) IDs the message is related to.
| submission\_ids | array of ID ?   | JSON array of [submission](#submissions) IDs the message is related to.

For the message, if a literal `{` is needed, `\{` must be used. Similarly for a literal `\`, `\\` must be used.

#### Known tags

Below is a list of known tags. If any of the tags below are used, they must
have the corresponding meaning. If the any of the meanings below are needed,
the corresponding tag should be used. There is no requirement that any of the
tags below are used.

| Tag                     | Meaing
| :---------------------- | :-----
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

#### Modifying commentary 

To add a commentary message, clients can use the `POST` method on the commentary endpoint.
The following [capability](#capabilities) is required to add commentary,
with description below:

| Name               | Description
| :----------------- | :----------
| post\_comment      | POST a commentary message

All requests must include a valid JSON object with the same properties as the commentary
endpoint returns from a `GET` request with the following exceptions:

- `id`, `time`, `contest\_time`, and `source\_id` must not be provided, and will be set by the server.

The request must fail with a 4xx error code if any of the following happens:

- A required property is missing.
- A property that must not be provided is provided.
- The supplied team, problem, or submission can not be found.

The response will contain a `Location` header pointing to the newly created commentary
and the response body will contain the initial state of the commentary.

Performing a `POST` is not supported when this capability is not available.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/commentary`

Returned data:

```json
[{"id":"143730", "time":"2021-03-06T19:02:02.328+00", "contest_time":"0:02:02.328", "message": "{t:314089} made a submission for {p:anttyping}. If correct, they will solve the first problem and take the lead", "team_ids": ["314089"], "problem_ids": ["anttyping"]}, 
 {"id": "143736", "time": "2021-03-06T19:02:10.858+00", "contest_time": "0:02:10.858", "message": "{t:314089} fails its first attempt on {p:anttyping} due to WA", "team_ids": ["314089"], "problem_ids": ["anttyping"]}, 
 {"id": "143764", "time": "2021-03-06T19:03:07.517+00", "contest_time": "0:03:07.517", "message": "{t:314115} made a submission for {p:march6}. If correct, they will solve the first problem and take the lead", "team_ids": ["314115"], "problem_ids": ["march6"]}
]
```

### Scoreboard

Scoreboard of the contest.

Since this is generated data, only the `GET` method is allowed here,
irrespective of role.

The following endpoint is associated with the scoreboard:

| Endpoint                   | Mime-type        | Description
| :------------------------- | :--------------- | :----------
| `contests/<id>/scoreboard` | application/json | JSON object with scoreboard data as defined in the table below.

#### Scoreboard request options

The following options can be passed to the scoreboard endpoint.

##### Group scoreboard

By passing `group_id` with a valid group ID a scoreboard can be requested for the teams in a particular group:

`contests/<id>/scoreboard?group_id=site1`

Each group scoreboard is ranked independently and contains only the teams that belong to the
specified group. If a client wants to know 'local' vs 'global' rank it can query both the group and primary scoreboards.

A 4xx error code will be returned if the group id is not valid. Groups
that are not included in the groups endpoint for the role making the
request are not valid.

#### Scoreboard format

Properties of the scoreboard object.

| Name          | Type    | Description
| :------------ | :------ | :----------
| time          | TIME    | Time contained in the [event](#event-feed) after which this scoreboard was generated. Implementation defined if the event has no associated time.
| contest\_time | RELTIME | Contest time contained in the associated event. Implementation defined if the event has no associated contest time.
| state         | object  | Identical data as returned by the [ contest state](#contest-state) endpoint. This is provided here for ease of use and to guarantee the data is synchronized.
| rows          | array of scoreboard row objects | A list of rows of team with their associated scores.

The scoreboard `rows` array is sorted according to rank and alphabetical
on team name within identically ranked teams. Here alphabetical ordering
means according to the [Unicode Collation
Algorithm](https://www.unicode.org/reports/tr10/), by default using the
`en-US` locale.

Properties of scoreboard row objects:

| Name              | Type      | Description
| :---------------- | :-------- | :----------
| rank              | integer   | Rank of this team, 1-based and duplicate in case of ties.
| team\_id          | ID        | Identifier of the [ team](#teams).
| score             | object    | JSON object as specified in the rows below (for possible extension to other scoring methods).
| score.num\_solved | integer   | Number of problems solved by the team. Required iff contest:scoreboard\_type is `pass-fail`.
| score.total\_time | RELTIME   | Total penalty time accrued by the team. Required iff contest:scoreboard\_type is `pass-fail`.
| score.score       | number    | Total score of problems by the team. Required iff contest:scoreboard\_type is `score`.
| score.time        | RELTIME ? | Time of last score improvement, used for tiebreaking purposes. Must be `null` iff `num\_solved=0`.
| problems          | array of problem data objects ? | JSON array of problems with scoring data, see below for the specification of each object.

Properties of problem data objects:

| Name         | Type      | Description
| :----------- | :-------- | :----------
| problem\_id  | ID        | Identifier of the [ problem](#problems).
| num\_judged  | integer   | Number of judged submissions (up to and including the first correct one),
| num\_pending | integer   | Number of pending submissions (either queued or due to freeze).
| solved       | boolean   | Required iff contest:scoreboard\_type is `pass-fail`.
| score        | number    | Required iff contest:scoreboard\_type is `score`.
| time         | RELTIME   | Minutes into the contest when this problem was solved by the team. Required iff `solved=true` or `score>0`.

#### Examples

Request:

` GET https://example.com/api/contests/wf14/scoreboard`

Returned data:

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

### Event feed

Change [notifications](#notification-format) (events) of the data
presented by the API.

The following endpoint is associated with the event feed:

| Endpoint                   | Mime-type            | Description
| :------------------------- | :------------------- | :----------
| `contests/<id>/event-feed` | application/x-ndjson | NDJSON feed of events as defined in [notification format](#notification-format).

The event feed is a streaming HTTP endpoint that allows connected
clients to receive change notifications. The feed is a complete log of
contest objects that starts "at the beginning of time" so all existing
objects will be sent upon initial connection, but may appear in any
order (e.g. teams or problems first).

Each line is an NDJSON formatted notification. The feed does not
terminate under normal circumstances, so to ensure keep alive a newline
must be sent if there has been no event within 120 seconds.

Since this is generated data, only the `GET` method is allowed for this
endpoint, irrespective of role.

#### General requirements

Every notification provides the current state of a single contest
object. There is no guarantee on order of events (except for general
requirements below), whether two consecutive changes cause one or two
events, duplicate events, or even that different clients will receive
the same order or set of events. The only guarantees are:

- when an object changes one or more times a notification will be sent,
- the latest notification sent for any object is the correct and current
state of that object. E.g. if an object was created and deleted the
delete notification will be sent last.
- when a notification is sent the change it describes must already have
happened. I.e. if a client receives an update for a certain endpoint a
`GET` from that endpoint will return that state or possible some later
state, but never an earlier state.
- the notification for the [state endpoint](#contest-state) setting
`end_of_updates` must be the last event in the feed.

##### Reconnection

If a client loses connection or needs to reconnect after a brief
disconnect (e.g. client restart), it can use the `since_token` parameter to
specify the last notification token it received:

`contests/<id>/event-feed?since_token=xx`

If specified, the server will attempt to start sending events since the
given token to reduce the volume of events and required reconciliation.
If the token is invalid, the time passed is too large (a server that
supports `since_token` should support an expiry time of at least
15 minutes), or the server does not support this parameter, the
request will fail with a 400 error.

The client is guaranteed to either get a 400 error or receive at
least all changes since the token (but it could also get (a lot) more,
e.g. if the server is multithreaded and needs to resend some events
to ensure they were received).

###### Server support for reconnecting

Some servers may not support any form of reconnection and may not
include any notification tokens, or will always return 400 when the
`since_token` parameter is used.

Other servers may support reconnecting, but only at certain checkpoints
or time periods. These providers might use timestamps or counters
as tokens, or only output them in certain events.

Other servers may include tokens in every notification and support
reconnecting at any point.

##### Examples

The following are examples of contest events:

```json
{"type":"problems","id":null,"data":[
   {"id":"asteroids","label":"A","name":"Asteroid Rangers","ordinal":1,"color":"blue","rgb":"#00f","time_limit":2,"test_data_count":10},
   {"id":"bottles","label":"B","name":"Curvy Little Bottles","ordinal":2,"color":"gray","rgb":"#808080","time_limit":3.5,"test_data_count":15}]}
```

```json
{"type":"state","id":null,"data":{
   "started": "2014-06-25T10:00:00+01",
   "ended": null,
   "frozen": "2014-06-25T14:00:00+01",
   "thawed": null,
   "finalized": null,
   "end_of_updates": null}}
```

```json
{"type":"teams","id":"11","data":{"id":"11","icpc_id":"201433","name":"Shanghai Tigers","organization_id":"inst123","group_id":"asia"}}
```

```json
{"type":"teams","id":"11","data":{"id":"11","icpc_id":"201433","name":"The Shanghai Tigers","organization_id":"inst123","group_id":"asia"}}
```

```json
{"type":"teams","id":"11","data":null}
```

### Webhooks

Webhooks receiving change [notifications](#notification-format) (events)
of the data presented by the API.

The following endpoints are associated with webhooks:

| Endpoint        | Mime-type        | Description
| --------------- | ---------------- | :----------
| `webhooks`      | application/json | JSON array of all webhook callbacks with properties as defined in the table below. Also used to register new webhooks.
| `webhooks/<id>` | application/json | JSON object representing a single webhook callback with properties as defined in the table below.

Properties of webhook callback objects:

| Name         | Type            | Description
| :----------- | :-------------- | :----------
| id           | ID              | identifier of the webhook.
| url          | string          | The URL to post HTTP callbacks to.
| endpoints    | array of string | Names of endpoints to receive callbacks for. Empty array means all endpoints.
| contest\_ids | array of ID     | ID’s of contests to receive callbacks for. Empty array means all configured contests.

A webhook allows you to receive HTTP callbacks whenever there is a
change to the contest. Clients are only notified of changes after
signing up; they are expected to use other mechanisms if they need to
determine the current state of the contest. Every callback will contain
one JSON object containing the id of the contest that changed and any
number of [notifications](#notification-format) objects as follows:

```json
{"contest_id": "<id>", "notifications":[ <JSON notification format>, <JSON notification format> ] }
```

Responding to each callback with a 2xx response code indicates successful
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

##### Adding a webhook

To register a webhook, you need to post your server's callback URL. To
do so, perform a `POST` request with a JSON body with the properties (except
`id`) from the above table to the `webhooks` endpoint together with one
additional property, called `token`. In this property put a client-generated
token that can be used to verify that callbacks come from the CCS. If
you don't supply `contest_ids` and/or `endpoints`, they will default to
`[]`.

##### Examples

Request:

` POST https://example.com/api/webhooks`

Payload:

```json
{"url": "https://myurl", "token": "mysecrettoken" }
```

Request:

` GET https://example.com/api/webhooks`

Returned data:

```json
[{
    "id":"icpc-live",
    "url":"https://myurl",
    "endpoints": [],
    "contest_ids": [],
    "active": true
},{
    "id":"shadow",
    "url":"https://myotherurl",
    "endpoints": ["teams", "problems"],
    "contest_ids": ["wf2014"],
    "active": false
}]
```

When a system wants to send out a callback, it will check all active
webhooks, filter them on applicable endpoint and contest ID and perform
a `POST` to the URL. The system will add a header to this request called
`Webhook-Token` which contains the token as supplied when creating the
webhook. Clients should verify that this token matches with what they
expect.

Client callback:
```json
{"contest_id":"finals","notifications":[
  {"type":"teams","id":"11","data":{"id":"11","icpc_id":"201433","name":"Shanghai Tigers","organization_id":"inst123","group_id":"asia"}},
  {"type":"submissions","id":"187","data":{
      "id": "187",
      "team_id": "123",
      "problem_id": "10-asteroids",
      "language_id": "1-java",
      "time": "2014-06-25T11:22:05.034+01",
      "contest_time": "1:22:05.034",
      "entry_point": "Main",
      "files": [{"href":"contests/wf14/submissions/187/files","mime":"application/zip"}]}},
   {"type":"state","data":{
      "started": "2014-06-25T10:00:00+01",
      "ended": null,
      "frozen": "2014-06-25T14:00:00+01",
      "thawed": null,
      "finalized": null,
      "end_of_updates": null}}
]}
```
