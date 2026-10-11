# Local Windows release — 2026-10-11

Finalization changed documentation only. Application architecture, local data, website source and dependencies were preserved.

## Executed verification

- `flutter --version`: Flutter 3.47.1 / Dart 3.13.1.
- `flutter doctor -v`: no issues found; Windows desktop and Visual Studio build tools available.
- `flutter analyze`: no issues found.
- `flutter build windows --release`: succeeded.
- Required nonempty release files verified: executable, `flutter_windows.dll`, `file_selector_windows_plugin.dll`, `data/app.so`, `data/icudtl.dat`, asset/font manifests and bundled seed JSON.
- All 42 bundled seed media files and the seed JSON matched their project sources byte-for-byte. Release folder contains 56 files in total.
- Website `git status --short`: clean.

The earlier reliability phase's 81-test suite passed; it was not rerun during this documentation-only finalization. Native launch, visual inspection, file-picker interaction and installation on another PC were not performed in this phase. No synchronization or real analytics connection is claimed.

## Exact output

Release directory:

```text
C:\Users\Lenovo\StudioProjects\portfolio_admin_dashboard\build\windows\x64\runner\Release
```

Executable:

```text
C:\Users\Lenovo\StudioProjects\portfolio_admin_dashboard\build\windows\x64\runner\Release\portfolio_admin_dashboard.exe
```

Executable SHA-256 for this build:

```text
8d61b8859a462fc720895a7c84c29a39e821b9b8445b6bdbf5ff54c3c20e8a42
```

Keep the whole Release folder together; this checksum covers the runner executable, not the entire application bundle. Required Windows runtime prerequisites and development/build commands are in [README](../README.md). No installer, signing or automatic-update mechanism was added.

## Operational references

- [README](../README.md): prerequisites, running, building, storage and limits.
- [Backup/restore](DATA_TRANSFER.md): versioned format, media inclusion, confirmation and safety backups.
- [Firebase plan](FIREBASE_READINESS.md): proposed shared backend and safe migration; not implemented.
- [Analytics](ANALYTICS.md): future instrumentation and secure reporting requirements.
- [Reliability review](RELIABILITY_REVIEW.md): previous automated test coverage and remaining manual verification limits.

Icon update: replaced the default Flutter icon with an original portfolio/dashboard briefcase mark. Release rebuilt successfully; all nine icon resolutions verified in the executable. Source preview: `windows/runner/resources/app_icon.png`; regenerate with `powershell -NoProfile -File tool/generate_app_icon.ps1`.
