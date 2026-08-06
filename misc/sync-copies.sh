#!/usr/bin/env bash
#
# sync-copies.sh — dual-copy divergence reconciliation for the EKS upgrade skill.
#
# THE TWO-COPY MODEL
# ------------------
# This repo ships the same skill twice, with two different runtime contracts:
#
#   Parent (Claude Code)  .claude/skills/eks-upgrade/
#       steering/*.md , data/oss_addon_registry.json , tools/md_to_html.py , SKILL.md
#   Port   (DevOps Agent) DevOpsAgent/
#       references/*.md , assets/oss_addon_registry.json , README.md , SKILL.md  (no tools/)
#
# The prose is shared, but the two copies diverge INTENTIONALLY on ~200 lines:
# directory names (steering/ vs references/), the tool-vs-no-tool story, the
# CLI-form vs API-form of the same call, and Claude-Code-vs-DevOps-Agent
# framing. SKILL.md and the two READMEs are deliberately different (different
# runtime contracts) and are NOT reconciled here.
#
# So this is NOT a copy/overwrite tool. It is a RECONCILIATION REPORTER. For
# every mapped file pair it diffs the two copies and buckets each differing
# line into:
#     EXPECTED  — matches a known-intentional divergence pattern
#                 (misc/sync-divergences.txt: the systematic path/framing axes), OR
#                 is recorded in the accepted baseline (misc/sync-baseline.txt:
#                 the remaining prose divergences frozen at a known-good commit).
#     DRIFT     — differs and matches NEITHER. That is the danger case: a
#                 content fix that landed in only ONE copy and must be mirrored
#                 into the other (or, if truly intentional, added to the baseline).
#
# Why a baseline as well as patterns: the two copies reword whole sentences, not
# just paths, so a line-level regex whitelist alone false-fires on legitimate
# rewording. The baseline freezes the current known-good divergence set so the
# gate stays quiet until something genuinely new appears.
#
# USAGE
#     misc/sync-copies.sh                 # human-readable report; always exits 0
#     misc/sync-copies.sh --check         # CI/pre-push gate; exit 1 on any DRIFT
#     misc/sync-copies.sh --update-baseline
#                                         # re-freeze the accepted divergence set
#                                         # (run only after confirming every
#                                         #  current divergence is intentional)
#
# Portable: POSIX diff/grep/sort/awk, bash 3.2-safe (no mapfile / assoc arrays /
# GNU-only flags). Whitelist patterns are extended regexes (ERE), one per line.
# NOTE: patterns are NOT anchored — they match anywhere in the differing line
# (substring/ERE), so a short unanchored token can excuse an arbitrary line whose
# real divergence is elsewhere. Keep divergence patterns as specific as possible.
# See CONTRIBUTING.md ("does not catch") for this blind spot.
#
# Hardening notes (what --check catches, and its limits — mirror CONTRIBUTING.md):
#   * The mapped .md file list is derived by GLOB of both steering/ and
#     references/, so a NEW file added to either copy is seen automatically.
#   * A mapped file present on only ONE side is a MISSING error and fails --check.
#   * Baseline entries are PER-FILE (label-scoped): a line accepted for one file
#     does NOT excuse the same text in another file.
#   * --check still cannot prove sync — matching deletions, baselined twins, and
#     unmapped files (SKILL.md, READMEs) are invisible. The dual-copy DIFF, not a
#     green --check, is the mirror-proof. See CONTRIBUTING.md.

set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(dirname "$SCRIPT_DIR")
WHITELIST="$SCRIPT_DIR/sync-divergences.txt"
BASELINE="$SCRIPT_DIR/sync-baseline.txt"

PARENT_MD_DIR=".claude/skills/eks-upgrade/steering"
PORT_MD_DIR="DevOpsAgent/references"
PARENT_REGISTRY=".claude/skills/eks-upgrade/data/oss_addon_registry.json"
PORT_REGISTRY="DevOpsAgent/assets/oss_addon_registry.json"

