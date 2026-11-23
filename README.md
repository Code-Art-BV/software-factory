# Software factory

A Claude Code pipeline that turns GitHub issues into reviewed pull requests.
One Claude Code session orchestrates every job:

```
intake → route → spec-writer → builder → gate (checks.sh) → reviewers → approver → merge or human
```

Based on [software-factory-claude-code-v2](https://github.com/zazencodes/zazencodes-season-3/tree/main/src/software-factory-claude-code-v2)
by ZazenCodes, modified so it also runs on Windows (Git Bash): no `fcntl`, no
`lsof`, UTF-8 everywhere, LF-pinned scripts.

## Requirements

On the machine that runs the factory:

- Claude Code
- `git`, `bash` (Git Bash on Windows) and Python 3.9+ as `python3` on `PATH`
- GitHub CLI `gh`, signed in with write access to the target repo
- `agent-browser` (`npm install -g agent-browser`) for the builder and the
  UI/UX reviewers to look at pages

## Install

Open Claude Code in your project and paste:

```text
Install this software factory in this project. Read INSTALL.md in the
repository and follow it (the repo is private: use gh, not a web fetch):

https://github.com/Code-Art-BV/software-factory
```

Your agent reads [`INSTALL.md`](INSTALL.md), runs the installer, fills
`factory/checks.sh` with your project's real build, lint and test commands,
tailors the agents and `CLAUDE.md` to your code, creates the GitHub labels,
checks that `checks.sh` passes on the base branch, and commits. It asks before
pushing.

The installer adds this to the target repo:

```
factory/bin/{job,gate,route}     state machine, gate and routing scripts
factory/config.json              concurrency, rounds, base branch, routing, prices
factory/checks.sh                the repo's checks (the installing agent fills it in)
factory/dashboard.html           job dashboard
.claude/agents/*.md              intake, spec-writer, builder, 4 reviewers, approver
.claude/skills/factory/SKILL.md  the /factory command
```

It also appends the factory's entries to `.gitignore` and `.gitattributes`,
and Dev server, Validation and Software factory sections to `CLAUDE.md`.

### By hand

```bash
git clone https://github.com/Code-Art-BV/software-factory.git
bash software-factory/install.sh /path/to/your/repo
```

| Option | What it does |
| --- | --- |
| `--base <branch>` | Branch PRs target. Default: the remote's default branch. |
| `--human-merge` | The factory never merges; every finished PR goes to a human. **Use it when merging to the base branch deploys.** |
| `--no-labels` | Don't create the GitHub labels (`factory`, `factory:needs-info`, `factory:needs-human`). |
| `--update` | Refresh only the scripts, dashboard and skill. Your agents, `config.json`, `checks.sh` and `CLAUDE.md` are left alone. |
| `--force` | Overwrite an existing install, customizations included. |

The template is generic, so customize it before the first run: open Claude
Code in the target repo and tell it to follow steps 2 to 4 of
[`INSTALL.md`](INSTALL.md). Job worktrees are created from the base branch, so
agents only see what is committed and pushed there.

## Use

In Claude Code, in the target repo:

```
/factory run          every open issue labeled `factory`, `concurrency` at a time; also resumes
/factory run <n>      one issue
/factory <anything>   ask about jobs, give feedback on an escalated job, file a feature
```

Dashboard: `cd factory && python3 -m http.server`, then open
http://localhost:8000/dashboard.html.

Only issues labeled `factory` run; the label is the trust boundary, so give it
only to issues you would hand to a contractor.

## Settings

`factory/config.json`:

- `concurrency`: jobs running at once. `max_rounds`: build → gate → review
  rounds before a job goes to a human.
- `base_branch`, `merge_method` (`merge`, `squash` or `rebase`).
- `routing` and `surface_reviewers`: which reviewers run, on which model, for
  each risk level and surface intake assigns.
- `protected_paths`: files a job branch may not modify.
- `ports`: dev server ports per job (`base + step × job number`).
- `prices_usd_per_mtok`: used for the cost column. Add a row when a new model
  appears, or `job` stops with "no price for model".

## Updating an install

Tell your agent to update the software factory from the link above (it follows
the last section of `INSTALL.md`), or by hand:

```bash
git -C software-factory pull
bash software-factory/install.sh --update /path/to/your/repo
```

## This repo

```
INSTALL.md        instructions for the installing agent
install.sh        the installer
lib/configure.py  its helper for config and text files
template/         what gets copied into the target repo
```
