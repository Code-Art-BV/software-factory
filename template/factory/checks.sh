#!/usr/bin/env bash
# The repo's checks. Exit 0 only when the branch is fit to review.
#
# The gate runs this script from the main checkout with the job's worktree as
# the working directory. Keep it fast, deterministic and non-interactive: no
# watch modes, no prompts, nothing that rewrites tracked files.
set -euo pipefail

# Replace the two lines below with this repo's build, lint and tests, e.g.
#   dotnet build MyApp/MyApp.csproj --nologo -v q
#   npm ci && npm run lint && npm test
echo "factory/checks.sh has no checks yet: edit it for this repo" >&2
exit 1
