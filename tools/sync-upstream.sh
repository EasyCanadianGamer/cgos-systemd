#!/usr/bin/env bash
# sync-upstream.sh — Fetch upstream systemd and rebase fork patches on top.
#
# Usage:
#   ./tools/sync-upstream.sh [--dry-run]
#
# First-run setup (done automatically on first invocation):
#   - Adds the 'upstream' remote pointing to systemd/systemd
#   - Enables git rerere so conflict resolutions are remembered

set -euo pipefail

UPSTREAM_URL="https://github.com/systemd/systemd.git"
UPSTREAM_REMOTE="upstream"
UPSTREAM_BRANCH="main"
DRY_RUN=false

# ── helpers ────────────────────────────────────────────────────────────────────

log()  { printf '\e[1;34m=>\e[0m %s\n' "$*"; }
ok()   { printf '\e[1;32m✓\e[0m  %s\n' "$*"; }
warn() { printf '\e[1;33m!\e[0m  %s\n' "$*"; }
die()  { printf '\e[1;31mERROR:\e[0m %s\n' "$*" >&2; exit 1; }

# ── argument parsing ───────────────────────────────────────────────────────────

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            sed -n '2,7p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) die "Unknown argument: $arg" ;;
    esac
done

# ── preflight checks ───────────────────────────────────────────────────────────

cd "$(git rev-parse --show-toplevel)"

[[ -d .git ]] || die "Not inside a git repository."

if [[ -n "$(git status --porcelain)" ]]; then
    die "Working tree is dirty. Commit or stash your changes before syncing."
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# ── one-time setup ─────────────────────────────────────────────────────────────

if ! git remote get-url "$UPSTREAM_REMOTE" &>/dev/null; then
    log "Adding remote '$UPSTREAM_REMOTE' → $UPSTREAM_URL"
    $DRY_RUN || git remote add "$UPSTREAM_REMOTE" "$UPSTREAM_URL"
fi

if [[ "$(git config --get rerere.enabled 2>/dev/null || true)" != "true" ]]; then
    log "Enabling git rerere (conflict resolution memory)"
    $DRY_RUN || git config rerere.enabled true
fi

# ── fetch ──────────────────────────────────────────────────────────────────────

log "Fetching $UPSTREAM_REMOTE/$UPSTREAM_BRANCH …"
$DRY_RUN || git fetch "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"

UPSTREAM_REF="$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
COMMITS_BEHIND="$(git rev-list --count HEAD.."$UPSTREAM_REF")"
FORK_COMMITS="$(git rev-list --count "$UPSTREAM_REF"..HEAD)"

if [[ "$COMMITS_BEHIND" -eq 0 ]]; then
    ok "Already up to date with $UPSTREAM_REF."
    exit 0
fi

log "Upstream has $COMMITS_BEHIND new commit(s). Fork has $FORK_COMMITS commit(s) on top."

if $DRY_RUN; then
    warn "Dry-run mode — no changes will be made."
    log "Would run: git rebase $UPSTREAM_REF"
    exit 0
fi

# ── rebase ─────────────────────────────────────────────────────────────────────

log "Rebasing '$CURRENT_BRANCH' onto $UPSTREAM_REF …"

if ! git rebase "$UPSTREAM_REF"; then
    cat <<'EOF'

  Rebase paused due to conflicts.

  Resolve each conflict, then continue with:
    git add <file>
    git rebase --continue

  To abort and return to the previous state:
    git rebase --abort

  Rerere is enabled — once you resolve a conflict, future rebases against
  the same upstream change will be resolved automatically.

EOF
    exit 1
fi

ok "Rebase complete. '$CURRENT_BRANCH' is now based on $UPSTREAM_REF."

# ── summary ────────────────────────────────────────────────────────────────────

NEW_FORK_COMMITS="$(git rev-list --count "$UPSTREAM_REF"..HEAD)"
log "Fork patches still applied: $NEW_FORK_COMMITS commit(s)"
git log --oneline "$UPSTREAM_REF"..HEAD | sed 's/^/    /'
