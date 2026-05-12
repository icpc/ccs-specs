# Contest Control System specifications

This repository contains a set of related specifications for
interoperability between different contest control systems and tooling
that interacts with it. These specifications have been designed and
used in the contest of the ICPC World Finals, and have also been used
at various (sub)regionals; they are meant to be useful outside an ICPC
context as well.

The following specifications are present:

- Contest Control System requirements for the ICPC World Finals
- JSON Format: the shared data model defining the JSON objects used
  across these specifications.
- Contest API: an API specification for accessing information provided by a
  CCS.
- Contest Package Format: a format closely related to the Contest API for
  storing a contest on disk.

Furthermore, a tool and JSON schema specifications are available to
validate an implementation of the Contest API. Run `check-api.sh -h`
from the root of the repository for usage information.

There are multiple versions of the CCS specifications available on the
[documentation pages](https://ccs-specs.icpc.io/).

This is the draft of some future version of the CCS specification.

## Changes compared to the `2026-01` version

- Added a style guide to be used for all specifications.
- Split the former "CCS System Requirements" document into two documents:
  a generic [Contest Control System](ccs) specification defining what it
  means to be a CLICS-compatible CCS, and a
  [World Finals CCS Requirements](wf_requirements) document that defines
  the specific requirements for running the ICPC World Finals by
  referencing the former and mandating a specific subset of its optional
  capabilities.
- Extracted a new [JSON Format](json_format) specification containing
  the shared data model (JSON property types, object definitions, and
  notification object format) previously embedded in the [Contest API](contest_api). 
  The Contest API and Contest Package Format now reference this document for
  all shared object definitions.
- Renamed object sections in JSON Format from plural to singular (e.g.
  "Problems" to "Problem"), renamed "File" to "File reference" and
  "Notification object" to "Notification", and updated all cross-references
  accordingly.
- Added `score` field to [runs](json_format#runs) for scoring contests,
  with a note that per-run scores are not well-defined for most problems.
- Restructured the `role` field on [persons](json_format#persons) into a
  `roles` array of objects, each with a `type`, optional `title`, and
  optional `team_id`, to support persons with multiple roles.
- Added `coach` as a supported [account](json_format#accounts) type.
- Added `desktop` and `webcam` as known [file reference](json_format#file-reference)
  tags.
- Added `removed_intervals` to the [contest state](json_format#contest-state)
  object, allowing time intervals to be marked as disregarded for scoring
  purposes. Intervals must be non-overlapping and sorted by start time.
- Removed `contest_time` from [judgements](json_format#judgements) and
  [runs](json_format#runs), as these values are not meaningful for scoring
  and would require unnecessary resending of objects when removed intervals
  change.
- Added `primary_rgb`, `primary_color`, `secondary_rgb`, and `secondary_color`
  fields to [teams](json_format#teams) for t-shirt color information.

## References

- Website: <https://ccs-specs.icpc.io>
- Github: <https://github.com/icpc/ccs-specs>
- Problem package format specification: <https://icpc.io/problem-package-format/>
