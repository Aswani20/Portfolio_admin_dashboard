# Projects management (Phase 4)

The existing local Project model and JSON schema are retained. Website fields are title, one description, ordered imagePaths, ordered techStack, nullable githubUrl and liveUrl. The website has no project categories, featured flag, separate full/short description or explicit order property, so none was invented. Collection order drives display order.

## Features

- Responsive project list with cover image, description preview, screenshot/technology counts and current position.
- Add, view complete details, edit, and delete after a named confirmation. Deletion retains media files.
- Case-insensitive, whitespace-trimmed title search; clear search restores all records.
- Up/down controls save display order atomically. Ordering is disabled while searching to avoid ambiguity about hidden records. New projects append to the list.
- The editor supports title, description, one technology per line, optional HTTP/HTTPS links, and screenshot selection from the existing local media library. Gallery images can be reordered or removed; the first is the cover.
- Screenshots and technology lists may be empty, consistent with the website's image fallback and optional tags. Title and description must be nonblank. Entered URLs must be full HTTP/HTTPS URLs without credentials or whitespace. Both form and repository validate saves.
- Existing ID, untouched strings, optional links, technologies and gallery order are preserved when editing. No silent trimming/reformatting of untouched imported content occurs.
- Loading, empty and no-search-match states; Refresh/retry; save/delete/order success messages and clear errors.
- Failed saves keep form entries. Stale edits/deletes/reorders are rejected by revision checks. Cancel and navigation out of an editor do not save changes.
- Overview refreshes its saved counts after Projects reloads/mutations, including when the user switches pages during an in-flight delete. Existing sidebar destinations and shortcuts remain functional.

## Persistence and scope

All content operations and image reads use PortfolioRepository/RecordRepository. No widget accesses local files. Startup retains the repository and passes it into the shell. The repository's reorderProjects method requires the entire ID list plus the revisions last read, then commits the complete new order in one snapshot and advances record revisions to detect concurrent ordering changes. No storage migration or new dependency was required.

Edits are local only. The website is not rewritten or published. Image upload/import and other management sections remain out of scope; screenshot selection uses the media imported in Phase 3. Links in the details dialog are selectable for copying; the app does not launch external sites.

## Verification

- Formatting and Flutter analysis passed with no issues.
- 25 tests passed, including all earlier navigation/storage checks plus creating, viewing, editing, searching, deleting (cancel and confirm), required/URL validation, failed-save recovery, gallery ordering, persisted project ordering, stale conflicts, loading errors, empty states, compact forms and refreshed Overview counts.
- The disk repository test reopens the store to verify ordering persists and rejects stale/partial reorder requests without losing content.
- The independent-process tool passed create, read/update, read/delete and deleted-record checks across four process launches; it also verified display ordering across restart and OS file locking.
- Test data is confined to temporary stores or in-memory UI fixtures. No sample records are written to the production store.


Windows release build passed and the updated app was launched. Windows confirmed a responding Portfolio Admin Dashboard window. Existing production snapshot hashes and count remained unchanged during launch. Native startup was checked through process properties; project interactions were verified by widget/repository tests. The app is left open for review.
