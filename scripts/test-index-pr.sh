#!/usr/bin/env bash
# Tests scripts/index-pr.sh against a local bare repository standing in for
# GitHub, with a fake gh that records what it was asked to do.
# Assertions are single-quoted for eval, and the cases are called by name in
# the loop at the end.
# shellcheck disable=SC2016,SC2329
set -euo pipefail

script="$(cd "$(dirname "$0")" && pwd)/index-pr.sh"
failed=0

# setup builds a checkout of main whose origin is a bare repository, and a fake
# gh that answers `pr list` with $FAKE_OPEN_PR and logs every call.
setup() {
  work=$(mktemp -d)
  git init -q --bare "$work/remote.git"
  git init -q -b main "$work/repo"
  cd "$work/repo"
  git config user.email t@t
  git config user.name t
  mkdir presets
  echo "a: 1" > presets/a.yaml
  echo "old index" > index.yaml
  git add -A
  git commit -q -m one
  git push -q "$work/remote.git" main
  git config url."$work/remote.git".insteadOf "https://x-access-token:secret@github.com/acme/presets.git"
  mkdir "$work/bin"
  cat > "$work/bin/gh" <<'EOF'
#!/usr/bin/env bash
echo "gh $*" >> "$GH_LOG"
if [ "$1 $2" = "pr list" ]; then echo "$FAKE_OPEN_PR"; fi
EOF
  chmod +x "$work/bin/gh"
  export PATH="$work/bin:$PATH" GH_LOG="$work/gh.log" GH_TOKEN=secret GITHUB_REPOSITORY=acme/presets
  export GITHUB_SHA
  GITHUB_SHA=$(git rev-parse HEAD)
  : > "$GH_LOG"
}

# run runs the script and keeps its output in $out.
run() {
  out=$(FAKE_OPEN_PR="$1" bash "$script" 2>&1) || { echo "index-pr.sh failed: $out"; return 1; }
}

expect() {
  if ! eval "$2"; then
    echo "FAIL  $1"
    echo "      output: $out"
    echo "      gh calls: $(tr '\n' ';' < "$GH_LOG")"
    failed=1
  fi
}

case_new_index_opens_a_pr() {
  setup
  echo "new index" > index.yaml
  run ""
  expect "a changed index is pushed to the index branch" \
    '[ "$(git --git-dir="$work/remote.git" show index-rebuild:index.yaml)" = "new index" ]'
  expect "main is never pushed to" \
    '[ "$(git --git-dir="$work/remote.git" show main:index.yaml)" = "old index" ]'
  expect "the branch commit is the app's" \
    '[ "$(git --git-dir="$work/remote.git" log -1 --format=%an index-rebuild)" = "nearhost-ci[bot]" ]'
  expect "a pull request is opened" 'grep -q "^gh pr create .*--head index-rebuild" "$GH_LOG"'
}

case_open_pr_is_updated() {
  setup
  echo "new index" > index.yaml
  run "7"
  expect "the index branch is updated" \
    '[ "$(git --git-dir="$work/remote.git" show index-rebuild:index.yaml)" = "new index" ]'
  expect "no second pull request is opened" '! grep -q "^gh pr create" "$GH_LOG"'
  expect "the open pull request is edited" 'grep -q "^gh pr edit 7 " "$GH_LOG"'
}

case_current_index_closes_a_stale_pr() {
  setup
  run "7"
  expect "nothing is pushed" '! git --git-dir="$work/remote.git" rev-parse -q --verify index-rebuild >/dev/null'
  expect "the stale pull request is closed" 'grep -q "^gh pr close 7 .*--delete-branch" "$GH_LOG"'
}

case_moved_main_stands_down() {
  setup
  echo "new index" > index.yaml
  git commit -q --allow-empty -m "two, merged after this run started"
  run ""
  expect "nothing is pushed" '! git --git-dir="$work/remote.git" rev-parse -q --verify index-rebuild >/dev/null'
  expect "gh is not called" '[ ! -s "$GH_LOG" ]'
}

for c in case_new_index_opens_a_pr case_open_pr_is_updated case_current_index_closes_a_stale_pr case_moved_main_stands_down; do
  # Each case runs in its own subshell and directory; its failures come back
  # as the subshell's exit status.
  if ( $c; exit $failed ); then echo "ok    ${c#case_}"; else failed=1; fi
done
exit $failed
