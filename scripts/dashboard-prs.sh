#!/usr/bin/env bash
# Open pull requests of the current repo as a compact table for the snacks
# dashboard ("Pull Requests / Issues" section). One GraphQL call via `gh`,
# formatted with jq. Columns:
#
#   #      title              author   cmts unres  CI
#
#   cmts  - all comments (conversation + review-thread comments)
#   unres - unresolved review threads
#   CI    - rollup of the last commit's checks. On failure the row shows
#           "✗ N" and the failed check names follow on indented lines (parent
#           rollups like "atlantis/plan" are dropped when a child
#           "atlantis/plan: x" failed too; at most MAXFAIL names per PR).
#
# Sorted: my PRs first, then by last update. Draft PRs get a "draft:" prefix.
#
# Width is dynamic: by default it is read from the pty the script runs in
# (snacks gives the terminal section a pty of `width - indent` columns), the
# title column stretches to fill it and every line is cut to that width, so
# the terminal buffer never wraps a row. Pass a number as WIDTH to override.
#
# Usage: dashboard-prs.sh [limit] [width|auto] [maxfail]
set -o pipefail

LIMIT="${1:-6}"
WIDTH="${2:-auto}"
MAXFAIL="${3:-2}"

if [ "$WIDTH" = "auto" ]; then
  # stty asks the pty itself; tput would trust an inherited $COLUMNS first
  WIDTH="$(stty size 2>/dev/null | cut -d' ' -f2)"
  [ -n "$WIDTH" ] || WIDTH="$(tput cols 2>/dev/null)"
  case "$WIDTH" in ''|*[!0-9]*|0) WIDTH=58 ;; esac
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "  jq: not installed (brew install jq)"
  exit 0
fi

QUERY='
query($owner: String!, $name: String!, $limit: Int!) {
  viewer { login }
  repository(owner: $owner, name: $name) {
    pullRequests(states: OPEN, first: $limit, orderBy: {field: UPDATED_AT, direction: DESC}) {
      nodes {
        number title isDraft updatedAt
        author { login }
        comments { totalCount }
        reviewThreads(first: 100) { nodes { isResolved comments { totalCount } } }
        commits(last: 1) { nodes { commit { statusCheckRollup { state
          contexts(first: 100) { nodes { __typename
            ... on CheckRun { name conclusion status }
            ... on StatusContext { context state } } } } } } }
      }
    }
  }
}'

if ! OUT="$(gh api graphql -F owner='{owner}' -F name='{repo}' -F limit="$LIMIT" -f query="$QUERY" 2>/dev/null)"; then
  echo "  gh: unavailable (not a GitHub repo / not logged in / offline)"
  exit 0
fi

jq -r --argjson width "$WIDTH" --argjson maxfail "$MAXFAIL" '
  def rpad(n): .[:n] | (n - length) as $k | if $k > 0 then . + (" " * $k) else . end;
  def lpad(n): tostring | (n - length) as $k | if $k > 0 then (" " * $k) + . else . end;
  def trunc(n): if length > n then .[:n-1] + "…" else . end;
  def red:   "\u001b[31m" + . + "\u001b[0m";
  def green: "\u001b[32m" + . + "\u001b[0m";
  def yellow:"\u001b[33m" + . + "\u001b[0m";
  def dim:   "\u001b[2m"  + . + "\u001b[0m";
  def bold:  "\u001b[1m"  + . + "\u001b[0m";

  # fixed columns: "#NNNN " + " author " + " cmts" + " unres" + "  " + CI (9: "● running")
  ([$width - 37, 8] | max) as $tw
  | .data.viewer.login as $me
  | (.data.repository.pullRequests.nodes // []) as $prs
  | if ($prs | length) == 0 then "  none" else
    ( ("#" | rpad(5)) + " " + ("title" | rpad($tw)) + " " + ("author" | rpad(8))
      + " " + ("cmts" | lpad(4)) + " " + ("unres" | lpad(5)) + "  CI" | trunc($width) | dim ),
    ( $prs
      | sort_by(.author.login != $me)
      | .[]
      | .author.login as $author
      | (.commits.nodes[0].commit.statusCheckRollup) as $roll
      | ([ $roll.contexts.nodes[]?
           | select((.conclusion // .state) | IN("FAILURE","ERROR","TIMED_OUT","CANCELLED","ACTION_REQUIRED","STARTUP_FAILURE"))
           | (.name // .context) ]) as $failed
      | ($failed | map(. as $n | select(any($failed[]; . != $n and startswith($n + ":")) | not))) as $leaf
      | (if $roll == null then ("–" | dim)
         elif ($leaf | length) > 0 then (("✗ " + ($leaf | length | tostring)) | red)
         elif $roll.state == "SUCCESS" then ("✓" | green)
         elif $roll.state | IN("PENDING","EXPECTED") then ("● running" | yellow)
         else (("? " + $roll.state) | trunc(9) | yellow) end) as $ci
      | ([.reviewThreads.nodes[] | select(.isResolved | not)] | length) as $unres
      | (.comments.totalCount + ([.reviewThreads.nodes[].comments.totalCount] | add // 0)) as $cmts
      | ((if .isDraft then "draft: " else "" end) + .title) as $title
      | ("#" + (.number | tostring) | rpad(5)) + " "
        + ($title | trunc($tw) | rpad($tw)) + " "
        + ((if $author == $me then ("me" | bold) + "      " else ($author | trunc(8) | rpad(8)) end)) + " "
        + ($cmts | lpad(4)) + " "
        + ((if $unres > 0 then ($unres | lpad(5) | red) else ($unres | lpad(5)) end)) + "  "
        + $ci,
        # failed checks, one per line under the row
        ( $leaf[:$maxfail][] | ("        ✗ " + .) | trunc($width) | red ),
        ( if ($leaf | length) > $maxfail
          then ("        … +" + (($leaf | length) - $maxfail | tostring) + " more") | dim
          else empty end )
    )
  end
' <<<"$OUT"
