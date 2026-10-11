# Reliability review — 2026-10-11

## Results

| Check actually executed | Result |
| --- | --- |
| `flutter pub get` | Passed. Five newer transitive package versions are outside current constraints; no dependency upgrade was attempted. |
| Dart format / final no-change check | Passed, 54 Dart files. |
| `flutter analyze` | No issues found. |
| Full `flutter test` | 81 passed, including 11 new regression/validation cases. |
| `tool/repository_process_check.dart` | Project CRUD/order, imported media/thumbnail references, deletion and cross-process lock checks passed across fresh processes. |
| `tool/content_process_check.dart` | Create/update/delete and final persisted content checks passed across fresh processes. |
| `tool/transfer_process_check.dart` | Import, restart verification, backup restore and restart verification passed with bundled media. |
| Website migration verifier | Seed matches 8 projects, profile, 5 education entries, 3 experiences, 15 skills and 42 media files. |
| Website `git status` / `git diff --stat` | Clean; no source changes. |
| `flutter build windows` | Passed; release executable built. |
| Hidden native process smoke check | Process remained alive and created its initial snapshot in isolated temporary LOCALAPPDATA. No interactive window handle was available; graceful window-close was unavailable, so the test process was terminated. This is startup/storage evidence, not a visual UI pass. |

## Bugs reproduced and fixed

1. After backup restoration remapped an imported image's local path, deleting that restored file and reimporting its original image returned success but left the record pointing at the missing file. The importer now commits the repaired local reference on the same media ID and preserves existing physical files. Regression verifies readable bytes, no duplicate metadata and persistence after reopening.
2. A revision-zero file could make the snapshot count appear complete despite a missing intermediate revision. The reader now rejects revision zero before checking continuity. Regression verifies fail-closed behavior and preservation of the latest snapshot.

Both regressions failed before their fixes and passed afterward. Nine further tests reject invalid required fields/URLs/email and invalid nested color/boolean values through the import/model validation path.

## Coverage and limits

The full suite exercises Projects CRUD; experience/milestones; skills/categories; education/certification links; profile/About/contact/social details; settings/navigation and section headings; cancellation, conflicts, failed saves and empty states. It also covers selected image bytes, unsupported/missing/duplicate files, previews and thumbnail/gallery references; transfer confirmation, invalid schemas/IDs/checksums, backup failure and restoration; search/filter/sort/reset/paging/order; repository-derived Overview counts; and disconnected/error/empty analytics with no fabricated visitor numbers. Tests use temporary data or injected repositories/pickers, not the user's real store.

No automated test or analysis failure remains. Native interactive visual inspection and actual Windows picker clicks were not performed. Startup recovery of an already-corrupt store still requires preserving/recovering the store outside the in-app restore screen, as documented in DATA_TRANSFER.md. Analytics remains intentionally disconnected. No Firebase integration or architecture rewrite was added.

Executable: `build/windows/x64/runner/Release/portfolio_admin_dashboard.exe`. Keep the complete Release directory together when running/distributing it.
