"""Export the short GDD (docs/short-gdd/short-gdd.md) to PDF.

It wraps the Markdown in a small HTML page that renders it in the browser (marked for
Markdown, mermaid for the diagrams, both loaded from the jsDelivr CDN, so an internet
connection is needed), then prints that page to PDF with Microsoft Edge in headless mode.

Usage, from the repo root:

  python tools/export_short_gdd_pdf.py

Writes docs/short-gdd/short-gdd.pdf. Edge is found at its usual Windows path; set
EDGE_BIN to use another Chromium-based browser. The PDF's text is the same on every run
(PDF files carry their own timestamps, so the bytes differ).
"""

import html
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "docs" / "short-gdd" / "short-gdd.md"
OUTPUT = ROOT / "docs" / "short-gdd" / "short-gdd.pdf"
EDGE_PATHS = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
]
MARKED = "https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js"
MERMAID = "https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js"

STYLE = """
@page { size: A4; margin: 18mm 16mm; }
body { font-family: "Segoe UI", Arial, sans-serif; font-size: 10.5pt; line-height: 1.45; color: #1b1d26; }
h1 { font-size: 26pt; margin: 0 0 8pt; color: #2a1d5c; }
h2 { font-size: 15pt; margin: 18pt 0 6pt; color: #2a1d5c; border-bottom: 1.5pt solid #c2186b; padding-bottom: 2pt; break-after: avoid; }
table { border-collapse: collapse; width: 100%; margin: 6pt 0 10pt; font-size: 9.5pt; break-inside: avoid; }
th, td { border: 0.75pt solid #c9ccd6; padding: 4pt 6pt; text-align: left; vertical-align: top; }
th { background: #eef0f6; }
ul { padding-left: 16pt; }
li { margin: 3pt 0; }
.mermaid { text-align: center; margin: 8pt 0 12pt; break-inside: avoid; }
code { font-family: Consolas, monospace; }
"""


def build_html(markdown_text):
    """The page that renders the Markdown; the text travels as JSON so nothing in it can break the script."""
    payload = json.dumps(markdown_text)
    return f"""<!doctype html>
<html><head><meta charset="utf-8"><title>Solid Carbide: short GDD</title>
<style>{STYLE}</style>
<script src="{html.escape(MARKED)}"></script>
<script src="{html.escape(MERMAID)}"></script>
</head><body><main id="doc"></main>
<script>
const md = {payload.replace("</", "<\\/")};
const doc = document.getElementById("doc");
doc.innerHTML = marked.parse(md);
for (const code of doc.querySelectorAll("code.language-mermaid")) {{
  const div = document.createElement("div");
  div.className = "mermaid";
  div.textContent = code.textContent;
  code.parentElement.replaceWith(div);
}}
mermaid.initialize({{ startOnLoad: false, theme: "neutral" }});
mermaid.run();
</script>
</body></html>
"""


def find_browser():
    candidates = [os.environ["EDGE_BIN"]] if os.environ.get("EDGE_BIN") else EDGE_PATHS
    for path in candidates:
        if Path(path).exists():
            return path
    return None


def main():
    browser = find_browser()
    if not browser:
        print("error: Microsoft Edge not found; set EDGE_BIN to a Chromium-based browser", file=sys.stderr)
        return 2
    page = build_html(SOURCE.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory() as tmp:
        html_path = Path(tmp) / "short-gdd.html"
        html_path.write_text(page, encoding="utf-8")
        cmd = [browser, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
               "--run-all-compositor-stages-before-draw", "--virtual-time-budget=20000",
               f"--user-data-dir={Path(tmp) / 'profile'}",
               f"--print-to-pdf={OUTPUT}", html_path.as_uri()]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    if not OUTPUT.exists() or OUTPUT.stat().st_size == 0:
        print("error: the browser did not write the PDF", file=sys.stderr)
        print(result.stderr[-2000:], file=sys.stderr)
        return 1
    print(f"wrote {OUTPUT.relative_to(ROOT)} ({OUTPUT.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
