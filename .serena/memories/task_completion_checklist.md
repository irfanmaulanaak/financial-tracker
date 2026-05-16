# Task completion checklist

Before finishing a code change, run relevant checks:

- `rtk flutter analyze`
- `rtk flutter test`
- For Firestore rules/transaction changes: `rtk firebase emulators:exec --only firestore --project demo-ft "cd emulator_tests && npm test"`
- For Dart changes: `rtk dart format lib test`
- Check `rtk git status --short` and do not revert unrelated user changes.

For review-only tasks, report findings first with file/line references, then tests run and any skipped verification.