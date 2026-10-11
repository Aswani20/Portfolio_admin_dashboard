import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:portfolio_admin_dashboard/main.dart';
import 'package:portfolio_admin_dashboard/pages/media/media_library.dart';
import 'package:portfolio_admin_dashboard/pages/projects/project_image.dart';
import 'package:portfolio_admin_dashboard/services/image_selection.dart';

import 'fixture_repository.dart';

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late FixtureRepository repository;
  setUp(() {
    repository = FixtureRepository(fixtureContent());
  });
  Future<void> library(
    WidgetTester tester, {
    ImageFilePicker? picker,
    bool selection = false,
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MediaLibrary(
              repository: repository,
              picker: picker ?? () async => [],
              selection: selection,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'selected file imports with dimensions, thumbnail preview and success feedback',
    (tester) async {
      final bytes = img.encodePng(img.Image(width: 4, height: 3));
      repository.mediaBytes = bytes;
      await library(
        tester,
        picker: () async => [
          XFile.fromData(bytes, name: 'chosen.png', path: 'chosen.png'),
        ],
      );
      await tap(tester, 'import-images');
      expect(repository.content.media.length, 43);
      expect(find.byKey(const ValueKey('media-notice')), findsOneWidget);
      expect(find.text('chosen.png'), findsOneWidget);
      expect(find.textContaining('4 × 3'), findsWidgets);
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'cancel and selection failure preserve content; invalid file reports error',
    (tester) async {
      var calls = 0;
      await library(
        tester,
        picker: () async {
          calls++;
          if (calls == 1) return [];
          if (calls == 2) throw StateError('Picker unavailable');
          return [
            XFile.fromData(
              Uint8List.fromList([1, 2]),
              name: 'bad.png',
              path: 'bad.png',
            ),
          ];
        },
      );
      await tap(tester, 'import-images');
      expect(repository.content.media.length, 42);
      expect(find.byKey(const ValueKey('media-error')), findsNothing);
      await tap(tester, 'import-images');
      expect(find.textContaining('Picker unavailable'), findsOneWidget);
      await tap(tester, 'import-images');
      expect(find.textContaining('bad.png'), findsOneWidget);
      expect(repository.content.media.length, 42);
    },
  );
  testWidgets(
    'missing file is visible, unselectable, and project preview falls back',
    (tester) async {
      repository.mediaFailure = 'Missing file';
      await library(tester, selection: true);
      expect(find.text('Missing or unreadable file'), findsWidgets);
      final asset = repository.content.media.firstWhere(
        (a) => a.kind == 'image',
      );
      expect(
        tester
            .widget<TextButton>(
              find.byKey(ValueKey('select-media-${asset.id}')),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectImage(
            repository: repository,
            media: repository.content.media,
            path: asset.sourcePath,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'invalid image bytes show fallback without an uncaught rendering error',
    (tester) async {
      repository.mediaBytes = Uint8List.fromList([0, 1, 2]);
      await library(tester, selection: true);
      expect(find.text('Missing or unreadable file'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'project thumbnail selection, replacement, multiple screenshots and removal save correctly',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        PortfolioAdminDashboardApp(openRepository: () async => repository),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'nav-projects');
      final before = repository.content.projects.last;
      final assets = repository.content.media
          .where(
            (a) =>
                a.kind == 'image' && !before.imagePaths.contains(a.sourcePath),
          )
          .take(4)
          .toList();
      await tap(tester, 'edit-${before.id}');
      await tap(tester, 'choose-project-cover');
      await tap(tester, 'select-media-${assets[0].id}');
      await tap(tester, 'use-images');
      await tap(tester, 'replace-image-0');
      await tap(tester, 'select-media-${assets[1].id}');
      await tap(tester, 'use-images');
      await tap(tester, 'browse-project-media');
      await tap(tester, 'select-media-${assets[2].id}');
      await tap(tester, 'select-media-${assets[3].id}');
      await tap(tester, 'use-images');
      await tap(tester, 'remove-image-1');
      await tap(tester, 'save-project');
      final saved = await repository.projects.get(before.id);
      expect(saved!.imagePaths, [
        assets[1].sourcePath,
        ...before.imagePaths.skip(1),
        assets[2].sourcePath,
        assets[3].sourcePath,
      ]);
      expect(saved.description, before.description);
      expect(saved.githubUrl, before.githubUrl);
      expect(saved.techStack, before.techStack);
      expect(repository.content.media.length, 42);
      expect(tester.takeException(), isNull);
    },
  );
}
