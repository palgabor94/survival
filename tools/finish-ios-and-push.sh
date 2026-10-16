#!/bin/bash
# Run from the Mac's normal Terminal when this agent's network is restricted.
set -euo pipefail
survival_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

printf 'GitHub kapcsolat ellenorzese...\n'
if ! curl --silent --show-error --head --connect-timeout 10 --max-time 20 \
    https://github.com/ >/dev/null; then
  printf '\nA GitHub ebbol a Terminalbol sem erheto el. A pod install es push nem indult el.\n' >&2
  exit 1
fi

if ! command -v pod >/dev/null 2>&1; then
  printf 'A CocoaPods (pod) nincs a Terminal PATH-jaban.\n' >&2
  exit 1
fi

printf '\niOS fuggosegek telepitese...\n'
# Keep the workaround scoped to this process; do not alter system permissions.
CP_CACHE_DIR=/private/tmp/lost-canopy-cocoapods-cache \
  pod install --project-directory="$survival_root/survival_game/ios"

printf '\nTelepitett Firebase fuggosegek:\n'
python3 - "$survival_root/survival_game/ios/Podfile.lock" <<'PY'
from pathlib import Path
import sys
lock = Path(sys.argv[1]).read_text()
for line in lock.splitlines():
    if line.startswith('  - Firebase') or line.startswith('  - firebase_'):
        print(line.strip())
PY

survival_branch="$("$survival_root/git-workspace.sh" branch --show-current)"
if [ -z "$survival_branch" ]; then
  printf 'Detached HEAD: a push nem indult el.\n' >&2
  exit 1
fi
printf '\nCommitok pusholasa: %s\n' "$survival_branch"
"$survival_root/git-workspace.sh" push -u origin "$survival_branch"
printf '\nMunkakonyvtar allapota (az alabbi nem commitolt fajlok nincsenek pusholva):\n'
"$survival_root/git-workspace.sh" status --short
printf '\nKesz. Xcode-ban ezt nyisd meg: %s\n' "$survival_root/survival_game/ios/Runner.xcworkspace"
