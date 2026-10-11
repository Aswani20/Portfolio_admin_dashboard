# Search, filters, sorting and display order

This phase extends existing screens and controls without changing their CRUD forms, data schema, JSON storage or dependencies. No Firebase, analytics collection or website runtime changes were added.

## Available controls

| Screen | Search | Filter | View sorting |
| --- | --- | --- | --- |
| Projects | Project title | Existing technology tags, normalized for case/outer spaces | Saved order, title A-Z / Z-A |
| Experience | Role, company, location, duration, highlights and milestone titles | Current / not current | Saved order, title A-Z / Z-A, company A-Z, current first |
| Skills | Category title or technology name | Existing category ID | Saved order, category title A-Z / Z-A |
| Education | Qualification, institution, duration and location | Current / not current | Saved order, title A-Z / Z-A, institution A-Z, current first |
| Certifications | Education title, institution, duration and location | With / without a certificate link | Saved order, title A-Z / Z-A, institution A-Z, current first |
| Media Library | Filename or portable reference | Images, icons, documents | Library order, filename A-Z / Z-A |
| Image picker | Filename or portable reference | Images only, as before | Library order, filename A-Z / Z-A |

Search is case-insensitive and ignores surrounding query whitespace. Search and filter combine. Skills results are whole matching categories, retaining their technology context. Sort ties retain saved order. No featured or project-category filters are invented because those fields do not exist. Timeline dates remain free-form website display strings; no unreliable chronological parsing was added. Personal information and settings remain singleton editing screens rather than unnecessary searchable lists.

Reset filters clears the query, filter, view sort and page. Clearing only the search preserves the other controls. Empty collections keep their original guidance; zero matches show a separate message suggesting a different search or reset. A removed category/tag remains an explicitly unavailable filter selection until reset, rather than silently broadening the results.

## Saved order versus view sorting

Projects retain their existing display-order controls. Experience, education and skill categories now have earlier/later arrows too. Certifications shares education order; reorder the owning records in Education. Existing nested list ordering in the content editor and screenshot ordering in the project editor are unchanged. Fixed navigation/section identities remain fixed.

Alphabetical/current-first sorting changes only the view and writes nothing. Saving display order is allowed only in the unfiltered Saved order view. Page boundaries do not limit moves: moving a record to a neighboring page saves its position in the complete collection, then shows that page.

The repository's existing project ordering operation now delegates to the same operation used for a restricted enum of ordered collections. It retains the original complete-ID/per-record-revision checks and one atomic store change. A stale, duplicate or incomplete ordering request is rejected; no partial reorder or overwrite occurs. Nested record data and unrelated collections remain unchanged. No storage implementation or CRUD method was replaced.

## Session state and larger lists

The shell owns a small in-memory browse state per destination. Query, filter, sort and page survive navigation, refresh and CRUD operations in that Dashboard session. Education and Certifications have independent browsing preferences. Image picker state is private to each dialog and does not overwrite the Media Library page state; selected images stay selected while searching or changing pages. Application restart resets browsing preferences; persisted portfolio content and saved display order remain intact.

Content/project lists render at most 20 top-level cards per page. Media renders at most 50 tiles, so larger libraries do not read/decode every thumbnail at once. Previous/Next controls appear only when needed and show result/page counts. Search/filter/sort changes start at page one; deletion and refresh clamp a page that no longer exists. Loading placeholders do not erase a remembered page.

This deliberately keeps the existing JSON aggregate repository: records are filtered/sorted in memory, while UI rendering and media reads are bounded. It is not server-side paging and does not change local persistence architecture. No paging was added to the small singleton or fixed section-heading forms.

## Verification

- Flutter analysis: no issues found.
- Browsing widget tests cover combined search/filters, positive and empty certificate results, category removal, sort/reset, navigation/refresh retention, independent section state, compact 600 x 480 layout, reorder errors, media picker selection, project/content page boundaries and page clamping after deletion.
- Unit tests verify stable sort ties, case/whitespace behavior, source order preservation and page slicing.
- Repository tests verify education, experience and category reorder persistence, unchanged nested/unrelated values, and rejection of stale/partial/duplicate requests.
- Independent-process checks passed for new collection ordering, existing project ordering/CRUD/media and file locking. Tests use temporary stores, never production content.
- A 142-record media test verified exactly 50 thumbnail reads on the first page, 50 more on the next page, and one read for a targeted search result.
- Full Flutter regression suite: **57 tests passed**. Formatting check: 43 Dart files, zero changes required. Frozen website import verification passed and website Git status remained clean.
- Native Windows build/launch was not rerun for this UI-only browsing phase.

New files: lib/models/list_browse_state.dart, lib/widgets/list_controls.dart, test/list_browse_state_test.dart, test/list_browsing_test.dart, and this document. Existing list pages, shell, repository ordering method, test fixture, ordering tests, process check and documentation were updated.
