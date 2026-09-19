#!/usr/bin/env bash
set -euo pipefail

# Git hooks export worktree-specific variables. Flutter also invokes Git to
# resolve its SDK version, so those variables would make it inspect this app.
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE

echo '[commit-gate] flutter analyze'
flutter analyze

echo '[commit-gate] flutter test'
flutter test

echo '[commit-gate] git diff --check'
git diff --check
git diff --cached --check

echo '[commit-gate] PASS'
