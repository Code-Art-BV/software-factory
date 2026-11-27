# Install the software factory

You are a coding agent installing this factory into the user's project. Run
the installer, adapt what's repo-specific, verify it, and report. Work in the
project's root.

The source is `https://github.com/Code-Art-BV/software-factory`. It is a
private repository, so read it with `gh`, not over plain HTTP.

## 0. Check the project

Stop and tell the user if any of these fail:

- It's a git repo with an `origin` on GitHub, and `gh auth status` shows a user
  who can push to it and manage its labels.
- Its default branch (`gh repo view --json defaultBranchRef`) exists on
  `origin`.
- `bash`, `git` and Python 3.9 or later are on `PATH` (`python3`, or `python`
  on Windows). On Windows, run everything in this file from Git Bash, not
  PowerShell.
- `factory/config.json` doesn't exist yet. If it does, the factory is already
  installed: tell the user, and offer `--update` (see the end of this file)
  instead of installing over their customizations.
- None of `.claude/agents/{intake,spec-writer,builder,reviewer-code,reviewer-security,reviewer-ui,reviewer-ux,approver}.md`
  or `.claude/skills/factory/SKILL.md` exists. If one does, show the user the
  clash and ask before overwriting.

`agent-browser` is optional but wanted: the builder and the UI/UX reviewers use
it to look at pages. If it's missing, tell the user to run
`npm install -g agent-browser`; don't install it yourself.

## 1. Run the installer

Decide two things first:

- **Base branch.** The repo's default branch, unless the user names another.
- **Does merging to the base branch deploy?** Read the CI config
  (`.github/workflows/`, and whatever else the project deploys with). If a
  push to the base branch deploys anything, pass `--human-merge`: the factory
  then never merges, and every finished PR waits for a human. If you can't
  tell, ask the user.

Then clone the factory outside the project and run its installer on the
project:

```bash
SF="$(mktemp -d)/software-factory"
gh repo clone Code-Art-BV/software-factory "$SF" -- --depth 1
bash "$SF/install.sh" [--base <branch>] [--human-merge] .
```

The installer copies the scripts, dashboard, skill, agents, `config.json` and
`checks.sh` into the project, appends the factory's entries to `.gitignore`
and `.gitattributes` and its sections to `CLAUDE.md`, stages the scripts with
the executable bit, and creates the GitHub labels (`factory`,
`factory:needs-info`, `factory:needs-human`). Read its output: it warns when
`.gitignore` still ignores a factory file.

Don't copy this repository's `README.md`, `INSTALL.md`, `install.sh`, `lib/`
or `template/` into the project.

## 2. Adapt

The installed files are generic. Fill them in from the real code, and cite
real paths. Don't change `factory/bin/*`, `factory/dashboard.html` or
`.claude/skills/factory/SKILL.md`.

**`factory/checks.sh`.** Replace the placeholder with the project's real
checks: install dependencies if a fresh worktree needs them, then lint,
typecheck, tests and build, whichever the project has. Find them in
`CLAUDE.md`, `package.json` scripts, `Makefile`, `pyproject.toml`, project
files and CI config. The script runs with a job's worktree as its working
directory. It must be fast, non-interactive, must not rewrite tracked files
(no `--fix`, no `--update-snapshots`), and must exit non-zero on any failure.
Keep `set -euo pipefail`.

**`factory/config.json`.**

- `base_branch`: the installer set it; check it.
- `merge_method`: `merge`, `squash` or `rebase`, one the repo allows
  (`gh api repos/{owner}/{repo} --jq '{allow_merge_commit, allow_squash_merge, allow_rebase_merge}'`).
- `protected_paths`: keep the two factory entries and don't add the project's
  tests. Features legitimately change existing tests, and a protected test
  blocks the job with no way through. Add a path only when no job should ever
  change it.
- `ports`: move `base` if the project already uses ports 5300–5399.
- Leave `concurrency`, `max_rounds`, `routing`, `surface_reviewers` and
  `prices_usd_per_mtok` as they are unless the user asks.

**Agents.** In `.claude/agents/`, replace every `<!-- project:begin ... -->`
comment with what it asks for, keeping nothing of the comment, and remove the
`<!-- project:end -->` line. They are in `intake.md`, `approver.md`,
`reviewer-security.md`, `reviewer-ui.md` and `reviewer-ux.md`. Don't change the
agents' structure, file names, frontmatter, first-line formats or one-line
replies. With `--human-merge`, the installer already added the paragraph that
forbids APPROVE to `approver.md`; leave it.

**`CLAUDE.md`.** Every agent reads it. The installer appended Dev server,
Validation and Software factory sections:

- Fill in the Dev server section (replace the `<!-- factory: ... -->`
  comment): how to start the app on a given port, what it connects to (shared
  database? real email?), how to reach pages behind sign-in, and what agents
  must never do with it. If the project has no dev server, say so.
- List the real commands of `checks.sh` under Validation.
- Make sure the file also says how to set up a fresh checkout (install
  dependencies, env files to copy).

## 3. Verify

1. In the project root, on the base branch, `bash factory/checks.sh` exits 0.
   If it fails there, the factory can never pass a job: fix the script (not
   the project) or tell the user what's broken.
2. `factory/bin/job queue` runs without an error.
3. `grep -rn "project:begin\|project:end\|<!-- factory:" .claude/agents CLAUDE.md`
   finds nothing.
4. Each file in `.claude/agents/` has only these frontmatter keys: `name`,
   `description`, `tools`, `model`, and `hooks` on the builder.
5. `python3 -m json.tool factory/config.json` succeeds.
6. `git check-ignore factory/jobs/x .worktrees/x` prints both paths, and
   `git check-ignore factory/bin/job .claude/agents/intake.md .claude/skills/factory/SKILL.md`
   prints nothing: the factory's files are part of the project and get
   committed, so only `factory/jobs/` and `.worktrees/` are ignored.

## 4. Hand over

Stay on the branch the user is on: don't create or check out another branch.
Commit the install there with a one-line message and show the user the diff.
Ask before pushing: the factory branches every job from `origin/<base_branch>`,
so the install must be on that branch there before the first run.

Then tell the user, in a few lines:

- Label one or two small issues `factory`, then run `/factory run` in Claude
  Code from the project root. The label is the trust boundary: give it only to
  issues they would hand to a contractor.
- Every job ends as a PR. The approver merges what it approves (never, with
  `--human-merge`); the rest wait labeled `factory:needs-human`. Approve one
  by merging it on GitHub, or tell the factory what to change with
  `/factory <anything>`.
- To keep the factory running, leave `factory/bin/watch` running in a
  terminal: it starts `/factory run` headless whenever a `factory` issue
  opens, an author answers a question, or someone comments on a PR that
  needs a human. The run can't ask for permissions; see the README's "Keep it
  running".
- Intake runs on Fable, once per issue. Depending on their plan, Fable can
  bill to usage credits rather than the plan's included usage.
- To start carefully, set `concurrency` to 1 in `factory/config.json` and read
  every PR until they trust it.

## Updating an existing install

When `factory/config.json` already exists and the user wants the latest
scripts, clone as in step 1 and run:

```bash
bash "$SF/install.sh" --update .
```

This refreshes only `factory/bin/*`, `factory/dashboard.html` and the skill.
The agents, `config.json`, `checks.sh` and `CLAUDE.md` are left alone; compare
them with `$SF/template` and tell the user what changed there. Then run step 3
and commit.
