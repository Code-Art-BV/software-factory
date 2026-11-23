
## Dev server

<!-- factory: say how to start the app on a given port (`--urls http://localhost:<port>`
or `PORT=<port>`), what it connects to (shared database? real email?), and how
to reach pages behind sign-in. Agents follow this literally. -->

To stop a dev server, kill only the PID listening on its port. Windows (Git
Bash): `netstat -ano | grep ":<port> .*LISTENING"`, then
`taskkill //PID <pid> //F`. macOS and Linux: `lsof -tiTCP:<port> -sTCP:LISTEN`.
On Windows, run `factory/bin/*` and `factory/checks.sh` from Git Bash (the Bash
tool), not PowerShell.

## Validation

`bash factory/checks.sh` from the repo root is the bar, and it must exit 0.

## Software factory

`/factory run` builds every open GitHub issue labeled `factory` through
intake → spec → build → gate → review → approve, one PR per issue. State is in
`factory/jobs/` (gitignored); `factory/bin/job` is its only writer. Checks:
`factory/checks.sh`. Dashboard: `cd factory && python3 -m http.server`, then
open http://localhost:8000/dashboard.html.

Each job works in its own git worktree, a full checkout of the repo at
`.worktrees/<job-id>` (gitignored). A tool run from the repo root that doesn't
read `.gitignore` sees those copies too; exclude `.worktrees/` in its config.
