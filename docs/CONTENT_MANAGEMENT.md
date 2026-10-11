# Portfolio content management

This phase adds management for the remaining content that actually exists in the website. Existing Projects and Media Library implementations are reused without rebuilding them. Website runtime files and the frozen seed are unchanged. No new dependencies, Firebase, analytics data, publishing, or schema migration were added.

## Screens and relationships

- **Personal Information:** one profile editor for plain name, formatted hero name/title, tagline, profile photo, biography, contact email/phone/location, About detail rows, social links, CTA labels/section targets, and ordered hero orbit icons. About detail values and Contact values are separate fields in the original website; the editor explains this and does not silently synchronize them. Photo selection reuses the existing library/import dialog. Icons reference existing SVG media.
- **Experience:** list/add/edit/confirmed delete for roles, company, display duration, location, current status, ordered highlights and nested milestones. Each milestone keeps its title, duration, type and own ordered highlights.
- **Skills:** list/add/edit/confirmed delete for categories, with nested technology add/edit/remove, label, icon, ARGB color and theme-adaptive flag. Nested list order is editable.
- **Education:** list/add/edit/confirmed delete for degree/course, institution, duration, location, current-study flag and optional certificate URL.
- **Certifications:** a view over the same education records. Add/edit a certificate link or remove only that link after confirmation. No separate or fabricated certification records are introduced. When there are no education records, add one in Education first.
- **Settings:** singleton editor for branding, application/browser titles, description, CV document reference/label/download filename and navigation labels. Existing navigation IDs and order are fixed because they identify actual website sections. The current media library supports image import; this phase selects existing CV documents and SVG icons rather than adding new upload formats.
- **Section headings:** edit existing About, Skills, Projects, Education, Experience and Contact headings/subtitles under Settings. IDs remain fixed; adding nonexistent website sections or deleting fixed section definitions is intentionally unavailable.

The profile and settings singletons cannot be created/deleted through the UI. All applicable collection records support CRUD. Nested removals require confirmation and apply only when the parent form is saved. Cancel discards form edits; separately imported media stays in the library as before. Collection edits preserve existing display order and new records append. Nested ordered lists support move earlier/later.

## Architecture and preservation

`content_forms.dart` describes form fields only. `content_editor.dart` implements the shared form, nested lists, validation, media references, pending save/error state and confirmation controls. `content_management_page.dart` composes the section-specific pages and calls existing typed repository methods. It does not read or write files.

`ContentValidation` validates required values, email, HTTP(S) URLs, known CTA targets and ARGB colors at the local repository boundary. Existing aggregate validation continues to protect media references, IDs, singleton counts and nested relationships. Loading the original records does not normalize or rewrite legacy content.

Every edited model starts with all original fields; only form values are replaced. Text is not trimmed or reformatted on save: tabs/quotes in hero strings, trailing spaces, display dates, CV filename formatting, paragraph breaks and multiline highlights retain their values. Individual highlights use separate multiline controls, so editing another field cannot split one highlight into multiple records. Existing IDs persist. Changed nested rows receive the next revision; unchanged rows retain theirs. Parent revision checks protect the entire nested edit from stale writes. Failed saves leave all form entries available.

Read failures have Retry via Refresh; empty collections have explicit guidance; successful saves/deletes and operation failures appear in messages. Overview counts refresh from the repository after mutations. There is no duplicate persistence implementation, and no physical media file is deleted by these screens.

## Verification

- Full Flutter suite: **44 tests passed**, including existing Projects, Media Library, startup, repository and responsive navigation tests.
- Six new widget flows cover experience/milestones/highlights, skills/categories, profile/About/contact/social links, education/certificates, settings/navigation/headings, validation, cancellation, load/save errors, stale edits and a 600 x 480 form.
- Four new repository tests cover real local CRUD, nested-field preservation, certificates, singleton updates, restart reads, reference validation and failed mutation safety.
- `dart run tool/content_process_check.dart` passed create, update, delete and final verification in four independent Dart processes. Temporary stores only; no sample content was written to production data.
- Frozen website migration verification passed for all imported content and 42 media files.
- Formatting completed successfully (39 Dart files). Final Flutter analysis: no issues found. The six content-form tests also passed again after making validation/save errors visible beside the form actions.
- Native Windows build/launch was not rerun in this phase; verification here uses Flutter widget tests and actual local repository/process tests.

New files: `lib/models/content_validation.dart`; `lib/pages/content/content_forms.dart`, `content_editor.dart`, `content_management_page.dart`; `test/content_management_test.dart`, `content_repository_test.dart`; `tool/content_process_check.dart`; this document. Existing local repository validation, shell routing, Overview status text, test fixture and documentation were updated.

Subsequent browsing phase: [search, filters and saved display ordering](LIST_BROWSING.md) adds top-level ordering for experience, education and skill categories; existing nested editing remains unchanged.
