// Domain models contain no Flutter or file-system dependencies.
abstract interface class PortfolioRecord {
  String get id;
  int get revision;
  Map<String, dynamic> toJson();
}

Map<String, dynamic> jsonObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected JSON object.');
  }
  return value;
}

List<dynamic> jsonList(Object? value) {
  if (value is! List) throw const FormatException('Expected JSON list.');
  return value;
}

T _field<T>(Map<String, dynamic> json, String name) {
  if (!json.containsKey(name) || json[name] is! T) {
    throw FormatException('Invalid or missing field: $name');
  }
  return json[name] as T;
}

void _keys(Map<String, dynamic> json, List<String> expected) {
  if (json.length != expected.length || !expected.every(json.containsKey)) {
    throw const FormatException('Unexpected or missing model fields.');
  }
}

void validateRecord(PortfolioRecord record) {
  if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]{0,127}$').hasMatch(record.id) ||
      record.revision < 0) {
    throw const FormatException('Record ID or revision is invalid.');
  }
}

class Project implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String title;
  final String description;
  final List<String> imagePaths;
  final List<String> techStack;
  final String? liveUrl;
  final String? githubUrl;
  Project({
    required this.id,
    this.revision = 0,
    required this.title,
    required this.description,
    required List<String> imagePaths,
    required List<String> techStack,
    required this.liveUrl,
    required this.githubUrl,
  }) : imagePaths = List.unmodifiable(imagePaths),
       techStack = List.unmodifiable(techStack);
  factory Project.fromJson(Map<String, dynamic> json) {
    _keys(json, [
      'id',
      'revision',
      'title',
      'description',
      'imagePaths',
      'techStack',
      'liveUrl',
      'githubUrl',
    ]);
    final record = Project(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      title: _field<String>(json, 'title'),
      description: _field<String>(json, 'description'),
      imagePaths: jsonList(json['imagePaths']).map((v) {
        if (v is! String) throw const FormatException('Expected string list.');
        return v;
      }).toList(),
      techStack: jsonList(json['techStack']).map((v) {
        if (v is! String) throw const FormatException('Expected string list.');
        return v;
      }).toList(),
      liveUrl: _field<String?>(json, 'liveUrl'),
      githubUrl: _field<String?>(json, 'githubUrl'),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'title': title,
    'description': description,
    'imagePaths': List<String>.of(imagePaths),
    'techStack': List<String>.of(techStack),
    'liveUrl': liveUrl,
    'githubUrl': githubUrl,
  };
}

class Education implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String degree;
  final String institution;
  final String duration;
  final String location;
  final bool isCurrent;
  final String? certificateUrl;
  Education({
    required this.id,
    this.revision = 0,
    required this.degree,
    required this.institution,
    required this.duration,
    required this.location,
    required this.isCurrent,
    required this.certificateUrl,
  });
  factory Education.fromJson(Map<String, dynamic> json) {
    _keys(json, [
      'id',
      'revision',
      'degree',
      'institution',
      'duration',
      'location',
      'isCurrent',
      'certificateUrl',
    ]);
    final record = Education(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      degree: _field<String>(json, 'degree'),
      institution: _field<String>(json, 'institution'),
      duration: _field<String>(json, 'duration'),
      location: _field<String>(json, 'location'),
      isCurrent: _field<bool>(json, 'isCurrent'),
      certificateUrl: _field<String?>(json, 'certificateUrl'),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'degree': degree,
    'institution': institution,
    'duration': duration,
    'location': location,
    'isCurrent': isCurrent,
    'certificateUrl': certificateUrl,
  };
}

class ExperienceMilestone implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String title;
  final String duration;
  final String type;
  final List<String> highlights;
  ExperienceMilestone({
    required this.id,
    this.revision = 0,
    required this.title,
    required this.duration,
    required this.type,
    required List<String> highlights,
  }) : highlights = List.unmodifiable(highlights);
  factory ExperienceMilestone.fromJson(Map<String, dynamic> json) {
    _keys(json, ['id', 'revision', 'title', 'duration', 'type', 'highlights']);
    final record = ExperienceMilestone(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      title: _field<String>(json, 'title'),
      duration: _field<String>(json, 'duration'),
      type: _field<String>(json, 'type'),
      highlights: jsonList(json['highlights']).map((v) {
        if (v is! String) throw const FormatException('Expected string list.');
        return v;
      }).toList(),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'title': title,
    'duration': duration,
    'type': type,
    'highlights': List<String>.of(highlights),
  };
}

