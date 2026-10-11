import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/data/json_portfolio_store.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_models.dart';
import 'package:portfolio_admin_dashboard/pages/overview_page.dart';
import 'package:portfolio_admin_dashboard/pages/website_analytics_page.dart';
import 'package:portfolio_admin_dashboard/repositories/local_portfolio_repository.dart';
import 'package:portfolio_admin_dashboard/services/website_analytics.dart';

class Reports implements WebsiteAnalyticsService {
  final pending = <Completer<AnalyticsReport?>>[];
  final ranges = <AnalyticsRange>[];
  @override
  Future<AnalyticsReport?> fetchReport(AnalyticsRange range) {
    ranges.add(range);
    final request = Completer<AnalyticsReport?>();
    pending.add(request);
    return request.future;
  }
}

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets(
    'Overview counts persisted records and reflects changed snapshots',
    (tester) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('overview_counts_'),
      ))!;
      addTearDown(() => directory.delete(recursive: true));
      final store = JsonPortfolioStore(directory);
      await tester.runAsync(
        () => store.initialize(
          loadSeed: () => File('assets/seed/portfolio.json').readAsString(),
          loadSeedMedia: (_) async => Uint8List.fromList([1]),
        ),
      );
      final repository = LocalPortfolioRepository(store);
      Future<void> check() async {
        final content = await LocalPortfolioRepository(
          JsonPortfolioStore(directory),
        ).read();
        await tester.pumpWidget(
          host(OverviewPage(content: content, onNavigate: (_) {})),
        );
        final counts = {
          'projects': content.projects.length,
          'skills': content.skillCategories.fold<int>(
            0,
            (sum, category) => sum + category.skills.length,
          ),
          'experience': content.experiences.length,
          'education': content.education.length,
          'certifications': content.education
              .where((item) => item.certificateUrl?.trim().isNotEmpty ?? false)
              .length,
          'media': content.media.length,
        };
        for (final entry in counts.entries) {
          expect(
            tester.widget<Text>(find.byKey(ValueKey('stat-${entry.key}'))).data,
            '${entry.value}',
          );
        }
      }

      await tester.runAsync(check);
      await tester.runAsync(() async {
        final item = (await repository.education.list()).first;
        await repository.education.update(
          Education.fromJson({
            ...item.toJson(),
            'certificateUrl': 'https://example.org/certificate',
          }),
          expectedRevision: item.revision,
        );
        final project = (await repository.projects.list()).first;
        await repository.projects.delete(
          project.id,
          expectedRevision: project.revision,
        );
      });
      await tester.runAsync(check);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('stat-certifications')))
            .data,
        '1',
      );
    },
  );

  testWidgets('Disconnected analytics has no fabricated numbers', (
    tester,
  ) async {
    await tester.pumpWidget(host(const WebsiteAnalyticsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Analytics are not connected yet'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(4));
    expect(find.text('0'), findsNothing);
    await tester.tap(find.text('Last 7 days').first);
    await tester.pumpAndSettle();
    expect(find.text('Analytics are not connected yet'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(4));
  });

  testWidgets('Loading, failure, retry and empty reports are distinct', (
    tester,
  ) async {
    final service = Reports();
    await tester.pumpWidget(host(WebsiteAnalyticsPage(service: service)));
    expect(find.text('Loading analytics…'), findsOneWidget);
    service.pending.last.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to load analytics. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();
    service.pending.last.complete(
      AnalyticsReport(
        range: service.ranges.last,
        timezone: 'UTC',
        updatedAt: DateTime.utc(2026),
        totalVisits: 0,
        dailyVisits: const [],
        pages: const [],
        sources: null,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    expect(
      find.text('No visits reported for this date range.'),
      findsOneWidget,
    );
    expect(
      find.text('This metric is not available from the reporting service.'),
      findsOneWidget,
    );
  });

  testWidgets('Range changes ignore late responses and show actual reports', (
    tester,
  ) async {
    final service = Reports();
    await tester.pumpWidget(host(WebsiteAnalyticsPage(service: service)));
    await tester.tap(find.text('Last 7 days').first);
    await tester.pump();
    final range = service.ranges.last;
    expect(range.end.difference(range.start).inDays, 6);
    service.pending.last.complete(
      AnalyticsReport(
        range: range,
        timezone: 'UTC',
        updatedAt: DateTime.utc(2026),
        totalVisits: 123,
        dailyVisits: [DailyVisits(range.start, 12)],
        pages: const [AnalyticsRanking('/projects', 10)],
        sources: const [],
      ),
    );
    await tester.pumpAndSettle();
    service.pending.first.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('123'), findsOneWidget);
    expect(find.text('/projects'), findsOneWidget);
    expect(find.text('Analytics are not connected yet'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('Invalid reversed date ranges are rejected', () {
    expect(
      () => AnalyticsRange(DateTime(2026, 2), DateTime(2026, 1)),
      throwsArgumentError,
    );
  });
}
