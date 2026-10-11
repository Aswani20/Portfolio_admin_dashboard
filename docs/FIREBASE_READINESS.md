# Future shared Firebase backend

**Status: design only.** The Dashboard still starts with `openLocalPortfolio`; the website still reads static Dart content. No Firebase project, SDK, credentials, network repository, synchronization or rule deployment has been added.

## Architecture review and small preparation

- `main.dart` accepts a `Future<PortfolioRepository> Function()` factory. `PortfolioBootstrap`, the shell and management screens consume interfaces; only `data/open_local_portfolio.dart` constructs `LocalPortfolioRepository` and `JsonPortfolioStore`.
- `RecordRepository<T>` already provides stable IDs, typed CRUD and `expectedRevision` checks. `PortfolioRepository.read()` supplies the aggregate used by forms and statistics. Keep these behaviors in any future adapter; do not turn successful saves into unacknowledged cloud writes.
- This phase extracts **MediaRepository**, inherited by PortfolioRepository. `ProjectImage` and the image-selection service now depend on that smaller interface. Local implementations and stored bytes are unchanged. UI obtains media bytes by ID, never by opening a storage path.
- Native JSON/image pickers remain device services. `PortfolioTransfer` is a portable validation/serialization contract, not an alternate storage implementation. Bulk replacement still promises confirmation, a backup and stale-preview rejection; an online implementation must fulfill that promise or expose the operation as unavailable. Never map it to a series of unrelated remote deletes.
- `WebsiteAnalyticsService` is independent of content and media. Its injected default remains disconnected. Future composition can inject a reporting implementation into WebsiteAnalyticsPage; no visitor metric comes from local content counts.

Proposed flow: Dashboard interfaces → authenticated adapter/backend → private Firestore drafts + Storage. An explicit server-side publication produces an immutable public release. Website → public release reader/media resolver → existing presentation models. Both applications use the same Firebase project per environment, while unpublished edits stay private.

