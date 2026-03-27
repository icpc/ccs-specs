---
sort: 3
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

The data returned by this API is described in the [JSON Format](json_format)
specification.

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

### File references

The `href` property of [file reference objects](json_format#file) must always
be present in responses from the API. Relative URLs must be interpreted
relative to the `baseurl` of the API. For example, if
`baseurl` is <https://example.com/api/>, then the following are
equivalent JSON response snippets pointing to the same location:

```json
  "href":"https://example.com/api/contests/wf14/submissions/187/files"
  "href":"contests/wf14/submissions/187/files"
  "href":"/api/contests/wf14/submissions/187/files"
```

Resources referenced by file references must be accessible using the
exact same (possibly none) authentication as the call that returned the
data.

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

### Referential integrity

Some properties in an object are references to IDs of other objects,
as defined in the [JSON Format](json_format#object-definitions) specification.
When such a property has a non-`null` value, then the referenced
object must exist. That is, the full set of data exposed by the API
must at all times be referentially intact. This implies for example that
before creating a [team](json_format#teams) with an `organization_id`,
the [organization](json_format#organizations) must already exist. In
reverse, that organization can only be deleted after the team is
deleted, or alternatively, the team's `organization_id` is set to
`null`.

Furthermore, the ID property (see [JSON Format](json_format#json-property-types))
of objects are not allowed to change. However, note that a particular ID might be
reused by first deleting an object and then creating a new object with the same ID.

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

Each notification is a [notification object](json_format#notification-object)
as defined in JSON Format. The correspondence between notification types
and API endpoints is:

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

In the tables below, the columns are as described in
[JSON Format](json_format#table-column-description).

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
See [JSON Format](json_format#api-information) for the object definition and
examples.

The following endpoint is associated with API information:

| Endpoint | Mime-type        | Description
| :------- | :--------------- | :----------
| `.`      | application/json | [API information object](json_format#api-information).

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
| type         | string          | The type of the endpoint, e.g. "problems". See [JSON Format](json_format#notification-object) for the list of types.
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
See [JSON Format](json_format#contests) for object properties and examples.

The following endpoints are associated with contest:

| Endpoint        | Mime-type        | Description
| :-------------- | :--------------- | :----------
| `contests`      | application/json | JSON array of [contest objects](json_format#contests) with properties as specified by [access](#access).
| `contests/<id>` | application/json | A [contest object](json_format#contests) with properties as specified by [access](#access).

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

See [JSON Format](json_format#judgement-types) for object properties and examples.

The following endpoints are associated with judgement types:

| Endpoint                             | Mime-type        | Description
| :----------------------------------- | :--------------- | :----------
| `contests/<id>/judgement-types`      | application/json | JSON array of [judgement type objects](json_format#judgement-types) with properties as specified by [access](#access).
| `contests/<id>/judgement-types/<id>` | application/json | A [judgement type object](json_format#judgement-types) with properties as specified by [access](#access).

### Languages

See [JSON Format](json_format#languages) for object properties and examples.

The following endpoints are associated with languages:

| Endpoint                       | Mime-type        | Description
| :----------------------------- | :--------------- | :----------
| `contests/<id>/languages`      | application/json | JSON array of [language objects](json_format#languages) with properties as specified by [access](#access).
| `contests/<id>/languages/<id>` | application/json | A [language object](json_format#languages) with properties as specified by [access](#access).

### Problems

See [JSON Format](json_format#problems) for object properties and examples.

The following endpoints are associated with problems:

| Endpoint                      | Mime-type        | Description
| :---------------------------- | :--------------- | :----------
| `contests/<id>/problems`      | application/json | JSON array of [problem objects](json_format#problems) with properties as specified by [access](#access).
| `contests/<id>/problems/<id>` | application/json | A [problem object](json_format#problems) with properties as specified by [access](#access).

### Groups

See [JSON Format](json_format#groups) for object properties and examples.

The following endpoints are associated with groups:

| Endpoint                    | Mime-type        | Description
| :-------------------------- | :--------------- | :----------
| `contests/<id>/groups`      | application/json | JSON array of [group objects](json_format#groups) with properties as specified by [access](#access).
| `contests/<id>/groups/<id>` | application/json | A [group object](json_format#groups) with properties as specified by [access](#access).

Note that these endpoints must be provided if groups are used. If they
are not provided no other endpoint may refer to groups (i.e. return any
group\_ids).

### Organizations

See [JSON Format](json_format#organizations) for object properties and examples.

The following endpoints are associated with organizations:

| Endpoint                           | Type             | Description
| :--------------------------------- | :--------------- | :----------
| `contests/<id>/organizations`      | application/json | JSON array of [organization objects](json_format#organizations) with properties as specified by [access](#access).
| `contests/<id>/organizations/<id>` | application/json | An [organization object](json_format#organizations) with properties as specified by [access](#access).

Note that the first two endpoints must be provided if organizations are
used. If they are not provided no other endpoint may refer to
organizations (i.e. return any organization\_ids).

### Teams

See [JSON Format](json_format#teams) for object properties and examples.

The following endpoints are associated with teams:

| Endpoint                    | Mime-type        | Description
| :-------------------------- | :--------------- | :----------
| `contests/<id>/teams`       | application/json | JSON array of [team objects](json_format#teams) with properties as specified by [access](#access).
| `contests/<id>/teams/<id>`  | application/json | A [team object](json_format#teams) with properties as specified by [access](#access).

### Persons

See [JSON Format](json_format#persons) for object properties and examples.

The following endpoints are associated with persons:

| Endpoint                     | Mime-type        | Description
| :--------------------------- | :--------------- | :----------
| `contests/<id>/persons`      | application/json | JSON array of [person objects](json_format#persons) with properties as specified by [access](#access).
| `contests/<id>/persons/<id>` | application/json | A [person object](json_format#persons) with properties as specified by [access](#access).

### Accounts

See [JSON Format](json_format#accounts) for object properties and examples.

The following endpoints are associated with accounts:

| Endpoint                      | Mime-type        | Description
| :---------------------------- | :--------------- | :----------
| `contests/<id>/accounts`      | application/json | JSON array of [account objects](json_format#accounts) with properties as specified by [access](#access).
| `contests/<id>/accounts/<id>` | application/json | An [account object](json_format#accounts) with properties as specified by [access](#access).
| `contests/<id>/account`       | application/json | The [account object](json_format#accounts) of the client making the request, with properties as specified by [access](#access) for the account used.

The account endpoint exists so that the clients can tell which account (and hence which person or team) they are logged in as. The corresponding JSON file does not appear in a Contest Package, and the endpoint will fail with a 404 error code if the client is not authenticated.

### Contest state

See [JSON Format](json_format#contest-state) for object properties and examples.

The following endpoints are associated with state:

| Endpoint              | Type             | Description
| :-------------------- | :--------------- | :----------
| `contests/<id>/state` | application/json | The [contest state object](json_format#contest-state) with properties as specified by [access](#access).

### Submissions

See [JSON Format](json_format#submissions) for object properties and examples.

The following endpoints are associated with submissions:

| Endpoint                         | Type             | Description
| :------------------------------- | :--------------- | :----------
| `contests/<id>/submissions`      | application/json | JSON array of [submission objects](json_format#submissions) with properties as specified by [access](#access).
| `contests/<id>/submissions/<id>` | application/json | A [submission object](json_format#submissions) with properties as specified by [access](#access).

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
   "files":[{"data": "<base64 encoded zip file>"}]
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

See [JSON Format](json_format#judgements) for object properties and examples.

The following endpoints are associated with judgements:

| Endpoint                        | Mime-type        | Description
| :------------------------------ | :--------------- | :----------
| `contests/<id>/judgements`      | application/json | JSON array of [judgement objects](json_format#judgements) with properties as specified by [access](#access).
| `contests/<id>/judgements/<id>` | application/json | A [judgement object](json_format#judgements) with properties as specified by [access](#access).

### Runs

See [JSON Format](json_format#runs) for object properties and examples.

The following endpoints are associated with runs:

| Endpoint                  | Mime-type        | Description
| :------------------------ | :--------------- | :----------
| `contests/<id>/runs`      | application/json | JSON array of [run objects](json_format#runs) with properties as specified by [access](#access).
| `contests/<id>/runs/<id>` | application/json | A [run object](json_format#runs) with properties as specified by [access](#access).

### Clarifications

See [JSON Format](json_format#clarifications) for object properties and examples.

The following endpoints are associated with clarification messages:

| Endpoint                            | Mime-type        | Description
| :---------------------------------- | :--------------- | :----------
| `contests/<id>/clarifications`      | application/json | JSON array of [clarification objects](json_format#clarifications) with properties as specified by [access](#access).
| `contests/<id>/clarifications/<id>` | application/json | A [clarification object](json_format#clarifications) with properties as specified by [access](#access).

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

See [JSON Format](json_format#awards) for object properties and examples.

The following endpoints are associated with awards:

| Endpoint                    | Mime-type        | Description
| :-------------------------- | :--------------- | :----------
| `contests/<id>/awards`      | application/json | JSON array of [award objects](json_format#awards) with properties as specified by [access](#access).
| `contests/<id>/awards/<id>` | application/json | An [award object](json_format#awards) with properties as specified by [access](#access).

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

See [JSON Format](json_format#commentary) for object properties and examples.

The following endpoints are associated with commentary:

| Endpoint                        | Mime-type        | Description
| :------------------------------ | :--------------- | :----------
| `contests/<id>/commentary`      | application/json | JSON array of [commentary objects](json_format#commentary) with properties as specified by [access](#access).
| `contests/<id>/commentary/<id>` | application/json | A [commentary object](json_format#commentary) with properties as specified by [access](#access).

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

### Scoreboard

Scoreboard of the contest.
See [JSON Format](json_format#scoreboard) for the scoreboard object format.

Since this is generated data, only the `GET` method is allowed here,
irrespective of role.

The following endpoint is associated with the scoreboard:

| Endpoint                   | Mime-type        | Description
| :------------------------- | :--------------- | :----------
| `contests/<id>/scoreboard` | application/json | [Scoreboard object](json_format#scoreboard).

The scoreboard includes all teams indicated by `main_scoreboard_group_id` in the `contest` endpoint.

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

### Event feed

Change [notifications](json_format#notification-object) (events) of the data
presented by the API.

The following endpoint is associated with the event feed:

| Endpoint                   | Mime-type            | Description
| :------------------------- | :------------------- | :----------
| `contests/<id>/event-feed` | application/x-ndjson | NDJSON feed of [notification objects](json_format#notification-object).

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
- the notification for the [state endpoint](json_format#contest-state) setting
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

Webhooks receiving change [notifications](json_format#notification-object) (events)
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
| contest\_ids | array of ID     | ID's of contests to receive callbacks for. Empty array means all configured contests.

A webhook allows you to receive HTTP callbacks whenever there is a
change to the contest. Clients are only notified of changes after
signing up; they are expected to use other mechanisms if they need to
determine the current state of the contest. Every callback will contain
one JSON object containing the id of the contest that changed and any
number of [notification objects](json_format#notification-object) as follows:

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
