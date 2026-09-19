#!/usr/bin/env bash
set -euo pipefail

echo '[commit-gate] flutter analyze'
flutter analyze

echo '[commit-gate] flutter test'
flutter test

echo '[commit-gate] git diff --check'
git diff --check
git diff --cached --check

echo '[commit-gate] PASS'
