# cloud-master

The index of the cloud project — twelve repositories, with a `clone.sh` that
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