class Experience implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String role;
  final String company;
  final String duration;
  final String location;
  final List<String> highlights;
  final List<ExperienceMilestone> milestones;
  final bool isCurrent;
  Experience({
    required this.id,
    this.revision = 0,
    required this.role,
    required this.company,
    required this.duration,
    required this.location,
    required List<String> highlights,
    required List<ExperienceMilestone> milestones,
    required this.isCurrent,
  }) : highlights = List.unmodifiable(highlights),
       milestones = List.unmodifiable(milestones);
  factory Experience.fromJson(Map<String, dynamic> json) {
    _keys(json, [
      'id',
      'revision',
      'role',
      'company',
      'duration',
      'location',
      'highlights',
      'milestones',
      'isCurrent',
    ]);
    final record = Experience(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      role: _field<String>(json, 'role'),
      company: _field<String>(json, 'company'),
      duration: _field<String>(json, 'duration'),
      location: _field<String>(json, 'location'),
      highlights: jsonList(json['highlights']).map((v) {
        if (v is! String) throw const FormatException('Expected string list.');
        return v;
      }).toList(),
      milestones: jsonList(json['milestones'])
          .map((v) => ExperienceMilestone.fromJson(jsonObject(v)))
          .toList(),
      isCurrent: _field<bool>(json, 'isCurrent'),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'role': role,
    'company': company,
    'duration': duration,
    'location': location,
    'highlights': List<String>.of(highlights),
    'milestones': milestones.map((v) => v.toJson()).toList(),
    'isCurrent': isCurrent,
  };
}

class Skill implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String label;
  final String assetPath;
  final int colorValue;
  final bool themeAdaptive;
  Skill({
    required this.id,
    this.revision = 0,
    required this.label,
    required this.assetPath,
    required this.colorValue,
    required this.themeAdaptive,
  });
  factory Skill.fromJson(Map<String, dynamic> json) {
    _keys(json, [
      'id',
      'revision',
      'label',
      'assetPath',
      'colorValue',
      'themeAdaptive',
    ]);
    final record = Skill(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      label: _field<String>(json, 'label'),
      assetPath: _field<String>(json, 'assetPath'),
      colorValue: _field<int>(json, 'colorValue'),
      themeAdaptive: _field<bool>(json, 'themeAdaptive'),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'label': label,
    'assetPath': assetPath,
    'colorValue': colorValue,
    'themeAdaptive': themeAdaptive,
  };
}

class SkillCategory implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String title;
  final List<Skill> skills;
  SkillCategory({
    required this.id,
    this.revision = 0,
    required this.title,
    required List<Skill> skills,
  }) : skills = List.unmodifiable(skills);
  factory SkillCategory.fromJson(Map<String, dynamic> json) {
    _keys(json, ['id', 'revision', 'title', 'skills']);
    final record = SkillCategory(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      title: _field<String>(json, 'title'),
      skills: jsonList(json['skills'])
          .map((v) => Skill.fromJson(jsonObject(v)))
          .toList(),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'title': title,
    'skills': skills.map((v) => v.toJson()).toList(),
  };
}

class PersonalDetail implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String icon;
  final String label;
  final String value;
  PersonalDetail({
    required this.id,
    this.revision = 0,
    required this.icon,
    required this.label,
    required this.value,
  });
  factory PersonalDetail.fromJson(Map<String, dynamic> json) {
    _keys(json, ['id', 'revision', 'icon', 'label', 'value']);
    final record = PersonalDetail(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      icon: _field<String>(json, 'icon'),
      label: _field<String>(json, 'label'),
      value: _field<String>(json, 'value'),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'icon': icon,
    'label': label,
    'value': value,
  };
}

class SocialLink implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String label;
  final String url;
  final String iconPath;
  SocialLink({
    required this.id,
    this.revision = 0,
    required this.label,
    required this.url,
    required this.iconPath,
  });
  factory SocialLink.fromJson(Map<String, dynamic> json) {
    _keys(json, ['id', 'revision', 'label', 'url', 'iconPath']);
    final record = SocialLink(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      label: _field<String>(json, 'label'),
      url: _field<String>(json, 'url'),
      iconPath: _field<String>(json, 'iconPath'),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'label': label,
    'url': url,
    'iconPath': iconPath,
  };
}

