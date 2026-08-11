#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║ clone.sh — pick which cloud repos to have locally                ║
# ║                                                                  ║
# ║   ./clone.sh                list what exists and what does not   ║
# ║   ./clone.sh <name>...      clone those, then link them          ║
# ║   ./clone.sh --all          clone everything in repos.json       ║
# ║   ./clone.sh --group 1_cloud   clone one group                   ║
# ║   ./clone.sh --link         relink whatever is already cloned    ║
# ║   ./clone.sh --unlink       remove the symlinks, keep the clones ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# cloud-master is an INDEX, not a container. Clones live outside it (in
# $CLOUD_GIT_BASE, default ~/git) and appear here as symlinks:
#
#     cloud-master/1_cloud/unix  ->  ~/git/unix
#
# A repo you have cloned shows up; one you have not simply is not there. The
# symlinks are per-machine and therefore gitignored — this repo commits only
# repos.json and this script.
#
# Why not submodules: a submodule pins a commit and wants --recursive, which
# here meant cloud-master containing cloud containing cloud-master (an
# unterminating recursive clone), private repos breaking init for anyone
# without those credentials, and 26 repositories dragged along to read one
# file. An index of working clones is a different thing from a pinned build
# input, and this is the former.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REGISTRY="$SCRIPT_DIR/repos.json"
BASE="${CLOUD_GIT_BASE:-$HOME/git}"

[ -f "$REGISTRY" ] || { echo "FATAL: $REGISTRY missing" >&2; exit 1; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node required to read $REGISTRY" >&2; exit 1; }

# Registry readers. node, not jq: node is already required by every build.sh
# in the fleet, jq is not guaranteed present.
_names() { node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));process.stdout.write(r.repos.map(x=>x.name).join(" "))' "$REGISTRY"; }
_field() { node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));const e=r.repos.find(x=>x.name===process.argv[2]);process.stdout.write(e?String(e[process.argv[3]]??""):"")' "$REGISTRY" "$1" "$2"; }
_groups() { node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));process.stdout.write([...new Set(r.repos.map(x=>x.group))].sort().join(" "))' "$REGISTRY"; }

link_one() {
    _n="$1"; _g=$(_field "$_n" group); _t="$BASE/$_n"
    [ -d "$_t" ] || return 1
    mkdir -p "$SCRIPT_DIR/$_g"
    # The group directory holds nothing but machine-local symlinks, so it
    # ignores itself. Written here rather than listed in .gitignore so that
    # adding a group to repos.json needs no second edit — and so a symlink
    # pointing at someone else's home directory can never be committed.
    [ -f "$SCRIPT_DIR/$_g/.gitignore" ] || printf '%s\n' '*' > "$SCRIPT_DIR/$_g/.gitignore"
    # -n so relinking an existing link replaces it instead of nesting inside it.
    ln -sfn "$_t" "$SCRIPT_DIR/$_g/$_n"
    return 0
}

clone_one() {
    _n="$1"; _u=$(_field "$_n" url); _t="$BASE/$_n"
    if [ -d "$_t/.git" ]; then
        printf "  = %-24s already cloned at %s\n" "$_n" "$_t"
    else
        printf "  + %-24s cloning -> %s\n" "$_n" "$_t"
        mkdir -p "$BASE"
        if ! git clone "$_u" "$_t"; then
            printf "  ! %-24s CLONE FAILED" "$_n"
            [ "$(_field "$_n" private)" = "true" ] && printf " (private — check your credentials)"
            printf "\n"
            return 1
        fi
    fi
    link_one "$_n" && printf "  > %-24s linked\n" "$_n"
}

do_list() {
    printf "base: %s   (override with \$CLOUD_GIT_BASE)\n\n" "$BASE"
    for g in $(_groups); do
        printf "%s/\n" "$g"
        for n in $(_names); do
            [ "$(_field "$n" group)" = "$g" ] || continue
            if [ -d "$BASE/$n/.git" ]; then
                [ -L "$SCRIPT_DIR/$g/$n" ] && s="cloned + linked" || s="cloned, NOT linked (run --link)"
            else
                s="not cloned"
                [ "$(_field "$n" private)" = "true" ] && s="$s (private)"
            fi
            printf "  %-24s %s\n" "$n" "$s"
        done
        printf "\n"
    done
    printf "clone with:  ./clone.sh <name>...  |  --group <g>  |  --all\n"
}

case "${1:-}" in
    ""|-l|--list) do_list ;;
    --link)
        for n in $(_names); do link_one "$n" && printf "  > %-24s linked\n" "$n"; done
        ;;
    --unlink)
        for n in $(_names); do
            g=$(_field "$n" group); [ -L "$SCRIPT_DIR/$g/$n" ] && { rm -f "$SCRIPT_DIR/$g/$n"; printf "  x %-24s unlinked\n" "$n"; }
            rmdir "$SCRIPT_DIR/$g" 2>/dev/null || true
        done
        ;;
    --all)
        fail=0
        for n in $(_names); do clone_one "$n" || fail=$((fail+1)); done
        [ "$fail" -eq 0 ] || { echo; echo "$fail repo(s) failed — see above."; exit 1; }
        ;;
    --group)
        g="${2:?usage: clone.sh --group <group>}"
        for n in $(_names); do [ "$(_field "$n" group)" = "$g" ] && clone_one "$n" || true; done
        ;;
    -h|--help)
        sed -n '2,12p' "$0" | sed 's/^# \?//'
        ;;
    *)
        for n in "$@"; do
            case " $(_names) " in
                *" $n "*) clone_one "$n" || true ;;
                *) echo "unknown repo: $n  (see ./clone.sh --list)" >&2; exit 1 ;;
            esac
        done
        ;;
esac
