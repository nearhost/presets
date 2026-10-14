#!/usr/bin/env bash
# Publishes index.yaml through a pull request, as release-please does for
# releases. CI runs this on main after `make index`. When the index changed,
# it pushes the new index to the index-rebuild branch and opens a pull request,
# or updates the one already open. When main's index is already current, it
# closes any index pull request still open. Merging that pull request is what
# publishes: clients read the index from main.
#
# Environment:
#   GITHUB_SHA         the commit this run's check passed
#   GITHUB_REPOSITORY  owner/name
#   GH_TOKEN           a token that may push branches and open pull requests;
#                      it must not be GITHUB_TOKEN, whose pull requests start
#                      no checks
set -euo pipefail

branch=index-rebuild
title='chore: rebuild the index'

# Only the commit this run checked may be indexed. When main has moved on, the
# run for the newer commit takes over once its own check passes.
if [ "$(git rev-parse HEAD)" != "$GITHUB_SHA" ]; then
  echo "main has moved past $GITHUB_SHA; the run for the newer commit takes over."
  exit 0
fi

open=$(gh pr list --repo "$GITHUB_REPOSITORY" --head "$branch" --state open --json number --jq '.[0].number // empty')

if git ls-files --error-unmatch index.yaml >/dev/null 2>&1 && git diff --quiet -- index.yaml; then
  echo "index.yaml on main is current."
  if [ -n "$open" ]; then
    gh pr close "$open" --repo "$GITHUB_REPOSITORY" --delete-branch \
      --comment "index.yaml on main is current again, so this is no longer needed."
  fi
  exit 0
fi

ref=$(git log -1 --format=%H -- presets)
git switch -q -C "$branch"
git add index.yaml
git -c user.name='nearhost-ci[bot]' -c user.email='342397698+nearhost-ci[bot]@users.noreply.github.com' \
  commit -q -m "$title"
git push -q --force "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$branch"

body="Rebuilds \`index.yaml\` for the presets at ${ref}.

Merging this publishes them: clients read the index from \`main\`. Until then they keep getting the presets the current index names, which still match it. Another preset change merged before this one updates this pull request."
if [ -z "$open" ]; then
  gh pr create --repo "$GITHUB_REPOSITORY" --base main --head "$branch" --title "$title" --body "$body"
else
  gh pr edit "$open" --repo "$GITHUB_REPOSITORY" --body "$body"
fi
