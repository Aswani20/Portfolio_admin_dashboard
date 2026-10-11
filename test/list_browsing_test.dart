import 'package:portfolio_admin_dashboard/models/portfolio_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/main.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_content.dart';

import 'fixture_repository.dart';

Future<void> tap(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> search(WidgetTester t, String name, String value) async {
  final f = find.byKey(ValueKey('search-$name'));
  await t.ensureVisible(f);
  await t.enterText(f, value);
  await t.pumpAndSettle();
}

Future<void> choose(
  WidgetTester t,
  String name,
  String kind,
  String label,
) async {
  final f = find.byWidgetPredicate(
    (w) =>
        w is DropdownButtonFormField<String> &&
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>).value.startsWith('$kind-$name-'),
  );
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
  await t.tap(find.text(label).last);
  await t.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  late FixtureRepository repo;
  Future<void> start(
    WidgetTester t,
    String page, {
    PortfolioContent? content,
    Size size = const Size(1440, 1000),
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    repo = FixtureRepository(content ?? fixtureContent());
    await t.pumpWidget(
      PortfolioAdminDashboardApp(openRepository: () async => repo),
    );
    await t.pumpAndSettle();
    await tap(t, 'nav-$page');
  }

  testWidgets(
    'projects combine search and technology, sort without writes, retain state and reset',
    (t) async {
      await start(t, 'projects');
      final before = repo.content.toJson();
      final technology = repo.content.projects.first.techStack.first.trim();
      await choose(t, 'projects', 'filter', technology);
      final matches = repo.content.projects
          .where(
            (p) => p.techStack.any(
              (s) => s.trim().toLowerCase() == technology.toLowerCase(),
            ),
          )
          .toList();
      expect(
        find.text(
          '${matches.length} of ${repo.content.projects.length} results',
        ),
        findsOneWidget,
      );
      await choose(t, 'projects', 'sort', 'Title Z-A');
      expect(
        t
            .widget<IconButton>(
              find.byKey(ValueKey('down-${matches.first.id}')),
            )
            .onPressed,
        isNull,
      );
      await search(t, 'projects', '  ${matches.first.title.toUpperCase()}  ');
      expect(
        find.byKey(ValueKey('project-row-${matches.first.id}')),
        findsOneWidget,
      );
      await tap(t, 'nav-overview');
      await tap(t, 'nav-projects');
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('search-projects')))
            .controller!
            .text
            .trim(),
        matches.first.title.toUpperCase(),
      );
      await tap(t, 'refresh-projects');
      expect(find.text('Title Z-A'), findsOneWidget);
      await search(t, 'projects', 'absent title');
      expect(find.text('No matching projects'), findsOneWidget);
      await tap(t, 'reset-projects');
      expect(
        find.text(
          '${repo.content.projects.length} of ${repo.content.projects.length} results',
        ),
        findsOneWidget,
      );
      expect(repo.content.toJson(), before);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'experience status/company sorting and persistent display ordering',
    (t) async {
      await start(t, 'experience');
      final before = repo.content.experiences;
      await choose(t, 'experience', 'filter', 'Current');
      expect(
        find.text(
          '${before.where((e) => e.isCurrent).length} of ${before.length} results',
        ),
        findsOneWidget,
      );
      await choose(t, 'experience', 'sort', 'Company A-Z');
      await search(t, 'experience', 'unlikely organization');
      expect(find.byKey(const ValueKey('no-matching-content')), findsOneWidget);
      await tap(t, 'reset-experience');
      await tap(t, 'order-down-${before.first.id}');
      expect(repo.content.experiences[1].id, before.first.id);
      expect(repo.content.experiences[1].highlights, before.first.highlights);
      repo.writeFailure = 'Cannot save order';
      await tap(t, 'order-up-${before.first.id}');
      expect(find.textContaining('Cannot save order'), findsOneWidget);
      expect(repo.content.experiences[1].id, before.first.id);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'skill category and technology queries combine and stale filter is recoverable',
    (t) async {
      await start(t, 'skills');
      final category = repo.content.skillCategories.first;
      await choose(t, 'skills', 'filter', category.title);
      await search(t, 'skills', category.skills.first.label.toUpperCase());
      expect(find.text('1 of 4 results'), findsOneWidget);
      await tap(t, 'nav-education');
      await tap(t, 'nav-skills');
      expect(find.text('1 of 4 results'), findsOneWidget);
      await repo.skillCategories.delete(
        category.id,
        expectedRevision: category.revision,
      );
      await tap(t, 'refresh-content');
      expect(find.byKey(const ValueKey('no-matching-content')), findsOneWidget);
      expect(
        find.text('Unavailable selection (reset to clear)'),
        findsOneWidget,
      );
      await tap(t, 'reset-skills');
      expect(find.text('3 of 3 results'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('education and certificate filters have independent state', (
    t,
  ) async {
    await start(t, 'education');
    await choose(t, 'education', 'filter', 'Current');
    await choose(t, 'education', 'sort', 'Institution A-Z');
    await tap(t, 'nav-certifications');
    await choose(t, 'certifications', 'filter', 'With certificate');
    expect(find.byKey(const ValueKey('no-matching-content')), findsOneWidget);
    final record = repo.content.education.first;
    await repo.education.update(
      Education.fromJson({
        ...record.toJson(),
        'certificateUrl': 'https://example.com/certificate',
      }),
      expectedRevision: record.revision,
    );
    await tap(t, 'refresh-content');
    expect(find.text('1 of 5 results'), findsOneWidget);
    expect(find.byKey(ValueKey('content-row-${record.id}')), findsOneWidget);
    await tap(t, 'reset-certifications');
    expect(find.text('5 of 5 results'), findsOneWidget);
    await tap(t, 'nav-education');
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Institution A-Z'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'large content list pages, remembers page and clamps after deletion',
    (t) async {
      final seed = fixtureContent();
      final content = PortfolioContent.fromJson({
        ...seed.toJson(),
        'education': [
          for (var i = 0; i < 41; i++)
            {
              ...seed.education.first.toJson(),
              'id': 'edu-$i',
              'degree': 'Course ${i.toString().padLeft(2, '0')}',
            },
        ],
      });
      await start(t, 'education', content: content, size: const Size(600, 480));
      expect(find.byKey(const ValueKey('content-row-edu-19')), findsOneWidget);
      expect(find.byKey(const ValueKey('content-row-edu-20')), findsNothing);
      await tap(t, 'next-education');
      await tap(t, 'next-education');
      expect(find.text('Page 3 of 3'), findsOneWidget);
      await tap(t, 'nav-personal');
      expect(find.byKey(const ValueKey('page-personal')), findsOneWidget);
      await tap(t, 'nav-education');
      expect(find.text('Page 3 of 3'), findsOneWidget);
      await tap(t, 'delete-content-edu-40');
      await tap(t, 'confirm-content-delete');
      expect(find.text('Page 2 of 2'), findsOneWidget);
      await search(t, 'education', 'COURSE 00');
      expect(find.byKey(const ValueKey('content-row-edu-0')), findsOneWidget);
      expect(find.text('1 of 40 results'), findsOneWidget);
      await tap(t, 'reset-education');
      expect(find.text('Page 1 of 2'), findsOneWidget);
      await tap(t, 'order-down-edu-19');
      expect(repo.content.education[20].id, 'edu-19');
      expect(find.text('Page 2 of 2'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'media filename/type filters and picker selection survive search changes',
    (t) async {
      await start(t, 'media');
      await choose(t, 'media', 'filter', 'Documents');
      await search(t, 'media', 'CV');
      expect(find.text('1 of 42 results'), findsOneWidget);
      await tap(t, 'nav-projects');
      await tap(t, 'nav-media');
      expect(find.text('1 of 42 results'), findsOneWidget);
      await tap(t, 'reset-media');
      await tap(t, 'nav-projects');
      await tap(t, 'add-project');
      await tap(t, 'browse-project-media');
      final asset = repo.content.media.firstWhere((a) => a.kind == 'image');
      await tap(t, 'select-media-${asset.id}');
      await search(t, 'media-picker', 'no-such-image');
      expect(
        find.text(
          'No matching media. Try another search or reset your filters.',
        ),
        findsOneWidget,
      );
      expect(find.text('Use 1 image(s)'), findsOneWidget);
      await tap(t, 'use-images');
      expect(find.byKey(const ValueKey('remove-image-0')), findsOneWidget);
      await tap(t, 'cancel-project');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('large media library reads only the visible page of thumbnails', (
    t,
  ) async {
    final seed = fixtureContent();
    final image = seed.media.firstWhere((a) => a.kind == 'image');
    final content = PortfolioContent.fromJson({
      ...seed.toJson(),
      'media': [
        ...seed.media.map((a) => a.toJson()),
        for (var i = 0; i < 100; i++)
          {
            ...image.toJson(),
            'id': 'bulk-$i',
            'sourcePath': 'assets/images/bulk-$i.png',
            'localPath': 'media/bulk-$i.png',
            'label': 'Bulk $i',
          },
      ],
    });
    await start(t, 'media', content: content);
    expect(repo.mediaReads, 50);
    expect(find.text('Page 1 of 3'), findsOneWidget);
    await tap(t, 'next-media');
    expect(repo.mediaReads, 100);
    await search(t, 'media', 'Bulk 99');
    expect(find.text('1 of 142 results'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Card), matching: find.text('Bulk 99')),
      findsOneWidget,
    );
    expect(repo.mediaReads, 101);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'project paging and boundary reorder keep complete collection order',
    (t) async {
      final seed = fixtureContent();
      final content = PortfolioContent.fromJson({
        ...seed.toJson(),
        'projects': [
          for (var i = 0; i < 41; i++)
            {
              ...seed.projects.first.toJson(),
              'id': 'project-page-$i',
              'title': 'Example ${i.toString().padLeft(2, '0')}',
            },
        ],
      });
      await start(t, 'projects', content: content);
      expect(
        find.byKey(const ValueKey('project-row-project-page-20')),
        findsNothing,
      );
      await tap(t, 'down-project-page-19');
      expect(repo.content.projects[20].id, 'project-page-19');
      expect(find.text('Page 2 of 3'), findsOneWidget);
      await tap(t, 'nav-overview');
      await tap(t, 'nav-projects');
      expect(find.text('Page 2 of 3'), findsOneWidget);
      await search(t, 'projects', 'example 40');
      expect(find.text('1 of 41 results'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('project-row-project-page-40')),
        findsOneWidget,
      );
      await tap(t, 'reset-projects');
      expect(find.text('Page 1 of 3'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
