"""MkDocs build hook reconstructing links from the old Jekyll conventions.

  * URL routing: each page carries a YAML front matter `permalink:` (its public
    slug); MkDocs derives URLs from filenames instead, so `on_files` remaps each
    page's output path to `<permalink-slug>.html` (README/readme -> index.html),
    preserving the existing public URLs.
  * Internal links: they are extensionless and point at those permalinks
    (e.g. `[Contest API](contest_api)`); `on_page_markdown` rewrites `](slug)`
    to the *source* filename so MkDocs resolves it to the remapped URL. Unknown
    slugs (already dead in Jekyll) are left untouched.

MkDocs strips the YAML front matter itself (it becomes `page.meta`), so nothing
here needs to remove it.

Referenced from each config via `hooks: [hooks.py]`.
"""

import os
import re
from pathlib import Path

import yaml

FRONT_MATTER_RE = re.compile(r"\A---\n(.*?)\n---\n", re.DOTALL)
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


def _rewrite_links(body):
    def repl(m):
        target, frag = m.group(1), m.group(2) or ""
        src = _slug_to_src.get(target)
        if src is None:
            return m.group(0)
        return f"]({src}{frag})"

    return LINK_RE.sub(repl, body)


def on_page_markdown(markdown, page, config, files):
    return _rewrite_links(markdown)
