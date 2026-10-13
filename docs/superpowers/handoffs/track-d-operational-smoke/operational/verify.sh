#!/bin/zsh
set -euo pipefail

usage() {
  print -r -- 'Usage: verify.sh TARGET_REPO'
  print -r -- 'Verifies the exact gm-crypto-rs-demo Track-D operational-smoke candidate diff.'
}

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  usage
  exit 0
fi

if (( $# != 1 )); then
  usage >&2
  exit 64
fi

typeset -r repo=$1
typeset -r expected_head=53d7a4d27ebb396b541f9c12a439667a7db45569
typeset -r expected_branch=main
typeset -r expected_origin=https://github.com/frankxue831/gm-crypto-rs-demo.git
typeset -r expected_target_sha=1d9e28262855f4c2eec3bdae4605d9f7cf8cc52e1e0bd16bd981e1d08ef7c335
typeset -r expected_description='Downstream crates.io smoke-test demo for the gmcrypto-core SM2/SM3/SM4 crate'

[[ -d $repo && ! -L $repo ]] || {
  print -u2 -r -- "not a regular repository directory: $repo"
  exit 65
}

cd "$repo"

[[ -f Cargo.toml && ! -L Cargo.toml ]]
[[ $(git rev-parse HEAD) == $expected_head ]]
[[ $(git branch --show-current) == $expected_branch ]]
[[ $(git remote get-url origin) == $expected_origin ]]
[[ $(git status --porcelain=v1 --untracked-files=all) == ' M Cargo.toml' ]]
[[ $(git diff --name-only) == Cargo.toml ]]
[[ $(git diff --numstat) == $'1\t1\tCargo.toml' ]]
[[ $(shasum -a 256 Cargo.toml | awk '{print $1}') == $expected_target_sha ]]

rg -Fxq 'description = "Downstream crates.io smoke-test demo for the gmcrypto-core SM2/SM3/SM4 crate"' Cargo.toml
! rg -Fq 'description = "Downstream crates.io smoke-test demo for the gmcrypto-core SM2/SM3 crate"' Cargo.toml
git diff --check
cargo fmt --check
cargo test --locked --offline
cargo metadata --locked --offline --no-deps --format-version 1 |
  jq -e --arg description "$expected_description" \
    '.packages | length == 1 and .[0].name == "gm-crypto-rs-demo" and .[0].description == $description' >/dev/null

[[ $(git status --porcelain=v1 --untracked-files=all) == ' M Cargo.toml' ]]
print -r -- 'TRACK_D_OPERATIONAL_SMOKE_VERIFIER_PASS'
