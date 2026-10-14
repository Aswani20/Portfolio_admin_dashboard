import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/main.dart';

import 'fixture_repository.dart';

void main() {
  testWidgets('write, validate, read, edit, filter, copy and delete articles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FixtureRepository(fixtureContent());
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    Future<void> tapKey(String key) async {
      final target = find.byKey(ValueKey(key));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> input(String key, String text) async {
      final target = find.byKey(ValueKey('field-$key'));
      await tester.ensureVisible(target);
      await tester.enterText(target, text);
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(
      PortfolioAdminDashboardApp(openRepository: () async => repository),
    );
    await tester.pumpAndSettle();
    await tapKey('nav-articles');
    expect(find.textContaining('No articles yet.'), findsOneWidget);
    await tapKey('add-articles');
    await tapKey('save-content');
    expect(find.text('This field is required.'), findsWidgets);
    await input('title', 'My first article');
    await input('summary', 'A short introduction');
    await input('body', 'First paragraph.\n\nSecond paragraph.');
    await input('publishedOn', '2026-02-30');
    await tapKey('save-content');
    expect(find.text('Enter a valid calendar date.'), findsOneWidget);
    await input('publishedOn', '2026-10-13');
    await tapKey('save-content');
    final saved = repository.content.articles.single;
    expect(saved.isPublished, false);
    await tester.tap(find.text('Copy website JSON'));
    await tester.pumpAndSettle();
    expect(jsonDecode(clipboard!)['articles'], isEmpty);
    final read = find.text('Read article');
    await tester.ensureVisible(read);
    await tester.pumpAndSettle();
    await tester.tap(read);
    await tester.pumpAndSettle();
    expect(find.text(saved.body), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tapKey('edit-content-${saved.id}');
    await input('title', 'Updated article');
    await tapKey('field-isPublished');
    await tapKey('save-content');
    expect(repository.content.articles.single.body, saved.body);
    await tester.ensureVisible(find.text('Copy website JSON'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy website JSON'));
    await tester.pumpAndSettle();
    expect(jsonDecode(clipboard!)['articles'][0]['title'], 'Updated article');
    await tester.enterText(
      find.byKey(const ValueKey('search-articles')),
      'no match',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('no-matching-content')), findsOneWidget);
    await tapKey('reset-articles');
    await tapKey('filter-articles-');
    await tester.tap(find.text('Drafts').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('no-matching-content')), findsOneWidget);
    await tapKey('reset-articles');
    await tapKey('delete-content-${saved.id}');
    await tapKey('cancel-content-delete');
    expect(repository.content.articles.length, 1);
    await tapKey('delete-content-${saved.id}');
    await tapKey('confirm-content-delete');
    expect(repository.content.articles, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
