# Articles — static publishing workflow

The Dashboard and website remain disconnected. Dashboard saves only affect local data. No Firebase, runtime API, folder watcher or automatic publishing is used.

## Write and publish manually

1. Open **Articles → Add article** in the Dashboard. Enter title, short summary, article text and a valid `YYYY-MM-DD` date. Text is plain text with preserved line breaks, not HTML/Markdown. Use **Read article** for a full-text preview.
2. Save as a draft, or enable **Include in website export**. This flag only controls export; the displayed date does not schedule publication. Edit/delete use the existing local repositories and revision checks.
3. Use search, status filter and title/date sorting to browse. Reset filters and select Saved order to move entries with arrows. That order is retained in the exported list and breaks ties when dates are equal. The website sorts by publication date, newest first.
4. Select **Copy website JSON**. It copies a complete schema-1 public article document to the clipboard, including only marked articles, excluding drafts and local revision tokens.
5. Manually replace the contents of `C:\Users\Lenovo\StudioProjects\portfolio_app\assets\content\articles.json` with that JSON. Keep a backup or version-control commit of the previous file. Copy JSON only, without Markdown code fences.
6. In the website folder run `flutter build web --release` and deploy the rebuilt `build/web` through your normal hosting workflow. For local preview use `flutter run -d chrome`. Editing the Dashboard alone never changes the website.

The website initially contains `{"schemaVersion":1,"articles":[]}`. An empty list hides both the Articles section and navigation link. The homepage shows up to three newest published articles. See more opens a page with all articles, newest first, and Read article opens the existing full-text reading page. See more is available whenever there is at least one article. Deleting/unpublishing all Dashboard articles only hides the website after copying the new empty export and rebuilding. Malformed or missing static data is logged and hides the section without breaking other sections.

## Data safety

Local snapshot and full portfolio transfer schema **2** add `articles` as a ninth collection. Older schema-1 stores/backups are accepted with an empty list. Reading an old store does not overwrite snapshots; the next mutation appends schema 2. Existing content and media remain intact. Older Dashboard binaries cannot read newly written schema-2 snapshots, so retain a backup before downgrading.

Article records have `id`, `revision`, `title`, `summary`, `body`, `publishedOn`, `isPublished`. Saved array order breaks ties between equal publication dates; the website otherwise shows newest dates first. Full Settings backups contain all articles, including drafts; **do not use a full backup as the website article file**. Restoring an old schema-1 backup replaces articles with an empty list after the existing confirmation and automatic backup steps.

The public static file has `schemaVersion: 1` and `articles: [...]`, with `id`, `title`, `summary`, `body`, `publishedOn` per article. These are two distinct formats: full local backup versus website-only export. Export is text-only and needs no media uploads.

Future Firebase mapping can add an `articles/{id}` collection with these fields, `displayOrder`, and the existing proposed audit/revision fields; draft filtering must remain server-enforced at publication. No backend integration is included here.

Latest-three update: article content, static JSON format and export rules are unchanged. Dates determine website recency; the Dashboard still exports every marked article so the full-list page can display them all.
