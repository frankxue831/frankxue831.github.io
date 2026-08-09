#!/bin/zsh -df
setopt ERR_EXIT NO_CLOBBER PIPE_FAIL

[[ -o interactive ]] && exit 90
[[ -t 0 || -t 1 || -t 2 ]] && exit 91
[[ ! -e '<v21b-evidence-dir>' && ! -L '<v21b-evidence-dir>' ]] || exit 92
[[ ! -e '<v21b-retained-dir>' && ! -L '<v21b-retained-dir>' ]] || exit 93

umask 077

typeset -gr TRACK_D_INSTRUMENT_DIR=${0:A:h}
typeset -gr TRACK_D_PRECOMMIT_PATH=$TRACK_D_INSTRUMENT_DIR/precommit.json
typeset -gr TRACK_D_PRECOMMIT_EXPECTED='{"precommit_version":"track-d-v21b-precommit-v1","product_authority":false,"profile":"grok-build-1.0.0|grok-4.5|strict|dontAsk|read_file,search_replace|single-file|no-shell","q_fail":"retire_profile_until_2026-08-17T00:00:00+08:00","q_not_run":"consume_namespace_and_retire_lane_until_2026-08-17T00:00:00+08:00","q_pass":"eligible_for_one_separately_authorized_new_task_only","timezone":"Asia/Shanghai"}'

[[ -f $TRACK_D_PRECOMMIT_PATH && ! -L $TRACK_D_PRECOMMIT_PATH ]] || exit 94
typeset -gr TRACK_D_PRECOMMIT_ACTUAL=$(jq -S -c . "$TRACK_D_PRECOMMIT_PATH")
[[ $TRACK_D_PRECOMMIT_ACTUAL == $TRACK_D_PRECOMMIT_EXPECTED ]] || exit 95

typeset -g TRACK_D_TEST_ROOT=''
typeset -g TRACK_D_TEST_ROOT_VALIDATED=false

cleanup_test_root() {
  setopt LOCAL_OPTIONS NO_ERR_EXIT
  local recorded_root=$TRACK_D_TEST_ROOT current_root
  [[ $TRACK_D_TEST_ROOT_VALIDATED == true ]] || return 0
  [[ -n $recorded_root && $recorded_root != / && -d $recorded_root && ! -L $recorded_root ]] || return 0
  [[ ${recorded_root:t} == OFFLINE-track-d-v21b.* ]] || return 0
  current_root=$(/bin/realpath "$recorded_root" 2>/dev/null) || return 0
  [[ $current_root == $recorded_root ]] || return 0
  /bin/rm -rf -- "$recorded_root"
}

TRAPEXIT() {
  cleanup_test_root
}

typeset TRACK_D_TMP_PARENT=${TMPDIR:-/tmp}
TRACK_D_TMP_PARENT=${TRACK_D_TMP_PARENT%/}
TRACK_D_TEST_ROOT=$(/usr/bin/mktemp -d "$TRACK_D_TMP_PARENT/OFFLINE-track-d-v21b.XXXXXXXX")
TRACK_D_TEST_ROOT=$(/bin/realpath "$TRACK_D_TEST_ROOT")
[[ -d $TRACK_D_TEST_ROOT && ! -L $TRACK_D_TEST_ROOT ]] || exit 96
[[ ${TRACK_D_TEST_ROOT:t} == OFFLINE-track-d-v21b.* ]] || exit 96
TRACK_D_TEST_ROOT_VALIDATED=true

typeset -gr TRACK_D_CASE_ROOT=$TRACK_D_TEST_ROOT/transport-pass
/bin/mkdir -m 700 "$TRACK_D_CASE_ROOT"
typeset -gr TRACK_D_CASE_ROOT_REAL=$(/bin/realpath "$TRACK_D_CASE_ROOT")
[[ $TRACK_D_CASE_ROOT_REAL == "$TRACK_D_TEST_ROOT"/* ]] || exit 96

run_case() {
  local case_name=$1 expected=$2 mutation=$3
  print -u2 -r -- "runner_missing case=$case_name expected=$expected mutation=$mutation"
  return 97
}

assert_artifact() {
  local file_path=$1 predicate=$2
  [[ -f $file_path && ! -L $file_path ]] || return 1
  jq -e "$predicate" "$file_path" >/dev/null
}

run_case transport-pass Q-NOT-RUN_PREFLIGHT none
