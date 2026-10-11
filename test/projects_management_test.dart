import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/main.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_models.dart';

import 'fixture_repository.dart';

void main() {
  late FixtureRepository repository;
  Future<void> start(
    WidgetTester tester, {
    Size size = const Size(1440, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    repository = FixtureRepository(fixtureContent());
    await tester.pumpWidget(
      PortfolioAdminDashboardApp(openRepository: () async => repository),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'nav-projects');
  }

  Future<void> search(WidgetTester tester, String text) async {
    final finder = find.byKey(const ValueKey('search-projects'));
    await tester.ensureVisible(finder);
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'create, view, search, edit, cancel/confirm delete and refresh Overview',
    (tester) async {
      await start(tester);
      await tap(tester, 'add-project');
      await enter(tester, 'project-title', 'New portfolio example');
      await enter(
        tester,
        'project-description',
        'A complete project description.',
      );
      await enter(tester, 'project-technologies', 'Flutter\nDart');
      await enter(
        tester,
        'project-github',
        'https://github.com/example/project',
      );
      await enter(tester, 'project-live', 'https://example.com/demo');
      await tap(tester, 'browse-project-media');
      final image = repository.content.media.singleWhere(
        (a) => a.sourcePath == 'assets/images/aflam_pair1_landscape.jpg',
      );
      await tap(tester, 'select-media-${image.id}');
      await tap(tester, 'use-images');
      await tap(tester, 'save-project');
      expect(repository.content.projects.length, 9);
      final created = repository.content.projects.last;
      expect(created.imagePaths, ['assets/images/aflam_pair1_landscape.jpg']);
      expect(created.techStack, ['Flutter', 'Dart']);
      await tap(tester, 'nav-overview');
      expect(find.text('9'), findsOneWidget);
      await tap(tester, 'nav-projects');
      await search(tester, ' NEW PORTFOLIO ');
      expect(find.byKey(ValueKey('project-row-${created.id}')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('project-row-project-001')),
        findsNothing,
      );
      await tap(tester, 'view-${created.id}');
      expect(find.byKey(const ValueKey('details-title')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('A complete project description.'),
        ),
        findsOneWidget,
      );
      expect(find.text('https://example.com/demo'), findsOneWidget);
      await tap(tester, 'close-project-details');
      await tap(tester, 'edit-${created.id}');
      await enter(tester, 'project-title', 'Updated portfolio example');
      await tap(tester, 'save-project');
      final edited = await repository.projects.get(created.id);
      expect(edited!.description, created.description);
      expect(edited.imagePaths, created.imagePaths);
      expect(edited.techStack, created.techStack);
      expect(edited.githubUrl, created.githubUrl);
      expect(edited.liveUrl, created.liveUrl);
      expect(find.text('No matching projects'), findsOneWidget);
      await search(tester, 'Updated portfolio');
      await tap(tester, 'delete-${created.id}');
      await tap(tester, 'cancel-delete');
      expect(await repository.projects.get(created.id), isNotNull);
      await tap(tester, 'delete-${created.id}');
      await tap(tester, 'confirm-delete');
      expect(await repository.projects.get(created.id), isNull);
      await tap(tester, 'nav-overview');
      expect(find.text('8'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('required fields and URLs validate; failed save retains form', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, 'add-project');
    await tap(tester, 'save-project');
    expect(find.text('Title is required.'), findsOneWidget);
    expect(find.text('Description is required.'), findsOneWidget);
    await enter(tester, 'project-title', 'Validated project');
    await enter(tester, 'project-description', 'Description');
    await enter(tester, 'project-github', 'javascript:alert(1)');
    await tap(tester, 'save-project');
    expect(
      find.text('Enter a full http:// or https:// URL, or leave blank.'),
      findsOneWidget,
    );
    expect(repository.content.projects.length, 8);
    await enter(tester, 'project-github', '');
    repository.writeFailure = 'Simulated disk failure';
    await tap(tester, 'save-project');
    expect(find.text('Simulated disk failure'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('project-title')))
          .controller!
          .text,
      'Validated project',
    );
    repository.writeFailure = null;
    await tap(tester, 'save-project');
    expect(repository.content.projects.last.title, 'Validated project');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'edit preserves untouched source strings and gallery order can change',
    (tester) async {
      await start(tester);
      final old = repository.content.projects.first;
      await tap(tester, 'edit-${old.id}');
      await enter(tester, 'project-title', 'Renamed FindWay');
      await tap(tester, 'image-down-0');
      await tap(tester, 'save-project');
      final updated = await repository.projects.get(old.id);
      expect(updated!.description, old.description);
      expect(updated.techStack, old.techStack);
      expect(updated.imagePaths[0], old.imagePaths[1]);
      expect(updated.imagePaths[1], old.imagePaths[0]);
      expect(updated.imagePaths.length, 12);
      await tap(tester, 'down-${old.id}');
      expect(repository.content.projects[1].id, old.id);
      await search(tester, 'Renamed');
      expect(
        tester
            .widget<IconButton>(find.byKey(ValueKey('up-${old.id}')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stale edits cannot replace newer saved information', (
    tester,
  ) async {
    await start(tester);
    final old = repository.content.projects.first;
    await tap(tester, 'edit-${old.id}');
    await enter(tester, 'project-title', 'Stale edit');
    await repository.projects.update(
      Project.fromJson({...old.toJson(), 'title': 'Newer edit'}),
      expectedRevision: old.revision,
    );
    await tap(tester, 'save-project');
    expect(find.byKey(const ValueKey('project-save-error')), findsOneWidget);
    expect((await repository.projects.get(old.id))!.title, 'Newer edit');
    await tap(tester, 'cancel-project');
    await tap(tester, 'refresh-projects');
    expect(find.text('1. Newer edit'), findsOneWidget);
  });

  testWidgets(
    'load failure retries; empty state and compact dialog are usable',
    (tester) async {
      await start(tester, size: const Size(600, 480));
      repository.readFailure = 'Simulated read failure';
      await tap(tester, 'refresh-projects');
      expect(find.text('Projects could not be loaded'), findsOneWidget);
      repository.readFailure = null;
      repository.saveProjects([]);
      await tap(tester, 'refresh-projects');
      expect(find.text('No projects yet'), findsOneWidget);
      await tap(tester, 'add-project');
      await enter(tester, 'project-title', 'Compact project');
      await enter(
        tester,
        'project-description',
        'Created at a small window size.',
      );
      await tap(tester, 'save-project');
      expect(repository.content.projects.single.title, 'Compact project');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Overview updates if navigation changes during an in-flight delete',
    (tester) async {
      await start(tester);
      final completion = Completer<void>();
      repository.beforeDelete = completion.future;
      await tap(tester, 'delete-project-001');
      await tester.tap(find.byKey(const ValueKey('confirm-delete')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('nav-overview')));
      await tester.pumpAndSettle();
      completion.complete();
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);
      expect(repository.content.projects.length, 7);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String text) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}
