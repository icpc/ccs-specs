---
sort: 5
permalink: /wf_requirements
---
# World Finals CCS Requirements

## Introduction

This document specifies the requirements for a Contest Control System (CCS) to
be considered for managing the operation of the
[ICPC World Finals](https://icpc.global). It defines the specific capabilities
and constraints that any candidate system must provide, beyond those required
for general CLICS compatibility.

A candidate CCS MUST first satisfy all base requirements defined in the
[Contest Control System](ccs) specification. This document then defines
additional requirements and constraints specific to the World Finals, as well as
mandating certain optional capabilities from the base specification.

The current draft of this requirements document is *Version 1.0*, published
*\<insert publication date\>* by the *Competitive Learning Institute*
(*\<insert CLI website URL\>*). \[TODO: insert final publication date and CLI
website URL once approved.\]

The primary authors of this document are John Clevenger and Fredrik Niemelä,
acting under the auspices of the Competitive Learning Institute (CLI).
Contributors include Samir Ashoo, Per Austrin, Troy Boudreau, Tim deBoer, Emma
Enström, Mikael Goldman, Gunnar Kreitz, Doug Lane, Pehr Söderman, and Mattias
de Zalenski.

### Rationale

This document is intended to specify functional requirements, not
implementation requirements. Nothing in this document should be construed as
requiring any particular implementation architecture or use of any particular
implementation language or languages.

These requirements are not intended to act as a specification for what
constitutes "best practices" in a Contest Control System; rather, they act
solely as a specification of what functionality is required to be a candidate
for running the ICPC World Finals. As such, there may be functions listed in
this document which are specific solely to the ICPC World Finals but might not
be required for running other contests.

Likewise, there may be functionality which a CCS provides to meet the
requirements of some other contest; such additional functionality will not
disqualify the CCS from qualifying as a candidate to run the ICPC World Finals
provided the CCS meets all the requirements listed in this document.

### Overview

A contest control system may be submitted to the Director of Operations for the
ICPC World Finals for consideration as a candidate to run the World Finals. The
items which must be submitted in order to be considered are described under
[Documentation Requirements](#documentation-requirements) in this document. Any
submitted CCS which meets all of the requirements defined in this document will
be certified as being accepted as a candidate to run the World Finals. Meeting
or failing to meet each requirement will be determined by a test specified by
the Director of Operations and/or their designee.

The choice of the CCS actually used to run the World Finals each year will be
made by the Director of Operations from among those CCSs which have been
accepted as candidates prior to the acceptance deadline.

## Required Capabilities

In addition to all base requirements in the
[Contest Control System](ccs) specification, a World Finals CCS MUST implement
the following optional capabilities defined there:

- [Contest API](ccs#contest-api)
- [Removing Time Intervals](ccs#removing-time-intervals)
- [Shadow Mode](ccs#shadow-mode)

A World Finals CCS MUST be capable of operating both as a Primary CCS and as a
Shadow CCS, meeting all requirements for both modes as defined in the
[Contest Control System](ccs#shadow-mode) specification. This applies
regardless of which mode the CCS would actually be used in for a particular
World Finals.

## General Requirements

### Licensing

The CCS MUST either be freely usable, or MUST be accompanied by a license
granting to the ICPC the non-exclusive, non-revocable, non-transferable rights
of use of the CCS both for purposes of evaluation and testing and for use in
the ICPC World Finals. The CCS MUST NOT require obtaining any third-party
license in order to be used by the ICPC.

### No Outside Contact

The CCS MUST be able to run at the World Finals site without contact to
anything outside the contest network.

### Limitations

#### Number of Problems

The CCS MUST support at least 15 problems. Specifically any UI, scoreboards or
other reports MUST be fully usable with that number of problems.

#### Number of Teams

The CCS MUST support at least 200 teams.

#### Test Data Files

The CCS MUST support at least 200 test data files per problem, a maximum size
of 8GB per test data file and a combined size for all test data files in a
problem of 20GB.

### Use At The World Finals

In order for a CCS to be selected for use at the World Finals the following
constraints must be satisfied:

#### Support Personnel

At least one person from the submitting entity with intimate knowledge about the
inner workings of the CCS MUST be willing and able to attend at the World
Finals where it is used.

#### Computer Platform

The CCS MUST run on the computer platform set aside for the CCS at the World
Finals and posted at the ICPC web site. Normally this will consist of one
machine per team, several auto-judging machines that are identical to the team
machines, and one or more servers.

## Contest Configuration

### Supported Languages

The CCS MUST provide the ability to compile and execute (or interpret, as
appropriate for the language) submitted source code files for each of the
languages specified by the
[Environment of the World Finals](https://icpc.global/worldfinals/programming-environment).

### Language Options

As required by the [Contest Control System](ccs#language-options) base
specification, the CCS MUST allow configuring compiler and interpreter
invocation options for all supported languages.

### Predefined Clarification Answers

As required by the [Contest Control System](ccs#predefined-clarification-answers)
base specification, the CCS MUST support predefined answers to clarification
requests. At least the following predefined answers MUST be provided as
defaults:

- No comment, read problem statement.
- This will be answered during the answers to questions session.

### Clarification Categories

As required by the [Contest Control System](ccs#clarification-categories) base
specification, the CCS MUST support clarification categories. At least the
following categories MUST be supported:

- General
- SysOps
- Operations

## Admin Interface

### Scoreboard Freeze Message

As required by the [Contest Control System](ccs#freezing-the-scoreboard) base
specification, the CCS MUST support freezing the scoreboard. When the
scoreboard is frozen, the exact phrase displayed MUST be:

The CCS must have a mechanism to disable any account (either an account for a
human user or for another system), without the need for starting or stopping
the contest. For example, this includes [team accounts]
(#secure-authentication) and judge accounts.

### Changes To Authentication Data

The CCS must allow user authentication credential information to be changed
dynamically by contest administration staff while the contest is running.

### Starting the Contest

The contest must automatically start when the configured start time is reached.
It must also be possible to start the contest at the current time.

### Adjusting for Exceptional Circumstances

#### Removing time intervals

It must be possible to, potentially retroactively, specify time intervals that
will be disregarded for the purpose of scoring. The time during all such
intervals will not be counted towards a team's penalty time for solved
problems. Beginning and end of time intervals are given in wall-clock time.
Time intervals must not overlap.

Note that removing a time interval changes the wall-clock time when the contest
ends, as the duration of the contest in
[contest.json](#importing-contest-configuration) is specified in contest time.

Removing the interval between time T<sub>0</sub> and T<sub>1</sub>, where
T<sub>0</sub> ≤ T<sub>1</sub>, means that all submissions received between
T<sub>0</sub> and T<sub>1</sub> will have the same contest time and that the
time for all submissions received after T<sub>1</sub> will have a contest time
that is T<sub>1</sub>-T<sub>0</sub> lower than if the interval was not
removed.

The removal of a time interval must be reversible. This means that if a time
interval is removed, the CCS must support the capability of subsequently
restoring the contest to the state it had prior to the removal of the time
interval.

Note that time interval removal does not affect the order in which submissions
arrived to the CCS. If submission S<sub>i</sub> arrived before submission
S<sub>j</sub> during a removed interval, S<sub>i</sub> must still be considered
by the CCS to have arrived strictly before S<sub>j</sub>.

#### Changing contest length

It must be possible to change the length of the contest at any time during the
contest.

#### Adding penalty time

It must be possible to specify, for each team, an integer, potentially negative,
amount of penalty time to be added into that team's total penalty time.

#### Ignoring submissions

It must be possible to remove, ignore or somehow mark a submission so that it in
no way affects the scoring of the contest.

### Pausing Judging

The CCS must provide some way to temporarily pause judging on a per problem
basis. While judging is paused teams should still be able to make submissions
and these submission should be shown on the scoreboard as usual.

### Rejudging

#### Automatic Rejudging

The CCS must allow the ability to automatically rejudge a selected set of
submissions.

Each submission in the set of selected submissions is executed and judged in the
same manner as for a newly arrived submission.

#### Previewing Rejudgement Results

There must be a way to preview the judgements which result from rejudging the
set of selected submissions without committing the resulting judgements.

#### Submission Selection

The CCS must provide the ability to specify a filter defining the set of
submissions to be rejudged. The CCS must support any combination of filters of
the following types:

- A specific (single) submission.
- All submissions for a specific problem.
- All submissions using a specific language.
- All submissions by a specific team or set of teams.
- All submissions between some time T<sub>0</sub> and some subsequent time
  T<sub>1</sub>.
- All submissions which have been assigned any specific one of the allowable
  submission judgments as defined in [Judge Responses](#judge-responses), or
  all submissions that received any judgment other than "Accepted" (that is,
  all rejected submissions).
- All submissions which have been run on a specific computer (identified in some
  reasonable way, e.g., IP address or hostname). This requirement is only
  applicable if the CCS uses multiple machines to run submissions.

Thus, for example, it must be possible to select "all rejected submissions for
problem B", "all Time Limit Exceeded submissions using Java for problem
C", "all submissions between time 2013-07-01 08:00:00+00 and time 2013-07-01
09:00:00+00 of the contest using Java", or "all submissions using C++".

### Manual Override of Judgments

The CCS must support the ability to assign, to a single submission, an updated
judgment chosen from among any of the allowed submission judgments as defined
in [Judge Responses](#judge-responses).

The CCS must require a separate authentication every time a judgment is changed
manually and all such changes must be logged.

### Scoreboard Display

The CCS must provide a mechanism for judges to view the current scoreboard. The
scoreboard must be updated in such a way that it's never more than 30 seconds
out of date.

During times when the scoreboard is frozen, administrators must be able to view
the current (updated) scoreboard as well as the frozen scoreboard.

### Freezing the Scoreboard

The scoreboard must automatically freeze when the configured scoreboard freeze
time is reached. It must also be possible to manually freeze the scoreboard at
the current time. All submissions received after the freeze time must be
treated as pending on a frozen scoreboard.

The exact phrase displayed on the frozen scoreboard must be:

> The scoreboard was frozen with XX minutes remaining - submissions in the last XX minutes of the contest are still shown as pending.

where XX is the number of minutes remaining in the contest at the time the
scoreboard was frozen.

### Finalizing the Contest

As required by the [Contest Control System](ccs#finalizing-the-contest) base
specification, the CCS MUST support finalizing the contest. In addition, the
following World Finals-specific requirements apply.

Before finalizing the contest the value B, as used in
[Scoring Data Generation](#scoring-data-generation), MUST be provided. The
default value for B MUST be 0.

If, after providing the correct and final value of B, the
[Scoreboard](contest_api#scoreboard) and [Awards](contest_api#awards) endpoints
contain the correct results, the admin MAY finalize the contest. These
endpoints MUST be compared with the ones exposed by the
[Shadow CCS](ccs#shadow-mode) and SHOULD also be manually sanity checked before
finalizing.

## Judging

### Judge Responses

As required by the [Contest Control System](ccs#judge-responses) base
specification, the CCS MUST answer each submission with a response from the
[known judgement types](json_format#known-judgement-types) list. For World
Finals use, the CCS MUST support exactly the following responses, which include
the Big 5 as well as SV and JE:

| Response            | Acronym | Penalty | Solved |
| ------------------- | ------- | ------- | ------ |
| Compile Error       | CE      | No      | No     |
| Run-Time Error      | RTE     | Yes     | No     |
| Time Limit Exceeded | TLE     | Yes     | No     |
| Wrong Answer        | WA      | Yes     | No     |
| Accepted            | AC      | No      | Yes    |
| Security Violation  | SV      | Yes     | No     |
| Judging Error       | JE      | No      | No     |

## Scoring

### Scoring Data Generation

The CCS MUST be capable of automatically generating up-to-date scoring data
according to the following:

1. For purposes of scoring, the *contest time of a submission* is the number of
   minutes elapsed from the beginning of the contest when the submission was
   made, skipping removed time intervals if specified (see
   [Removing Time Intervals](ccs#removing-time-intervals)). This is rounded
   *down* to the nearest minute, so 59.99 seconds is 0 minutes.
2. The *contest time that a team solved a problem* is the contest time of the
   team's first accepted submission to that problem.
3. A team's *penalty time on a problem* is the contest time that the team
   solved the problem, plus *penaltytime* (from
   [contest.json](ccs#importing-contest-configuration)) minutes for each
   previous submission rejected with a judgement that causes penalty time, by
   that team on that problem, or 0 if the team has not solved the problem.
4. A team's *total penalty time* is the sum of the penalty times for all
   problems plus any judge added penalty time.
5. A team's *last accepted submission* is the contest time of the problem that
   the team solved last.
6. The *position* of a team is determined by sorting the teams first by number
   of problems solved (descending), then within that by total penalty time
   (ascending), then within that by last accepted submission (ascending).
7. The *rank* of a team is then determined as follows:
   1. For teams in positions up to and including 12+B, the rank equals the
      position (B is provided when
      [finalizing the contest](#finalizing-the-contest); the default value is 0).
   2. Teams that solved fewer problems than the median team are not ranked at all.
   3. For the remaining teams, the rank is determined by sorting the teams by
      number of problems solved (descending).
8. The *awards* of a team are:
   1. `gold-medal` if rank is 1 through 4.
   2. `silver-medal` if rank is 5 through 8.
   3. `bronze-medal` if rank is 9 through 12+B.
   4. `rank-<rank>` if rank is not 1 through 12+B but the team is ranked.
   5. `highest-honors` if the team is ranked and the number of problems solved
      is at least as high as the team ranked 12+B.
   6. `high-honors` if the team is ranked and the number of problems solved is
      exactly one less than the team ranked 12+B.
   7. `honors` if the team is ranked and the number of problems solved is at
      least two less than the team ranked 12+B.
   8. `honorable-mention` if the team is not ranked.

When a number of teams are tied for the same position/rank, they all occupy the
same position/rank and a suitable number of subsequent positions/ranks are left
empty. For instance, if four teams are tied for 17th position, they are all in
17th position and positions 18, 19 and 20 are unoccupied.

### Scoreboard

As required by the [Contest Control System](ccs#scoreboard) base specification,
the CCS MUST provide a scoreboard. For World Finals use, the CCS MUST implement
the university-name-based scoreboard mode. The World Finals scoreboard MUST
therefore include:

- University name
- University logo

## Data Export

### Contest API

As defined in the [Contest Control System](ccs#contest-api) base specification,
a CCS MAY provide a live implementation of the [Contest API](contest_api). For
World Finals use, this is mandatory. The CCS MUST provide access to the Contest
API including the `/scoreboard` and `/event-feed` endpoints and MUST be
consistent with (at least) the following return from the `/access` endpoint:

```json
{
   "capabilities": [],
   "endpoints": [
      {
         "type": "contest",
         "properties": [
            "id", "name", "formal_name", "start_time", "duration",
            "scoreboard_freeze_duration", "penalty_time"
         ]
      },
      {
         "type": "judgement-types",
         "properties": [
            "id", "name", "penalty", "solved"
         ]
      },
      {
         "type": "languages",
         "properties": [
            "id", "name", "entry_point_required", "entry_point_name",
            "extensions", "compiler.command", "runner.command"
         ]
      },
      {
         "type": "problems",
         "properties": [
            "id", "label", "name", "ordinal", "rgb", "color",
            "time_limit", "test_data_count", "statement",
            "attachments"
         ]
      },
      {
         "type": "groups",
         "properties": [
            "id", "icpc_id", "name"
         ]
      },
      {
         "type": "organizations",
         "properties": [
            "id", "icpc_id", "name", "formal_name"
         ]
      },
      {
         "type": "teams",
         "properties": [
            "id", "icpc_id", "label", "name", "display_name",
            "organization_id", "group_ids"
         ]
      },
      {
         "type": "state",
         "properties": [
            "started", "frozen", "ended", "thawed", "finalized",
            "end_of_updates"
         ]
      },
      {
         "type": "submissions",
         "properties": [
            "id", "language_id", "problem_id", "team_id", "time",
            "contest_time", "entry_point", "files"
         ]
      },
      {
         "type": "judgements",
         "properties": [
            "id", "submission_id", "judgement_type_id", "start_time",
            "start_contest_time", "end_time", "end_contest_time",
            "max_run_time"
         ]
      },
      {
         "type": "runs",
         "properties": [
            "id", "judgement_id", "ordinal", "judgement_type_id",
            "time", "contest_time", "run_time"
         ]
      },
      {
         "type": "awards",
         "properties": [
            "id", "citation", "team_ids"
         ]
      }
   ]
}
```

Furthermore, the CCS MUST satisfy the following:

- It MUST publish [run](contest_api#runs) objects in real-time, so that
  ICPC-Live can track and publish judging progress.

#### Access Restrictions

The following access restrictions MUST apply to GETs on the API endpoints:

- The `public` role can only access the `/problems` endpoint after the contest
  has started. That is, before contest start `/problems` returns an empty array
  for clients with the `public` role.
- The `backup` element of the `/teams` endpoint requires the `admin` or
  `analyst` role for access.
- The `desktop` and `webcam` elements of the `/teams` endpoint are available
  for the `public` role only when the scoreboard is not frozen.
- The `entry_point` and `files` elements of the `/submissions` endpoint are
  accessible only for clients with `admin` or `analyst` role. The `reaction`
  element is available to clients with `public` role only when the contest is
  not frozen.
- For clients with the `public` role the `/judgements` and `/runs` endpoints
  MUST NOT include judgements or runs for submissions received while the
  scoreboard is frozen. This means that all judgements and runs for submissions
  received before the scoreboard has been frozen will be available immediately,
  and all judgements and runs for submissions received after the scoreboard has
  been frozen will be available immediately after the scoreboard has been thawed.
- For clients with the `public` role the `/clarifications` endpoint MUST only
  contain replies from the jury to all teams, that is, messages where both
  `from_team_id`, `to_team_ids` and `to_group_ids` are `null`. For clients with
  the `team` role the `/clarifications` endpoint MUST only contain their own
  clarifications (sent or received) and public clarifications.
- For clients with the `public` role the `/awards` and `/scoreboard` endpoints
  MUST NOT include information from judgements of submissions received after
  the scoreboard freeze until it has been thawed.

### Final Results Data Files

As required by the [Contest Control System](ccs#results-data-files) base
specification, the CCS MUST be capable of producing results data after the
contest has ended. For World Finals use, the CCS MUST be capable of generating
at least the following awards (via the `awards.json` file or the
[Awards](contest_api#awards) endpoint):

- `winner`
- `gold-medal`
- `silver-medal`
- `bronze-medal`
- `rank-<rank>`
- `honorable-mention`
- `first-to-solve-<id>`
- `group-winner-<id>`

The CCS does not have to be able to make them available during the contest.

See [Scoring Data Generation](#scoring-data-generation) for details on how the
awards must be calculated, and the list of
[known awards](contest_api#known-awards) for additional comments.

## Documentation Requirements

In order for a given CCS to be considered as a candidate for running the ICPC
World Finals contest, the following documents must be submitted.

- A text file named "License" containing the license, conforming to the
  [Licensing](#licensing) section, under which the CCS is made available to
  the ICPC.
- A *Requirements Compliance Document* as defined below.
- A *Team Guide* as defined below.
- A *Judge's Guide* as defined below.
- A *Contest Administrator's Guide* as defined below.
- A *System Manager's Guide* as defined below.

### Requirements Compliance Document

The CCS MUST include a *Requirements Compliance Document* in PDF format, that
for each requirement (referenced by section number) in this document and in the
[Contest Control System](ccs) specification confirms that the CCS conforms and
explains how it does so. In the event that a configuration item is provided by
using services of the underlying operating system rather than facilities
directly implemented or controlled by the CCS itself, this fact must be
explicitly stated.

### Team Guide

The CCS MUST include a "Team Guide" in PDF format. The Team Guide MUST provide
all the necessary instructions showing how a contest team uses the functions of
the team interface.

### Judge's Guide

The CCS MUST include a "Judge's Guide" in PDF format. The Judge's Guide MUST
provide all the necessary instructions showing how a human contest judge uses
the functions of the human judge interface.

### Contest Administrator's Guide

The CCS MUST include a "Contest Administrator's Guide" in PDF format. The
Administrator's Guide MUST provide all the necessary instructions showing how
contest personnel use the functions of the CCS to set up and manage a contest.

### System Manager's Guide

The CCS MUST include a "System Manager's Guide" in PDF format. The System
Manager's Guide MUST describe the steps required to install and start the CCS
on the OS platform specified for use in the World Finals. In the event that the
CCS consists of multiple modules and/or packages, the guide MUST contain a
description of the relationship between the modules or packages, including any
specific installation and/or startup steps required for each module or package.

The System Manager's Guide MUST provide instructions to contest personnel
explaining situations (if any) where the CCS uses functions of the underlying
operating system (OS) platform to meet requirements laid out in this document.
For example, if the CCS relies on the use of OS account and password management
to implement requirements related to contest security and credentials, or print
services provided by the OS to implement requirements related to external
notifications, this MUST be described in the System Manager's Guide.

The System Manager's Guide MUST explicitly list any operating system
dependencies of the CCS, including but not limited to which OS platform and
version are required and which optional OS packages must be installed for the
CCS to function properly.

The System Manager's Guide MUST explicitly list any software dependencies of
the CCS. For example, any tools such as Java, PERL, WebServer, Browser,
database systems, etc., which are required for correct operation of the CCS
MUST be listed in the guide, including specific version numbers of each tool
which the CCS requires for its correct operation.
