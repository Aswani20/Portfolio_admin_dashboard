/// Calendar dates are inclusive and interpreted in the reporting timezone.
class AnalyticsRange {
  AnalyticsRange(DateTime start, DateTime end)
    : start = DateTime(start.year, start.month, start.day),
      end = DateTime(end.year, end.month, end.day) {
    if (this.start.isAfter(this.end)) {
      throw ArgumentError('The start date must not follow the end date.');
    }
  }
  final DateTime start;
  final DateTime end;
}

/// Null metrics or collections mean unsupported/unavailable, never zero.
/// Empty collections mean a successful report with no matching activity.
class AnalyticsReport {
  const AnalyticsReport({
    required this.range,
    required this.timezone,
    required this.updatedAt,
    this.totalVisits,
    this.visitsToday,
    this.visits7Days,
    this.visits30Days,
    this.dailyVisits,
    this.pages,
    this.sources,
  });
  final AnalyticsRange range;
  final String timezone;
  final DateTime updatedAt;
  final int? totalVisits, visitsToday, visits7Days, visits30Days;
  final List<DailyVisits>? dailyVisits;
  final List<AnalyticsRanking>? pages, sources;
}

class DailyVisits {
  const DailyVisits(this.date, this.visits);
  final DateTime date;
  final int visits;
}

class AnalyticsRanking {
  const AnalyticsRanking(this.label, this.visits);
  final String label;
  final int visits;
}

abstract interface class WebsiteAnalyticsService {
  /// Returns null when reporting is not connected. Throws on retrieval failure.
  /// Summary windows end on the reporting timezone's current day, while
  /// daily visits and rankings use the requested range.
  Future<AnalyticsReport?> fetchReport(AnalyticsRange range);
}

class DisconnectedAnalyticsService implements WebsiteAnalyticsService {
  const DisconnectedAnalyticsService();
  @override
  Future<AnalyticsReport?> fetchReport(AnalyticsRange range) async => null;
}