# The mapped .md files are DERIVED by glob of both copies (not hardcoded), so a
# new file added to either steering/ or references/ is picked up automatically
# and, if it exists on only one side, surfaces as a MISSING failure below. We
# take the UNION of basenames across both dirs, deduped and sorted.
MD_FILES=$(
  {
    for f in "$REPO_ROOT/$PARENT_MD_DIR"/*.md; do
      [ -e "$f" ] && basename "$f" .md
    done
    for f in "$REPO_ROOT/$PORT_MD_DIR"/*.md; do
      [ -e "$f" ] && basename "$f" .md
    done
  } 2>/dev/null | sort -u
)

MODE="report"
case "${1:-}" in
  --check)           MODE="check" ;;
  --update-baseline) MODE="update" ;;
  -h|--help)
    printf 'usage: %s [--check | --update-baseline]\n' "$(basename "$0")"
    printf '  (no args)          print a reconciliation report; always exits 0\n'
    printf '  --check            exit non-zero if any non-whitelisted DRIFT line is found\n'
    printf '  --update-baseline  re-freeze the accepted intentional-divergence set\n'
    exit 0
    ;;
  "") ;;
  *)
    printf 'error: unknown argument: %s (try --help)\n' "$1" >&2
    exit 2
    ;;
esac

# Scratch files. LABEL_BASE holds the current pair's baseline slice (per-file).
PATTERN_FILE=$(mktemp "${TMPDIR:-/tmp}/sync-wl.XXXXXX")
BASELINE_CLEAN=$(mktemp "${TMPDIR:-/tmp}/sync-bc.XXXXXX")
LABEL_BASE=$(mktemp "${TMPDIR:-/tmp}/sync-lb.XXXXXX")
NEW_BASELINE=$(mktemp "${TMPDIR:-/tmp}/sync-nb.XXXXXX")
trap 'rm -f "$PATTERN_FILE" "$BASELINE_CLEAN" "$LABEL_BASE" "$NEW_BASELINE"' EXIT

# Clean the pattern file down to real ERE patterns (drop comments/blank lines).
# Comments and blank lines are stripped here; the remaining ERE patterns are
# applied UNANCHORED (no leading '^' is inserted), so a pattern matches anywhere
# in a differing line and a bare substring pattern can excuse an arbitrary
# one-copy content edit that merely happens to contain the token. Author each
# divergence pattern as specifically as possible to limit this. See the
# "does not catch" list in CONTRIBUTING.md.
if [ -f "$WHITELIST" ]; then
  grep -E -v '^[[:space:]]*(#|$)' "$WHITELIST" > "$PATTERN_FILE" || true
fi
if [ ! -s "$PATTERN_FILE" ] && [ "$MODE" != "update" ]; then
  printf 'warning: no whitelist patterns loaded from %s\n' "$WHITELIST" >&2
fi

# The baseline is now PER-FILE: each accepted line is stored as
# "<label>\t<verbatim line>". Strip comments/blanks into a cleaned copy; the
# per-pair slice is extracted by label inside classify_pair so a line accepted
# for one file cannot excuse the same text appearing in a different file.
if [ -f "$BASELINE" ]; then
  grep -E -v '^[[:space:]]*(#|$)' "$BASELINE" > "$BASELINE_CLEAN" || true
fi

total_drift=0
total_expected=0
total_baseline=0
total_missing=0
pairs_diverged=0

# classify_pair <label> <fileA> <fileB>
classify_pair() {
  label="$1"; file_a="$2"; file_b="$3"

  # A mapped file present on only one side is DRIFT of the worst kind (a whole
  # file mirrored into one copy, or deleted from one copy). Count it so --check
  # fails; previously a missing file returned silently and passed.
  if [ ! -f "$file_a" ] || [ ! -f "$file_b" ]; then
    [ ! -f "$file_a" ] && printf '\n== %s\n  MISSING: %s\n' "$label" "$file_a" >&2
    [ ! -f "$file_b" ] && printf '\n== %s\n  MISSING: %s\n' "$label" "$file_b" >&2
    total_missing=$((total_missing + 1))
    return
  fi

  # Changed content lines from both sides, diff prefix stripped. Plain POSIX diff.
  changed=$(diff "$file_a" "$file_b" 2>/dev/null | grep -E '^[<>] ' | cut -c3-)
  [ -z "$changed" ] && return
  pairs_diverged=$((pairs_diverged + 1))

  # 1) split by pattern whitelist
  if [ -s "$PATTERN_FILE" ]; then
    expected_lines=$(printf '%s\n' "$changed" | grep -E -f "$PATTERN_FILE" || true)
    remainder=$(printf '%s\n' "$changed" | grep -E -v -f "$PATTERN_FILE" || true)
  else
    expected_lines=""; remainder="$changed"
  fi

  # 2) split the remainder by the accepted baseline — PER FILE. Extract only the
  #    baseline lines recorded for THIS label ("<label>\t<line>") so a line
  #    accepted for file A cannot excuse the same text in file B.
  : > "$LABEL_BASE"
  if [ -s "$BASELINE_CLEAN" ]; then
    # Match "<label><TAB>" prefix exactly, then strip it to recover the verbatim
    # line. awk keeps this bash-3.2/POSIX-safe (no GNU-only grep flags).
    awk -F '\t' -v L="$label" 'index($0, L "\t")==1 {
      sub(/^[^\t]*\t/, ""); print }' "$BASELINE_CLEAN" > "$LABEL_BASE"
  fi

  if [ -s "$LABEL_BASE" ]; then
    baselined_lines=$(printf '%s\n' "$remainder" | grep -F -x -f "$LABEL_BASE" || true)
    drift_lines=$(printf '%s\n' "$remainder" | grep -F -x -v -f "$LABEL_BASE" || true)
  else
    baselined_lines=""; drift_lines="$remainder"
  fi

  # In update mode, the "remainder" (everything not matched by a systematic
  # pattern) becomes the new frozen baseline, tagged with this file's label so
  # the freeze is per-file too.
  if [ "$MODE" = "update" ]; then
    printf '%s\n' "$remainder" | grep -v '^$' \
      | while IFS= read -r bl; do printf '%s\t%s\n' "$label" "$bl"; done \
      >> "$NEW_BASELINE"
  fi

  n_expected=0; n_baseline=0; n_drift=0
  [ -n "$expected_lines" ]  && n_expected=$(printf '%s\n' "$expected_lines"  | grep -c .)
  [ -n "$baselined_lines" ] && n_baseline=$(printf '%s\n' "$baselined_lines" | grep -c .)
  [ -n "$drift_lines" ]     && n_drift=$(printf '%s\n' "$drift_lines"     | grep -c .)

  total_expected=$((total_expected + n_expected))
  total_baseline=$((total_baseline + n_baseline))
  total_drift=$((total_drift + n_drift))

  printf '\n== %s\n' "$label"
  printf '   %s\n   %s\n' "$file_a" "$file_b"
  printf '   expected (pattern): %s | accepted (baseline): %s | DRIFT: %s\n' \
    "$n_expected" "$n_baseline" "$n_drift"

  if [ "$n_drift" -gt 0 ]; then
    printf '   --- these lines differ, match NO pattern, and are NOT in the baseline ---\n'
    printf '   --- is this a fix that landed in only one copy? mirror it, or re-baseline ---\n'
    printf '%s\n' "$drift_lines" | while IFS= read -r line; do
      [ -n "$line" ] && printf '   DRIFT | %s\n' "$line"
    done
  fi
}

printf 'Dual-copy reconciliation report (parent Claude Code  <->  DevOps Agent port)\n'
printf 'repo root: %s\n' "$REPO_ROOT"

for name in $MD_FILES; do
  classify_pair "$name.md" \
    "$REPO_ROOT/$PARENT_MD_DIR/$name.md" \
    "$REPO_ROOT/$PORT_MD_DIR/$name.md"
done
classify_pair "oss_addon_registry.json" \
  "$REPO_ROOT/$PARENT_REGISTRY" "$REPO_ROOT/$PORT_REGISTRY"

if [ "$MODE" = "update" ]; then
  if [ "$total_missing" -gt 0 ]; then
    printf '\nerror: %s mapped file(s) missing on one side; refusing to freeze a\n' "$total_missing" >&2
    printf '       baseline over an incomplete tree. Restore the file(s) first.\n' >&2
    exit 1
  fi
  # Freeze the accepted divergence set: each line is "<label>\t<verbatim line>",
  # unique, sorted, with a comment header.
  {
    printf '# sync-baseline.txt — accepted intentional divergences, frozen by\n'
    printf '# the sync-copies.sh --update-baseline mode. Each entry is\n'
    printf '# "<file-label><TAB><verbatim divergent line>": a per-file accepted\n'
    printf '# divergence NOT matched by a systematic pattern in sync-divergences.txt\n'
    printf '# but reviewed as intentional. The line is accepted ONLY for its own\n'
    printf '# file; the same text in another file is still flagged as DRIFT. A NEW\n'
    printf '# divergence not present here is flagged as DRIFT by --check.\n'
    printf '# DO NOT hand-edit; regenerate after a reviewed reconciliation.\n'
    sort -u "$NEW_BASELINE" | grep -v '^$'
  } > "$BASELINE"
  count=$(sort -u "$NEW_BASELINE" | grep -c .)
  printf '\n----------------------------------------------------------------\n'
  printf 'Baseline updated: %s accepted divergence line(s) written to %s\n' "$count" "$BASELINE"
  exit 0
fi

printf '\n----------------------------------------------------------------\n'
printf 'Summary: %s pairs diverge | %s pattern-expected | %s baseline-accepted | %s DRIFT | %s MISSING\n' \
  "$pairs_diverged" "$total_expected" "$total_baseline" "$total_drift" "$total_missing"

if [ "$MODE" = "check" ]; then
  if [ "$total_missing" -gt 0 ]; then
    printf 'RESULT: FAIL — %s mapped file(s) present on only one side. A file was\n' "$total_missing"
    printf '        added, moved, or deleted in only one copy. Mirror the change.\n'
    exit 1
  fi
  if [ "$total_drift" -gt 0 ]; then
    printf 'RESULT: FAIL — %s non-whitelisted divergence line(s). A content fix may have\n' "$total_drift"
    printf '        landed in only one copy. Mirror it into the other copy; or, if the\n'
    printf '        divergence is genuinely intentional, add a pattern to\n'
    printf '        misc/sync-divergences.txt or run --update-baseline after review.\n'
    exit 1
  fi
  printf 'RESULT: PASS — every divergence is pattern-whitelisted or baseline-accepted.\n'
  printf 'NOTE: PASS means no NEW drift on mapped lines; it is NOT proof of sync.\n'
  printf '      Confirm with a dual-copy diff (see CONTRIBUTING.md).\n'
  exit 0
fi

printf 'Run with --check to fail CI on non-whitelisted drift.\n'
exit 0
