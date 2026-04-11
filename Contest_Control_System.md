---
sort: 1
permalink: /ccs
---
# Contest Control System

## Introduction

This document specifies requirements and capabilities for a *Contest Control
System* (CCS) — software which automatically manages the operation of a
programming contest. Operations managed by the CCS include: running submissions
by teams, judging of submissions, handling clarification requests from teams and
clarification responses from judges, calculation of standings, generating
external representations of contest results, and overall CCS configuration.

This document defines the base requirements that a CCS must satisfy in order to
be considered compatible with this specification, as well as a set of optional
capabilities that a CCS may implement. A conforming CCS is referred to as a
*CLICS-compatible CCS*.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

### Rationale

This document is intended to specify functional requirements, not
implementation requirements. Nothing in this document should be construed as
requiring any particular implementation architecture or use of any particular
implementation language or languages. For example, a CCS might be implemented
as a set of stand-alone applications using a client-server architecture, or
might equally well be implemented as a set of scripts, web pages, and/or other
facilities.

## General Requirements

### Data Persistency

#### Contest Configuration Persistency

The CCS MUST support persistence of the contest configuration. This means that
following a shutdown of the CCS, or a failure on the machine(s) on which the
CCS runs, it must be possible to quickly restore the configuration information
already entered into the CCS without the necessity of reentering that
configuration data.

#### Contest State Persistency

The CCS MUST support persistence of the contest state once the contest has been
started. This means that following a shutdown of the CCS, a power or hardware
failure on the machine(s) on which the CCS runs, it must be possible to quickly
restore the contest state to what it was prior to the disruption. The contest
state for purposes of this requirement includes all data regarding team
submissions, clarification requests, clarifications, judgements, and similar
data defining and/or affecting the standings of the contest.

The CCS MUST NOT lose more than 1 minute of contest data on a failure of any
part of the contest system.

### Account Types

The CCS MUST support the ability of clients to access the system through
different *account types*. The type of account which a client uses to access
the system constrains the functions which the client may perform, as described
below. At least the following different types of accounts must be supported:

