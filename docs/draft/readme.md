# Contest Control System specifications

This repository contains a set of related specifications for
interoperability between different contest control systems and tooling
that interacts with it. These specifications have been designed and
used in the contest of the ICPC World Finals, and have also been used
at various (sub)regionals; they are meant to be useful outside an ICPC
context as well.

The following specifications are present:

- Contest Control System requirements for the ICPC World Finals
- Contest API: an API specification for accessing information provided by a
  CCS.
- Contest Archive Format: a format closely related to the Contest API for
  storing a contest on disk for archival.

There are multiple versions of the CCS specifications available on the
[documentation pages](https://ccs-specs.icpc.io/).

This is the draft of some future version of the CCS specification.

## Changes compared to the `2022-07` version

These are the main changes made since the `2022-07` version:

* Renamed `version-command` to `version_command` in the Language endpoint.
* Added `twitter_account` to the Organization endpoint.
* Changed `team_id` (of type `ID`) to `team_ids` (of type `array of ID`) in the Person endpoint.
* Added `name` to the Account endpoint.
* Added a `contest_thaw` capability to thaw a contest via a PATCH request.


## References

- Website: <https://ccs-specs.icpc.io>
- Github: <https://github.com/icpc/ccs-specs>
- Problem package format specification: <https://icpc.io/problem-package-format/>
