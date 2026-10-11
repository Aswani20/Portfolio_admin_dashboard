import 'fixture_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/main.dart';
import 'package:portfolio_admin_dashboard/navigation/dashboard_destination.dart';

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(800, 600),
    const Size(600, 480),
  ]) {
    testWidgets('Every destination works at ${size.width} x ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const PortfolioAdminDashboardApp(openRepository: openFixture),
      );
      await tester.pumpAndSettle();
      for (final destination in DashboardDestination.values) {
        final nav = find.byKey(ValueKey('nav-${destination.name}'));
        await tester.ensureVisible(nav);
        await tester.tap(nav);
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('page-${destination.name}')),
          findsOneWidget,
        );
        for (final other in DashboardDestination.values.where(
          (item) => item != destination,
        )) {
          expect(find.byKey(ValueKey('page-${other.name}')), findsNothing);
        }
        expect(
          tester.takeException(),
          isNull,
          reason: '${destination.label} must render without overflow',
        );
      }
      final overviewNav = find.byKey(const ValueKey('nav-overview'));
      await tester.scrollUntilVisible(
        overviewNav,
        -200,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(overviewNav);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('page-overview')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Overview shortcuts open their intended pages', (tester) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const PortfolioAdminDashboardApp(openRepository: openFixture),
    );
    await tester.pumpAndSettle();
    for (final name in ['personal', 'education', 'projects']) {
      final shortcut = find.byKey(ValueKey('shortcut-$name'));
      await tester.ensureVisible(shortcut);
      await tester.tap(shortcut);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('page-$name')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-overview')));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
