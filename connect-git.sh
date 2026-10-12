#!/bin/sh
# Run in the normal terminal to make the existing Git state discoverable
# by editors and to publish the prepared branch.
set -eu
workspace_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$workspace_dir"
if [ ! -e .git ]; then
  ln -s .git-state .git
fi
exec git push -u origin codex/mvp-state-2026-10-12
