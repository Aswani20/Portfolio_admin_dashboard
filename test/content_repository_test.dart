import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/data/json_portfolio_store.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_models.dart';
import 'package:portfolio_admin_dashboard/repositories/local_portfolio_repository.dart';
import 'package:portfolio_admin_dashboard/repositories/portfolio_repository.dart';

void main() {
  late Directory directory;
  late LocalPortfolioRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'content_repository_test_',
    );
    final store = JsonPortfolioStore(directory);
    await store.initialize(
      loadSeed: () => File('assets/seed/portfolio.json').readAsString(),
      loadSeedMedia: (_) async => Uint8List.fromList([1]),
    );
    repository = LocalPortfolioRepository(store);
  });
  tearDown(() async => directory.delete(recursive: true));
  LocalPortfolioRepository reopen() =>
      LocalPortfolioRepository(JsonPortfolioStore(directory));
  test('experience milestones/highlights survive edits and restart; CRUD remains revision protected', () async {
    final original = (await repository.experiences.list())[1];
    final saved = await repository.experiences.create(
      Experience.fromJson({
        ...original.toJson(),
        'id': 'new-experience',
        'revision': 0,
      }),
    );
    final updated = await repository.experiences.update(
      Experience.fromJson({...saved.toJson(), 'company': 'New company'}),
      expectedRevision: saved.revision,
    );
    expect(
      (await reopen().experiences.get(saved.id))!.milestones
          .map((m) => m.toJson())
          .toList(),
      original.milestones.map((m) => m.toJson()).toList(),
    );
    expect(
      (await reopen().experiences.get(saved.id))!.highlights,
      original.highlights,
    );
    await expectLater(
      repository.experiences.delete(saved.id, expectedRevision: saved.revision),
      throwsA(isA<ConflictException>()),
    );
    await repository.experiences.delete(
      updated.id,
      expectedRevision: updated.revision,
    );
    expect(await reopen().experiences.get(saved.id), isNull);
  });
  test('skills and education with certificates retain nested values across CRUD and restart', () async {
    final c = (await repository.read());
    final category = await repository.skillCategories.create(
      SkillCategory.fromJson({
        ...c.skillCategories.first.toJson(),
        'id': 'new-category',
        'revision': 0,
      }),
    );
    final edited = await repository.skillCategories.update(
      SkillCategory.fromJson({
        ...category.toJson(),
        'title': 'Updated category',
      }),
      expectedRevision: 1,
    );
    expect(
      (await reopen().skillCategories.get(category.id))!.skills
          .map((s) => s.toJson())
          .toList(),
      category.skills.map((s) => s.toJson()).toList(),
    );
    final education = await repository.education.create(
      Education.fromJson({
        ...c.education.first.toJson(),
        'id': 'new-education',
        'revision': 0,
      }),
    );
    final certified = await repository.education.update(
      Education.fromJson({
        ...education.toJson(),
        'certificateUrl': 'https://example.com/certificate',
      }),
      expectedRevision: 1,
    );
    expect(
      (await reopen().education.get(education.id))!.certificateUrl,
      'https://example.com/certificate',
    );
    final cleared = await repository.education.update(
      Education.fromJson({...certified.toJson(), 'certificateUrl': null}),
      expectedRevision: certified.revision,
    );
    expect(
      (await reopen().education.get(education.id))!.degree,
      education.degree,
    );
    expect(
      (await reopen().education.get(education.id))!.certificateUrl,
      isNull,
    );
    await repository.education.delete(
      education.id,
      expectedRevision: cleared.revision,
    );
    await repository.skillCategories.delete(
      category.id,
      expectedRevision: edited.revision,
    );
    expect(await reopen().education.get(education.id), isNull);
    expect(await reopen().skillCategories.get(category.id), isNull);
  });
  test('profile/contact/social, settings/navigation and heading updates retain all unrelated fields', () async {
    final before = await repository.read();
    final original = before.profiles.single;
    final profile = PersonalProfile.fromJson({
      ...original.toJson(),
      'bio': 'New biography\nExact formatting  ',
      'email': 'new@example.com',
      'socialLinks': [
        ...original.socialLinks.map((l) => l.toJson()),
        SocialLink(
          id: 'new-social',
          revision: 1,
          label: 'Website',
          url: 'https://example.com',
          iconPath: original.socialLinks.first.iconPath,
        ).toJson(),
      ],
    });
    final saved = await repository.profiles.update(
      profile,
      expectedRevision: original.revision,
    );
    final reopened = (await reopen().read()).profiles.single;
    expect(reopened.toJson(), saved.toJson());
    expect(reopened.heroName, original.heroName);
    expect(reopened.heroTitle, original.heroTitle);
    expect(
      reopened.personalDetails.map((d) => d.toJson()).toList(),
      original.personalDetails.map((d) => d.toJson()).toList(),
    );
    final settings = before.settings.single;
    await repository.settings.update(
      SiteSettings.fromJson({...settings.toJson(), 'brandName': 'Brand'}),
      expectedRevision: settings.revision,
    );
    final section = before.sectionContent.first;
    await repository.sectionContent.update(
      SectionContent.fromJson({...section.toJson(), 'heading': 'Heading'}),
      expectedRevision: section.revision,
    );
    final result = await reopen().read();
    expect(
      result.settings.single.cvDownloadFilename,
      settings.cvDownloadFilename,
    );
    expect(
      result.settings.single.navigationLabels.map((n) => n.toJson()).toList(),
      settings.navigationLabels.map((n) => n.toJson()).toList(),
    );
    expect(result.sectionContent.first.heading, 'Heading');
    expect(result.sectionContent.first.subtitle, section.subtitle);
    expect(
      result.projects.map((p) => p.toJson()).toList(),
      before.projects.map((p) => p.toJson()).toList(),
    );
  });
  test('repository rejects required-field, URL, nested and relationship errors without committing', () async {
    final before = await repository.read();
    final education = before.education.first;
    for (final patch in [
      {'degree': '  '},
      {'certificateUrl': 'javascript:alert(1)'},
    ]) {
      await expectLater(
        repository.education.update(
          Education.fromJson({...education.toJson(), ...patch}),
          expectedRevision: education.revision,
        ),
        throwsA(isA<RepositoryException>()),
      );
    }
    final category = before.skillCategories.first;
    await expectLater(
      repository.skillCategories.update(
        SkillCategory.fromJson({
          ...category.toJson(),
          'skills': [
            {...category.skills.first.toJson(), 'label': ''},
          ],
        }),
        expectedRevision: category.revision,
      ),
      throwsA(isA<RepositoryException>()),
    );
    final profile = before.profiles.single;
    for (final patch in [
      {'email': 'invalid'},
      {'primaryCtaTarget': 'missing-section'},
      {'photoPath': 'assets/missing.png'},
    ]) {
      await expectLater(
        repository.profiles.update(
          PersonalProfile.fromJson({...profile.toJson(), ...patch}),
          expectedRevision: profile.revision,
        ),
        throwsA(isA<RepositoryException>()),
      );
    }
    await expectLater(
      repository.profiles.delete(
        profile.id,
        expectedRevision: profile.revision,
      ),
      throwsA(isA<RepositoryException>()),
    );
    expect((await reopen().read()).toJson(), before.toJson());
  });
  for (final collection in [
    OrderedCollection.education,
    OrderedCollection.experiences,
    OrderedCollection.skillCategories,
  ]) {
    test(
      '${collection.name} ordering is atomic, persists and rejects stale/partial orders',
      () async {
        final before = await repository.read();
        final rows = jsonList(before.toJson()[collection.name])
            .map(jsonObject)
            .toList();
        final ids = rows.reversed.map((r) => r['id'] as String).toList();
        final revisions = {
          for (final row in rows) row['id'] as String: row['revision'] as int,
        };
        await repository.reorderContent(
          collection,
          ids,
          expectedRevisions: revisions,
        );
        final after = await reopen().read();
        final saved = jsonList(after.toJson()[collection.name])
            .map(jsonObject)
            .toList();
        expect(
          saved,
          rows.reversed
              .map((r) => {...r, 'revision': (r['revision'] as int) + 1})
              .toList(),
        );
        for (final key in before.toJson().keys.where(
          (key) => key != collection.name,
        )) {
          expect(after.toJson()[key], before.toJson()[key]);
        }
        await expectLater(
          repository.reorderContent(
            collection,
            ids.reversed.toList(),
            expectedRevisions: revisions,
          ),
          throwsA(isA<ConflictException>()),
        );
        final fresh = {
          for (final row in saved) row['id'] as String: row['revision'] as int,
        };
        await expectLater(
          repository.reorderContent(
            collection,
            ids.skip(1).toList(),
            expectedRevisions: fresh,
          ),
          throwsA(isA<ConflictException>()),
        );
        await expectLater(
          repository.reorderContent(
            collection,
            List.filled(ids.length, ids.first),
            expectedRevisions: fresh,
          ),
          throwsA(isA<ConflictException>()),
        );
        expect((await reopen().read()).toJson(), after.toJson());
      },
    );
  }
}
