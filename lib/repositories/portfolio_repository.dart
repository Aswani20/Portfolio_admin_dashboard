import '../models/portfolio_content.dart';
import '../models/portfolio_models.dart';
import 'media_repository.dart';

/// Updates and deletes require the revision that the caller last read.
abstract interface class RecordRepository<T extends PortfolioRecord> {
  Future<List<T>> list();
  Future<T?> get(String id);
  Future<T> create(T record);
  Future<T> update(T record, {required int expectedRevision});
  Future<void> delete(String id, {required int expectedRevision});
}

enum OrderedCollection { projects, education, experiences, skillCategories }

abstract interface class PortfolioRepository implements MediaRepository {
  Future<PortfolioContent> read();

  /// Export a consistent snapshot, optionally including available media bytes.
  Future<String> exportData({bool includeMedia = false});

  /// Replace only the reviewed snapshot; returns the automatic backup path.
  Future<String> replaceData(
    String document, {
    required String expectedFingerprint,
  });

  /// Reorders a complete existing collection under the same revision checks.
  Future<void> reorderContent(
    OrderedCollection collection,
    List<String> ids, {
    required Map<String, int> expectedRevisions,
  });

  /// Atomically reorders the complete project list, rejecting stale snapshots.
  Future<void> reorderProjects(
    List<String> ids, {
    required Map<String, int> expectedRevisions,
  });
  RecordRepository<Project> get projects;
  RecordRepository<Education> get education;
  RecordRepository<Experience> get experiences;
  RecordRepository<SkillCategory> get skillCategories;
  RecordRepository<PersonalProfile> get profiles;
  RecordRepository<MediaAsset> get media;
  RecordRepository<SiteSettings> get settings;
  RecordRepository<SectionContent> get sectionContent;
}

class RepositoryException implements Exception {
  const RepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}

class StoreException extends RepositoryException {
  const StoreException(super.message);
}

class ConflictException extends RepositoryException {
  const ConflictException(super.message);
}

class RecordNotFoundException extends RepositoryException {
  const RecordNotFoundException(super.message);
}
