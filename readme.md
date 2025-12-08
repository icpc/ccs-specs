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

   1. Add support for **post\_comment** capability (posting commentary)
   2. Add property **tag** (array of string) to file reference objects (FILE) along with a description of how it may be used. (eg. hints such as light or dark for images)
   3. contests endpoint
      1. Change **penalty\_time** from integer minutes to **RELTIME** (breaking change)
   4. judgement-types endpoint
      1. Add property **simplified\_judgement\_type\_id** (ID ?)
   5. problems endpoint
      1. Add property **memory\_limit** (integer)
      2. Add property **output\_limit** (integer)
      3. Add property **code\_limit**  (integer)
      4. Add property **attachments** (array of FILE ?)
   6. organizations endpoint
      1. Add property **country\_subdivision** (string ?)
      2. Add property **country\_subdivision\_flag** (array of FILE ?)
   7. submissions endpoint
      1. Add property **account\_id** (ID ?)
      2. Made **team\_id** optional (ID ?)
   8. judgements endpoint
      1. Add property **current** (boolean ?)
      2. Add property **simplified\_judgement\_type\_id** (ID ?)
   9. clarifications endpoint
      1. Teams must have the **post\_clar** capability to post a clarification (previously was **team\_clar**)  (breaking change)
      2. Rule change about what properties may be specified in a **POST** when the **post\_clar** capability is present. (breaking change)
      3. Remove **to\_team\_id** and replace it with **to\_team\_ids** and **to\_group\_ids** to allow broader targeting of destination team(s). (breaking change)
   10. awards endpoint
      1. Added new ICPC world finals specific rules for honors, high-honors and highest-honors
   11. commentary endpoint
       1. Add ability to modify (post) a comment
   12. scoreboard endpoint
       1. Change **score.total\_time** from **integer** to **RELTIME** (breaking change)
       2. Change **score.time** from **integer** to **RELTIME ?** (breaking change)
       3. Change **problems.time** from **integer** to **RELTIME** (breaking change)
   13. **Note:** Event feed notifications containing the above objects must also be updated as indicated.

Further improvements (no functional changes intended):

   1. Clarify that **baseurl** must end in a slash. Change all endpoint URLs to be correctly relative by removing prefix slashes.
   2. Change [IETF.org](http://IETF.org) RFC references to use the current website.
   3. General design principles
      1. JSON property types
         1) Description of *Identifiers* clarified.
         2) Clarify no meaning is implied by the order of objects in arrays.
         3) Added note to href
      2. Capabilities
         1) Removed TODO about adding capabilities for team view and awards.
         2) Added warning about capabilities being fleeting
   4. Interface specification
      1. Types of endpoints
         1) Wording change (groups-\>types)
      2. Filtering
         1) Specify explicitly that nullable ID’s can be filtered on
      3. Access
         1) Updated examples (already backpatched to 2023-06)
      4. Contests
         1) Clarify wording for **countdown\_pause\_time** and description below
      5. Languages
         1) Change gcc example to include **\-o a.out**
         2) **ERROR** in example for **“id”: “cpp”** \-  can not use gcc to build c++ programs  \- should be fixed
      6. Problems
         1) Clarify maximum score for problems in **score** type contests.
         2) Clarify that the **rgb** property should not include an alpha channel.
         3) Fixed JSON formatting error in example.
      7. Teams
         1) Update description of **id** property to no longer include suggestion of using the **id** as the seat number since **label** does that.
         2) Allow HLS video (`application/vnd.apple.mpegurl`) for **video**, **desktop, webcam** and **reaction** properties.
      8. State
          1) Minor wording changes that affect nothing
      9. Submissions
          1) Added text indicating why the **id** should be a small number
          2) Clarify what a missing **team\_id** property implies.
          3) Spelling fixes (entrypoint \-\> entry point)
          4) Clarify that the **data** property for the **files** array is a *base64 encoded zip* file
      10. Clarifications
          1) Provide more detail on broadcast clarification responses
          2) Consistently use “judges” instead of “jury” in descriptions.


## References

- Website: <https://ccs-specs.icpc.io>
- Github: <https://github.com/icpc/ccs-specs>
- Problem package format specification: <https://icpc.io/problem-package-format/>
