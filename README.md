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

The installer adds this to the target repo:

```
factory/bin/{job,gate,route}     state machine, gate and routing scripts
factory/config.json              concurrency, rounds, base branch, routing, prices
factory/checks.sh                the repo's checks (you write these)
factory/dashboard.html           job dashboard
.claude/agents/*.md              intake, spec-writer, builder, 4 reviewers, approver
.claude/skills/factory/SKILL.md  the /factory command
```

It also appends the factory's entries to `.gitignore` and `.gitattributes`,
and Dev server, Validation and Software factory sections to `CLAUDE.md`.

## Customize

The template is generic. Before the first run, open Claude Code in the target
repo and paste:

> The software factory was just installed in this repo. Customize it:
>
> 1. Write `factory/checks.sh`: this repo's build, lint and tests. It must be
>    fast, non-interactive, not rewrite tracked files, and exit 0 on the base
>    branch. Run it to prove it.
> 2. In `CLAUDE.md`, fill in the Dev server section (replace the
>    `<!-- factory: ... -->` comment): how to start the app on a given port,
>    what it connects to, how to reach pages behind sign-in, and what agents
>    must never do with it. List the real commands of `checks.sh` under
>    Validation.
> 3. In `.claude/agents/`, replace every `<!-- project:begin ... -->` comment
>    (keep nothing of the comment, and remove the `<!-- project:end -->` line)
>    with what it asks for, based on the real code: `intake.md`,
>    `approver.md`, `reviewer-security.md`, `reviewer-ui.md`, `reviewer-ux.md`.
>    Cite real paths.
> 4. Check whether merging to the base branch deploys anything (CI workflows).
>    If it does and `approver.md` doesn't already forbid APPROVE, tell me.
> 5. Check that `.gitignore` doesn't ignore `factory/bin/`, `.claude/agents/`
>    or `.claude/skills/`.
>
> Don't change `factory/bin/*`, `factory/dashboard.html` or the skill.

Then commit and push to the base branch: job worktrees are created from it, so
agents only see what is there.

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

```bash
git -C software-factory pull
bash software-factory/install.sh --update /path/to/your/repo
```

## This repo

```
install.sh        the installer
lib/configure.py  its helper for config and text files
template/         what gets copied into the target repo
```
