import 'portfolio_models.dart';

class PortfolioContent {
  final List<Project> projects;
  final List<Article> articles;
  final List<Education> education;
  final List<Experience> experiences;
  final List<SkillCategory> skillCategories;
  final List<PersonalProfile> profiles;
  final List<MediaAsset> media;
  final List<SiteSettings> settings;
  final List<SectionContent> sectionContent;

  PortfolioContent.fromJson(Map<String, dynamic> json)
    : articles = _read(
        {...json, 'articles': json['articles'] ?? <dynamic>[]},
        'articles',
        Article.fromJson,
      ),
      projects = _read(json, 'projects', Project.fromJson),
      education = _read(json, 'education', Education.fromJson),
      experiences = _read(json, 'experiences', Experience.fromJson),
      skillCategories = _read(json, 'skillCategories', SkillCategory.fromJson),
      profiles = _read(json, 'profiles', PersonalProfile.fromJson),
      media = _read(json, 'media', MediaAsset.fromJson),
      settings = _read(json, 'settings', SiteSettings.fromJson),
      sectionContent = _read(json, 'sectionContent', SectionContent.fromJson) {
    if (json.length != (json.containsKey('articles') ? 9 : 8) ||
        (json.containsKey('articles') && json['articles'] == null)) {
      throw const FormatException('Unexpected content collections.');
    }
    if (profiles.length != 1 || settings.length != 1) {
      throw const FormatException(
        'Exactly one profile and settings record are required.',
      );
    }
    final sourcePaths = <String>{};
    final localPaths = <String>{};
    for (final asset in media) {
      if (!safeRelativePath(asset.sourcePath) ||
          !safeRelativePath(asset.localPath) ||
          !asset.localPath.startsWith('media/') ||
          !['image', 'icon', 'document'].contains(asset.kind) ||
          !sourcePaths.add(asset.sourcePath) ||
          !localPaths.add(asset.localPath)) {
        throw const FormatException('Invalid or duplicate media path.');
      }
    }
    void reference(String path) {
      if (!sourcePaths.contains(path)) {
        throw FormatException('Unknown media reference: $path');
      }
    }

    for (final project in projects) {
      project.imagePaths.forEach(reference);
    }
    for (final category in skillCategories) {
      _unique(category.skills);
      for (final skill in category.skills) {
        reference(skill.assetPath);
        if (skill.colorValue < 0 || skill.colorValue > 0xFFFFFFFF) {
          throw const FormatException('Invalid ARGB skill color.');
        }
      }
    }
    for (final experience in experiences) {
      _unique(experience.milestones);
    }
    for (final profile in profiles) {
      reference(profile.photoPath);
      profile.orbitIconPaths.forEach(reference);
      _unique(profile.personalDetails);
      _unique(profile.socialLinks);
      for (final link in profile.socialLinks) {
        reference(link.iconPath);
      }
    }
    for (final item in settings) {
      reference(item.cvPath);
      _unique(item.navigationLabels);
    }
  }

  Map<String, dynamic> toJson() => {
    'articles': articles.map((v) => v.toJson()).toList(),
    'projects': projects.map((v) => v.toJson()).toList(),
    'education': education.map((v) => v.toJson()).toList(),
    'experiences': experiences.map((v) => v.toJson()).toList(),
    'skillCategories': skillCategories.map((v) => v.toJson()).toList(),
    'profiles': profiles.map((v) => v.toJson()).toList(),
    'media': media.map((v) => v.toJson()).toList(),
    'settings': settings.map((v) => v.toJson()).toList(),
    'sectionContent': sectionContent.map((v) => v.toJson()).toList(),
  };
}

List<T> _read<T extends PortfolioRecord>(
  Map<String, dynamic> json,
  String name,
  T Function(Map<String, dynamic>) decode,
) {
  final items = jsonList(json[name]).map((v) => decode(jsonObject(v))).toList();
  _unique(items);
  return List.unmodifiable(items);
}

void _unique(Iterable<PortfolioRecord> items) {
  final ids = <String>{};
  for (final item in items) {
    validateRecord(item);
    if (item.revision < 1 || !ids.add(item.id)) {
      throw const FormatException(
        'Duplicate IDs or invalid persisted revision.',
      );
    }
  }
}

bool safeRelativePath(String path) =>
    path.isNotEmpty &&
    !path.startsWith('/') &&
    !path.contains('\\') &&
    !path.contains(':') &&
    path
        .split('/')
        .every((part) => part.isNotEmpty && part != '.' && part != '..');
