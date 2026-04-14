# CCS specifications style guide

This document defines the formatting and writing style conventions for the CCS specifications documents.

## Purpose

This style guide ensures consistency across all specification documents and makes diffs more useful when reviewing changes.
This guide is adapted from the [problem package format style guide](https://github.com/icpc/problem-package-format/blob/master/STYLE.md).
The two guides are kept intentionally similar to reduce cognitive overhead for contributors working across both projects.

## Markdown formatting

### Text emphasis

- Use `_` for _italics_
- Use `**` for **bold** text

### Tables

Tables should be formatted with the following conventions:

- No prefix `|` at the beginning of rows
- No postfix `|` at the end of rows, unless the last column is empty
- Exactly one space between `---` and `|` in the header divider row on each side
- Match width of columns for all rows (that is, all columns are as wide as the largest content), except when that becomes unreasonable
- Last header divider matches the length of the header text, not the content below

**Example:**
```markdown
Endpoint   | Type          | Required | Description
---------- | ------------- | -------- | -----------
api        | Metadata      | Yes      | Information about the API itself and the version it supports.
access     | Metadata      | Yes      | Which endpoints and properties are offered by this provider.
contests   | Configuration | No       | Name, start time, duration, and other contest-level settings.
scoreboard | Aggregate     | No       | Current scoreboard, computed from judgements and the scoring rules.
event-feed | Aggregate     | No       | Streaming NDJSON feed of all changes to contest data since the start.
```

### Line breaks and paragraphs

Add newlines to make diffs maximally useful:

- Add a newline after every sentence
- Add newlines at subclauses (after commas) when the sentence becomes too long **and** it makes semantic sense

### Inline code markup

Use backticks for:

- File and directory names (for example, `contest.json`, `other-systems/`)
- API endpoint paths (for example, `/contests/<id>/submissions`)
- JSON property names and values (for example, `scoreboard_type`, `"pass-fail"`)
- HTTP method names and header names (for example, `GET`, `Cache-Control`)
- Command-line invocations and arguments in inline text
- Literal values and identifiers

### API endpoint and path notation

Use angle brackets for placeholders in endpoint paths and file patterns.
Placeholder names should be lowercase and use hyphens, matching the style of the surrounding prose.

**Examples:**
- `/contests/<id>/<endpoint>`
- `<endpoint>/<id>/<filename>`
- `other-systems/<system>`

Wrap the entire path in backticks, including any placeholder tokens.

### Cross-document references

When referencing another document in this repository, use a relative Markdown link whose href matches the target document's `permalink`.

**Examples:**
- `[JSON Format](json_format)`
- `[Contest API](contest_api)`
- `[file reference](json_format#file)`

Use descriptive link text that identifies the target document or section by name, not a generic phrase like "here" or "this section".

### Code blocks

Always specify a language tag on fenced code blocks.

Common tags used in this project:

Tag        | Use
---------- | ---
`json`     | JSON object or array examples
`yaml`     | YAML equivalents of JSON examples
`markdown` | Markdown formatting examples

When showing a JSON example and its YAML equivalent side by side,
introduce each block with a short sentence identifying which it is.

### Inline HTTP requests

Short HTTP request examples may be presented as inline code with a leading space rather than as a fenced block, for example:

` GET https://example.com/api/contests/wf14/teams`

Multi-line HTTP payloads should use a `json` fenced code block.

### Link text

Use descriptive link text that makes sense out of context:

- ✅ `see the [JSON Format](json_format) document`
- ✅ `as described in [referential integrity](json_format#referential-integrity)`
- ❌ `see [here](json_format)`
- ❌ `[click here](#file-references) for details`

## Language and terminology

### Latin abbreviations

Use full English phrases instead of Latin abbreviations for clarity:

- Write "for example" instead of "e.g."
- Write "that is" instead of "i.e."
- Write "and so on" instead of "etc."

**Rationale:** This is clearer for non-native English speakers and those without Latin knowledge,
and helps avoid formatting issues.

### Headers and capitalization

Capitalize headers like normal sentences (sentence case),
that is, only capitalize the first word and proper nouns.

**Examples:**
- ✅ "Example YAML files"
- ✅ "CCS configuration"
- ❌ "Example Yaml Files"
- ❌ "Ccs Configuration"

### Terminology

- Use "directory" instead of "folder"

## Implementation guidelines

### When making changes

- Apply these style conventions when making content changes
- Separate stylistic changes from content changes as much as reasonably possible
- Focus on consistency within the section being modified
- When in doubt, prioritize diff clarity over perfect formatting
- Style can always be fixed in a follow-up PR

### Review process

- Reviewers should check for adherence to these style guidelines
- Style consistency is important but should not block substantive improvements

## Rationale

These conventions were chosen to:

1. **Minimize line length** — important for tables that cannot be line-broken
2. **Maximize diff usefulness** — changes should be easy to review
3. **Improve readability** — especially for non-native English speakers
4. **Ensure consistency** — across all specification versions and documents
5. **Facilitate maintenance** — clear conventions reduce decision fatigue

## Examples

### Good table formatting

```markdown
Endpoint   | Type          | Required | Description
---------- | ------------- | -------- | -----------
api        | Metadata      | Yes      | Information about the API itself and the version it supports.
access     | Metadata      | Yes      | Which endpoints and properties are offered by this provider.
contests   | Configuration | No       | Name, start time, duration, and other contest-level settings.
scoreboard | Aggregate     | No       | Current scoreboard, computed from judgements and the scoring rules.
event-feed | Aggregate     | No       | Streaming NDJSON feed of all changes to contest data since the start.
```

### Good header hierarchy

```markdown
## File references

### Default filenames

#### Image file extensions

The supported extensions for image files are listed below.
```

### Good cross-document links

```markdown
Object definitions are specified in the [JSON Format](json_format) document.
A valid package must satisfy all [referential integrity](json_format#referential-integrity) requirements.
```

---

_This style guide is a living document and may be updated based on community feedback and evolving needs._
