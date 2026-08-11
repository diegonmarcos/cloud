# 0_specs — what this repo is

`cloud-master` is the **index** of the cloud project: one place that knows
every repository the project consists of, and a tool to pull down whichever of
them you actually want on this machine.

It holds no project code. Two files carry the whole thing:

- `repos.json`  the registry — name, group, url, private, one-line purpose
- `clone.sh`    clone what you want, symlink it into view

```
./clone.sh                 # what exists here, what does not
./clone.sh unix cloud      # clone those two
./clone.sh --group 1_cloud # clone a whole group
./clone.sh --all           # everything
./clone.sh --link          # relink whatever is already cloned
```

## How it looks on disk

Clones live OUTSIDE this repo — `$CLOUD_GIT_BASE`, default `~/git` — and
appear here as symlinks:

```
cloud-master/1_cloud/unix   ->  ~/git/unix
cloud-master/2_tools/tools  ->  ~/git/tools
```

Every repo in the project has a link, **committed**, whether or not you have
cloned it. `ls 1_cloud/` is the project; the links that dangle are the repos
you do not have yet, and `./clone.sh --list` spells that out. Nothing is
duplicated — the link points at the same working tree you develop in, so edits
through `cloud-master/1_cloud/unix` and through `~/git/unix` are the same edits.

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

Sibling headers: `0_tasks/` (what is being done) and `1_configs/` (how the repo
runs).
