# Local import, export, backup and restore

Open **Settings → Import, export and backups**.

- **Export JSON** saves managed content, media metadata and portable references, without physical media bytes.
- **Create backup** saves the same content plus every available referenced media file (images, icons and documents). Missing files are omitted and the saved-result message reports the embedded-file count.
- **Import / Restore** opens either kind of file, validates it, and previews record/media counts. Cancel changes nothing. **Back up and replace** replaces all collections, including removing records absent from the file. There is deliberately no implicit merge or duplicate-ID conflict resolution.
- Save with a new filename. Existing export/backup files are never overwritten by these controls.

## JSON format, version 1

The exact top-level keys are:

```json
{
  "format": "portfolio-admin-transfer",
  "schemaVersion": 1,
  "content": {},
  "mediaFiles": {}
}
```

This example shows the envelope only; an empty `content` object is not valid. `content` must contain all eight collections: `projects`, `education`, `experiences`, `skillCategories`, `profiles`, `media`, `settings`, `sectionContent`. Their fields are the existing model `toJson` format in `lib/models/portfolio_models.dart`. Export a file from the app for a complete editable example. Exactly one profile and settings record are required. Certifications remain education entries with certificate links. Array order is display order. Nested records remain inside their parent record.

Each record retains its stable ID and a positive revision in the transfer file. Imported top-level revision tokens are renewed for local concurrency protection; IDs and content relationships are retained. Unknown fields, unknown schema versions, invalid field types/required values/URLs, duplicate IDs within a collection or nested list, unsafe relative media paths, and references to nonexistent media metadata are rejected before applying changes. Duplicate-ID errors identify the collection path and ID. IDs can occur in distinct collection scopes as the existing models permit.

`mediaFiles` is keyed by a media record ID. Each value has exactly `sha256` (hex digest of decoded bytes) and `base64` (file bytes). For example its shape is `"media-id": {"sha256": "...", "base64": "..."}`. Every payload must have metadata and a matching checksum. Checksums detect corruption, not authenticity. Empty `mediaFiles` is a content-only export. A backup may be incomplete if source files were already missing: metadata is retained and no bytes are fabricated.

Maximum UTF-8 JSON size is 256 MB, including base64 overhead. Backups that exceed this bound fail; automatic replacement is aborted if its safety backup cannot be created. No schema migration is silently guessed. A future schema must add an explicit migration and validation path before being accepted. Transfer JSON is distinct from the internal `revision-*.json` snapshot envelope, which is not accepted as an import.

Exports contain only the allowlisted portfolio model fields and, for backups, referenced media bytes. They do not export environment variables, credentials, provider tokens, application configuration, unrelated filesystem files, or historical snapshots. The public profile/contact content remains part of the portfolio export. There are no analytics/Firebase secrets in this data model.

## Replacement and safety backups

The preview fingerprints the current repository snapshot. Replacement obtains the existing process/OS store lock and checks that fingerprint again. A concurrent edit invalidates the preview and requires another review; it is not silently overwritten.

Before writing replacement content, the store writes a complete transfer backup of current content and available media under `%LOCALAPPDATA%\PortfolioAdminDashboard\backups\backup-<unique-id>.json`. The success message gives the exact path. If backup creation fails, content is not replaced. Use Import / Restore and select this file to undo a replacement. Restoring it creates another automatic backup first.

Replacement publishes one new append-only snapshot using the existing same-directory pending-file rename. Prior snapshots remain untouched. Media is written before publishing the snapshot. If replacement fails before publication, the previous snapshot remains authoritative; a safety backup and unreferenced new files may remain. No automatic cleanup deletes physical files or older backups.

Embedded media is restored into unique relative paths under `media/restored/`. Imported destination paths are never used to overwrite existing files. The source asset reference, record ID, label and kind are preserved; the local storage path is implementation-specific and remapped. Public references never become absolute Windows filesystem paths.

For content-only imports, existing media is reused only when its ID and source reference match. Otherwise a unique unavailable local path is assigned; the existing missing-media UI handles previews gracefully. An import with metadata alone cannot recover missing physical files. Use a backup with embedded bytes to transfer the entire portfolio to another initialized Dashboard installation.

The in-app replacement flow requires a readable initialized store. It does not bypass the existing fail-closed startup recovery rules for a corrupted or incomplete snapshot history; preserve that directory and recover the store before using in-app restore. This phase does not add a startup recovery wizard.

## Verification commands

```powershell
flutter analyze
flutter test
dart run tool/transfer_process_check.dart
```

Repository tests cover export round trips, replacement and automatic-backup restoration, duplicate IDs (including nested records), malformed JSON, incompatible schemas, forbidden fields, invalid paths/references, media checksum failure, stale confirmation, backup-write failure, missing media and reopening storage. Widget tests cover validation before confirmation, cancellation, confirmed replacement, parent notification and export/backup media policies. The process check imports, verifies after a process restart, restores the automatic backup, and verifies again in another process using real bundled media in temporary storage. It does not change the production store.
