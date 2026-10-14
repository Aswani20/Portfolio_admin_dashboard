import 'package:portfolio_admin_dashboard/models/content_validation.dart';
import 'package:portfolio_admin_dashboard/models/image_import.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:portfolio_admin_dashboard/models/portfolio_content.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_models.dart';
import 'package:portfolio_admin_dashboard/models/project_validation.dart';
import 'package:portfolio_admin_dashboard/repositories/portfolio_repository.dart';

/// In-memory UI test double. Disk persistence is covered by local_repository_test.
class FixtureRepository implements PortfolioRepository {
  FixtureRepository(this.content);
  PortfolioContent content;
  String? readFailure;
  String? writeFailure;
  String? mediaFailure;
  int mediaReads = 0;
  Uint8List? mediaBytes;
  Future<void>? beforeDelete;
  @override
  Future<PortfolioContent> read() async {
    if (readFailure != null) throw StoreException(readFailure!);
    return content;
  }

  @override
  Future<Uint8List> readMedia(String id) async {
    mediaReads++;
    if (mediaFailure != null) throw StoreException(mediaFailure!);
    return mediaBytes ??
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        );
  }

  @override
  Future<MediaAsset> importImage(
    Uint8List bytes, {
    required String filename,
  }) async {
    ImageInfo.inspect(bytes, decode: true);
    if (writeFailure != null) throw StoreException(writeFailure!);
    final asset = MediaAsset(
      id: 'imported-${content.media.length}',
      revision: 1,
      sourcePath: 'assets/images/imported-${content.media.length}.png',
      localPath: 'media/uploads/imported-${content.media.length}.png',
      kind: 'image',
      label: filename,
    );
    content = PortfolioContent.fromJson({
      ...content.toJson(),
      'media': [...content.media.map((a) => a.toJson()), asset.toJson()],
    });
    return asset;
  }

  @override
  RecordRepository<Project> get projects => _FixtureProjects(this);
  void saveProjects(List<Project> projects) {
    if (writeFailure != null) throw StoreException(writeFailure!);
    content = PortfolioContent.fromJson({
      ...content.toJson(),
      'projects': projects.map((p) => p.toJson()).toList(),
    });
  }

  @override
  Future<void> reorderProjects(
    List<String> ids, {
    required Map<String, int> expectedRevisions,
  }) async {
    final byId = {for (final project in content.projects) project.id: project};
    if (ids.length != byId.length ||
        ids.toSet().length != ids.length ||
        !ids.every(
          (id) =>
              byId.containsKey(id) &&
              byId[id]!.revision == expectedRevisions[id],
        )) {
      throw const ConflictException('Projects changed. Refresh first.');
    }
    saveProjects([
      for (final id in ids)
        Project.fromJson({
          ...byId[id]!.toJson(),
          'revision': byId[id]!.revision + 1,
        }),
    ]);
  }

  @override
  Future<void> reorderContent(
    OrderedCollection collection,
    List<String> ids, {
    required Map<String, int> expectedRevisions,
  }) async {
    if (writeFailure != null) throw StoreException(writeFailure!);
    final document = content.toJson();
    final records = jsonList(document[collection.name])
        .map(jsonObject)
        .toList();
    final byId = {for (final r in records) r['id'] as String: r};
    if (ids.length != records.length ||
        ids.toSet().length != ids.length ||
        expectedRevisions.length != records.length ||
        !ids.every(
          (id) =>
              byId.containsKey(id) &&
              byId[id]!['revision'] == expectedRevisions[id],
        )) {
      throw const ConflictException(
        'Content changed. Refresh before reordering.',
      );
    }
    document[collection.name] = [
      for (final id in ids)
        {...byId[id]!, 'revision': (byId[id]!['revision'] as int) + 1},
    ];
    content = PortfolioContent.fromJson(document);
  }

  @override
  RecordRepository<Article> get articles =>
      _FixtureRecords(this, 'articles', Article.fromJson);
  @override
  RecordRepository<Education> get education =>
      _FixtureRecords(this, 'education', Education.fromJson);
  @override
  RecordRepository<Experience> get experiences =>
      _FixtureRecords(this, 'experiences', Experience.fromJson);
  @override
  RecordRepository<SkillCategory> get skillCategories =>
      _FixtureRecords(this, 'skillCategories', SkillCategory.fromJson);
  @override
  RecordRepository<PersonalProfile> get profiles =>
      _FixtureRecords(this, 'profiles', PersonalProfile.fromJson);
  @override
  RecordRepository<SiteSettings> get settings =>
      _FixtureRecords(this, 'settings', SiteSettings.fromJson);
  @override
  RecordRepository<SectionContent> get sectionContent =>
      _FixtureRecords(this, 'sectionContent', SectionContent.fromJson);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixtureProjects implements RecordRepository<Project> {
  _FixtureProjects(this.owner);
  final FixtureRepository owner;
  @override
  Future<List<Project>> list() async => owner.content.projects;
  @override
  Future<Project?> get(String id) async =>
      owner.content.projects.where((p) => p.id == id).firstOrNull;
  @override
  Future<Project> create(Project record) async {
    ProjectValidation.validate(record);
    if (await get(record.id) != null) {
      throw const ConflictException('Duplicate ID');
    }
    final saved = Project.fromJson({...record.toJson(), 'revision': 1});
    owner.saveProjects([...owner.content.projects, saved]);
    return saved;
  }

  @override
  Future<Project> update(
    Project record, {
    required int expectedRevision,
  }) async {
    ProjectValidation.validate(record);
    final old = await get(record.id);
    if (old == null || old.revision != expectedRevision) {
      throw const ConflictException('Project changed. Refresh before editing.');
    }
    final saved = Project.fromJson({
      ...record.toJson(),
      'revision': expectedRevision + 1,
    });
    owner.saveProjects([
      for (final project in owner.content.projects)
        project.id == saved.id ? saved : project,
    ]);
    return saved;
  }

  @override
  Future<void> delete(String id, {required int expectedRevision}) async {
    await owner.beforeDelete;
    final old = await get(id);
    if (old == null || old.revision != expectedRevision) {
      throw const ConflictException(
        'Project changed. Refresh before deleting.',
      );
    }
    owner.saveProjects(
      owner.content.projects.where((p) => p.id != id).toList(),
    );
  }
}

