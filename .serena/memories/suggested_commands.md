# Suggested commands

Prefix shell commands with rtk in this environment.

- Explore files: `rtk rg --files lib test emulator_tests/rules claude-design`
- Search code: `rtk rg -n "pattern" lib test emulator_tests/rules`
- Static analysis: `rtk flutter analyze`
- Unit tests: `rtk flutter test`
- Firestore emulator tests: `rtk firebase emulators:exec --only firestore --project demo-ft "cd emulator_tests && npm test"`
- Format Dart: `rtk dart format lib test`
- Git status: `rtk git status --short`

If the Firestore emulator cannot bind localhost ports inside the sandbox, rerun the same emulator command with escalation.