For Windows, recheck platform support before selecting an adapter. Firebase currently marks Flutter Auth, Firestore and Storage for Windows as beta; do not assume web/mobile features or plugins work identically. An authenticated HTTPS backend adapter is a practical alternative for the desktop app. See the [official Flutter platform matrix](https://firebase.google.com/docs/flutter/setup#available-plugins).

## Proposed Firestore contract

This is a future **cloud schema 1**, separate from local snapshot/transfer schema 1. Use explicit DTO mappers: current model parsers reject unknown fields, so Firestore metadata must not be passed directly into `fromJson`.

Private control document: `sites/{siteId}` with `schemaVersion`, `activeDraftId`. Private draft manifest: `sites/{siteId}/drafts/{generationId}` with `schemaVersion`, `contentRevision`, `createdAt`, `updatedAt`, `updatedBy`. Each generation has these eight subcollections, with existing stable record IDs as document IDs:

| Collection | Content fields (besides ID/revision) |
| --- | --- |
| `projects` | `title`, `description`, ordered `imagePaths`, ordered `techStack`, nullable `liveUrl`, `githubUrl` |
| `education` | `degree`, `institution`, display-string `duration`, `location`, `isCurrent`, nullable `certificateUrl` |
| `experiences` | `role`, `company`, `duration`, `location`, `highlights[]`, `isCurrent`, `milestones[]` containing `id`, `revision`, `title`, `duration`, `type`, `highlights[]` |
| `skillCategories` | `title`, ordered `skills[]`: `id`, `revision`, `label`, `assetPath`, ARGB integer `colorValue`, boolean `themeAdaptive` |
| `profiles` | Exactly one existing profile ID: `name`, formatted `heroName`, `heroTitle`, `tagline`, `photoPath`, `primaryCtaLabel`, `primaryCtaTarget`, `secondaryCtaLabel`, `secondaryCtaTarget`, `bio`, `email`, `phone`, `location`, `orbitIconPaths[]`, `personalDetails[]` (`id`, `revision`, `icon`, `label`, `value`), `socialLinks[]` (`id`, `revision`, `label`, `url`, `iconPath`) |
| `settings` | Exactly one existing settings ID: `brandName`, `brandSuffix`, `appTitle`, `browserTitle`, `description`, `cvPath`, `cvLabel`, `cvDownloadFilename`, ordered `navigationLabels[]` (`id`, `revision`, `label`) |
| `sectionContent` | Existing section IDs with `heading`, `subtitle` |
| `media` | `sourcePath` (unique portable reference), `kind`, `label`; cloud-only `storagePath`, `contentType`, `byteSize`, `sha256`, optional `width`, `height`, and upload `state` (`pending`, `ready`, `failed`). No `localPath` in cloud documents. |

All content documents add `schemaVersion`, `revision`, server-managed `createdAt`, `updatedAt`, `updatedBy`; document ID is authoritative and supplied as model `id` by the mapper. Projects, education, experiences and skill categories add integer `displayOrder`; read by `(displayOrder, documentId)`. Nested array order already carries ordering. Preserve nested IDs and update nested content with its parent's revision. Do not introduce separate certifications, contacts or social collections: certificates belong to education and contact/social content belongs to the profile.

Public pointer: `publishedSites/{siteId}` with `activeReleaseId`, `schemaVersion`, `publishedAt`. Immutable manifests at `publishedSites/{siteId}/releases/{releaseId}` contain `state`, `schemaVersion`, `publishedAt`; their eight subcollections mirror the content fields above, excluding private audit fields and upload-incomplete media. Publish only after validating the complete release and its media, then atomically switch the pointer. Readers pin one release ID for the entire page. Retain the prior release for rollback. Firestore documents/collections are the storage units; large collections must be separate documents rather than one ever-growing aggregate. See [Firestore data model](https://firebase.google.com/docs/firestore/data-model).

## Media and website compatibility

Keep `sourcePath` as the unique compatibility key initially: projects.imagePaths, skills.assetPath, profile photo/orbit/social icon paths and settings.cvPath must each resolve to one media record in that generation. Certificate URLs remain external URLs. IDs, source references and local cache filenames are different concepts.

Cloud Storage paths should be generated by the backend, for example `sites/{siteId}/media/{mediaId}/{sha256}.{extension}`. Upload bytes, validate actual type/size/hash, then mark metadata ready; a failed upload must not create a usable content reference. Firestore writes and Storage uploads are not one atomic operation: use idempotent upload states and safe retries. Reuse matching hashes within the authorized site where practical. Do not remove shared objects when a project reference is deleted; cleanup must check drafts and retained releases first. Public copies/access are enabled only for published media. Do not expose tokenized download links for private drafts.

The current MediaAsset requires `localPath`, and aggregate validation requires safe unique local paths. A cloud DTO must omit it; an adapter can temporarily provide a safe synthetic cache key while resolving bytes through MediaRepository. Before true synchronization, migrate local schema explicitly to separate media identity/metadata from optional local cache location and optional remote object key. Never put a Windows path in a public URL or replace asset-reference fields with arbitrary download URLs.

The website's Project/Education/Experience models match the content fields above but have no IDs/serialization; skill and personal information are static maps. A future read-only adapter should preserve fields and array order, remove backend metadata at the boundary, and supply resolved media to presentation widgets. Existing `Image.asset`/`SvgPicture.asset`, gallery/precache code and CV download need a network-capable resolver and loading/fallback states before remote content can work. About/Contact should read the same profile. Preserve formatted hero strings, freeform durations, highlights and milestones; do not silently normalize them. No category/featured fields exist on projects today. Browser metadata in `web/index.html` needs a separate future publishing/build decision. The contact form remains mailto, not a message database.

## Authorization and analytics

Require administrator sign-in and site-scoped authorization for drafts, media uploads, publishing and reporting. Provision admin claims only in trusted server code; account creation or knowing a project identifier must never grant admin access. Deny by default; public clients may read only ready published releases/media and cannot write content. Validate allowed fields, ownership/site, immutable IDs and revision progression in rules or trusted backend handlers. Test non-admin, cross-site, unauthenticated and malformed writes with emulators before deployment. Client checks are not authorization. Use least-privilege IAM for server code, which must independently authorize requests. See [Firebase authorization rules](https://firebase.google.com/docs/rules/rules-and-auth), [admin custom claims](https://firebase.google.com/docs/auth/admin/custom-claims) and [Storage rules](https://firebase.google.com/docs/storage/security).

Keep service-account keys and reporting credentials on the server, never in Flutter source, exports or local JSON. Client Firebase configuration identifies a project; it is not an authorization boundary. Require token verification, secure session handling/sign-out and HTTPS for the desktop adapter. Select a supported Windows sign-in flow and credential storage during implementation; no auth UI or token persistence is implemented now.

Website visits require actual website instrumentation. Define visits (for example sessions) separately from page views and anchor-navigation events; choose reporting timezone, consent and retention, and exclude dashboard activity. Dashboard → authenticated reporting endpoint → authorized GA4 Data API (or another real provider) → normalized AnalyticsReport. Check admin/site scope, constrain date ranges, cache with freshness, handle quotas/errors, and distinguish unsupported from zero metrics. A GA service identity needs reporting access to the intended property; Firebase content access does not itself grant analytics report access. See [Google Analytics Data API setup](https://developers.google.com/analytics/devguides/reporting/data/v1/quickstart) and the existing [analytics contract](ANALYTICS.md). No reporting secrets or unrestricted query proxy belong in either client.

## Synchronization and safe migration

Cloud synchronization needs additional metadata: base remote revision, pending operation ID, acknowledged state/error, generation ID, server timestamps, and deletion tombstones. Keep this in a separate local sync journal/schema migration, not in website presentation models. Preserve optimistic conflict checks using transactions and server acknowledgements; timestamps alone are not conflict detection. Firestore transactions can retry and fail offline, so local persistence is not automatically a cloud sync queue. See [transaction behavior](https://firebase.google.com/docs/firestore/manage-data/transactions).

For a small portfolio, aggregate reads can check draft `contentRevision` before/after loading and retry on change; all writes must advance it. Reorders require a bounded atomic transaction with expected revisions. Bulk replacement stages a new complete generation, validates it, backs up the previous generation, then conditionally switches activeDraftId against the reviewed revision. Interrupted staging is never made visible. Deletes must reject live references or update related content atomically. Publication and local restore remain distinct actions.

1. Freeze a backup of the current local store including available media. Treat saved Dashboard edits as authoritative; use the frozen website seed only for missing initial content, never reseed over edits. Run `python tool/import_website.py ../portfolio_app --verify` and review differences; its positional seed IDs must not be regenerated after reordering.
2. Later, in a separate authorized integration phase, create an isolated development backend, implement DTOs/auth/adapters and emulator rule/contract tests. Keep local mode as the default until Windows support and offline/error behavior are verified.
3. Dry-run a migration manifest containing stable IDs, original reference keys, order, content checksums and missing-media errors. Upload media first, create private documents idempotently, and reject conflicting IDs/content rather than overwrite. Test original galleries, SVGs, CV, contact links and nested records.
4. Compare Dashboard repository output with source content and verify rollback from backup. Build a staged public release, preview the website with its new reader behind an explicit source switch, and test network failure, permissions and caching.
5. Publish only after approval and validation. Keep the original static source, previous release and local backup for rollback. Add multi-device synchronization only after conflict/tombstone and retry behavior are tested; do not silently push local edits at startup.

No local schema/data changes were made in this readiness phase. The current offline CRUD, media, statistics and backup/restore workflows remain supported.
