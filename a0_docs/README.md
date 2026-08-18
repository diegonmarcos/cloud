# a0_docs — what this repo is

`cloud-master` is the **index** of the cloud project: one place that knows
every repository the project consists of, and a tool to pull down whichever of
them you actually want on this machine.

It holds no project code. Two files carry the whole thing:

- `repos.json`  the registry — name, url, private, one-line purpose
- `clone.sh`    clone what you want, symlink it into view

```
./clone.sh                 # what exists here, what does not
./clone.sh unix cloud      # clone those two
./clone.sh --all           # everything
./clone.sh --link          # relink whatever is already cloned
```

## cloud-master and repo_master

Two indexes, one a subset of the other:

| | `cloud-master` | `repo_master` |
|---|---|---|
| covers | the cloud project (12) | all 26 repositories |
| layout | cloud repos at the **root**, vault under `2_vault/` | every repo under its group |
| for | working on the cloud project | "what do I own, where is it" |

`repo_master` is the superset and the place to add a new repository. If it
belongs to the cloud project, add it here too — the overlapping entries must
agree field for field.

## Why the repos sit at the root

They used to live under `a_cloud/`, alongside `b_data_science/` and
`y_others/`. Those two moved to `repo_master`, and with them gone `a_cloud/`
was a directory that contained everything and therefore distinguished nothing:
one level of nesting between you and every path you type. So the eleven cloud
repos have no `group` in the registry and link at the root.

`2_vault/` keeps its directory, because it is not a repo group at all — it is a
**config tier**, the same `2_` prefix the rest of the fleet uses for env and
dotfile config. It happens to contain a repo; that does not make it a group.

`2_sops/` is the same kind of thing: a real working directory for sops
operations — runbooks and cross-repo commands — holding no symlinks and no
secrets. Encrypted material stays in `2_vault/`, and the ship scripts stay in
`cloud/1_cicd/`; copying either here would recreate the drift trap that left
vault's `.mcp.json` behind cloud's.

Groups are data, not structure. `clone.sh` derives the layout from
`repos.json`: an entry **with** a `group` links inside that directory
(`../../<name>`), an entry **without** one links at the root (`../<name>`).
Regrouping is an edit to that file plus `./clone.sh --relink`.

## How it looks on disk

Clones live OUTSIDE this repo — `$CLOUD_GIT_BASE`, default `~/git` — and
appear here as symlinks:

```
cloud-master/unix         ->  ~/git/cloud-unix
cloud-master/tools        ->  ~/git/cloud-mykonsole-dtk
cloud-master/2_vault/vault ->  ~/git/cloud-vault
```

Every repo in the project has a link, **committed**, whether or not you have
cloned it. `ls` is the project; the links that dangle are the repos you do not
have yet, and `./clone.sh --list` spells that out. Nothing is duplicated — the
link points at the same working tree you develop in, so edits through
`cloud-master/unix` and through `~/git/cloud-unix` are the same edits.

The links are **relative**, and that is what makes committing them work. Git
stores a symlink target verbatim, so an absolute `/home/diego/git/cloud-unix` would
resolve on one machine and dangle on every other — exactly the failure
`.mcp.json` had as a link to `/home/diego/.mcp.json`. Relative depends on
nothing but the layout: clone the repos as siblings anywhere — `~/git`, `/srv`,
a container — and every link resolves.

The depth follows the nesting and is not guesswork: `../<name>` from the root,
`../../<name>` from inside `2_vault/`. Getting that wrong does not fail loudly
— it produces a link that resolves somewhere plausible and wrong — which is why
`clone.sh` computes it rather than hard-coding it.

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
