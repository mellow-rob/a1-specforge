#!/usr/bin/env bash
# Test-Mode für a1-pr-review CLI-Subcommands.
# Verwendet einen Dummy-Registry via A1_WORKTREE_REGISTRY und einen
# temporären Worktree-Pfad. Mutiert nichts Echtes.

set -euo pipefail

CLI="node $(cd "$(dirname "${BASH_SOURCE[0]}")/../../_shared" && pwd)/a1-tools.cjs"
FIXTURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REGISTRY="$TMP/registry.json"
WT="$TMP/worktrees/demo-feature"
mkdir -p "$WT/.a1-review"

cat > "$REGISTRY" <<JSON
{
  "version": 1,
  "worktrees": [
    {
      "id": "20260513-1200-demo-feature",
      "slug": "demo-feature",
      "repo_root": "/fake/repo",
      "worktree_path": "$WT",
      "branch": "feature/demo-feature",
      "base": "main",
      "created_at": "2026-05-13T12:00:00Z",
      "status": "handoff",
      "phase_history": [
        { "at": "2026-05-13T11:55:00Z", "from": "active", "to": "handoff", "by": "a1-worktree" }
      ]
    },
    {
      "id": "20260513-1300-other",
      "slug": "other",
      "repo_root": "/fake/repo",
      "worktree_path": "/nonexistent",
      "branch": "feature/other",
      "created_at": "2026-05-13T13:00:00Z",
      "status": "active",
      "phase_history": []
    }
  ]
}
JSON

export A1_WORKTREE_REGISTRY="$REGISTRY"

pass() { echo "  PASS — $1"; }
fail() { echo "  FAIL — $1"; exit 1; }

echo "== Test 1: list-handoff returns one entry"
out="$($CLI pr list-handoff)"
count="$(echo "$out" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const o=JSON.parse(d);process.stdout.write(String(o.count));})')"
[ "$count" = "1" ] && pass "count=1" || fail "expected count=1, got $count"

echo "== Test 2: findings-summary fails without findings.json"
if $CLI pr findings-summary demo-feature 2>/dev/null; then
  fail "should have errored on missing findings.json"
else
  pass "errored as expected"
fi

echo "== Test 3: findings-summary with findings.json"
cat > "$WT/.a1-review/findings.json" <<JSON
{
  "summary": "Looks fine overall.",
  "blocker": [],
  "major": [
    { "file": "src/auth.ts", "line": 42, "title": "Missing tenant check", "detail": "Function bypasses tenantId filter." }
  ],
  "minor": [
    { "file": "src/util.ts", "line": 10, "title": "Unused import" }
  ]
}
JSON
out="$($CLI pr findings-summary demo-feature)"
echo "$out" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const o=JSON.parse(d);if(o.counts.major!==1)process.exit(1);if(o.counts.minor!==1)process.exit(1);if(!o.major_md.includes("Missing tenant check"))process.exit(1);if(!o.inline_minor_md.includes("Unused import"))process.exit(1);})' && pass "counts + markdown ok" || fail "summary mismatch"

echo "== Test 4: mark-status transitions"
$CLI pr mark-status demo-feature in-review > /dev/null
$CLI pr mark-status demo-feature reviewed > /dev/null
status="$(node -e 'const r=JSON.parse(require("fs").readFileSync(process.env.A1_WORKTREE_REGISTRY,"utf8"));process.stdout.write(r.worktrees[0].status)')"
[ "$status" = "reviewed" ] && pass "status=reviewed" || fail "expected reviewed, got $status"

echo "== Test 5: invalid status is rejected"
if $CLI pr mark-status demo-feature bogus 2>/dev/null; then
  fail "should have rejected invalid status"
else
  pass "rejected invalid status"
fi

echo "== Test 6: mark-pr-open requires valid URL"
if $CLI pr mark-pr-open demo-feature "not-a-url" 2>/dev/null; then
  fail "should have rejected bad URL"
else
  pass "rejected bad URL"
fi

echo "== Test 7: mark-pr-open success"
$CLI pr mark-pr-open demo-feature "https://github.com/foo/bar/pull/42" > /dev/null
pr_url="$(node -e 'const r=JSON.parse(require("fs").readFileSync(process.env.A1_WORKTREE_REGISTRY,"utf8"));process.stdout.write(r.worktrees[0].pr_url||"")')"
[ "$pr_url" = "https://github.com/foo/bar/pull/42" ] && pass "pr_url stored" || fail "pr_url mismatch: $pr_url"

echo "== Test 8: unknown slug fails clean"
if $CLI pr findings-summary nonexistent-slug 2>/dev/null; then
  fail "should have failed on unknown slug"
else
  pass "unknown slug rejected"
fi

echo ""
echo "All tests passed."
