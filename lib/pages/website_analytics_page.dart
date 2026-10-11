import 'package:flutter/material.dart';

import '../services/website_analytics.dart';
import '../theme/dashboard_theme.dart';
import '../widgets/dashboard_components.dart';

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

class WebsiteAnalyticsPage extends StatefulWidget {
  const WebsiteAnalyticsPage({
    super.key,
    this.service = const DisconnectedAnalyticsService(),
  });
  final WebsiteAnalyticsService service;
  @override
  State<WebsiteAnalyticsPage> createState() => _WebsiteAnalyticsPageState();
}

class _WebsiteAnalyticsPageState extends State<WebsiteAnalyticsPage> {
  late AnalyticsRange _range;
  AnalyticsReport? _report;
  bool _loading = true;
  bool _failed = false;
  int _request = 0;
  int? _days = 30;

  @override
  void initState() {
    super.initState();
    _range = _recent(30);
    _load();
  }

  AnalyticsRange _recent(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return AnalyticsRange(
      DateTime(today.year, today.month, today.day - days + 1),
      today,
    );
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
      _report = null;
    });
    try {
      final report = await widget.service.fetchReport(_range);
      if (!mounted || request != _request) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _customRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _range.start, end: _range.end),
    );
    if (selected == null || !mounted) return;
    _range = AnalyticsRange(selected.start, selected.end);
    _days = null;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Column(
      key: const ValueKey('page-analytics'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          title: 'Website Analytics',
          description: 'Website visits and traffic reports, separate from local portfolio content.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final days in [1, 7, 30])
              ChoiceChip(
                label: Text(days == 1 ? 'Today' : 'Last $days days'),
                selected: _days == days,
                onSelected: (_) {
                  _days = days;
                  _range = _recent(days);
                  _load();
                },
              ),
            OutlinedButton.icon(
              onPressed: _customRange,
              icon: const Icon(Icons.date_range),
              label: const Text('Custom range'),
            ),
            IconButton(
              tooltip: 'Refresh analytics',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${_date(_range.start)} – ${_date(_range.end)} · Daily chart and rankings',
        ),
        const SizedBox(height: 20),
        DashboardPanel(
          child: _loading
              ? const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text('Loading analytics…'),
                  ],
                )
              : _failed
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unable to load analytics. Please try again.'),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                )
              : report == null
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics are not connected yet',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Connect website instrumentation and a secure reporting service to view real visitor data. Dashboard launches are never counted as website visits.',
                    ),
                  ],
                )
              : Text(
                  'Reporting timezone: ${report.timezone} · Updated: ${report.updatedAt.toUtc().toIso8601String()}',
                ),
        ),
        const SizedBox(height: 20),
        ResponsiveCards(
          minWidth: 180,
          children: [
            for (final metric in [
              ('Total visits', report?.totalVisits, 'All time'),
              ('Visits today', report?.visitsToday, 'Current reporting day'),
              ('Last 7 days', report?.visits7Days, 'Including today'),
              ('Last 30 days', report?.visits30Days, 'Including today'),
            ])
              DashboardPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.$1,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      metric.$2?.toString() ?? '—',
                      key: ValueKey('analytics-${metric.$1}'),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Text(metric.$3),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _section(
          context,
          'Daily visits',
          report?.dailyVisits == null
              ? Text(_noData)
              : report!.dailyVisits!.isEmpty
              ? const Text('No visits reported for this date range.')
              : _DailyChart(days: report.dailyVisits!),
        ),
        const SizedBox(height: 20),
        _ranking(context, 'Most visited pages', report?.pages),
        const SizedBox(height: 20),
        _ranking(context, 'Traffic sources', report?.sources),
      ],
    );
  }

  String get _noData => _loading
      ? 'Waiting for report…'
      : _failed
      ? 'Report could not be loaded.'
      : _report == null
      ? 'Unavailable until analytics are connected.'
      : 'This metric is not available from the reporting service.';

  Widget _section(BuildContext context, String title, Widget child) =>
      DashboardPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );

  Widget _ranking(
    BuildContext context,
    String title,
    List<AnalyticsRanking>? rows,
  ) {
    final sorted = rows == null
        ? null
        : ([...rows]..sort((a, b) => b.visits.compareTo(a.visits)));
    return _section(
      context,
      title,
      sorted == null
          ? Text(_noData)
          : sorted.isEmpty
          ? const Text('No activity reported for this date range.')
          : Column(
              children: [
                for (final row in sorted.take(10))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(row.label)),
                        const SizedBox(width: 16),
                        Text('${row.visits} visits'),
                      ],
                    ),
                  ),
                const Text('Top 10 reported results'),
              ],
            ),
    );
  }
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.days});
  final List<DailyVisits> days;
  @override
  Widget build(BuildContext context) {
    final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final max = sorted.fold<int>(
      1,
      (value, day) => day.visits > value ? day.visits : value,
    );
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final day = sorted[index];
          return Semantics(
            label: '${_date(day.date)}: ${day.visits} visits',
            child: Tooltip(
              message: '${_date(day.date)}: ${day.visits} visits',
              child: SizedBox(
                width: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${day.visits}'),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 150 * (day.visits / max).clamp(0, 1),
                      color: DashboardTheme.accent,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _date(day.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
