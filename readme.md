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

**Functional Changes**  
   1. Add support for **post\_comment** capability (posting commentary)  
   2. contests EP  
      1. Change **penalty\_time** from integer minutes to **RELTIME** (breaking change)  
   3. judgement-types EP  
      1. Add property **simplified\_judgement\_type\_id** (ID ?)  
   4. problems EP  
      1. Add property **memory\_limit** (integer)  
      2. Add property **output\_limit** (integer)  
      3. Add property **code\_limit**  (integer)  
      4. Add property **attachments** (array of FILE ?)  
   5. organizations EP  
      1. Add property **country\_subdivision** (string ?)  
      2. Add property **country\_subdivision\_flag** (array of FILE ?)  
   6. submissions EP  
      1. Add property **account\_id** (ID ?)  
      2. Made **team\_id** optional (ID ?)  
   7. judgements EP  
      1. Add property **current** (boolean ?)  
      2. Add property **simplified\_judgement\_type\_id** (ID ?)  
   8. clarifications EP  
      1. Teams must have the **post\_clar** capability to post a clarification (previously was **team\_clar**)  (breaking change)  
      2. Rule change about what properties may be specified in a **POST** when the **post\_clar** capability is present. (breaking change)  
      3. Remove **to\_team\_id** and replace it with **to\_team\_ids** and **to\_group\_ids** to allow broader targeting of destination team(s). (breaking change)  
   9. awards EP  
      1. Added new rules for honors, high-honors and highest-honors  
   10. commentary EP  
       1. Add ability to modify (post) a comment  
   11. scoreboard EP  
       1. Change **score.total\_time** from **integer** to **RELTIME** (breaking change)  
       2. Change **score.time** from **integer** to **RELTIME ?** (breaking change)  
       3. Change **problems.time** from **integer** to **RELTIME** (breaking change)  
   12. **Note:** Event feed notifications containing the above objects must also be updated as indicated.

**Non-functional Changes** (documentation)  
   1. Entire Document  
      1. Change all endpoint URLs to be correctly relative by removing prefix slashes.  This applies to all endpoints in the document.  
      2. Change [IETF.org](http://IETF.org) RFC references to use current website.  
   2. General design principles  
      1. Endpoint URLs  
         1) Clarify that **baseurl** must end in a slash.  
         2) Add examples and reference to RFC  
      2. JSON property types  
         1) Description of *Identifiers* clarified.  
         2) Clarify no meaning is implied by the order of objects in arrays.  
         3) Added note to href  
         4) Added property **tag** (array of string) to file reference objects (FILE) along with a description of how it may be used. (eg. hints such as light or dark for images)  
      3. Capabilities  
         1) Changed description of **post\_clar**  
         2) Added capability **post\_comment** for posting commentary  
         3) Removed TODO about adding capabilities for team view and awards.  
         4) Added warning about capabilities being fleeting  
   3. Interface specification  
      1. Types of endpoints  
         1) Wording change (groups-\>types)  
         2) Added statement about judgment **current** property may change  
      2. Filtering  
         1) Specify explicitly that nullable ID’s can be filtered on  
      3. Access  
         1) Updated examples (already backpatched to 2023-06)  
      4. Contests  
         1) Clarify wording for **countdown\_pause\_time** and description below  
         2) Change type of penalty\_time to **RELTIME**  
         3) Change examples to use **RELTIME** for **penalty\_time**  
      5. Judgement Types  
         1) Added description of new property **simplified\_judgement\_type**  
         2) Added example for **simplified\_judgement\_type**  
      6. Languages  
         1) Change gcc example to include **\-o a.out**  
         2) **ERROR** in example for **“id”: “cpp”** \-  can not use gcc to build c++ programs  \- should be fixed  
      7. Problems  
         1) Added descriptions for new properties **memory\_limit**, **output\_limit**, **code\_limit, attachments**  
         2) Clarify maximum score for problems in **score** type contests.  
         3) Clarify that the **rgb** property should not include an alpha channel.  
         4) Fixed examples to include newly added properties  
         5) Fixed JSON formatting error in example.  
      8. Organizations  
         1) Added descriptions for new country subdivision properties  
         2) Updated examples to include country subdivisions  
      9. Teams  
         1) Update description of **id** property to no longer include suggestion of using the **id** as the seat number since **label** does that.  
         2) Remove specific mention of no implied order ID’s in an array for **team\_ids** and **group\_ids** since it’s covered in the *General Design Principles*.  
         3) Allow HLS video (application/vnd.apple.mpegurl) for **video**, **desktop, webcam** and **reaction** properties.  
      10. State  
          1) Minor wording changes that affect nothing  
      11. Submissions  
          1) Added text indicating why the **id** should be a small number  
          2) Add description of new property **account\_id**.  
          3) Clarify what a missing **team\_id** property implies.  
          4) Spelling fixes (entrypoint \-\> entry point)  
          5) Clarify that the **data** property for the **files** array is a *base64 encoded zip* file  
      12. Judgements  
          1) Add description of new properties: **current, simplified\_judgement\_type**  
      13. Clarifications  
          1) Change **team\_clar** capability to **post\_clar** capability  
          2) Added description of how the new **to\_team\_ids** and **to\_group\_ids** properties should be used.  
          3) Provide more detail on broadcast clarification responses  
          4) Consistently use “judges” instead of “jury” in descriptions.  
          5) Update rules for **post\_clar** capability (which fields may be specified by what roles, etc).  
      14. Awards  
          1) Added descriptions of new “Bill” rules awards for honors, high-honors, highest-honors  
      15. Commentary  
          1) Add description of how to post commentary  
      16. Scoreboard  
          1) Change types for **score.total\_time**, **score.time**, **problems.time** to **RELTIMEs**  
          2) Update examples to use **RELTIME**s in changed properties


## References

- Website: <https://ccs-specs.icpc.io>
- Github: <https://github.com/icpc/ccs-specs>
- Problem package format specification: <https://icpc.io/problem-package-format/>
