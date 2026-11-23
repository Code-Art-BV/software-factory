"""Called by install.sh from the target repo's root: set the base branch, apply
--human-merge, and add the factory's lines to .gitignore, .gitattributes and
CLAUDE.md. Usage: configure.py <template dir>, with BASE and HUMAN in the env.
"""

import json
import os
import sys
from pathlib import Path

SRC = Path(sys.argv[1])


def write(path, text):
    Path(path).write_bytes(text.encode("utf-8"))  # bytes: keep LF endings on Windows


def append(path, marker, block):
    p = Path(path)
    text = p.read_text(encoding="utf-8") if p.exists() else ""
    if marker in text:
        return
    if text and not text.endswith("\n"):
        text += "\n"
    write(p, text + block)


config = Path("factory/config.json")
text = config.read_text(encoding="utf-8")
old = json.loads(text)["base_branch"]
write(config, text.replace(f'"base_branch": "{old}"', f'"base_branch": "{os.environ["BASE"]}"'))

if os.environ.get("HUMAN") == "1":
    approver = Path(".claude/agents/approver.md")
    extra = (SRC / "approver-human-merge.md").read_text(encoding="utf-8").rstrip()
    text = approver.read_text(encoding="utf-8")
    if text.count("<!-- project:end -->") != 1:
        sys.exit("configure: approver.md has no single <!-- project:end --> marker")
    write(approver, text.replace("<!-- project:end -->", "<!-- project:end -->\n\n" + extra))

append(".gitignore", "/factory/jobs/",
       "\n# Software factory: runtime state and per-job worktrees\n/factory/jobs/\n/.worktrees/\n")
append(".gitattributes", "/factory/bin/*",
       "\n# Run by bash and by shebang, so they need LF endings on Windows checkouts too\n"
       "/factory/checks.sh text eol=lf\n/factory/bin/* text eol=lf\n")
append("CLAUDE.md", "## Software factory", (SRC / "CLAUDE.section.md").read_text(encoding="utf-8"))
