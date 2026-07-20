"""MkDocs build hook reproducing the ccs-specs Jekyll conventions.

The specification content on the version branches is Jekyll-flavoured and is
NOT modified for MkDocs. This hook bridges the gap at build time:

  * URL routing: each page carries a YAML front matter `permalink:` (its public
    slug); MkDocs derives URLs from filenames instead, so `on_files` remaps each
    page's output path to `<permalink-slug>.html` (README/readme -> index.html),
    preserving the existing public URLs.
  * Internal links: they are extensionless and point at those permalinks
    (e.g. `[Contest API](contest_api)`); `on_page_markdown` rewrites `](slug)`
    to the *source* filename so MkDocs resolves it to the remapped URL. Unknown
    slugs (already dead in Jekyll) are left untouched.
  * CommonMark fidelity: Jekyll used a CommonMark renderer, Python-Markdown
    differs. `on_page_markdown` re-indents closing code fences and inserts the
    blank line Python-Markdown needs before a list that interrupts a paragraph.

MkDocs strips the YAML front matter itself (it becomes `page.meta`), so nothing
here needs to remove it.

Referenced from each config via `hooks: [hooks.py]`.
"""

import os
import re
from pathlib import Path

import yaml

FRONT_MATTER_RE = re.compile(r"\A---\n(.*?)\n---\n", re.DOTALL)
OPEN_FENCE_RE = re.compile(r"^(\s{0,3})(`{3,}|~{3,})(.*)$")
LIST_ITEM_RE = re.compile(r"^\s*([-*+]|\d{1,9}[.)])\s")
FENCE_TOGGLE_RE = re.compile(r"^\s{0,3}(`{3,}|~{3,})")
LINK_RE = re.compile(r"\]\(([A-Za-z0-9_-]+)(#[^)]*)?\)")

# Populated in on_files, consumed in on_page_markdown: permalink slug -> source
# filename (e.g. "contest_api" -> "Contest_API.md").
_slug_to_src = {}


def _front_matter(text):
    m = FRONT_MATTER_RE.match(text)
    if not m:
        return {}
    meta = yaml.safe_load(m.group(1)) or {}
    return meta if isinstance(meta, dict) else {}


def _target_name(src_uri, meta):
    """Output basename (without extension) for a source page, or None to keep."""
    stem = Path(src_uri).stem
    if stem.lower() == "readme":
        return "index"
    permalink = meta.get("permalink")
    if permalink:
        return Path(str(permalink).strip("/")).name
    return None  # RELEASE, STYLE, ... keep their filename


def on_files(files, config):
    _slug_to_src.clear()
    for f in files:
        if not f.is_documentation_page() or not f.src_uri.endswith(".md"):
            continue
        meta = _front_matter(Path(f.abs_src_path).read_text(encoding="utf-8"))
        permalink = meta.get("permalink")
        if permalink:
            _slug_to_src[Path(str(permalink).strip("/")).name] = f.src_uri
        target = _target_name(f.src_uri, meta)
        if target and target != Path(f.src_uri).stem:
            dest = target + ".html"  # use_directory_urls is false
            f.name = target
            f.dest_path = dest
            f.abs_dest_path = os.path.join(config["site_dir"], dest)
            f.url = dest
    return files


def _normalize_fences(body):
    out = []
    fence = None  # (char, count, indent) while inside a fenced block
    for line in body.split("\n"):
        if fence is None:
            m = OPEN_FENCE_RE.match(line)
            if m:
                indent, ticks, info = m.groups()
                ch = ticks[0]
                if not (ch == "`" and "`" in info):
                    fence = (ch, len(ticks), len(indent))
            out.append(line)
        else:
            ch, count, oindent = fence
            close = re.match(r"^\s{0,3}(" + re.escape(ch) + r"{%d,})\s*$" % count, line)
            if close:
                out.append(" " * oindent + close.group(1))
                fence = None
            else:
                out.append(line)
    return "\n".join(out)


def _ensure_blank_before_lists(body):
    out = []
    in_fence = False
    in_list = False
    prev_blank = True
    for line in body.split("\n"):
        if FENCE_TOGGLE_RE.match(line):
            in_fence = not in_fence
            if len(line) - len(line.lstrip(" ")) == 0:
                in_list = False
            out.append(line)
            prev_blank = False
            continue
        if in_fence:
            out.append(line)
            prev_blank = False
            continue
        if line.strip() == "":
            out.append(line)
            prev_blank = True
            continue
        if LIST_ITEM_RE.match(line):
            if not in_list and not prev_blank:
                out.append("")
            in_list = True
        elif len(line) - len(line.lstrip(" ")) == 0:
            in_list = False
        out.append(line)
        prev_blank = False
    return "\n".join(out)


def _rewrite_links(body):
    def repl(m):
        target, frag = m.group(1), m.group(2) or ""
        src = _slug_to_src.get(target)
        if src is None:
            return m.group(0)
        return f"]({src}{frag})"

    return LINK_RE.sub(repl, body)


def on_page_markdown(markdown, page, config, files):
    return _rewrite_links(_ensure_blank_before_lists(_normalize_fences(markdown)))
