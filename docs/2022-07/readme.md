# 2022-07 Contest Control System (CCS) specification

This branch contains the 2022-07 CCS specification for
interoperability between different contest control systems and tools
that interact with them. These specifications have been designed and
used in the context of the [ICPC World Finals](https://icpc.global)
and various (sub)regionals, but they are meant to be useful outside
the ICPC context as well.

The following specifications are present:

* Contest Control System requirements for the ICPC World Finals
* Contest API: an API specification for accessing information
  provided by a CCS.
* Contest Package Format: a format closely related to the Contest API
  for storing contest information on disk.

This is the `2022-07` release of the CCS specification.
Other versions of the CCS specifications are available
[here](https://ccs-specs.icpc.io/).

## Changes compared to the `2021-11` version

These are the main changes made since the `2021-11` version:

* Access restrictions have been moved from the Contest API specification to
  the CCS system requirements document.
* `ORDINAL` types are removed.
* `IMAGE`, `VIDEO`, `ARCHIVE` and `STREAM` types are now of type `FILE`.
* Nullable types are added.
* `FILE` types now have a `filename` and `hash` property.
* The format of the event feed changed.
* The event feed now supports reconnection tokens.
* A new API information endpoint has been added.
* A new Access endpoint has been added.
* Specific permissions have been replaced with a generic capabilities approach.
* Renamed the Team members endpoint to Persons and made `team_id` in it optional.
* A new Accounts endpoint has been added.
* The CCS system requirements document specifies the required minimal access restrictions
  and the capabilities required by a CCS for the World Finals.
* Groups now support a `location` attribute.
* Performing a `POST` or `PUT` for the Submissions endpoint is now more generally available
  depending on the capabilities of an account.
* Performing a `POST` for the Clarification endpoint is now more generally available depending
  on the capabilities of an account.
* The Commentary endpoint now has a `tags`, `source_id` and `submission_ids` property and the
  mesage format changed.
* It is no longer possible to request the scoreboard at the time of a given event and the `event_id`
  property is dropped from the response.
* Importing contest configuration is no longer done through TSV files, but using a contest package.
* Contest Archive has been renamed to Contest Package.
* Add package and statement to Problem endpoint.

## References

* Website: <https://ccs-specs.icpc.io>
* Github: <https://github.com/icpc/ccs-specs>
* Problem package format specification: <https://icpc.io/problem-package-format/>