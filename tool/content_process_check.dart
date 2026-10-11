import 'package:portfolio_admin_dashboard/repositories/portfolio_repository.dart';

// Content persistence verification in temporary storage across four processes.
import 'dart:io';

import 'package:portfolio_admin_dashboard/data/json_portfolio_store.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_models.dart';
import 'package:portfolio_admin_dashboard/repositories/local_portfolio_repository.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    final directory = await Directory.systemTemp.createTemp(
      'portfolio_content_process_',
    );
    try {
      for (final stage in ['create', 'update', 'delete', 'verify']) {
        final result = await Process.run(Platform.resolvedExecutable, [
          Platform.script.toFilePath(),
          stage,
          directory.path,
        ]);
        if (result.exitCode != 0) {
          throw StateError('$stage failed: ${result.stdout} ${result.stderr}');
        }
        stdout.write(result.stdout);
      }
    } finally {
      await directory.delete(recursive: true);
    }
    return;
  }
  final store = JsonPortfolioStore(Directory(args[1]));
  await store.initialize(
    loadSeed: () => File('assets/seed/portfolio.json').readAsString(),
    loadSeedMedia: (path) => File('assets/seed/media/$path').readAsBytes(),
  );
  final repository = LocalPortfolioRepository(store);
  final content = await repository.read();
  switch (args.first) {
    case 'create':
      await repository.education.create(
        Education.fromJson({
          ...content.education.first.toJson(),
          'id': 'check-education',
          'revision': 0,
          'certificateUrl': 'https://example.com/certificate',
        }),
      );
      await repository.experiences.create(
        Experience.fromJson({
          ...content.experiences[1].toJson(),
          'id': 'check-experience',
          'revision': 0,
        }),
      );
      await repository.skillCategories.create(
        SkillCategory.fromJson({
          ...content.skillCategories.first.toJson(),
          'id': 'check-category',
          'revision': 0,
        }),
      );
      final p = content.profiles.single;
      await repository.profiles.update(
        PersonalProfile.fromJson({
          ...p.toJson(),
          'email': 'check@example.com',
          'bio': 'Persistent biography',
          'socialLinks': [
            ...p.socialLinks.map((s) => s.toJson()),
            SocialLink(
              id: 'check-social',
              revision: 1,
              label: 'Check',
              url: 'https://example.com',
              iconPath: p.socialLinks.first.iconPath,
            ).toJson(),
          ],
        }),
        expectedRevision: p.revision,
      );
      final settings = content.settings.single;
      await repository.settings.update(
        SiteSettings.fromJson({
          ...settings.toJson(),
          'brandName': 'Persistent brand',
        }),
        expectedRevision: settings.revision,
      );
      final section = content.sectionContent.first;
      await repository.sectionContent.update(
        SectionContent.fromJson({
          ...section.toJson(),
          'heading': 'Persistent heading',
        }),
        expectedRevision: section.revision,
      );
      final ordered = await repository.read();
      for (final collection in [
        OrderedCollection.education,
        OrderedCollection.experiences,
        OrderedCollection.skillCategories,
      ]) {
        final records = jsonList(ordered.toJson()[collection.name])
            .map(jsonObject)
            .toList();
        await repository.reorderContent(
          collection,
          records.reversed.map((r) => r['id'] as String).toList(),
          expectedRevisions: {
            for (final r in records) r['id'] as String: r['revision'] as int,
          },
        );
      }
    case 'update':
      check(
        content.education.first.id == 'check-education',
        'Education order lost',
      );
      check(
        content.experiences.first.id == 'check-experience',
        'Experience order lost',
      );
      check(
        content.skillCategories.first.id == 'check-category',
        'Category order lost',
      );
      check(
        content.profiles.single.email == 'check@example.com',
        'Contact lost',
      );
      check(
        content.profiles.single.socialLinks.last.id == 'check-social',
        'Social link lost',
      );
      check(
        content.settings.single.brandName == 'Persistent brand',
        'Settings lost',
      );
      check(
        content.sectionContent.first.heading == 'Persistent heading',
        'Heading lost',
      );
      final e = (await repository.education.get('check-education'))!;
      check(
        e.certificateUrl == 'https://example.com/certificate',
        'Certificate lost',
      );
      await repository.education.update(
        Education.fromJson({
          ...e.toJson(),
          'degree': 'Updated qualification',
          'certificateUrl': null,
        }),
        expectedRevision: e.revision,
      );
      final x = (await repository.experiences.get('check-experience'))!;
      check(x.milestones.single.title == 'Flutter Mentor', 'Milestone lost');
      await repository.experiences.update(
        Experience.fromJson({...x.toJson(), 'role': 'Updated role'}),
        expectedRevision: x.revision,
      );
      final c = (await repository.skillCategories.get('check-category'))!;
      check(c.skills.first.label == 'Flutter', 'Technology lost');
      await repository.skillCategories.update(
        SkillCategory.fromJson({...c.toJson(), 'title': 'Updated category'}),
        expectedRevision: c.revision,
      );
    case 'delete':
      final e = (await repository.education.get('check-education'))!;
      check(
        e.degree == 'Updated qualification' && e.certificateUrl == null,
        'Education update lost',
      );
      await repository.education.delete(e.id, expectedRevision: e.revision);
      final x = (await repository.experiences.get('check-experience'))!;
      check(
        x.role == 'Updated role' && x.milestones.isNotEmpty,
        'Experience update lost',
      );
      await repository.experiences.delete(x.id, expectedRevision: x.revision);
      final c = (await repository.skillCategories.get('check-category'))!;
      check(
        c.title == 'Updated category' && c.skills.length == 3,
        'Skill update lost',
      );
      await repository.skillCategories.delete(
        c.id,
        expectedRevision: c.revision,
      );
      final p = content.profiles.single;
      await repository.profiles.update(
        PersonalProfile.fromJson({
          ...p.toJson(),
          'socialLinks': p.socialLinks
              .where((s) => s.id != 'check-social')
              .map((s) => s.toJson())
              .toList(),
        }),
        expectedRevision: p.revision,
      );
    case 'verify':
      check(
        await repository.education.get('check-education') == null,
        'Education delete lost',
      );
      check(
        await repository.experiences.get('check-experience') == null,
        'Experience delete lost',
      );
      check(
        await repository.skillCategories.get('check-category') == null,
        'Category delete lost',
      );
      check(
        content.profiles.single.socialLinks.length == 3,
        'Social delete lost',
      );
      check(
        content.profiles.single.heroName.startsWith('\t'),
        'Original hero formatting changed',
      );
      check(
        content.projects.length == 8 && content.media.length == 42,
        'Unrelated content changed',
      );
  }
  stdout.writeln(
    'PASS: content ${args.first} across independent process launches',
  );
}