PortfolioContent fixtureContent() => PortfolioContent.fromJson(
  (jsonDecode(File('assets/seed/portfolio.json').readAsStringSync())
          as Map<String, dynamic>)['content']
      as Map<String, dynamic>,
);
Future<PortfolioRepository> openFixture() async =>
    FixtureRepository(fixtureContent());

class _FixtureRecords<T extends PortfolioRecord>
    implements RecordRepository<T> {
  _FixtureRecords(this.owner, this.collection, this.decode);
  final FixtureRepository owner;
  final String collection;
  final T Function(Map<String, dynamic>) decode;
  @override
  Future<List<T>> list() async =>
      jsonList((await owner.read()).toJson()[collection])
          .map((v) => decode(jsonObject(v)))
          .toList();
  @override
  Future<T?> get(String id) async {
    final items = (await list()).where((r) => r.id == id);
    return items.isEmpty ? null : items.single;
  }

  void _commit(List<T> items) {
    if (owner.writeFailure != null) throw StoreException(owner.writeFailure!);
    owner.content = PortfolioContent.fromJson({
      ...owner.content.toJson(),
      collection: items.map((r) => r.toJson()).toList(),
    });
  }

  @override
  Future<T> create(T record) async {
    ContentValidation.validate(record);
    final items = await list();
    final saved = decode({...record.toJson(), 'revision': 1});
    _commit([...items, saved]);
    return saved;
  }

  @override
  Future<T> update(T record, {required int expectedRevision}) async {
    ContentValidation.validate(record);
    final items = await list();
    final i = items.indexWhere((r) => r.id == record.id);
    if (i < 0 || items[i].revision != expectedRevision) {
      throw const ConflictException('Record changed. Reload before saving.');
    }
    final saved = decode({
      ...record.toJson(),
      'revision': expectedRevision + 1,
    });
    items[i] = saved;
    _commit(items);
    return saved;
  }

  @override
  Future<void> delete(String id, {required int expectedRevision}) async {
    final items = await list();
    final i = items.indexWhere((r) => r.id == id);
    if (i < 0 || items[i].revision != expectedRevision) {
      throw const ConflictException('Record changed. Reload before deleting.');
    }
    items.removeAt(i);
    _commit(items);
  }
}
