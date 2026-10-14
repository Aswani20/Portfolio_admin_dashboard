# Portfolio Admin Dashboard

Local Windows desktop application for writing articles and managing projects, media, personal information/About, contact/social links, experience/milestones, skills, education/certification links, and website settings/headings. Includes search, filtering, display ordering, repository-derived Overview counts and JSON backup/restore.

**The Dashboard does not synchronize with or publish to the website.** The website continues to use its existing static Dart source. Website Analytics displays “Analytics are not connected yet”; no real visitor statistics are collected or retrieved. Firebase is not configured or implemented.

## Prerequisites

For development/building:

- Windows with an x64 desktop build environment. This release was built on Windows 11 x64.
- Flutter **3.47.1**, including Dart **3.13.1**, was used and verified. The project requires Dart `^3.13.1`; reuse this Flutter SDK where practical.
- Visual Studio with **Desktop development with C++**, its MSVC tools, CMake tools and Windows SDK. Visual Studio Code alone does not provide the native compiler. Verified locally: Visual Studio Community 2026 18.10.3 and Windows SDK 10.0.26100.0.
- Flutter's `bin` directory on PATH. On this machine it is `C:\development\flutter\bin`; commands can also use the full `.bat` paths.
- Network access for initial dependency downloads. Normal local content management requires no Firebase account or network service.

Run `flutter doctor -v`; resolve Windows/Visual Studio errors before building. If the Windows target is disabled, run `flutter config --enable-windows-desktop`. Android setup is not required for this Windows application.

For running a built release: keep the entire Release folder together on an x64 Windows PC. Flutter and Visual Studio are not needed to run it. The compatible Microsoft Visual C++ x64 runtime must be installed; see [Microsoft's supported redistributable guidance](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170). Cross-machine installation has not been tested in this phase.

## Development run

```powershell
cd C:\Users\Lenovo\StudioProjects\portfolio_admin_dashboard
flutter pub get
flutter run -d windows
```

The first launch copies bundled portfolio content/media into the current Windows user's application-data directory. Later launches open saved content without reseeding. Development and release launches under the same Windows account use the **same local store**. Startup errors show details and Retry; the app never automatically resets data.

## Build and run the release

Close running copies of the Dashboard before rebuilding files they may have loaded.

```powershell
cd C:\Users\Lenovo\StudioProjects\portfolio_admin_dashboard
flutter pub get
flutter analyze
flutter build windows --release
.\build\windows\x64\runner\Release\portfolio_admin_dashboard.exe
```

Exact executable on this machine:

```text
C:\Users\Lenovo\StudioProjects\portfolio_admin_dashboard\build\windows\x64\runner\Release\portfolio_admin_dashboard.exe
```

Copy/distribute the **complete** `build\windows\x64\runner\Release` directory, including the executable, DLLs and `data` directory. Do not move only the `.exe`. The bundle is not an installer or an automatic updater. Replacing a build does not migrate or delete the per-user data directory.

## Local data and media

The store is `%LOCALAPPDATA%\PortfolioAdminDashboard`, normally:

```text
C:\Users\Lenovo\AppData\Local\PortfolioAdminDashboard
```

| Location inside the store | Purpose |
| --- | --- |
| `initialized` | First-run marker; prevents accidental reseeding. |
| `revision-000000000001.json`, subsequent revisions | Complete append-only content snapshots. Keep the full history. |
| `store.lock` | Cross-process storage locking. |
| `media\` | Seeded images/icons/CV and other media. |
| `media\uploads\` | Imported image files. |
| `media\restored\` | Files restored from JSON backups. |
| `backups\backup-<unique-id>.json` | Automatic safety backups before replacement. |

The executable directory is not the live data store. Do not manually prune snapshot history or edit media paths. Older snapshots, unreferenced media and backups are retained; disk usage can grow. See [storage details and recovery](docs/LOCAL_DATA.md).

## Back up and restore

In **Settings → Import, export and backups**:

1. **Create backup** saves JSON content plus available referenced media bytes. Choose a new filename outside the data store and keep a copy on another device. The result reports how many files were embedded; already-missing files cannot be backed up.
2. **Export JSON** saves content, media metadata and references only. It is not a complete physical-media backup.
3. **Import / Restore** accepts either supported JSON format, validates it, and previews counts. **Back up and replace** replaces all content collections after confirmation; there is no implicit merge. An automatic backup is saved first, and a concurrent edit invalidates the preview.
4. To undo a replacement, import the automatic backup path shown in the success message. Existing physical files are preserved. IDs/relationships/order are kept, while local revisions and restored media paths are renewed.

A metadata-only import reuses matching existing files when possible; otherwise previews remain unavailable. Supported transfer schemas are versions 1 and 2 with a 256 MB JSON limit. Unknown schemas, duplicate records, invalid references and bad media checksums are rejected. See [complete transfer format and behavior](docs/DATA_TRANSFER.md).

For a filesystem backup, close **all** Dashboard instances and copy the entire application-data folder. To recover that copy, keep the current folder separately and restore the complete backup folder at the original location while the app is closed; do not combine revision histories. The in-app restore screen requires a readable store. An incomplete/corrupt store has no startup recovery wizard: preserve it and use a complete known-good folder backup or seek repair before retrying. Never delete the store as a routine troubleshooting step.

## Current limitations and future backend

- Local single-user content management only; no website synchronization, publishing, multi-device sync, Firebase login or cloud storage.
- Analytics is an interface with loading/error/empty/unavailable states. Real reports need website instrumentation plus an authenticated reporting backend; Dashboard launches are not visits. See [analytics requirements](docs/ANALYTICS.md).
- Certifications are certificate links on education entries. Project categories/featured flags are not part of the website's current model. Image imports support PNG, JPEG and WebP; bundled SVG/PDF records are retained. Imported files remain even if an edit is cancelled.
- The Firebase plan covers repository adapters, Firestore collections/fields, private drafts/public releases, Storage media references, authorization, secure analytics reporting and a staged migration preserving local edits and static assets. It is a design, not an implemented integration: [Firebase readiness](docs/FIREBASE_READINESS.md).
- Native visual/file-picker testing and cross-machine release installation are not claimed by the automated checks. See [reliability review](docs/RELIABILITY_REVIEW.md) and [final release verification](docs/LOCAL_RELEASE.md).

## Automated verification

```powershell
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
dart run tool/repository_process_check.dart
dart run tool/content_process_check.dart
dart run tool/transfer_process_check.dart
```

The process checks use temporary storage and never modify the real local store. With Python installed, `python tool/import_website.py ../portfolio_app --verify` compares the frozen seed with the sibling website without changing either source.

## Source and further documentation

`lib/main.dart` composes interfaces with the local implementation; `models`, `repositories`, `data`, `services`, `pages` and `widgets` separate content, persistence and UI. `assets/seed` contains the frozen initial content/media; `windows` contains the native runner; `test` and `tool` contain verification code. No Firebase dependencies are installed.

See [content management](docs/CONTENT_MANAGEMENT.md), [Projects](docs/PROJECTS_MANAGEMENT.md), [media](docs/MEDIA_MANAGEMENT.md), [list browsing/order](docs/LIST_BROWSING.md), [website analysis](docs/CONTENT_ANALYSIS.md), and [file inventory](docs/CREATED_FILES.md). Historical verification documents describe their respective earlier phases.

## Articles

Use **Articles** to write/edit local drafts and mark articles for **Copy website JSON**. Manually paste that export into the website static asset and rebuild; no synchronization is performed. Empty static article data hides the website section and navigation link. See [article publishing and migration](docs/ARTICLES.md).
