#!/usr/bin/env bash
# Install or update the software factory in a git repository.
#
#   install.sh [options] [<target repo>]      default target: the current directory
#
#   --base <branch>    base branch PRs target (default: the remote's default branch)
#   --human-merge      the factory never merges: every finished PR goes to a human.
#                      Use it when merging to the base branch deploys.
#   --no-labels        don't create the GitHub labels
#   --update           only refresh the scripts, dashboard and skill; leaves the
#                      agents, config.json, checks.sh and CLAUDE.md alone
#   --force            overwrite an existing install, customizations included
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/template"
BASE="" HUMAN=0 LABELS=1 UPDATE=0 FORCE=0 TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:?--base needs a branch}"; shift ;;
    --human-merge) HUMAN=1 ;;
    --no-labels) LABELS=0 ;;
    --update) UPDATE=1 ;;
    --force) FORCE=1 ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "install: unknown option $1" >&2; exit 1 ;;
    *) TARGET="$1" ;;
  esac
  shift
done

TARGET="$(cd "${TARGET:-.}" && git rev-parse --show-toplevel 2>/dev/null)" \
  || { echo "install: target is not a git repository" >&2; exit 1; }
cd "$TARGET"

PY=python3; command -v python3 >/dev/null || PY=python
for tool in "$PY" git gh; do
  command -v "$tool" >/dev/null || { echo "install: $tool is required but not on PATH" >&2; exit 1; }
done

copy_scripts() {
  mkdir -p factory/bin .claude/skills/factory
  cp "$SRC"/factory/bin/* factory/bin/
  cp "$SRC"/factory/dashboard.html factory/
  cp "$SRC"/.claude/skills/factory/SKILL.md .claude/skills/factory/
  chmod +x factory/bin/*
}

if [ $UPDATE = 1 ]; then
  [ -f factory/config.json ] || { echo "install: nothing to update, factory/ is not installed here" >&2; exit 1; }
  copy_scripts
  echo "Updated factory/bin, factory/dashboard.html and the /factory skill in $TARGET."
  echo "Agents, config.json, checks.sh and CLAUDE.md were left alone; compare them with"
  echo "$SRC by hand if the template changed."
  exit 0
fi

if [ -e factory/config.json ] && [ $FORCE = 0 ]; then
  echo "install: factory/ already exists in $TARGET. Use --update to refresh the scripts," >&2
  echo "or --force to overwrite everything, customizations included." >&2
  exit 1
fi

if [ -z "$BASE" ]; then
  BASE="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)"
  [ -n "$BASE" ] || BASE="$(git branch --show-current)"
fi

copy_scripts
mkdir -p .claude/agents
cp "$SRC"/.claude/agents/*.md .claude/agents/
cp "$SRC"/factory/config.json "$SRC"/factory/checks.sh factory/
chmod +x factory/checks.sh

BASE="$BASE" HUMAN="$HUMAN" "$PY" -X utf8 "$SRC/../lib/configure.py" "$SRC"

# The factory's files must be tracked: worktrees and teammates need them.
if git check-ignore -q factory/bin/job; then
  printf '# bin/ is ignored above; the factory scripts are source\n!/factory/bin/\n' >> .gitignore
fi
WARN=""
for f in factory/bin/job .claude/agents/intake.md .claude/skills/factory/SKILL.md; do
  if git check-ignore -q "$f"; then WARN="$WARN  $f"$'\n'; fi
done

# Stage the scripts with the executable bit, which Windows checkouts don't record.
git add --chmod=+x factory/bin/gate factory/bin/job factory/bin/route factory/bin/watch factory/checks.sh

if [ $LABELS = 1 ]; then
  gh label create factory --color 5319e7 --description "Queue for the software factory (/factory run)" --force \
  && gh label create "factory:needs-info" --color fbca04 --description "Factory intake is waiting for the author" --force \
  && gh label create "factory:needs-human" --color d93f0b --description "Factory job needs a human decision or merge" --force \
  || echo "install: could not create the labels; create factory, factory:needs-info and factory:needs-human by hand" >&2
fi

echo
echo "Installed the software factory in $TARGET (base branch: $BASE)."
if [ -n "$WARN" ]; then
  echo
  echo "WARNING: .gitignore still ignores these; un-ignore them before committing:"
  printf '%s' "$WARN"
fi
if ! command -v agent-browser >/dev/null; then
  echo
  echo "Note: agent-browser is not on PATH. The builder and the UI/UX reviewers use it"
  echo "to look at pages: npm install -g agent-browser"
fi
echo
echo "Next:"
echo "  1. Customize it for this repo: follow steps 2 to 4 of INSTALL.md in the"
echo "     software-factory repository (or tell Claude Code to)."
echo "  2. Make sure bash factory/checks.sh exits 0 on the base branch."
echo "  3. Commit and push to the base branch (job worktrees are created from it)."
echo "  4. Label an issue factory and run /factory run in Claude Code, or keep"
echo "     factory/bin/watch running to pick up GitHub changes on its own."