class PersonalProfile implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String name;
  final String heroName;
  final String heroTitle;
  final String tagline;
  final String photoPath;
  final String primaryCtaLabel;
  final String primaryCtaTarget;
  final String secondaryCtaLabel;
  final String secondaryCtaTarget;
  final String bio;
  final List<PersonalDetail> personalDetails;
  final String email;
  final String phone;
  final String location;
  final List<SocialLink> socialLinks;
  final List<String> orbitIconPaths;
  PersonalProfile({
    required this.id,
    this.revision = 0,
    required this.name,
    required this.heroName,
    required this.heroTitle,
    required this.tagline,
    required this.photoPath,
    required this.primaryCtaLabel,
    required this.primaryCtaTarget,
    required this.secondaryCtaLabel,
    required this.secondaryCtaTarget,
    required this.bio,
    required List<PersonalDetail> personalDetails,
    required this.email,
    required this.phone,
    required this.location,
    required List<SocialLink> socialLinks,
    required List<String> orbitIconPaths,
  }) : personalDetails = List.unmodifiable(personalDetails),
       socialLinks = List.unmodifiable(socialLinks),
       orbitIconPaths = List.unmodifiable(orbitIconPaths);
  factory PersonalProfile.fromJson(Map<String, dynamic> json) {
    _keys(json, [
      'id',
      'revision',
      'name',
      'heroName',
      'heroTitle',
      'tagline',
      'photoPath',
      'primaryCtaLabel',
      'primaryCtaTarget',
      'secondaryCtaLabel',
      'secondaryCtaTarget',
      'bio',
      'personalDetails',
      'email',
      'phone',
      'location',
      'socialLinks',
      'orbitIconPaths',
    ]);
    final record = PersonalProfile(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      name: _field<String>(json, 'name'),
      heroName: _field<String>(json, 'heroName'),
      heroTitle: _field<String>(json, 'heroTitle'),
      tagline: _field<String>(json, 'tagline'),
      photoPath: _field<String>(json, 'photoPath'),
      primaryCtaLabel: _field<String>(json, 'primaryCtaLabel'),
      primaryCtaTarget: _field<String>(json, 'primaryCtaTarget'),
      secondaryCtaLabel: _field<String>(json, 'secondaryCtaLabel'),
      secondaryCtaTarget: _field<String>(json, 'secondaryCtaTarget'),
      bio: _field<String>(json, 'bio'),
      personalDetails: jsonList(json['personalDetails'])
          .map((v) => PersonalDetail.fromJson(jsonObject(v)))
          .toList(),
      email: _field<String>(json, 'email'),
      phone: _field<String>(json, 'phone'),
      location: _field<String>(json, 'location'),
      socialLinks: jsonList(json['socialLinks'])
          .map((v) => SocialLink.fromJson(jsonObject(v)))
          .toList(),
      orbitIconPaths: jsonList(json['orbitIconPaths']).map((v) {
        if (v is! String) throw const FormatException('Expected string list.');
        return v;
      }).toList(),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'name': name,
    'heroName': heroName,
    'heroTitle': heroTitle,
    'tagline': tagline,
    'photoPath': photoPath,
    'primaryCtaLabel': primaryCtaLabel,
    'primaryCtaTarget': primaryCtaTarget,
    'secondaryCtaLabel': secondaryCtaLabel,
    'secondaryCtaTarget': secondaryCtaTarget,
    'bio': bio,
    'personalDetails': personalDetails.map((v) => v.toJson()).toList(),
    'email': email,
    'phone': phone,
    'location': location,
    'socialLinks': socialLinks.map((v) => v.toJson()).toList(),
    'orbitIconPaths': List<String>.of(orbitIconPaths),
  };
}

class MediaAsset implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String sourcePath;
  final String localPath;
  final String kind;
  final String label;
  MediaAsset({
    required this.id,
    this.revision = 0,
    required this.sourcePath,
    required this.localPath,
    required this.kind,
    required this.label,
  });
  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    _keys(json, ['id', 'revision', 'sourcePath', 'localPath', 'kind', 'label']);
    final record = MediaAsset(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      sourcePath: _field<String>(json, 'sourcePath'),
      localPath: _field<String>(json, 'localPath'),
      kind: _field<String>(json, 'kind'),
      label: _field<String>(json, 'label'),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'sourcePath': sourcePath,
    'localPath': localPath,
    'kind': kind,
    'label': label,
  };
}

