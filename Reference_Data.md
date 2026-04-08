---
sort: 5
permalink: /reference_data
---
# Reference Data

## Introduction

This document defines the standard registries of values used across ICPC
specifications and tooling, including the [Contest API](contest_api), the
[JSON Format](json_format), the [Contest Package Format](contest_package), the
[Problem Package Format](https://www.kattis.com/problem-package-format/), the
[ICPC Problem Archive](https://github.com/icpc-problem-archive/), and the
[ICPC Contest Archive](https://github.com/icpc-contest-archive/).

These registries are maintained separately from the specifications that
reference them so that new values can be added independently of specification
release cycles. When a value needed by an implementation is not present in a
registry, a pull request should be opened at
<https://github.com/icpc/ccs-specs> to add it before using an ad-hoc value,
to ensure values remain interoperable across systems.

## Judgement Types

Standardized identifiers for judgement types, i.e. the possible verdicts
returned when evaluating a submission. These are used in the
[Contest API](contest_api#judgement-types), the [JSON Format](json_format),
the [Contest Package Format](contest_package), and the
[Problem Package Format](https://www.kattis.com/problem-package-format/).

The **Big 5** column lists the "Big 5" simplified equivalent, if any. A `*`
means the judgement is itself one of the Big 5.

The **Translation** column lists other judgement type IDs the judgement can
safely be translated to, if a system does not support it.

| ID  | Name                                     | A.k.a.                                                   | Big 5 | Translation       | Description
| :-- | :--------------------------------------- | :------------------------------------------------------- | :---- | :---------------- | :----------
| AC  | Accepted                                 | Correct, Yes (YES)                                       | \*    | \-                | Solves the problem
| RE  | Rejected                                 | Incorrect, No (NO)                                       | WA?   | \-                | Does not solve the problem
| WA  | Wrong Answer                             |                                                          | \*    | RE                | Output is not correct
| TLE | Time Limit Exceeded                      |                                                          | \*    | RE                | Too slow
| RTE | Run-Time Error                           |                                                          | \*    | RE                | Crashes
| CE  | Compile Error                            |                                                          | \*    | RE                | Does not compile
| APE | Accepted - Presentation Error            | Presentation Error, also see AC, PE, and IOF             | AC    | AC                | Solves the problem, although formatting is wrong
| OLE | Output Limit Exceeded                    |                                                          | WA    | WA, RE            | Output is larger than allowed
| PE  | Presentation Error                       | Output Format Error (OFE), Incorrect Output Format (IOF) | WA    | WA, RE            | Data in output is correct, but formatting is wrong
| EO  | Excessive Output                         |                                                          | WA    | WA, RE            | A correct output is produced, but also additional output
| IO  | Incomplete Output                        |                                                          | WA    | WA, RE            | Parts, but not all, of a correct output is produced
| NO  | No Output                                |                                                          | WA    | IO, WA, RE        | There is no output
| WTL | Wallclock Time Limit Exceeded            |                                                          | TLE   | TLE, RE           | CPU time limit is not exceeded, but wallclock is
| ILE | Idleness Limit Exceeded                  |                                                          | TLE   | WTL, TLE, RE      | No CPU time used for too long
| TCO | Time Limit Exceeded - Correct Output     |                                                          | TLE   | TLE, RE           | Too slow but producing correct output
| TWA | Time Limit Exceeded - Wrong Answer       |                                                          | TLE   | TLE, RE           | Too slow and also incorrect output
| TPE | Time Limit Exceeded - Presentation Error |                                                          | TLE   | TWA, TLE, RE      | Too slow and also presentation error
| TEO | Time Limit Exceeded - Excessive Output   |                                                          | TLE   | TWA, TLE, RE      | Too slow and also excessive output
| TIO | Time Limit Exceeded - Incomplete Output  |                                                          | TLE   | TWA, TLE, RE      | Too slow and also incomplete output
| TNO | Time Limit Exceeded - No Output          |                                                          | TLE   | TIO, TWA, TLE, RE | Too slow and also no output
| MLE | Memory Limit Exceeded                    |                                                          | RTE   | RTE, RE           | Uses too much memory
| SV  | Security Violation                       |                                                          | RTE   | IF, RTE, RE       | Uses some functionality that is not allowed by the system
| IF  | Illegal Function                         | Restricted Function                                      | RTE   | SV, RTE, RE       | Calls a function that is not allowed by the system
| RCO | Run-Time Error - Correct Output          |                                                          | RTE   | RTE, RE           | Crashing but producing correct output
| RWA | Run-Time Error - Wrong Answer            |                                                          | RTE   | RTE, RE           | Crashing and also incorrect output
| RPE | Run-Time Error - Presentation Error      |                                                          | RTE   | RWA, RTE, RE      | Crashing and also presentation error
| REO | Run-Time Error - Excessive Output        |                                                          | RTE   | RWA, RTE, RE      | Crashing and also excessive output
| RIO | Run-Time Error - Incomplete Output       |                                                          | RTE   | RWA, RTE, RE      | Crashing and also incomplete output
| RNO | Run-Time Error - No Output               |                                                          | RTE   | RIO, RWA, RTE, RE | Crashing and also no output
| CTL | Compile Time Limit Exceeded              |                                                          | CE    | CE, RE            | Compilation took too long
| JE  | Judging Error                            |                                                          | \-    | \-                | Something went wrong with the system
| SE  | Submission Error                         |                                                          | \-    | \-                | Something went wrong with the submission
| CS  | Contact Staff                            | Other                                                    | \-    | \-                | Something went wrong

## Languages

Standardized identifiers for programming languages used in contest
submissions. These are used in the
[Contest API](contest_api#languages), the [JSON Format](json_format), and the
[Problem Package Format](https://www.kattis.com/problem-package-format/appendix/languages.html).

Each entry specifies the standard identifier, display name, file extensions,
and entry point name (if the language requires one).

File endings in parentheses are not used for determining language.

When providing one of these languages, the corresponding identifier should be 
used. The language name and entry point name may be adapted e.g. for localization 
or to indicate a particular version of the language. In case multiple versions
of a language are provided, those must have separate, unique identifiers. It is 
recommended to choose new identifiers with a suffix appended to an existing one. 
For example `cpp17` to specify the ISO 2017 version of C++.

| Code         | Language            | Default entry point | File endings                    |
| ------------ | ------------------- |---------------------| ------------------------------- |
| ada          | Ada                 |                     | .adb, .ads                      |
| algol60      | Algol 60            |                     | .alg                            |
| algol68      | Algol 68            |                     | .a68                            |
| apl          | APL                 |                     | .apl                            |
| bash         | Bash                |                     | .sh                             |
| bcpl         | BCPL                |                     | .b                              |
| bqn          | BQN                 |                     | .bqn                            |
| c            | C                   |                     | .c                              |
| cgmp         | C with GMP          |                     | (.c)                            |
| cobol        | COBOL               |                     | .cob                            |
| cpp          | C++                 |                     | .cc, .cpp, .cxx, .c++, .C       |
| cppgmp       | C++ with GMP        |                     | (.cc, .cpp, .cxx, .c++, .C)     |
| crystal      | Crystal             |                     | .cr                             |
| csharp       | C\#                 |                     | .cs                             |
| d            | D                   |                     | .d                              |
| dart         | Dart                |                     | .dart                           |
| elixir       | Elixir              |                     | .ex                             |
| erlang       | Erlang              |                     | .erl                            |
| forth        | Forth               |                     | .fth, .4th, .forth, .frt, (.fs) |
| fortran      | Fortran             |                     | .f90                            |
| fortran77    | Fortran 77          |                     | .f, .for                        |
| fsharp       | F\#                 |                     | .fs                             |
| gerbil       | Gerbil              |                     | .ss                             |
| go           | Go                  |                     | .go                             |
| haskell      | Haskell             |                     | .hs                             |
| icon         | Icon                |                     | .icn                            |
| java         | Java                | Main                | .java                           |
| javaalgs4    | Java with Algs4     | Main                | (.java)                         |
| javascript   | JavaScript          | `main.js`           | .js                             |
| julia        | Julia               |                     | .jl                             |
| kotlin       | Kotlin              | MainKt              | .kt                             |
| lisp         | Common Lisp         | `main.{lisp,cl}`    | .lisp, .cl                      |
| lua          | Lua                 |                     | .lua                            |
| modula2      | Modula-2            |                     | .mod, .def                      |
| nim          | Nim                 |                     | .nim                            |
| objectivec   | Objective-C         |                     | .m                              |
| ocaml        | OCaml               |                     | .ml                             |
| octave       | Octave              |                     | (.m)                            |
| odin         | Odin                |                     | .odin                           |
| pascal       | Pascal              |                     | .pas                            |
| perl         | Perl                |                     | .pm, (.pl)                      |
| php          | PHP                 | `main.php`          | .php                            |
| pli          | PL/I                |                     | .pli                            |
| prolog       | Prolog              |                     | .pl                             |
| python2      | Python 2            | `__main__.py`       | (.py), .py2                     |
| python3      | Python 3            | `__main__.py`       | .py, .py3                       |
| python3numpy | Python 3 with NumPy | `__main__.py`       | (.py, .py3)                     |
| racket       | Racket              |                     | .rkt                            |
| ruby         | Ruby                |                     | .rb                             |
| rust         | Rust                |                     | .rs                             |
| scala        | Scala               |                     | .scala                          |
| simula       | Simula 67           |                     | .sim                            |
| smalltalk    | Smalltalk           |                     | .st                             |
| snobol       | Snobol              |                     | .sno                            |
| swift        | Swift               |                     | .swift                          |
| typescript   | TypeScript          |                     | .ts                             |
| uiua         | Uiua                |                     | .ua                             |
| visualbasic  | Visual Basic        |                     | .vb                             |
| zig          | Zig                 |                     | .zig                            |

## Contest Short Names

Standardized identifiers for contest series. A contest occurrence is identified
by three properties:

- `namespace`, identifying the contest ecosystem
- `contest`, identifying a contest series within that namespace
- `instance`, identifying a specific occurrence of that contest series

For example, the Nordic Collegiate Programming Contest 2025 is identified by
`namespace: icpc`, `contest: nordic`, and `instance: 2025`.

The `instance` is often the calendar year, but may use another value for
contests that have multiple occurrences in a year or use another naming
scheme.

This section defines contest identifiers in the namespaces `icpc`, `ioi`, and
`independent`.

Values for `namespace`, `contest`, and `instance` must consist only of the
characters `[a-z0-9-]` and must not begin or end with `-`. New contests
must choose a `contest` value that is unique, concise, and recognizable
within its namespace. If possible, it should be unique over all namespaces.

### ICPC

This section defines contest identifiers in the `icpc` namespace.

For the `icpc` namespace, `instance` should normally be a 4-digit year such as
`2025`. When needed to distinguish multiple occurrences in the same year, a
4-digit year may be followed by `-` and a short distinguishing string.

| Region            | Contest                | Name                                                  | Year (Instance) |
| ----------------- | ---------------------- | ----------------------------------------------------- | --------------- |
| International     | wf                     | World Finals                                          | 1974, 1978-     |
| Europe            | euc                    | Europe Championship                                   | 2024-           |
| Europe            | erc                    | European Regional Contest                             | 1988-1991       |
| Europe            | werc                   | Western European Regional Contest                     | 1992-1994       |
| Europe            | nwerc                  | Northwestern European Regional Contest                | 1995-           |
| Europe            | nordic                 | Nordic Collegiate Programming Contest                 | 2005-           |
| Europe            | bapc                   | Benelux Algorithm Programming Contest                 | 2005-           |
| Europe            | bapc-prelims           | BAPC Preliminaries                                    | 2009-           |
| Europe            | germany                | German Collegiate Programming Contest                 | 2010-           |
| Europe            | ukiepc                 | UK & Ireland Programming Contest                      | 2013-           |
| Europe            | swerc                  | Southwestern Europe Regional Contest                  | 1993-           |
| Europe            | mcerc                  | Mid-Central European Programming Contest              | 1999-2000       |
| Europe            | cerc                   | Central Europe Regional Contest                       | 1995-           |
| Europe            | ctuo                   | CTU Open                                              | 1997-           |
| Europe            | hungary                | Hungarian Programming Contest                         | 2007- ?         |
| Europe            | poland                 | Polish Collegiate Programming Contest                 | 1996-           |
| Europe            | croatia                | Croatian Programming Contest                          | 2007- ?         |
| Europe            | slovenia               | Slovenian Programming Contest                         | 2009- ?         |
| Europe            | seerc                  | Southeastern Europe Regional Contest                  | 1995-           |
| Europe            | ukraine                | All-Ukrainian Collegiate Programming Contest          | 2010-           |
| Europe            | turkey                 | Turkey Programming Contest                            | 2010- ?         |
| Europe            | romania                | Romania Programming Contest                           | 2010- ?         |
| Europe            | bulgaria               | Bulgarian Collegiate Programming Contest              | 2010-2013 ?     |
| Europe            | cyprus                 | Cyprus Collegiate Programming Contest                 | 2018-2020 ?     |
| Europe            | greece                 | Greece Programming Contest                            | 2023-           |
| North America     | nac                    | North America Championship                            | 2020-           |
| North America     | nadc                   | North America Division Championships                  | 2021            |
| North America     | naipc                  | North American Invitational Programming Contest       | 2014-2019       |
| North America     | naq                    | North America Qualifyer                               | 2012-           |
| North America     | south-na               | North America South Division                          | 2022-           |
| North America     | east-na                | North America East Division                           | 2023-           |
| North America     | central-na             | North America Central Division                        | ?               |
| North America     | west-na                | North America West Division                           | ?               |
| North America     | ecna                   | East Central NA Regional Contest                      | 1984-2022       |
| North America     | gny                    | Greater NY Regional Contest                           | 1997-2022       |
| North America     | mausa                  | Mid-Atlantic USA Regional Contest                     | 1996-2021       |
| North America     | mcpc                   | Mid-Central USA Regional Contest                      | 1993-           |
| North America     | ncna                   | North Central NA Regional Contest                     | 1993-           |
| North America     | nena                   | Northeast North America Regional Contest              | 1998-2022       |
| North America     | bospre-prel            | BOSPRE (Brown/Tufts) Preliminary Contest              | 2008- ?         |
| North America     | oswego-prel            | Oswego Preliminary Contest                            | 2008- ?         |
| North America     | wnec-prel              | WNEC Preliminary                                      | 2008- ?         |
| North America     | mcgill-prel            | McGill Preliminary Contest                            | 2008- ?         |
| North America     | moncton-prel           | Universite de Moncton APICS Contest                   | 2008- ?         |
| North America     | potsdam-prel           | Potsdam Preliminary Contest                           | 2009- ?         |
| North America     | dalhousie-prel         | Dalhousie University APICS Contest                    | 2009- ?         |
| North America     | fredonia-prel          | Fredonia Preliminary Contest                          | 2009- ?         |
| North America     | saint-mary-prel        | Saint Mary's APICS Contest                            | 2010- ?         |
| North America     | clarkson-prel          | Clarkson Preliminary Contest                          | 2011- ?         |
| North America     | sfx-prel               | Saint Francis Xavier's APICS Contest                  | 2011- ?         |
| North America     | pacnw                  | Pacific Northwest Regional Contest                    | 1994-           |
| North America     | rmc                    | Rocky Mountain Regional Contest                       | 1989-           |
| North America     | alberta                | Alberta Collegiate Programming Contest                | 2011-           |
| North America     | lethbridge             | Lethbridge Collegiate Programming Contest             | 2013-           |
| North America     | scusa                  | South Central USA Regional Contest                    | 1987-2021       |
| North America     | seusa                  | Southeast USA Regional Contest                        | 1988-2021       |
| North America     | ucf-qual               | UCF Qualifier                                         | 2012- ?         |
| North America     | socal                  | Southern California Regional Contest                  | 1979-           |
| Latin America     | lac                    | Latin America Championship                            | ?               |
| Latin America     | central-america        | Central America Programming Contest                   | 1997- ?         |
| Latin America     | caribbean              | Caribbean Finals                                      | 2010- ?         |
| Latin America     | cuba                   | Cuban Finals                                          | 2010- ?         |
| Latin America     | south-america          | South America Programming Contest                     | 1998-2007       |
| Latin America     | south-america-north    | South America - North                                 | 2008- ?         |
| Latin America     | south-america-south    | South America - South                                 | 2008- ?         |
| Latin America     | brazil                 | South America Brazil Programming Contest              | 2004- ?         |
| Northern Eurasia  | nerc                   | Northern Eurasia Finals                               | 2018-           |
| Northern Eurasia  | neerc                  | Northeastern Europe Programming Contest               | 1996-2017       |
| Northern Eurasia  | urals                  | Urals Subregional Contest                             | 1998-           |
| Northern Eurasia  | georgia                | Georgia Subregional Contest                           | 2004-           |
| Northern Eurasia  | east-siberia           | East Siberian Subregional Contest                     | 2000-           |
| Northern Eurasia  | central-russia         | Central Subregional Contest                           | 1998-           |
| Northern Eurasia  | west-neerc             | Western Subregional Contest                           | 1998-           |
| Northern Eurasia  | kazakhstan             | Kazakhstan Subregional Contest                        | 2003-           |
| Northern Eurasia  | azerbaijan             | Azerbaijan Subregional Contest                        | 2005-           |
| Northern Eurasia  | far-east-russia        | Far Eastern Subregional Contest                       | 1998-           |
| Northern Eurasia  | west-siberia           | West Siberian Subregional Contest                     | 1999-           |
| Northern Eurasia  | uzbekistan             | Uzbekistan Subregional Contest                        | 2002-           |
| Northern Eurasia  | moscow                 | Moscow Subregional Contest                            | 2003-           |
| Northern Eurasia  | south-russia           | Southern Subregional Contest                          | 1998-           |
| Northern Eurasia  | armenia                | Armenia Subregional Contest                           | 2004-           |
| Northern Eurasia  | north-russia           | Northern Subregional Contest                          | 1998-           |
| Northern Eurasia  | kyrgyzstan             | Kyrgyzstan Subregional Contest                        | 2004-           |
| Northern Eurasia  | taurida                | Taurida Subregional Contest                           | 2014-           |
| Africa and Arab   | acpc                   | Africa & Arab Collegiate Programming Championship     | 1998-           |
| Africa and Arab   | egypt                  | Egyptian Collegiate Programming Contest               | 2008-           |
| Africa and Arab   | lebanon                | Lebanese Collegiate Programming Contest               | 2009-           |
| Africa and Arab   | kuwait                 | Kuwait Collegiate Programming Contest                 | 2010-           |
| Africa and Arab   | jordan                 | Jordanian Collegiate Programming Contest              | 2011-           |
| Africa and Arab   | syria                  | Syrian Collegiate Programming Contest                 | 2011-           |
| Africa and Arab   | morocco                | Morocco Collegiate Programming Contest                | 2012-           |
| Africa and Arab   | palestine              | Palestinian Collegiate Programming Contest            | 2012-           |
| Africa and Arab   | tunisia                | Tunisian Collegiate Programming Contest               | 2013-           |
| Africa and Arab   | oman                   | Oman Collegiate Programming Contest                   | 2013-           |
| Africa and Arab   | algeria                | Algerian Collegiate Programming Contest               | 2014-           |
| Africa and Arab   | bahrain                | Bahrain Collegiate Programming Contest                | 2019-           |
| Africa and Arab   | qatar                  | Qatar Collegiate Programming Contest                  | 2020-           |
| Africa and Arab   | sudan                  | Sudanese Collegiate Programming Contest               | 2020-           |
| Africa and Arab   | saudi-arabia           | Saudi Collegiate Programming Contest                  | 2022-           |
| Africa and Arab   | south-africa           | South Africa Programming Contest                      | 1999-           |
| Africa and Arab   | togo                   | Togolese Collegiate Programming Contest               | 2016-           |
| Africa and Arab   | burkina-faso           | Burkinabe Collegiate Programming Contest              | 2016-2017 ?     |
| Africa and Arab   | benin                  | Beninese Collegiate Programming Contest               | 2016-           |
| Africa and Arab   | nigeria                | Nigerian Collegiate Programming Contest               | 2016-           |
| Africa and Arab   | ethiopia               | Ethiopian Collegiate Programming Contest              | 2016-           |
| Africa and Arab   | senegal                | Senegalese Collegiate Programming Contest             | 2017 ?          |
| Africa and Arab   | ivory-coast            | Ivorian Collegiate Programming Contest                | 2017 ?          |
| Africa and Arab   | angola                 | Angolan Collegiate Programming Contest                | 2017-           |
| Asia West         | awc                    | Asia West Continent Final Contest                     | 2016-           |
| Asia West         | dhaka                  | Asia Programming Contest, Dhaka                       | 1997-           |
| Asia West         | kanpur                 | Asia Programming Contest, Kanpur                      | 1999-           |
| Asia West         | tehran                 | Asia Programming Contest, Tehran                      | 2000-           |
| Asia West         | bombay                 | Asia Programming Contest, Bombay                      | 2003-2004       |
| Asia West         | kolkata-roorkee        | Asia Programming Contest, Kolkata-Roorkee             | 2003            |
| Asia West         | coimbatore             | Asia Programming Contest, Coimbatore                  | 2005-2006       |
| Asia West         | kolkata                | Asia Programming Contest, Kolkata                     | 2005, 2015-2016 |
| Asia West         | amritapuri             | Asia Programming Contest, Amritapuri                  | 2007-           |
| Asia West         | gwalior-kanpur         | Asia Gwalior-Kanpur Regional Contest                  | 2009, 2017      |
| Asia West         | kharagpur              | Asia Kharagpur Regional Contest                       | 2012-2019       |
| Asia West         | gwalior                | Asia Gwalior Regional Contest                         | 2014, 2022      |
| Asia West         | lahore                 | Asia Lahore Regional Contest                          | 2014-2018       |
| Asia West         | chennai                | Asia Chennai Regional Contest                         | 2015-2017, 2023 |
| Asia West         | kolkata-kanpur         | Asia Kolkata-Kanpur Contest                           | 2017-2018       |
| Asia West         | kabul                  | Asia Kabul Regional Contest                           | 2017-           |
| Asia West         | gwailor-pune           | Asia Gwalior-Pune Regional Contest                    | 2018-2021       |
| Asia West         | topi                   | Asia Topi Regional On-site Contest                    | 2019-           |
| Asia West         | mathura                | Asia Mathura Kanpur Regional Contest                  | 2022            |
| Asia East         | aec                    | Asia East Continent Final Contest                     | 2015-           |
| Asia East         | shanghai               | Asia Programming Contest, Shanghai                    | 1996-           |
| Asia East         | hong-kong              | Asia Programming Contest, Hong Kong                   | 2000, 2016-     |
| Asia East         | beijing                | Asia Programming Contest, Beijing                     | 2002-2018       |
| Asia East         | xian                   | Asia Programming Contest, Xian                        | 2002, 2006, 2014, 2017, 2022- |
| Asia East         | ghuangzhou             | Asia Programming Contest, Guangzhou                   | 2003, 2014      |
| Asia East         | chengdu                | Asia Programming Contest, ChengDu                     | 2005-2013       |
| Asia East         | hangzhou               | Asia Programming Contest, Hangzhou                    | 2005, 2008, 2010-2013, 2022- |
| Asia East         | changchun              | Asia Programming Contest, Changchun                   | 2007, 2012-2013, 2015 |
| Asia East         | nanjing                | Asia Programming Contest, Nanjing                     | 2007, 2013, 2018- |
| Asia East         | harbin                 | Asia Harbin Contest                                   | 2009-2010       |
| Asia East         | hefei                  | Asia Hefei Contest                                    | 2008-2009, 2015, 2022- |
| Asia East         | ningbo                 | Asia Ningbo Regional Contest                          | 2009            |
| Asia East         | wuhan                  | Asia Wuhan Regional Contest                           | 2009            |
| Asia East         | tianjin                | Asia Tianjin Regional Contest                         | 2010, 2012      |
| Asia East         | fuzhou                 | Asia Fuzhou Regional Contest                          | 2010-2011       |
| Asia East         | dalian                 | Asia Dalian Regional Contest                          | 2011, 2016      |
| Asia East         | jinhua                 | Asia Jinhua Regional Contest                          | 2012            |
| Asia East         | changsha               | Asia Changsha Regional Contest                        | 2013            |
| Asia East         | mudanjiang             | Asia Mudanjiang Regional Contest                      | 2014            |
| Asia East         | anshan                 | Asia Anshan Regional Contest                          | 2014            |
| Asia East         | shenyang               | Asia Shenyang Regional Contest                        | 2015-           |
| Asia East         | qingdao                | Asia QingDao Regional Contest                         | 2016-2018       |
| Asia East         | pyongyang              | Asia Pyongyang Regional Contest                       | 2016            |
| Asia East         | urumqi                 | Asia Urumqi Regional Programming Contest              | 2017            |
| Asia East         | nanning                | Asia Nanning Regional Contest                         | 2017            |
| Asia East         | jiaozuo                | Asia Jiaozuo Regional Contest                         | 2018            |
| Asia East         | xuzhou                 | Asia Xuzhou Regional Programming Contest              | 2018-2019       |
| Asia East         | yinchuan               | Asia Yinchuan Regional Contest                        | 2019            |
| Asia East         | nanchang               | Asia Nanchang Regional Contest                        | 2019            |
| Asia East         | jinan                  | Asia Jinan Regional Contest                           | 2020-           |
| Asia East         | macau                  | Asia Macau Regional Contest                           | 2020-           |
| Asia East         | kunming                | Asia Kunming Regional Contest                         | 2020-2021       |
| Asia Pacific      | apc                    | Asia Pacific Championship                             | 2024-           |
| Asia Pacific      | tokyo                  | Asia Programming Contest, Tokyo                       | 1998-2014       |
| Asia Pacific      | taipei                 | Asia Programming Contest, Taipei                      | 1995-2021       |
| Asia Pacific      | kyoto                  | Asia Programming Contest, Kyoto                       | 1999            |
| Asia Pacific      | seoul                  | Asia Programming Contest, Seoul                       | 2000-           |
| Asia Pacific      | singapore              | Asia Programming Contest, Singapore                   | 2000-2018       |
| Asia Pacific      | tsukuba                | Asia Programming Contest, Tsukuba                     | 2000-2017       |
| Asia Pacific      | hakodate               | Asia Programming Contest, Hakodate                    | 2001            |
| Asia Pacific      | taejon                 | Asia Programming Contest, Taejon                      | 2001-2002       |
| Asia Pacific      | kanazawa               | Asia Programming Contest, Kanazawa                    | 2002            |
| Asia Pacific      | kaohsiung              | Asia Programming Contest, Kaohsiung                   | 2002-2012       |
| Asia Pacific      | manila                 | Asia Programming Contest, Manila                      | 2002-           |
| Asia Pacific      | aizu                   | Asia Programming Contest, Aizu                        | 2003-2013       |
| Asia Pacific      | ehime                  | Asia Programming Contest, Ehime                       | 2004            |
| Asia Pacific      | hanoi                  | Asia Programming Contest, Hanoi                       | 2006-2021       |
| Asia Pacific      | yokahama               | Asia Programming Contest, Yokohama                    | 2006-           |
| Asia Pacific      | danang                 | Asia Programming Contest, Danang                      | 2007, 2013, 2019 |
| Asia Pacific      | kuala-lumpur           | Asia Kuala Lumpur Contest                             | 2008-2019       |
| Asia Pacific      | ho-chi-minh            | Asia Ho-Chi-Minh-City Contest                         | 2008, 2017, 2022 |
| Asia Pacific      | jakarta                | Asia Jakarta Contest                                  | 2008-           |
| Asia Pacific      | phuket                 | Asia Phuket Regional Contest                          | 2009-2015       |
| Asia Pacific      | hsinchu                | Asia Hsinchu Regional Contest                         | 2009, 2011      |
| Asia Pacific      | daejeon                | Asia Daejeon Regional Contest                         | 2010-2017       |
| Asia Pacific      | fukuoka                | Asia Fukuoka Regional Contest                         | 2011            |
| Asia Pacific      | hatyai                 | Asia Hatyai Regional Contest                          | 2012            |
| Asia Pacific      | chiayi                 | Asia Chia-Yi Regional Contest                         | 2013            |
| Asia Pacific      | bangkok                | Asia Bangkok Regional Contest                         | 2014, 2016, 2019 |
| Asia Pacific      | taichung               | Asia Taichung Regional Contest                        | 2014            |
| Asia Pacific      | nha-trang              | Asia Nha Trang Regional Contest                       | 2016            |
| Asia Pacific      | chung-li               | Asia Chung-Li Regional Contest                        | 2016            |
| Asia Pacific      | yangon                 | Asia Yangon Regional Programming Contest              | 2016-2018       |
| Asia Pacific      | hualien                | Asia Hua-Lien Regional Contest                        | 2017            |
| Asia Pacific      | nakhon-pathom          | Asia Nakhon Pathom Regional Contest                   | 2017-2018       |
| Asia Pacific      | taipei-hsinchu         | Asia Taipei-Hsinchu Site Programming Contest          | 2019-2020       |
| Asia Pacific      | can-tho                | Asia Can Tho Regional Contest                         | 2020            |
| Asia Pacific      | taoyuan                | Asia Taoyuan Regional Programming Contest             | 2022-2023       |
| Asia Pacific      | hue                    | Asia Hue City Regional Contest                        | 2023            |
| Asia Pacific      | south-pacific          | South Pacific Programming Contest                     | 1991-2023       |
| Asia Pacific      | south-pacific-west     | South Pacific Western Division                        | 2014-2019       |
| Asia Pacific      | south-pacific-central  | South Pacific Central Division                        | 2014-2019       |
| Asia Pacific      | south-pacific-east     | South Pacific Eastern Division                        | 2014-2019       |
| Asia Pacific      | south-pacific-division | South Pacific Independent Regional Contest Divisional | 2021-2023       |
| Asia Pacific      | nzpz                   | New Zealand Programming Contest                       | 2002-           |
| Asia Pacific      | australia              | Australian Programming Contest                        | 2013            |

### Independent

This section defines contest identifiers in the `independent` namespace.

The `independent` namespace is for contests that are not part of the ICPC or
IOI hierarchies but still benefit from stable identifiers for archives and
tooling.

| Contest | Name          | Instance        |
| ------- | ------------- | --------------- |
| bergen  | Bergen Open   | 2018-2019, 2021 |
| kth     | KTH Challenge | 2011-2022       |

## Problem Keywords

Standardized keywords for classifying the algorithmic and mathematical topics
of contest problems. These are used in the
[Problem Package Format](https://www.kattis.com/problem-package-format/) to
categorize problems.

Keywords are expected to be organized hierarchically. A problem may be tagged
with any number of keywords. When tagging, the most specific applicable
keyword should be preferred over a more general parent keyword.

No standardized keyword registry has been published yet.

Until such a registry is added here, producers and consumers that support
problem keywords should treat the set of standardized keywords as empty and
should not assume interoperability for ad-hoc keyword values.

This section is reserved for a future keyword registry to be developed as part
of the Problem Package Format work.
