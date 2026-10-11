# Local data layer (introduced in Phase 3, updated for media and content management)

## Storage choice and location

This portfolio has a small, ordered document with nested skill categories, career milestones and optional certificate links. Versioned JSON is sufficient; SQL and a runtime database package would add complexity without useful query requirements in this phase. The initial data phase added no runtime dependencies; the media phase adds image validation, hashing, and native selection packages.

Production location: `%LOCALAPPDATA%\PortfolioAdminDashboard` (normally `C:\Users\Lenovo\AppData\Local\PortfolioAdminDashboard`). No fallback to the website directory or working directory is allowed. LOCALAPPDATA must exist as an absolute Windows path.

- `initialized`: first-initialization marker, used to prevent accidental reseeding after interrupted initialization or missing data.
- `store.lock`: OS file lock used around reads, initialization and writes.
- `revision-000000000001.json`, subsequent numbered snapshots: schemaVersion, document revision and content.
- `media/assets/images/`, `media/assets/icons/`, `media/web/cv.pdf`: independent local copies of imported files.
- `media/uploads/`: imported images with SHA-256 filenames.
- `*.pending`: an incomplete write, if an operation was interrupted. Never treated as committed data.

Every successful mutation writes and flushes a complete new snapshot and then renames it in the same directory. Previous snapshots are retained. No in-place editing, silent fallback, automatic reset, or snapshot pruning occurs. JSON is ordinary local application data, not an encrypted database. Keep backups of the entire directory while the app is closed. Snapshot history is not a substitute for an external backup and will grow with writes; retention can be designed in a later phase.

## Architecture

- `lib/models/portfolio_models.dart`: immutable, typed records with explicit JSON codecs; no Flutter/file-system imports.
- `lib/models/portfolio_content.dart`: aggregate content and schema/reference validation.
- `lib/models/record_ids.dart`: secure random IDs for new records. Generate once and retain on edit. Imported IDs are frozen in the bundled seed and do not change with titles.
- `lib/repositories/portfolio_repository.dart`: backend-independent PortfolioRepository and RecordRepository interfaces and typed errors.
- `lib/repositories/local_portfolio_repository.dart`: local implementations; typed collections share the same store and validation boundary.
- `lib/data/json_portfolio_store.dart`: serialization, file locking, snapshot commits and safe initialization.
- `lib/data/open_local_portfolio.dart`: production composition and Flutter seed-asset loading.
- `lib/widgets/portfolio_bootstrap.dart`: uses the repository interface; provides loading, error details and Retry without a reset action.

The app initializes asynchronously and reads content through PortfolioRepository. Overview displays actual saved counts at startup. Projects, Media Library, Personal Information, Experience, Skills, Education, Certifications and Settings now provide repository-backed management. Analytics remains unconnected. No widget reads/writes files. A future Firebase implementation can replace openLocalPortfolio and implement the same repository contracts without changing domain/UI code; it must preserve ordering, revision checks and relationships. Firebase and website publishing are not implemented.

## Models and relationships

Each record has a stable string `id` and integer `revision`. List order is preserved.

- Project: title, description, ordered imagePaths, techStack, nullable liveUrl/githubUrl.
- Education: degree, institution, duration, location, isCurrent, nullable certificateUrl.
- Experience: role, company, duration, location, highlights, isCurrent, nested ExperienceMilestone records (title, duration, type, highlights).
- SkillCategory: title and ordered nested Skill records (label, assetPath, colorValue/ARGB and themeAdaptive).
- PersonalProfile: plain name, original formatted hero name/title, tagline, photo, CTA labels/targets, bio, labeled/icon personal details, email, phone, location, social links and orbit icons.
- MediaAsset: original sourcePath, safe local relative path, kind and label.
- SiteSettings: branding, app/browser titles, description, CV path/label/download filename, ordered navigation labels.
- SectionContent: existing section IDs, headings and subtitles.

Certificates remain optional links on Education; no fictitious standalone certification records are created. No analytics records are created. Nested skills/milestones are updated as part of their parent category/experience. Dates remain the website's original display strings. Profile and settings are required singletons. Referenced media cannot be deleted; source paths and local paths must be unique. Media bytes are accessed through repository.readMedia, not directly by widgets. New or relocated media metadata requires the corresponding local file to exist. repository.importImage validates bytes, writes local media, and commits metadata. Dimensions and byte size are derived from stored bytes; the schema stays compatible with existing snapshots.

## Repository operations

RecordRepository exposes `list`, `get`, `create`, `update`, and `delete`.

