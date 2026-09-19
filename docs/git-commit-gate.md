# Git Commit Gate

Every commit must pass two gates:

1. Peer review checks architecture, API contract, lifecycle, security, and test
   coverage. Critical and Important findings must be fixed or explicitly
   resolved before commit.
2. Automated gate runs `scripts/commit_gate.sh`:
   - `flutter analyze`
   - full `flutter test`
   - `git diff --check`

Enable repository hook once per checkout:

```bash
git config core.hooksPath .githooks
```

Manual run:

```bash
./scripts/commit_gate.sh
```

Hook only enforces automated checks. Peer-review evidence belongs in the task
handoff or review record.
