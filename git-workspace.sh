#!/bin/sh
# Git metadata lives in .git-state because this environment protects .git.
set -eu
workspace_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec git --git-dir="$workspace_dir/.git-state" --work-tree="$workspace_dir" "$@"
