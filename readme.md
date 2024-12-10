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

Furthermore, a tool and JSON schema specifications are available to
validate an implementation of the Contest API. Run `check-api.sh -h`
from the root of the repository for usage information.

There are multiple versions of the CCS specifications available on the
[documentation pages](https://ccs-specs.icpc.io/).

This is the draft of some future version of the CCS specification.

## Changes compared to the `2023-06` version

These are the main changes made since the `2023-06` version:

- Changed type of `penalty_time` in contest enpoint from `integer` to `RELTIME`.
- Changed type of time related properties in scoreboard endpoint from `integer` to `RELTIME`.
- Added `country_subdivision` and `country_subdivision_flag` to organizations endpoint.

## References

- Website: <https://ccs-specs.icpc.io>
- Github: <https://github.com/icpc/ccs-specs>
- Problem package format specification: <https://icpc.io/problem-package-format/>
