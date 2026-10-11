import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/main.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_models.dart';

import 'fixture_repository.dart';

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey('field-$key'));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String key, String label) async {
  await tap(tester, 'field-$key');
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  late FixtureRepository repository;
  Future<void> start(
    WidgetTester tester,
    String section, {
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
    await tap(tester, 'nav-$section');
  }

  testWidgets('experience CRUD, nested milestones and multiline highlights', (
    tester,
  ) async {
    await start(tester, 'experience');
    await tap(tester, 'add-experience');
    await tap(tester, 'save-content');
    expect(find.text('This field is required.'), findsWidgets);
    await enter(tester, 'role', 'Developer');
    await enter(tester, 'company', 'Studio');
    await enter(tester, 'duration', '2026 - Present');
    await enter(tester, 'location', 'Remote');
    await tap(tester, 'add-item-highlights');
    await enter(tester, 'highlights-0', 'Line one\nLine two  ');
    await tap(tester, 'add-item-milestones');
    await enter(tester, 'milestones-0-title', 'Team lead');
    await enter(tester, 'milestones-0-duration', 'October 2026');
    await enter(tester, 'milestones-0-type', 'Promotion');
    await tap(tester, 'save-content');
    final saved = repository.content.experiences.last;
    expect(saved.milestones.single.id, isNotEmpty);
    expect(saved.milestones.single.revision, 1);
    expect(saved.highlights, ['Line one\nLine two  ']);
    await tap(tester, 'edit-content-${saved.id}');
    await enter(tester, 'company', 'Updated Studio');
    await tap(tester, 'save-content');
    final edited = repository.content.experiences.last;
    expect(edited.highlights, saved.highlights);
    expect(edited.milestones.single.toJson(), saved.milestones.single.toJson());
    await tap(tester, 'edit-content-${saved.id}');
    await tap(tester, 'remove-milestones-0');
    await tap(tester, 'confirm-remove-item');
    await tap(tester, 'save-content');
    expect(repository.content.experiences.last.milestones, isEmpty);
    await tap(tester, 'delete-content-${saved.id}');
    await tap(tester, 'cancel-content-delete');
    expect(repository.content.experiences.length, 4);
    await tap(tester, 'delete-content-${saved.id}');
    await tap(tester, 'confirm-content-delete');
    expect(repository.content.experiences.length, 3);
    expect(tester.takeException(), isNull);
  });
  testWidgets('skills create/edit/delete retain color, icons and nested IDs', (
    tester,
  ) async {
    await start(tester, 'skills');
    await tap(tester, 'add-skills');
    await enter(tester, 'title', 'New category');
    await tap(tester, 'add-item-skills');
    await enter(tester, 'skills-0-label', 'Tool');
    await choose(tester, 'skills-0-assetPath', 'flutter.svg');
    await enter(tester, 'skills-0-colorValue', 'invalid');
    await tap(tester, 'save-content');
    expect(find.textContaining('Use 8 hexadecimal'), findsOneWidget);
    await enter(tester, 'skills-0-colorValue', 'FFAABBCC');
    await tap(tester, 'field-skills-0-themeAdaptive');
    await tap(tester, 'save-content');
    final category = repository.content.skillCategories.last;
    final skill = category.skills.single;
    expect(skill.colorValue, 0xFFAABBCC);
    expect(skill.themeAdaptive, isTrue);
    await tap(tester, 'edit-content-${category.id}');
    await enter(tester, 'skills-0-label', 'Updated tool');
    await tap(tester, 'save-content');
    expect(repository.content.skillCategories.last.skills.single.id, skill.id);
    expect(
      repository.content.skillCategories.last.skills.single.assetPath,
      skill.assetPath,
    );
    await tap(tester, 'edit-content-${category.id}');
    await tap(tester, 'remove-skills-0');
    await tap(tester, 'confirm-remove-item');
    await tap(tester, 'save-content');
    expect(repository.content.skillCategories.last.skills, isEmpty);
    await tap(tester, 'delete-content-${category.id}');
    await tap(tester, 'confirm-content-delete');
    expect(repository.content.skillCategories.length, 4);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'profile preserves formatting and edits About, contact, details and social links',
    (tester) async {
      await start(tester, 'personal');
      final original = repository.content.profiles.single;
      await tap(tester, 'edit-content-${original.id}');
      await enter(tester, 'bio', 'Updated biography\nSecond paragraph.');
      await enter(tester, 'email', 'invalid');
      await tap(tester, 'save-content');
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      await enter(tester, 'email', 'contact@example.com');
      await tap(tester, 'add-item-personalDetails');
      await enter(tester, 'personalDetails-3-label', 'Location');
      await enter(tester, 'personalDetails-3-value', 'Cairo');
      await choose(tester, 'personalDetails-3-icon', 'location_on_outlined');
      await tap(tester, 'add-item-socialLinks');
      await enter(tester, 'socialLinks-3-label', 'Website');
      await enter(tester, 'socialLinks-3-url', 'https://example.com');
      await choose(tester, 'socialLinks-3-iconPath', 'github.svg');
      await tap(tester, 'save-content');
      final saved = repository.content.profiles.single;
      expect(saved.heroName, original.heroName);
      expect(saved.heroTitle, original.heroTitle);
      expect(saved.orbitIconPaths, original.orbitIconPaths);
      expect(saved.email, 'contact@example.com');
      expect(saved.personalDetails.last.value, 'Cairo');
      expect(saved.socialLinks.last.url, 'https://example.com');
      expect(
        saved.personalDetails.first.toJson(),
        original.personalDetails.first.toJson(),
      );
      await tap(tester, 'edit-content-${saved.id}');
      await enter(tester, 'socialLinks-3-label', 'Portfolio link');
      await tap(tester, 'save-content');
      expect(
        repository.content.profiles.single.socialLinks.last.id,
        saved.socialLinks.last.id,
      );
      await tap(tester, 'edit-content-${saved.id}');
      await tap(tester, 'remove-socialLinks-3');
      await tap(tester, 'confirm-remove-item');
      await tap(tester, 'remove-personalDetails-3');
      await tap(tester, 'confirm-remove-item');
      await tap(tester, 'save-content');
      expect(repository.content.profiles.single.socialLinks.length, 3);
      expect(repository.content.profiles.single.personalDetails.length, 3);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('education CRUD and certification links share the same record', (
    tester,
  ) async {
    await start(tester, 'education');
    await tap(tester, 'add-education');
    await enter(tester, 'degree', 'Course');
    await enter(tester, 'institution', 'Academy');
    await enter(tester, 'duration', '2026');
    await enter(tester, 'location', 'Online');
    await tap(tester, 'save-content');
    final saved = repository.content.education.last;
    await tap(tester, 'edit-content-${saved.id}');
    await enter(tester, 'degree', 'Updated course');
    await tap(tester, 'save-content');
    await tap(tester, 'nav-certifications');
    await tap(tester, 'edit-content-${saved.id}');
    await enter(tester, 'certificateUrl', 'javascript:alert(1)');
    await tap(tester, 'save-content');
    expect(repository.content.education.last.certificateUrl, isNull);
    await enter(tester, 'certificateUrl', 'https://example.com/certificate');
    await tap(tester, 'save-content');
    expect(repository.content.education.last.degree, 'Updated course');
    expect(
      repository.content.education.last.certificateUrl,
      'https://example.com/certificate',
    );
    await tap(tester, 'delete-content-${saved.id}');
    await tap(tester, 'confirm-content-delete');
    expect(repository.content.education.last.certificateUrl, isNull);
    expect(repository.content.education.length, 6);
    await tap(tester, 'nav-education');
    await tap(tester, 'delete-content-${saved.id}');
    await tap(tester, 'confirm-content-delete');
    expect(repository.content.education.length, 5);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'settings/navigation and section headings preserve untouched fields',
    (tester) async {
      await start(tester, 'settings');
      final original = repository.content.settings.single;
      await tap(tester, 'edit-content-${original.id}');
      await enter(tester, 'brandName', 'My brand');
      await enter(tester, 'navigationLabels-0-label', 'Welcome');
      await tap(tester, 'save-content');
      final saved = repository.content.settings.single;
      expect(saved.cvDownloadFilename, original.cvDownloadFilename);
      expect(saved.cvPath, original.cvPath);
      expect(saved.navigationLabels.first.id, 'hero');
      expect(saved.navigationLabels.first.label, 'Welcome');
      expect(
        saved.navigationLabels.skip(1).map((e) => e.toJson()).toList(),
        original.navigationLabels.skip(1).map((e) => e.toJson()).toList(),
      );
      await tap(tester, 'edit-content-about');
      await enter(tester, 'heading', 'About my work');
      await tap(tester, 'save-content');
      expect(repository.content.sectionContent.first.heading, 'About my work');
      expect(repository.content.sectionContent.first.subtitle, '');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('load/save errors, conflicts, cancel and compact empty states', (
    tester,
  ) async {
    await start(tester, 'education', size: const Size(600, 480));
    final original = repository.content.education.first;
    repository.readFailure = 'Cannot load';
    await tap(tester, 'refresh-content');
    expect(find.text('Cannot load'), findsOneWidget);
    repository.readFailure = null;
    await tap(tester, 'refresh-content');
    await tap(tester, 'edit-content-${original.id}');
    repository.writeFailure = 'Disk full';
    await enter(tester, 'degree', 'Unsaved');
    await tap(tester, 'save-content');
    expect(find.text('Disk full'), findsOneWidget);
    expect(repository.content.education.first.degree, original.degree);
    repository.writeFailure = null;
    await repository.education.update(
      Education.fromJson({...original.toJson(), 'degree': 'Newer edit'}),
      expectedRevision: original.revision,
    );
    await tap(tester, 'save-content');
    expect(find.textContaining('Record changed.'), findsOneWidget);
    await tap(tester, 'cancel-content');
    expect(repository.content.education.first.degree, 'Newer edit');
    for (final e in [...repository.content.education]) {
      await repository.education.delete(e.id, expectedRevision: e.revision);
    }
    await tap(tester, 'refresh-content');
    expect(
      find.text('No education records yet. Add your first qualification.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
