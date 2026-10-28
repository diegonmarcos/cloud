# cloudy-___

The index of the cloudy project (formerly cloud; the cloud-me-* family keeps its name) — twelve repositories, with a `clone.sh` that
pulls down whichever ones you want on this machine.

```
./clone.sh                 # what exists here, what does not
./clone.sh unix cloud      # clone those two
./clone.sh --all           # everything
```

No project code lives here. `repos.json` is the registry and `clone.sh` reads
it and nothing else; the entries at the root are committed relative symlinks
out to the clones. A link that dangles is a repo you have not cloned yet — that
is the index working.

`repo_master` is the same idea widened to every repository this account owns.
See [`a0_docs/README.md`](a0_docs/README.md) for how the two relate, why the
repos sit at the root, and why this is not submodules.

## Hub submodule

This repo's parent hub is `_git-repos-master`, mounted as a git submodule at `0_hub/_git-repos-master` (one fixed path convention for every repo; URL https://github.com/diegonmarcos/_git-repos-master.git, pinned to the hub main). Only the upward link is a submodule; this hub keeps symlinks (not submodules) to its members, so there are no cycles. Source of truth: `repos.json` in _git-repos-master (`parent_hub` / `hub`, `_hub_submodule_doc`), guarded by `node repos-sot.js check-hubs`.
