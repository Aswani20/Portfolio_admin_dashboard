# Image and media management

This phase extends the existing Dashboard only. The website, frozen seed, projects model, project revision checks and other navigation destinations remain intact. Firebase Storage and website publishing are not connected.

## Use

- Open Media Library and choose Import images. The Windows file dialog supports multiple PNG, JPEG and WebP files. Cancellation changes nothing. Invalid, unsupported, unreadable, oversized or missing selections report errors individually while valid selections can complete.
- Thumbnail cards show the saved filename, dimensions and byte size. Details offers a larger preview and the portable reference. Existing SVG icons and PDF documents remain listed with a type icon; this phase does not add SVG/PDF import or rendering.
- From a project's editor, Browse / import screenshots opens the same library with multiple selection. Choose thumbnail selects one image and moves it to the front, retaining other screenshots. The website has one ordered imagePaths list, so the first entry is the cover and the remaining order is the carousel order.
- Use the replace icon to change a reference in place. Choosing an image already in the gallery swaps those positions. Existing move and remove controls remain. Removing the first image promotes the next one; removing every image restores the project's no-image placeholder.
- Save project commits reference changes through the project repository with its existing optimistic revision check. Cancel does not save those reference changes. Imported files are committed immediately and remain in the library on Cancel; the picker explains this.

## Storage and architecture

- Production root: `%LOCALAPPDATA%\PortfolioAdminDashboard`.
- Imported bytes: `media/uploads/<sha256>.<detected extension>` within that root.
- Portable content reference: `assets/images/imported/<sha256>.<extension>`. It is an asset reference, not an absolute Windows path or a deployed public URL. A future publishing/storage adapter must map or upload it.
- `MediaAsset` remains separate metadata (stable ID/revision, sourcePath, relative localPath, kind and filename label). Existing snapshots need no migration. Transient ImageInfo derives format, dimensions and size from bytes rather than changing the schema.
- Widgets call PortfolioRepository.readMedia/importImage. Native file access is confined to services/image_selection.dart; the storage implementation owns all local directory access.
- Imports validate detected content and decode the first frame on a background isolate. Supported files are at most 20 MB and 40 megapixels. File extensions alone are not trusted. Bytes are preserved exactly, including any existing image metadata. Animated images are retained; validation/dimensions concern the first frame.
- Under the existing store lock, SHA-256 comparisons reuse identical bytes, including seeded images. Duplicate imports keep the existing filename/ID. Only one physical copy and record is created for identical bytes.
- Bytes are staged, flushed and renamed before a new metadata snapshot is committed. A failed metadata commit may leave an unreferenced physical file; retry reuses it. Partial pending files are never presented as committed media. No automatic physical-file deletion or cleanup is performed.
- Missing physical files no longer prevent startup or unrelated saves. Metadata/reference/schema corruption still fails closed. Missing/invalid previews show a fallback; restore the file from backup or select a replacement. Explicit re-import of identical bytes restores a missing imported file. An existing damaged hash-named file is preserved and reports an error, rather than being silently overwritten.
- No absolute selected source path is stored. External originals are not modified. Removing a reference or deleting a project never deletes a media file that another record could use.

## Verification

Tests use temporary stores and injected file selection, never the real application-data directory. The suite covers selection/cancellation/failure, image validation, deduplication, previews, missing and invalid files, dimensions, thumbnail selection/replacement, multiple screenshots, removal, preserved fields and persisted galleries. The process check imports an image and confirms its bytes/reference across independent Dart process launches and retains it after deleting the test project.

Native Windows file-dialog interaction requires a manual smoke check; automated selection tests inject XFile results at the selection boundary. 
Executed results (2026-10-11):
- Dependency resolution succeeded with the existing Flutter 3.47.1 / Dart 3.13.1 SDK.
- Formatting check: 32 Dart files, zero changes required.
- Flutter analysis: no issues found.
- Full Flutter suite: all 34 tests passed.
- Independent-process CRUD/order/media/thumbnail persistence and OS lock check: passed.
- Windows release build: passed, including file_selector_windows registration/linking.
- Native launch: Windows reported a responding Portfolio Admin Dashboard window with a nonzero window handle. This is a process/window smoke check, not visual inspection of the native picker.
- Existing production snapshot hashes remained unchanged during launch. No test content was inserted into production storage.
- Frozen migration verification: all 8 projects, profile, 5 education entries, 3 experiences, 15 skills and 42 media files matched the website; website Git status remained clean.

New source files: lib/models/image_import.dart, lib/services/image_selection.dart, lib/pages/media/media_library.dart. New tests: test/media_repository_test.dart and test/media_management_test.dart. Existing repository/store, project editor/list, shell, test fixtures, process check, dependencies, generated Windows plugin registration, README and architecture documentation were updated.

Dependency references: [Flutter file_selector](https://pub.dev/packages/file_selector) and [image decoder API](https://pub.dev/documentation/image/latest/image/decodeImage.html).

