# Overview statistics and website analytics

## Local content statistics

Overview derives six counts from the repository snapshot: projects, nested skills across all categories, experience entries, education entries, certifications, and media records. Certifications are education entries with a nonblank certificate URL, not a separate collection. Media counts metadata records, including records whose physical file is missing. Empty collections correctly display zero.

The existing management screens reread the repository after successful saves/deletes/imports and notify DashboardShell. Overview receives the updated snapshot, including completion of saves after navigating away. Restarting loads the persisted snapshot. External file edits are not watched. No schema or persistence changes were required.

## Current analytics behavior

Website Analytics uses WebsiteAnalyticsService, separate from portfolio repositories. The shipped DisconnectedAnalyticsService returns null without network access or local visit counters. The page displays “Analytics are not connected yet” and dashes for unavailable metrics. Dashboard launches never become website visits.

Today, Last 7 days, Last 30 days and Custom range control the daily chart and rankings. Summary cards have independent, explicit windows: all time, current reporting day, trailing 7 and trailing 30 calendar days including today. Until a reporting timezone is configured, date selection uses the desktop calendar; a future provider must interpret those calendar dates in its stated reporting timezone. Custom selection supports dates from 2000 through today.

The service returns a report, null for an unconnected provider, or throws for retrieval failure. The UI distinguishes loading, disconnected, failed (with Retry), empty collections, and unsupported metrics (null). Successful zero values display as zero. Previous results are cleared while reloading, and late responses from older date-range requests cannot replace newer results.

Daily data renders as horizontally scrollable bars with date/value labels and tooltips. Missing dates are not filled with invented zeroes. Page/source rankings show the top 10 supplied results by visits. Null collections mean unsupported; empty collections mean no matching activity. The default implementation supplies no chart points, pages, sources, or numeric metrics. Synthetic visitor values exist only in tests.

## Future integration requirements

1. Instrument the deployed website with an actual analytics provider or first-party event collector, including initial loads and relevant navigation/route events. The Dashboard does not instrument the website. Define what a visit means (for example a session), how it differs from page views, session deduplication, bot/internal-traffic exclusions, and attribution before mapping reports to these labels.
2. Configure collection consent and retention appropriate to the website's users. Avoid sending private profile/form content or identifying URL parameters in events. Decide whether portfolio anchor navigation is an event or page view to avoid counting the same visit repeatedly.
3. Supply an authenticated reporting backend with access to the intended website/property only. Keep service-account credentials, reporting secrets and privileged provider tokens on that backend, never in Flutter assets, source, or the local JSON store. Authenticate the administrator, authorize report access, use HTTPS and short-lived access tokens, and handle expiry, rate limits and backend errors.
4. Implement WebsiteAnalyticsService and inject it into WebsiteAnalyticsPage in DashboardShell. Translate the provider's metrics into the agreed visit definition; do not substitute page views silently. Request bounded calendar ranges and aggregate in the configured reporting timezone. Validate nonnegative counts, unique daily dates within the requested range, and matching returned ranges before returning a report. Return immutable snapshots and identify unsupported metrics with null.
5. Return reporting timezone and data freshness (updatedAt), account for delayed reporting, and define inclusive date boundaries consistently across all summary windows. Fetch all-time and rolling summary windows separately from selected-range chart/rankings as necessary. Normalize URLs and source labels without inventing unavailable attribution.
6. Verify against real provider reports and add authenticated integration tests before claiming a live connection. No Firebase, Google Analytics SDK, credentials, or reporting backend is implemented in this phase.

## Verification

Focused tests cover disk-backed counts after repository changes and reopen, disconnected dashes, date-range requests, loading/error/retry, empty versus unsupported data, rendered report values and stale-response protection. Existing management tests cover saved updates reaching Overview. See the current phase result in VERIFICATION.md for executed checks.