- **Team**: used by teams competing in the contest. The functions available to
  team clients are as defined in the section on the [team interface](#team-interface).
- **Judge**: used by judges in the contest. The functions available to judge
  clients are as defined in the section on the [judge interface](#judge-interface).
- **Admin**: used by contest administrators. The functions available to admin
  clients are as defined in the section on the [admin interface](#admin-interface).

### Secure Authentication

The CCS MUST support a secure authentication mechanism, allowing each
registered user (being either a [team](#team-interface), an
[admin](#admin-interface), or a [judge](#judge-interface)) to gain access to the
contest, and must ensure that:

- Only users who supply correct authentication credentials may invoke
  contest-related functions.
- Users may only invoke functions corresponding to their authentication
  credentials. (In other words, it must not be possible for, e.g., a team to
  invoke functions as if they were some other team, or as if they were a judge.)

The CCS MAY rely on the underlying operating system account login/password
mechanism for purposes of meeting the requirements of this section, provided
that it is the case that the CCS enforces all of the requirements of this
section, including but not limited to the requirement that users not be allowed
to invoke functions as if they were some user other than that specified by their
login credentials.

#### Authentication Data

If the CCS uses a login/password mechanism to enforce secure authentication, it
MUST support password assignment by reading
[accounts.json](#importing-contest-configuration). Note that if it uses another
mechanism, it should still read that file to import (team) account information.

#### Logging Out

The CCS MUST support a mechanism for each user to disconnect from the contest,
with the effect that no other user of the computer system not possessing that
user's authentication credentials will be able to invoke CCS functions as if
they did possess those credentials.

### Network Security

All communication between CCS modules which takes place over a network MUST be
encrypted.

### Timestamps and IDs

A timestamp and an integer sequence, called an ID, are assigned to submissions
and clarification requests at the time they enter the system. The following
constraints must be enforced by the CCS:

- Submissions received earlier MUST have a lower ID than submissions received
  later. The same holds for the IDs of clarification requests.
- Timestamps MUST have at least second granularity.

## Contest Configuration

### Advance Configuration

All variable aspects of the CCS MUST be configurable prior to the start of a
contest. That is, the CCS MUST NOT require that any changes be made to the CCS
configuration once the contest has started. Note that this does not alter any
requirements which state that the CCS must allow certain configuration changes
to be able to be made after the contest starts; it means that the contest
administration staff must not be required to make any changes once the contest
starts.

### Importing Contest Configuration

The CCS MUST be able to import contest configuration from a
[Contest Package](contest_package), and use the data to configure the CCS. The
package contains all contest configuration data, including contest, problem,
organization, group, team and account configuration.

The following files and fields must be read by the CCS at a minimum:

- `contest.json` with the following fields: `id`, `name`, `formal_name`,
  `start_time`, `duration`, `scoreboard_freeze_duration`, `penalty_time`.
- `problems.json` with the following fields: `id`, `label`, `name`, `ordinal`,
  `rgb`, `color`.
- `languages.json` with the following fields: `id`, `name`,
  `entry_point_required`, `entry_point_name`, `extensions`,
  `compiler.command`, `runner.command`.
- `groups.json` with the following fields: `id`, `icpc_id`, `name`.
- `teams.json` with the following fields: `id`, `icpc_id`, `label`, `name`,
  `display_name`, `organization_id`, `group_ids`.
- `organizations.json` with the following fields: `id`, `icpc_id`, `name`,
  `formal_name`, and `logo`. This also means the CCS must be able to import
  the logos of organizations from the contest package.
- `accounts.json` with the following fields: `id`, `username`, `type`,
  `team_id` and `password`.

Note that for the files supporting YAML according to the
[Contest Package](contest_package) (i.e. `contest.yaml`, `problems.yaml` and
`accounts.yaml`) the CCS MUST also be able to import those YAML files instead
of the JSON version.

If any of the above files contain fields not recognized by the CCS, the CCS
MUST warn about them.

### Clock Synchronization

The CCS MUST be able to synchronize its clock to an NTP server provided on the
contest network.

### Predefined Clarification Answers

The CCS MUST support predefined answers to clarification requests, so that
judges can choose to reply to a clarification request by selecting a predefined
answer rather than being required to enter a specific answer. At least one
predefined answer to the effect of "No comment, read problem statement." SHOULD
be provided as a default.

### Clarification Categories

The CCS MUST support "categories" to which clarification requests can be
assigned. A request belongs to exactly one category. In addition, the CCS MUST
construct one category per problem (e.g. "Problem A", "Problem B", etc. for
each problem in the contest).

### Language Options

For each supported language compiler or interpreter it MUST be possible to
configure the CCS to invoke it with any of the options specified in the
compiler or interpreter's documentation.

### Contest Problems

Problems (including judge data, validators, execution time limit, etc.) are
specified and configured using the
[Problem Package Format](https://icpc.io/problem-package-format/). The CCS MUST
support the [ICPC subset](https://icpc.io/problem-package-format/spec/legacy-icpc.html)
but MAY support more.

The CCS MUST report an error when importing problems that use any unsupported
features. The CCS MAY report an error when unsupported keys are used, even if
they are given the default value.

### Configuration Change

The CCS MUST allow updating of configuration data without restarting or
stopping the CCS.

## Admin Interface

This section describes all the required capabilities for users authenticated
as admin.

### Account Disabling

The CCS MUST have a mechanism to disable any account (either an account for a
human user or for another system), without the need for starting or stopping
the contest.

### Changes To Authentication Data

The CCS MUST allow user authentication credential information to be changed
dynamically by contest administration staff while the contest is running.

### Starting the Contest

The contest MUST automatically start when the configured start time is reached.
It MUST also be possible to start the contest at the current time.

### Adjusting for Exceptional Circumstances

#### Changing Contest Length

It MUST be possible to change the length of the contest at any time during
the contest.

#### Adding Penalty Time

It MUST be possible to specify, for each team, an integer, potentially
negative, amount of penalty time to be added into that team's total penalty
time.

#### Ignoring Submissions

It MUST be possible to remove, ignore or otherwise mark a submission so that
it in no way affects the scoring of the contest.

### Pausing Judging

The CCS MUST provide some way to temporarily pause judging on a per problem
basis. While judging is paused teams SHOULD still be able to make submissions
and these submissions SHOULD be shown on the scoreboard as usual.

### Rejudging

#### Automatic Rejudging

The CCS MUST allow the ability to automatically rejudge a selected set of
submissions. Each submission in the set of selected submissions is executed and
judged in the same manner as for a newly arrived submission.

#### Previewing Rejudgement Results

There MUST be a way to preview the judgements which result from rejudging the
set of selected submissions without committing the resulting judgements.

#### Submission Selection

The CCS MUST provide the ability to specify a filter defining the set of
submissions to be rejudged. The CCS MUST support any combination of filters of
the following types:

- A specific (single) submission.
- All submissions for a specific problem.
- All submissions using a specific language.
- All submissions by a specific team or set of teams.
- All submissions between some time T<sub>0</sub> and some subsequent time T<sub>1</sub>.
- All submissions which have been assigned any specific one of the allowable
  submission judgments as defined in [Judge Responses](#judge-responses), or
  all submissions that received any judgment other than "Accepted" (that is,
  all rejected submissions).
- All submissions which have been run on a specific computer (identified in
  some reasonable way, e.g., IP address or hostname). This requirement is only
  applicable if the CCS uses multiple machines to run submissions.

### Manual Override of Judgments

The CCS MUST support the ability to assign, to a single submission, an updated
judgment chosen from among any of the allowed submission judgments as defined
in [Judge Responses](#judge-responses).

The CCS MUST require a separate authentication every time a judgment is changed
manually and all such changes MUST be logged.

### Scoreboard Display

The CCS MUST provide a mechanism for admins to view the current scoreboard. The
scoreboard MUST be updated in such a way that it is never more than 30 seconds
out of date.

### Freezing the Scoreboard

The scoreboard MUST automatically freeze when the configured scoreboard freeze
time is reached. It MUST also be possible to manually freeze the scoreboard at
the current time. All submissions received after the freeze time MUST be treated
as pending on a frozen scoreboard.

It MUST be possible to re-enable scoreboard display updating (i.e. thaw the
scoreboard) at any time after it has been frozen, without stopping the contest
or affecting contest operations in any way.

During times when the scoreboard is frozen, administrators MUST be able to view
the current (updated) scoreboard as well as the frozen scoreboard.

### Finalizing the Contest

Finalizing is the procedure to authorize the final results at the end of a
contest. When the contest has been finalized the
[contest state](contest_api#contest-state) endpoint will be updated to reflect
this.

When the contest is over but not finalized, all scoreboards MUST show a warning
that the results are not final.

The CCS MUST provide a way for admins to finalize the contest. It MUST NOT be
possible to finalize a contest if one or more of the following applies:

- The contest is still running (i.e., the contest is not over).
- There are un-judged submissions.
- There are submissions judged as [Judging Error](#exceptional-judgments).
- There are unanswered clarification requests.

## Team Interface

This section describes all the required capabilities for users authenticated
as team.

### Submissions

For purposes of this document, solutions to problems submitted for judging are
called **submissions**. A submission consists of a set of source code files
sent as a single unit at one time to the judging system by a team.

#### Submission Mechanism

The CCS MUST provide each team with the ability to make a submission to the
judging system.

#### Submission Contents

A team MUST be able to specify, for each submission:

- the contest problem to which the submission applies;
- the programming language used in the submission;
- the source code file or files comprising the submission.

The CCS MUST allow teams to specify at least 10 files in a given submission and
MUST allow teams to make submissions for any defined contest problem, written in
any defined contest programming language.

#### Team Viewing of Submission Status

The CCS MUST provide each team with a capability for reviewing the status of
each submission the team has made, including: the contest time of the
submission, the language and problem specified in the submission; and the most
recent judgment (if any) for the submission.

#### Submission Security

The CCS MUST ensure that no team can learn anything about the submissions of any
other team (other than what can be deduced from the scoreboard).

### Clarification Requests

A clarification request is a message sent from a team to the judges asking for
clarification regarding a contest problem or possibly the contest in general.

#### Sending Clarification Requests

The CCS MUST provide each team with the ability to submit a clarification
request to the judges over the network.

#### Content of Clarification Requests

The team MUST be able to specify the text content and category of a
clarification request.

#### Viewing of Clarification Request Status

The CCS MUST provide each team with a capability for reviewing the status of
each clarification request the team has submitted, including: the contest time
of the clarification request; the problem identified in the clarification
request if identification of a specific problem was required by the CCS; and
the response from the judges to the clarification request if any response has
occurred yet.

#### Clarification Request Security

The CCS MUST ensure that no team can see the clarification requests of any
other team, except as provided in the section [Judge Interface](#judge-interface).

### Broadcast Messages

#### Team Viewing of Broadcast Messages

The CCS MUST provide each team with a capability for viewing any broadcast
messages sent by the judges (see [Issuing Broadcast Messages](#issuing-broadcast-messages)).

### Notifications

The CCS MUST notify teams when a judgement, clarification or broadcast message
has been received. This notification MUST NOT steal focus.

### Scoreboard Display

The CCS MUST provide a mechanism for teams to view the current scoreboard. The
scoreboard MUST be updated in such a way that it is never more than 30 seconds
out of date.

## Judge Interface

This section describes all the required capabilities for users authenticated
as judge.

### Simultaneous Usage

It MUST be possible for multiple human judges, working on different computers,
to simultaneously perform the operations specified in this section
(on different submissions).

### Viewing Submissions

The CCS MUST provide a human judge with the ability to perform each of the
following operations:

- See a list of all submissions, where the list includes (for each submission)
  the contest time at which the submission was sent, the problem and language
  specified in the submission, and any judgments applied.
- Sort the list of submissions by submission time (newest submissions first).
- Filter the list of submissions by: problem, team, language, and judgement applied.
- View and download the output produced by the submission when run against the
  specified input data.
- View and download the source code contained in any specific submission.
- View the compiler output resulting from compiling any specific submission
  using the compiler arguments configured in the CCS.
- View the validator output resulting from invoking the external validator
  associated with the contest problem for any specific submission.
- View and download the judge's input data file associated with the contest
  problem for any specific submission.
- View and download the "judge's output" (the "correct answer" file) associated
  with the contest problem for any specific submission.
- View the judge data description, if available.
- View a diff between team output for the submission and judge answer file for
  the problem.
- View previous submissions by the same team on the same problem.

In addition, any additional analytical capabilities allowing the judges to track
differences between submissions are appreciated.

### Handling Clarification Requests

The CCS MUST provide a human judge with the ability to perform each of the
following operations:

- See a list of all clarification requests, where the list includes (for each
  clar) the team which submitted the request, the contest time at which the
  clar was submitted, and an indication of whether or not an answer to the clar
  has been sent to the team which submitted it.
- Sort the list of clarification requests by time.
- Filter the list of clarification requests by: a user-specified set of
  [categories](#clarification-categories), a team, or whether the clarification
  request has been answered.
- Determine, for any specific clarification request, what answer was returned
  to the team if the clar has already been answered.
- Compose an answer to the clar and send it, along with the text of the
  original clarification request, to the team. The best practice is to include
  the original clarification text in its entirety, prepending every line by
  `> ` (also known as internet-style quoting).
- Optionally choose to also send the clarification request text and answer to
  all teams in the contest.
- Change the category of a clarification request.

### Issuing Broadcast Messages

The CCS MUST provide the ability for a human judge to compose a message and
broadcast that message to all teams in the contest. It MUST be possible to do
this even when the contest is not running.

### Scoreboard Display

The CCS MUST provide a mechanism for judges to view the current scoreboard. The
scoreboard MUST be updated in such a way that it is never more than 30 seconds
out of date.

During times when the scoreboard is frozen, judges MUST be able to view the
current (updated) scoreboard as well as the frozen scoreboard.

## Judging

### Automated Judgements

The CCS MUST be able to automatically judge incoming submissions. This
mechanism must automatically (that is, without human intervention) process each
incoming submission, and for each such submission must automatically:

1. Compile (if appropriate for the language) the program contained in the
   submission, enforcing the
   [compilation time limit](https://icpc.io/problem-package-format/spec/problem_package_format#limits).
2. Execute the program contained in the submission, with the corresponding
   contest problem data automatically supplied to the program.
3. Prevent the submitted program from performing any
   [prohibited operations](#prohibited-operations).
4. Enforce any configured
   [execution time limit](https://icpc.io/problem-package-format/spec/problem_package_format#limits),
   [memory limit](https://icpc.io/problem-package-format/spec/problem_package_format#limits),
   and [output size limit](https://icpc.io/problem-package-format/spec/problem_package_format#limits)
   specified for the corresponding problem.
     - The execution time limit gives a restriction on the amount of *CPU time*
       that the submission may consume, per test file.
     - In addition, the CCS MUST restrict the amount of *wall clock time* that
       the submission may consume (to safeguard against submissions which spend
       a long time without using CPU time by e.g., sleeping).
5. Invoke an external program, known for purposes of this document as a
   [validator](https://icpc.io/problem-package-format/spec/problem_package_format#output-validators),
   passing to it the output generated by the program specified in the
   submission and getting back from it an indication of what judgment is to be
   applied to the submission (see the [Validators](#validators) section).
6. Assign an [appropriate judgment](#judge-responses) to the submission.
7. Send a notification about the judgement to the team.

It MUST be possible to configure the CCS such that these actions are performed
on a machine that is not accessible to any team (possibly just a different
virtual machine, e.g. if the machines used in the contest are thin clients
connecting to a shared server).

### Prevention of Auto-judge Machine Starvation

The CCS MUST use auto-judge machines efficiently and fairly. At a minimum it
needs to ensure:

- Submissions MUST NOT be left in queue if there are unused auto-judge machines.
- The system MUST prevent a single team from starving other teams out of
  auto-judge machines.

### Prohibited Operations

The CCS MUST ensure that prohibited operations in submissions have no
non-trivial outside effects.

The prohibited operations are:

- Using libraries except those explicitly allowed
- Executing other programs
- Reading any files
- Creating files
- Sending signals to other programs
- Side-stepping time or memory limits
- Sending or receiving network traffic, e.g. opening sockets

### Judge Responses

The CCS MUST answer each submission with a response. All judgement types used
MUST be from the list of [known judgement types](json_format#known-judgement-types)
defined in the JSON Format specification. The CCS MUST support at least the
"Big 5" judgement types: AC, WA, TLE, RTE, and CE.

### Assigning a Judgment

The next two sections define how to assign a judgment to a submission for
problems with a single input file and with multiple input files, respectively.
Note however that the **Judging Error** and **Security Violation** judgments
constitute exceptions to this, as defined in
[Exceptional Judgments](#exceptional-judgments).

#### Judging With a Single Input File

To determine which answer to use, the following rules must be applied in order:

1. If the submitted program fails to compile or compilation exceeds the
   [compilation time limit](https://icpc.io/problem-package-format/spec/problem_package_format#limits),
   the response MUST be **Compile Error**.
2. If the submitted program exceeds the
   [memory limit](https://icpc.io/problem-package-format/spec/problem_package_format#limits)
   or crashes before the
   [execution time limit](https://icpc.io/problem-package-format/spec/problem_package_format#limits)
   is exceeded, the answer MUST be **Run-Time Error**.
3. If the submitted program runs longer than the
   [execution time limit](https://icpc.io/problem-package-format/spec/problem_package_format#limits),
   the answer MUST be **Time Limit Exceeded**.
4. If the output of the submitted program exceeds the
   [output size limit](https://icpc.io/problem-package-format/spec/problem_package_format#limits)
   or if the output of the submitted program is not accepted by the output
   validator, the answer MUST be **Wrong Answer**.
5. If the output of the submitted program is accepted by the output validator,
   the answer MUST be **Accepted**.

#### Judging With Multiple Input Files

If the problem has multiple judge input files the judgment is assigned as
follows:

1. For each input file apply the
   [decision process for a single input file](#judging-with-a-single-input-file).
2. If any file is not judged as **Accepted**, the response MUST be that of the
   first file, in alphabetical order, that was not judged **Accepted**.
3. Otherwise the response MUST be **Accepted**.

Note that the CCS is only required to judge as many files as needed to
determine the first file, if any, that is not judged **Accepted**.

#### Exceptional Judgments

The preceding sections define how to assign a judgment to a submitted program.
However, the following two exceptions apply:

1. If, during any point of the judging process an error occurs that the CCS
   cannot recover from, **Judging Error** MUST be the judgment.
2. If, during any point of the judging process the submitted program tries to
   perform a [prohibited operation](#prohibited-operations), **Security
   Violation** MAY be the judgment.

### Validators

A CCS fulfilling these requirements MUST safeguard against faulty validators.
For instance, if a validator were to produce excessively large feedback files,
or crash, the CCS MUST handle this gracefully and report it to contest staff.
Reasons for such misbehaviour of the validator program could be for instance a
security bug in the validator program, enabling malicious submissions to
produce feedback files of their own choosing.

The content of *stdout* and *stderr* of the output validator MAY be ignored by
the contest control system.

## Scoring

### Scoring Data Generation

The CCS MUST be capable of automatically generating up-to-date scoring data
according to the following:

1. For purposes of scoring, the *contest time of a submission* is the number of
   minutes elapsed from the beginning of the contest when the submission was
   made, skipping removed time intervals if specified (see
   [Removing Time Intervals](#removing-time-intervals)). This is rounded *down*
   to the nearest minute, so 59.99 seconds is 0 minutes.
2. The *contest time that a team solved a problem* is the contest time of the
   team's first accepted submission to that problem.
3. A team's *penalty time on a problem* is the contest time that the team
   solved the problem, plus *penaltytime* (from
   [contest.json](#importing-contest-configuration)) minutes for each previous
   submission rejected with a judgement that causes penalty time, by that team
   on that problem, or 0 if the team has not solved the problem.
4. A team's *total penalty time* is the sum of the penalty times for all
   problems plus any judge added penalty time.
5. A team's *last accepted submission* is the contest time of the problem that
   the team solved last.
6. The *position* of a team is determined by sorting the teams first by number
   of problems solved (descending), then within that by total penalty time
   (ascending), then within that by last accepted submission (ascending).

When a number of teams are tied for the same position, they all occupy the same
position and a suitable number of subsequent positions are left empty.

A submission is pending judgement if it has no judgement or if the judgement
is **Judging Error**. Pending judgements have no effect on scoring.

### Scoreboard

The *current scoreboard* lists the teams sorted by position. A CCS MUST
implement at least one of the following two scoreboard modes:

- **Team-name-based**: teams are identified by team name, alphabetical order
  on team name is used as the final tie breaker, and the scoreboard MUST
  display team name.
- **University-name-based**: teams are identified by university name,
  alphabetical order on university name is used as the final tie breaker, and
  the scoreboard MUST display university name.

The scoreboard MUST include at least the following information.

For each team:

- team or university name (as determined by the scoreboard mode)
- team position
- number of problems solved
- total penalty time

For each team and problem:

- number of submissions from that team on that problem,
- whether the problem is solved, unsolved or a judgement is pending,
- if the problem is solved, the contest time at which it was solved,
- if the problem is pending judgement, how many submissions are pending
  judgement on that problem.

A problem is pending judgement if any submission on it is pending judgement and
there is not an earlier accepted submission on that problem.

## Data Export

### Results Data Files

The CCS MUST be capable of producing results data after the contest has ended.
The results data consists of files in the format defined by the
[Contest Package](contest_package) specification. How the CCS produces these
files is left to the implementation — for example, it may do so by exposing a
live [Contest API](#contest-api), by generating static files, or by some other
means.

At a minimum the CCS MUST be capable of producing the following files,
sufficient for a [results upload](contest_package#results-upload):

- `api.json`
- `teams.json`
- `scoreboard.json`

The CCS SHOULD also be capable of producing `awards.json`.

## Optional Capabilities

This section defines capabilities that a CCS MAY implement. These capabilities
are not required for a CCS to be considered CLICS-compatible, but specific
contest environments may mandate them.

### Contest API

The CCS MAY provide a live implementation of the [Contest API](contest_api),
making contest data available in a streaming fashion during the contest. A CCS
that implements the Contest API MUST support at least the `api` and `access`
endpoints, as these are the
[required endpoints](contest_api#required-and-optional-endpoints) defined in
the Contest API specification.

### Removing Time Intervals

It MAY be possible to, potentially retroactively, specify time intervals that
will be disregarded for the purpose of scoring. The time during all such
intervals will not be counted towards a team's penalty time for solved
problems. Beginning and end of time intervals are given in wall-clock time.

Note that removing a time interval changes the wall-clock time when the contest
ends, as the duration of the contest in
[contest.json](#importing-contest-configuration) is specified in contest time.

Removing the interval between time T<sub>0</sub> and T<sub>1</sub>, where
T<sub>0</sub> ≤ T<sub>1</sub>, means that all submissions received between
T<sub>0</sub> and T<sub>1</sub> will have the same contest time and that the
time for all submissions received after T<sub>1</sub> will have a contest time
that is T<sub>1</sub>-T<sub>0</sub> lower than if the interval was not removed.

The removal of a time interval MUST be reversible. This means that if a time
interval is removed, the CCS MUST support the capability of subsequently
restoring the contest to the state it had prior to the removal of the time
interval.

Note that time interval removal does not affect the order in which submissions
arrived to the CCS. If submission S<sub>i</sub> arrived before submission
S<sub>j</sub> during a removed interval, S<sub>i</sub> MUST still be
considered by the CCS to have arrived strictly before S<sub>j</sub>.

### Shadow Mode

A CCS MAY support operating as a *Shadow CCS* — a parallel independent system
that mirrors a *Primary CCS*, re-judges all submissions, and verifies that
results match. This section defines the requirements for shadow mode support.

A CCS that supports shadow mode MUST be able to operate in either Primary or
Shadow mode. It must in principle be possible to run two identical instances of
the CCS, one set to run in Primary mode and the other set to run in Shadow mode,
and where the two CCS instances communicate with each other as defined by the
requirements of this section.

The ability to run in either Primary or Shadow mode does not imply that a CCS
must be able to operate in these modes simultaneously, nor that a CCS must be
able to switch between these modes dynamically during a contest. Rather, it
means that a CCS supporting shadow mode must support BOTH Primary and
Shadow-mode operations and must meet all of the requirements for both modes.

#### External Communication

Beyond communicating with its own components (e.g., communicating with its
external auto-judges or with the humans managing it), the only external
communication which a CCS running in shadow mode is allowed to require is that
it has the ability to communicate with at least one "server" component of the
Primary CCS. In particular, a CCS running in shadow mode MAY NOT require that
it be able to communicate directly with any of the actual contest participants
(meaning the teams, judges, or contest administrators who communicate with the
Primary CCS). Said another way, the Shadow CCS MUST be able to perform all of
its functions while communicating only with the Primary CCS.

#### CCS Configuration

A CCS running in shadow mode MUST be able to import a complete contest
configuration as described in the [Importing Contest Configuration]
(#importing-contest-configuration) section. In particular a shadow-mode CCS
MUST be able to import a contest configuration from a
[Contest Package](contest_package).

#### Submissions

A CCS running in shadow mode MUST be able to obtain team submissions via
communication with the Primary CCS. As required elsewhere in this
specification, the Primary CCS MUST implement the endpoints defined in the
[Contest API](contest_api). The following requirements then apply to the
mechanisms used by the Shadow CCS for obtaining submissions:

- The Shadow CCS SHOULD use the `/event-feed` endpoint defined in the
  [Contest API](contest_api) to obtain notification of team submissions from
  the Primary CCS (in other words, the Shadow CCS should preferably use
  event-driven operation, rather than polling, for team submission notification).
- The Shadow CCS MUST use the `/submissions/<id>` and `/submissions/<id>/files`
  endpoints defined in the [Contest API](contest_api) for obtaining submission
  data from the Primary CCS.
- The Shadow CCS MUST provide an interface that can display information
  regarding any submission by looking up the submission using the submission ID
  assigned by the Primary CCS.
- The Shadow CCS MUST use the timestamp assigned to a submission by the Primary
  CCS as the time of the submission for purposes of computing standings,
  regardless of the time at which the submission is actually obtained by the
  Shadow CCS.
- A submission obtained from the Primary CCS MUST be executed and judged by the
  Shadow CCS in the same manner as if it had been submitted to the CCS running
  in non-shadow mode.

#### Judgement Comparison

A CCS running in shadow mode MUST have the capability to present a "diff" of
submissions — that is, a list of all submissions which at the current time have
a different judgement than that which was assigned by the Primary CCS.

#### Requirements Which May Be Imposed By The CCS

A CCS MAY require the following conditions to exist in order to guarantee
support for shadow-mode operations:

- The Shadow CCS is provided with auto-judging hardware which is the same as
  that being used by the Primary CCS.
- The Shadow CCS has a network connection to both the Event Feed and the REST
  services provided by the Primary CCS.
- The Shadow CCS is provided with credentials which allow appropriate access to
  the required Primary CCS REST endpoints.
- SubmissionIDs for submissions are unique contest-wide, even in the event of a
  contest with multiple independent sites being managed by a single distributed
  Primary CCS.
- The Shadow CCS has access to the same contest configuration files as those
  used to configure the Primary CCS.

A CCS MAY NOT require any conditions not specified above to exist in order to
guarantee support for shadow-mode operations.
