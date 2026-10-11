import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/main.dart';
import 'package:portfolio_admin_dashboard/repositories/portfolio_repository.dart';

import 'fixture_repository.dart';

void main() {
  testWidgets('startup loading, error and retry are visible without reset', (
    tester,
  ) async {
    final first = Completer<PortfolioRepository>();
    var attempts = 0;
    await tester.pumpWidget(
      PortfolioAdminDashboardApp(
        openRepository: () {
          attempts++;
          return attempts == 1 ? first.future : openFixture();
        },
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    first.completeError(
      const StoreException('Corrupted data preserved. Restore backup.'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Corrupted data preserved'), findsOneWidget);
    expect(find.byKey(const ValueKey('page-overview')), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-overview')), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(attempts, 2);
  });
}
