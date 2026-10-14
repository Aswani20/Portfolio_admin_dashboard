import '../models/content_validation.dart';
import '../models/project_validation.dart';

import 'dart:typed_data';

import '../data/json_portfolio_store.dart';
import '../models/portfolio_content.dart';
import '../models/portfolio_models.dart';
import 'portfolio_repository.dart';

class LocalPortfolioRepository implements PortfolioRepository {
  LocalPortfolioRepository(this._store);
  final JsonPortfolioStore _store;
  @override
  Future<String> exportData({bool includeMedia = false}) =>
      _store.exportData(includeMedia: includeMedia);
  @override
  Future<String> replaceData(
    String document, {
    required String expectedFingerprint,
  }) => _store.replaceData(document, expectedFingerprint: expectedFingerprint);
  @override
  Future<void> reorderProjects(
    List<String> ids, {
    required Map<String, int> expectedRevisions,
  }) => reorderContent(
    OrderedCollection.projects,
    ids,
    expectedRevisions: expectedRevisions,
  );
  @override
  Future<void> reorderContent(
    OrderedCollection collection,
    List<String> ids, {
    required Map<String, int> expectedRevisions,
  }) => _store.change((content) {
    final records = jsonList(content[collection.name]).map(jsonObject).toList();
    final byId = {for (final record in records) record['id'] as String: record};
    if (ids.length != records.length ||
        ids.toSet().length != ids.length ||
        expectedRevisions.length != records.length ||
        !ids.every(
          (id) =>
              byId.containsKey(id) &&
              expectedRevisions[id] == byId[id]!['revision'],
        )) {
      throw const ConflictException(
        'Content changed. Refresh before changing display order.',
      );
    }
    content[collection.name] = [
      for (final id in ids)
        {...byId[id]!, 'revision': (byId[id]!['revision'] as int) + 1},
    ];
  });
  @override
  Future<PortfolioContent> read() => _store.read();
  @override
  Future<MediaAsset> importImage(Uint8List bytes, {required String filename}) =>
      _store.importImage(bytes, filename: filename);
  @override
  Future<Uint8List> readMedia(String id) => _store.readMedia(id);
  @override
  RecordRepository<Article> get articles =>
      _records('articles', Article.fromJson);
  @override
  RecordRepository<Project> get projects =>
      _records('projects', Project.fromJson);
  @override
  RecordRepository<Education> get education =>
      _records('education', Education.fromJson);
  @override
  RecordRepository<Experience> get experiences =>
      _records('experiences', Experience.fromJson);
  @override
  RecordRepository<SkillCategory> get skillCategories =>
      _records('skillCategories', SkillCategory.fromJson);
  @override
  RecordRepository<PersonalProfile> get profiles =>
      _records('profiles', PersonalProfile.fromJson);
  @override
  RecordRepository<MediaAsset> get media =>
      _records('media', MediaAsset.fromJson);
  @override
  RecordRepository<SiteSettings> get settings =>
      _records('settings', SiteSettings.fromJson);
  @override
  RecordRepository<SectionContent> get sectionContent =>
      _records('sectionContent', SectionContent.fromJson);

  RecordRepository<T> _records<T extends PortfolioRecord>(
    String collection,
    T Function(Map<String, dynamic>) decode,
  ) => _LocalRecords<T>(_store, collection, decode);
}

class _LocalRecords<T extends PortfolioRecord> implements RecordRepository<T> {
  _LocalRecords(this.store, this.collection, this.decode);
  final JsonPortfolioStore store;
  final String collection;
  final T Function(Map<String, dynamic>) decode;

  @override
  Future<List<T>> list() async {
    final content = await store.read();
    return List.unmodifiable(
      jsonList(content.toJson()[collection]).map((v) => decode(jsonObject(v))),
    );
  }

  @override
  Future<T?> get(String id) async {
    final matches = (await list()).where((v) => v.id == id);
    return matches.isEmpty ? null : matches.single;
  }

  @override
  Future<T> create(T record) => store.change((content) {
    validateRecord(record);
    _validateContent(record);
    if (record.revision != 0) {
      throw const ConflictException('New records must have revision 0.');
    }
    final records = jsonList(content[collection]);
    if (records.any((v) => jsonObject(v)['id'] == record.id)) {
      throw ConflictException('Record ${record.id} already exists.');
    }
    final persisted = decode({...record.toJson(), 'revision': 1});
    records.add(persisted.toJson());
    return persisted;
  });
  @override
  Future<T> update(T record, {required int expectedRevision}) =>
      store.change((content) {
        _validateContent(record);
        final records = jsonList(content[collection]);
        final index = _find(records, record.id, expectedRevision);
        if (record.revision != expectedRevision) {
          throw const ConflictException(
            'Record and expected revision differ. Reload before updating.',
          );
        }
        final persisted = decode({
          ...record.toJson(),
          'revision': expectedRevision + 1,
        });
        records[index] = persisted.toJson();
        return persisted;
      });
  @override
  Future<void> delete(String id, {required int expectedRevision}) =>
      store.change((content) {
        final records = jsonList(content[collection]);
        records.removeAt(_find(records, id, expectedRevision));
      });
  int _find(List<dynamic> records, String id, int expectedRevision) {
    final index = records.indexWhere((v) => jsonObject(v)['id'] == id);
    if (index == -1) throw RecordNotFoundException('Record $id was not found.');
    if (jsonObject(records[index])['revision'] != expectedRevision) {
      throw ConflictException(
        'Record $id changed. Reload it before saving or deleting.',
      );
    }
    return index;
  }
}

void _validateContent(PortfolioRecord record) {
  try {
    if (record is Project) {
      ProjectValidation.validate(record);
    }
    ContentValidation.validate(record);
  } on FormatException catch (error) {
    throw RepositoryException(error.message);
  }
}