class NavigationLabel implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String label;
  NavigationLabel({required this.id, this.revision = 0, required this.label});
  factory NavigationLabel.fromJson(Map<String, dynamic> json) {
    _keys(json, ['id', 'revision', 'label']);
    final record = NavigationLabel(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      label: _field<String>(json, 'label'),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'label': label,
  };
}

class SiteSettings implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String brandName;
  final String brandSuffix;
  final String appTitle;
  final String browserTitle;
  final String description;
  final String cvPath;
  final String cvLabel;
  final String cvDownloadFilename;
  final List<NavigationLabel> navigationLabels;
  SiteSettings({
    required this.id,
    this.revision = 0,
    required this.brandName,
    required this.brandSuffix,
    required this.appTitle,
    required this.browserTitle,
    required this.description,
    required this.cvPath,
    required this.cvLabel,
    required this.cvDownloadFilename,
    required List<NavigationLabel> navigationLabels,
  }) : navigationLabels = List.unmodifiable(navigationLabels);
  factory SiteSettings.fromJson(Map<String, dynamic> json) {
    _keys(json, [
      'id',
      'revision',
      'brandName',
      'brandSuffix',
      'appTitle',
      'browserTitle',
      'description',
      'cvPath',
      'cvLabel',
      'cvDownloadFilename',
      'navigationLabels',
    ]);
    final record = SiteSettings(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      brandName: _field<String>(json, 'brandName'),
      brandSuffix: _field<String>(json, 'brandSuffix'),
      appTitle: _field<String>(json, 'appTitle'),
      browserTitle: _field<String>(json, 'browserTitle'),
      description: _field<String>(json, 'description'),
      cvPath: _field<String>(json, 'cvPath'),
      cvLabel: _field<String>(json, 'cvLabel'),
      cvDownloadFilename: _field<String>(json, 'cvDownloadFilename'),
      navigationLabels: jsonList(json['navigationLabels'])
          .map((v) => NavigationLabel.fromJson(jsonObject(v)))
          .toList(),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'brandName': brandName,
    'brandSuffix': brandSuffix,
    'appTitle': appTitle,
    'browserTitle': browserTitle,
    'description': description,
    'cvPath': cvPath,
    'cvLabel': cvLabel,
    'cvDownloadFilename': cvDownloadFilename,
    'navigationLabels': navigationLabels.map((v) => v.toJson()).toList(),
  };
}

class SectionContent implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String heading;
  final String subtitle;
  SectionContent({
    required this.id,
    this.revision = 0,
    required this.heading,
    required this.subtitle,
  });
  factory SectionContent.fromJson(Map<String, dynamic> json) {
    _keys(json, ['id', 'revision', 'heading', 'subtitle']);
    final record = SectionContent(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      heading: _field<String>(json, 'heading'),
      subtitle: _field<String>(json, 'subtitle'),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'heading': heading,
    'subtitle': subtitle,
  };
}

class Article implements PortfolioRecord {
  @override
  final String id;
  @override
  final int revision;
  final String title, summary, body, publishedOn;
  final bool isPublished;
  const Article({
    required this.id,
    this.revision = 0,
    required this.title,
    required this.summary,
    required this.body,
    required this.publishedOn,
    this.isPublished = false,
  });
  factory Article.fromJson(Map<String, dynamic> json) {
    _keys(json, [
      'id',
      'revision',
      'title',
      'summary',
      'body',
      'publishedOn',
      'isPublished',
    ]);
    final record = Article(
      id: _field<String>(json, 'id'),
      revision: _field<int>(json, 'revision'),
      title: _field<String>(json, 'title'),
      summary: _field<String>(json, 'summary'),
      body: _field<String>(json, 'body'),
      publishedOn: _field<String>(json, 'publishedOn'),
      isPublished: _field<bool>(json, 'isPublished'),
    );
    validateRecord(record);
    return record;
  }
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'title': title,
    'summary': summary,
    'body': body,
    'publishedOn': publishedOn,
    'isPublished': isPublished,
  };
}
