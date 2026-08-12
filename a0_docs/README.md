# a0_docs — what this repo is

`cloud-master` is the **index** of the cloud project: one place that knows
every repository the project consists of, and a tool to pull down whichever of
them you actually want on this machine.

It holds no project code. Two files carry the whole thing:

- `repos.json`  the registry — name, group, url, private, one-line purpose
- `clone.sh`    clone what you want, symlink it into view

```
./clone.sh                 # what exists here, what does not
./clone.sh unix cloud      # clone those two
./clone.sh --group a_cloud # clone a whole group
./clone.sh --all           # everything
./clone.sh --link          # relink whatever is already cloned
```

## Groups

Four, and the prefixes are the sort order, not decoration:

| group | | |
|---|---|---|
| `2_vault/`        |  1 | Secrets (sops/age). Numbered so it sorts ahead of the lettered groups — it is the one repo whose absence breaks the others. |
| `a_cloud/`        | 11 | The cloud project: infra, services, data, front-end, and the tooling built for it. |
| `b_data_science/` |  3 | Machine-learning and data-science work. |
| `y_others/`       | 11 | Coursework, experiments, forks, personal. `y_` so it sorts **last**. |

`2_sops/` sits beside them but is **not** a group: it is a real working
directory for sops operations — runbooks and cross-repo commands — holding no
symlinks and no secrets. Encrypted material stays in `2_vault/`, and the ship
scripts stay in `a_cloud/cloud/9_others/`; copying either here would recreate
the drift trap that left vault's `.mcp.json` behind cloud's.

`tools` lives in `a_cloud/` rather than a group of its own: it is the cloud
project's toolkit, not a separate concern. `vault` is the opposite case — it
serves everything, so it sits above the lettered groups instead of inside one.

Group names are data. `clone.sh` derives the directory layout from
`repos.json`, so renaming a group is an edit to that file plus
`./clone.sh --relink`.

## How it looks on disk

Clones live OUTSIDE this repo — `$CLOUD_GIT_BASE`, default `~/git` — and
appear here as symlinks:

```
cloud-master/a_cloud/unix   ->  ~/git/unix
cloud-master/a_cloud/tools  ->  ~/git/tools
```

Every repo in the project has a link, **committed**, whether or not you have
cloned it. `ls a_cloud/` is the project; the links that dangle are the repos
you do not have yet, and `./clone.sh --list` spells that out. Nothing is
duplicated — the link points at the same working tree you develop in, so edits
through `cloud-master/a_cloud/unix` and through `~/git/unix` are the same edits.

The links are **relative** (`../../unix`), and that is what makes committing
them work. Git stores a symlink target verbatim, so an absolute
`/home/diego/git/unix` would resolve on one machine and dangle on every other
— exactly the failure `.mcp.json` had as a link to `/home/diego/.mcp.json`.
Relative depends on nothing but the layout: clone the repos as siblings
anywhere — `~/git`, `/srv`, a container — and every link resolves.

## Why not submodules

cloud-master used submodules until 2026-08-11, and they were the wrong tool:

- **Circular.** cloud-master contained cloud, and cloud contained
  cloud-master. `git clone --recursive` never terminates.
- **Private repos broke init.** Six of them. Anyone without those credentials
  got a failed `submodule update`, not a partial one.
- **Pinned, when it should float.** A submodule records a commit. An index of
  the repos you work in wants HEAD, not a pin — bumping twelve gitlinks after
  every change is bookkeeping that buys nothing here.
- **All or nothing, and heavy.** Reading one file meant dragging 26
  repositories.

A submodule is a pinned build input. This is a directory of working clones.
Different things.

Sibling headers: `a0_tasks/` (what is being done) and `9_others/` (how the repo
runs).
