# 2021-11 Contest Control System (CCS) specification

This branch contains the 2021-11 CCS specification for
interoperability between different contest control systems and tools
that interact with them. These specifications have been designed and
used in the context of the [ICPC World Finals](https://icpc.global)
and various (sub)regionals, but they are meant to be useful outside
the ICPC context as well.

The following specifications are present:

* Contest Control System requirements for the ICPC World Finals
* Contest API: an API specification for accessing information
  provided by a CCS.
* Contest Archive Format: a format closely related to the Contest API
  for storing contest information on disk.

This is the `2021-11` release of the CCS specification.
Other versions of the CCS specifications are available
[here](https://ccs-specs.icpc.io/).

## Changes compared to the `2020-03` version

These are the main changes made since the `2020-03` version:

* `decimal` types are removed.
* Images can now also be SVG.
* Introduced a notification format that replaces the current event feed
  format and added support for webhooks.
* Added generic support for filtering on fields with type `ID`.
* Addded support for scoring contests.
* Added location to a contest.
* Added entry point information, extensions and compiler/runner command objects
  to languages.
* Added a `uuid` field to problems.
* Added group scoreboards and removed `hidden` from the groups endpoint.
* Added country flags to organizations.
* Added a `hiden` field to teams.
* Merged `first_name` and `last_name` of team members into `name` and added `email`.
* Added support for `POST` and `PUT` on submissions.
* Added support for `POST` on clarifications.
* Added support for `POST`, `PUT`, `PATCH` and `DELETE` on awards.
* Added commentary endpoint.

## References

* Website: <https://ccs-specs.icpc.io>
* Github: <https://github.com/icpc/ccs-specs>
* Problem package format specification: <https://icpc.io/problem-package-format/>
