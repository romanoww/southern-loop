#!/usr/bin/env bash
#
# setup-repo.sh — create the GitHub repo, push the planner, enable Pages.
#
# Run this from the folder containing trip_planner.html, picks.json and README.md.
# Safe to re-run: it skips anything already done.
#
#   chmod +x setup-repo.sh
#   ./setup-repo.sh
#
set -euo pipefail

# ----------------------------------------------------------------- settings
REPO_NAME="${REPO_NAME:-southern-loop}"
VISIBILITY="${VISIBILITY:-private}"     # private | public   (see note at the end)
BRANCH="${BRANCH:-main}"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# ----------------------------------------------------------------- checks
command -v git >/dev/null || die "git is not installed."
command -v gh  >/dev/null || die "GitHub CLI not found. Install it: https://cli.github.com"

gh auth status >/dev/null 2>&1 || {
  say "Not logged in to GitHub. Starting login…"
  gh auth login
}
OWNER="$(gh api user --jq .login)"
say "Authenticated as $OWNER"

[[ -f trip_planner.html ]] || die "trip_planner.html not found. Run this from the folder containing it."

# ----------------------------------------------------------------- assemble
say "Preparing files"
# GitHub Pages serves index.html at the site root
cp -f trip_planner.html index.html

# picks.json must exist so the app's first fetch succeeds rather than 404-ing
if [[ ! -f picks.json ]]; then
  printf '{\n  "updated": 0,\n  "picks": {}\n}\n' > picks.json
  say "Created an empty picks.json"
fi

[[ -f README.md ]] || warn "README.md missing — continuing without it."
[[ -f CLAUDE.md ]] || warn "CLAUDE.md missing — continuing without it."

# Stops Jekyll from trying to build the site (it would ignore files starting with _)
touch .nojekyll

cat > .gitignore <<'EOF'
.DS_Store
trip_planner.html
EOF

# ----------------------------------------------------------------- git init
if [[ ! -d .git ]]; then
  say "Initialising git repository"
  git init -q
  git symbolic-ref HEAD "refs/heads/$BRANCH"
else
  say "Existing git repository detected — reusing it"
fi

git add index.html picks.json .nojekyll .gitignore README.md CLAUDE.md 2>/dev/null || \
  git add index.html picks.json .nojekyll .gitignore

if git diff --cached --quiet 2>/dev/null && git rev-parse HEAD >/dev/null 2>&1; then
  say "No changes to commit"
else
  git -c user.name="${GIT_NAME:-$OWNER}" \
      -c user.email="${GIT_EMAIL:-$OWNER@users.noreply.github.com}" \
      commit -q -m "Southern Loop trip planner" || true
  say "Committed"
fi

# ----------------------------------------------------------------- remote
if gh repo view "$OWNER/$REPO_NAME" >/dev/null 2>&1; then
  say "Repo $OWNER/$REPO_NAME already exists — pushing to it"
  git remote get-url origin >/dev/null 2>&1 || \
    git remote add origin "https://github.com/$OWNER/$REPO_NAME.git"
else
  say "Creating $VISIBILITY repo $OWNER/$REPO_NAME"
  gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin
fi

say "Pushing to $BRANCH"
git push -u origin "$BRANCH" --force-with-lease

# ----------------------------------------------------------------- pages
say "Enabling GitHub Pages"
if gh api "repos/$OWNER/$REPO_NAME/pages" >/dev/null 2>&1; then
  say "Pages already enabled"
else
  gh api -X POST "repos/$OWNER/$REPO_NAME/pages" \
    -f "source[branch]=$BRANCH" -f "source[path]=/" >/dev/null 2>&1 \
    && say "Pages enabled" \
    || warn "Could not enable Pages via API. Turn it on manually: Settings → Pages → branch $BRANCH, folder /(root)."
fi

URL="https://$OWNER.github.io/$REPO_NAME/"

cat <<EOF

────────────────────────────────────────────────────────────
  Repo : https://github.com/$OWNER/$REPO_NAME
  Site : $URL   (first build takes ~1 minute)

  Next — enable one-tap saving from the app:

   1. Create a fine-grained token:
        https://github.com/settings/personal-access-tokens/new
        · Repository access : Only select repositories → $REPO_NAME
        · Permissions       : Contents → Read and write
        · Everything else   : No access
        · Expiration        : past the end of the trip (Aug 2027)

   2. Open $URL → Bookings tab → "Set up GitHub"
        Owner  : $OWNER
        Repo   : $REPO_NAME
        Branch : $BRANCH
        Token  : the github_pat_… string

  To update the planner later, drop in the new file and re-run this script.
────────────────────────────────────────────────────────────
EOF

if [[ "$VISIBILITY" == "public" ]]; then
  warn "This repo is PUBLIC, so picks.json is public too. Fine for campsite names —"
  warn "keep booking references and personal details out of it."
else
  warn "This repo is PRIVATE. GitHub Pages on a private repo needs a paid plan."
  warn "If the site 404s, either make it public (VISIBILITY=public ./setup-repo.sh)"
  warn "or open index.html directly from disk — everything except sync still works."
fi