- create takes a record with revision 0 and returns revision 1; duplicate IDs are rejected.
- update takes the edited record and its expectedRevision; returns the next revision.
- delete requires expectedRevision and rejects missing/stale records.
- get returns null if the record is absent.
- All operations reload committed data under a shared in-process queue and an OS file lock. Another process holding the store produces a retryable busy error. Stale writes raise ConflictException rather than overwriting changes.
- Models and returned lists are immutable. To edit a model today, construct a new instance or use `Project.fromJson({...record.toJson(), 'title': 'Updated'})`, retaining id and revision.
- Invalid changes are rejected before commit. File errors are reported as StoreException; failed writes leave earlier commits intact. Nested records have stable identities; concurrency is enforced at their owning parent.

## Migration

`assets/seed/portfolio.json` contains the exact inspected content. On a genuinely empty store, initialization imports it once and copies the bundled media. Existing initialized stores never reload the seed, even if records were deleted or the bundle changes.

Imported: 8 projects; 5 education records; 3 experience records and 1 career milestone; 4 categories and 15 skills; personal/hero/about/contact content; social links; navigation/branding/CV metadata; section headings/subtitles; 22 images, 19 SVG icons and 1 PDF.

Website strings (including existing typos, duplicate project description, whitespace and hero code-format quotes), ordering, colors and asset paths were preserved. `MediaAsset.sourcePath` retains the website-relative reference; localPath points to the independent copy. No runtime dependency on the sibling website directory remains.

`tool/import_website.py` implements only the inspected Dart constant subset. It is a development-time import/verification tool, not a general Dart parser or a runtime sync mechanism. The frozen seed cannot be overwritten by rerunning it. Verify content and byte-for-byte media copies using:

```powershell
python tool/import_website.py ../portfolio_app --verify
```

No current project or personal content needs manual re-entry. Future website changes are not automatically imported; a later explicit merge/migration must preserve existing IDs and local edits. Presentation-only widget code, animation/layout/theme implementation and image precache lists were not migrated into editable data. Website publishing and Firebase schema mapping are deferred.

## Error handling and recovery

Malformed JSON, wrong types, unknown fields/schema versions, duplicate IDs, broken metadata references and incomplete snapshot history fail closed. Missing physical media files are reported in previews without blocking startup or unrelated edits. No missing file is automatically reseeded; an explicit re-import of identical imported bytes can restore that missing file. Unknown fields are rejected rather than discarded on the next save. Corrupted/newer data is never automatically replaced with the seed or an older snapshot.

The startup error identifies the issue and offers Retry. Close the app and preserve a copy of the entire store before any manual recovery. Restore a complete known-good backup (snapshots, initialized marker and media), then retry. After an interrupted first initialization with no user content, explicitly archive/rename the incomplete directory before intentionally starting a fresh import; the app never does this automatically. Do not hand-edit, delete or reorder committed snapshots. Manual deletion of the newest snapshot cannot be distinguished from an older complete history, so restore complete directories, not selected files. Future schema migrations must be explicit and backed up.

## Verification

- Dependency resolution, formatting and Flutter analysis passed.
- 17 Flutter tests passed, covering source round-trip, immutable records, CRUD, reopened repositories, stale edits/deletes, duplicate IDs, concurrent instances, reference integrity, corrupted/unknown schemas, missing data/media, interrupted initialization/writes, failed commits, startup Retry, and all existing navigation/responsive checks.
- `dart run tool/repository_process_check.dart` passed: create, read/update, read/delete and verify-deleted ran in four independent Dart processes against a temporary store. A separate process holding the OS lock correctly blocked access.
- The migration verifier confirmed all imported values and every media file against the website.
- Sample CRUD and corruption tests use temporary directories, never the user's application-data store.

## Native application verification

- Windows release build passed.
- First production launch created the store under the Windows LOCALAPPDATA directory with 8 projects, 5 education entries, 3 experience entries, the existing personal profile and 42 media records.
- SHA-256 comparisons confirmed all 42 locally copied media files match the bundled source files.
- Closed and restarted the native application. The committed snapshot hash was unchanged and no extra snapshot was created; no reseeding occurred. Windows confirmed a responding Portfolio Admin Dashboard window. The app was left open.
- The website remained unchanged (clean Git status). No sample/test records were written into the production store.

## Ordered collections

PortfolioRepository.reorderContent supports projects, education, experiences and skillCategories through a restricted OrderedCollection enum. It uses the original project reorder algorithm and store.change boundary: complete IDs and expected revisions are required, all reordered parent revisions advance, and a single snapshot commits the list. reorderProjects remains a compatibility entry point. Search/filter/view-sort state is session-only and never enters portfolio snapshots.
