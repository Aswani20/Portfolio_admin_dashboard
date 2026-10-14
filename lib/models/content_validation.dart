import 'portfolio_models.dart';
import 'project_validation.dart';

/// Validation for edited content; loading preserves the original source values.
class ContentValidation {
  static String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
  static String? articleDate(String? value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value ?? '')) {
      return 'Use YYYY-MM-DD.';
    }
    final date = DateTime.tryParse(value!);
    if (date == null || date.toIso8601String().substring(0, 10) != value) {
      return 'Enter a valid calendar date.';
    }
    return null;
  }

  static String? email(String? value) =>
      requiredText(value) ??
      (RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!)
          ? null
          : 'Enter a valid email address.');
  static String? url(String? value) => ProjectValidation.optionalUrl(value);
  static String? color(String? value) =>
      RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(value ?? '')
      ? null
      : 'Use 8 hexadecimal digits: AARRGGBB (for example FF4479A1).';
  static void validate(PortfolioRecord record) {
    void requiredFields(List<String> values) {
      if (values.any((v) => requiredText(v) != null)) {
        throw const FormatException('Required content fields cannot be blank.');
      }
    }

    void checkUrl(String? value) {
      final error = url(value);
      if (error != null) throw FormatException(error);
    }

    switch (record) {
      case Article():
        requiredFields([record.title, record.summary, record.body]);
        final error = articleDate(record.publishedOn);
        if (error != null) throw FormatException(error);
      case Education():
        requiredFields([
          record.degree,
          record.institution,
          record.duration,
          record.location,
        ]);
        checkUrl(record.certificateUrl);
      case Experience():
        requiredFields([
          record.role,
          record.company,
          record.duration,
          record.location,
          ...record.highlights,
        ]);
        for (final item in record.milestones) {
          validate(item);
        }
      case ExperienceMilestone():
        requiredFields([
          record.title,
          record.duration,
          record.type,
          ...record.highlights,
        ]);
      case SkillCategory():
        requiredFields([record.title]);
        for (final item in record.skills) {
          validate(item);
        }
      case Skill():
        requiredFields([record.label, record.assetPath]);
        if (record.colorValue < 0 || record.colorValue > 0xFFFFFFFF) {
          throw const FormatException('Invalid ARGB color.');
        }
      case PersonalProfile():
        requiredFields([
          record.name,
          record.heroName,
          record.heroTitle,
          record.tagline,
          record.bio,
          record.photoPath,
          record.phone,
          record.location,
          record.primaryCtaLabel,
          record.secondaryCtaLabel,
        ]);
        final error = email(record.email);
        if (error != null) throw FormatException(error);
        const sections = [
          'hero',
          'about',
          'skills',
          'projects',
          'education',
          'experience',
          'contact',
        ];
        if (!sections.contains(record.primaryCtaTarget) ||
            !sections.contains(record.secondaryCtaTarget)) {
          throw const FormatException(
            'Choose an existing website section for each button.',
          );
        }
        for (final item in [...record.personalDetails, ...record.socialLinks]) {
          validate(item);
        }
      case PersonalDetail():
        requiredFields([record.icon, record.label, record.value]);
      case SocialLink():
        requiredFields([record.label, record.url, record.iconPath]);
        checkUrl(record.url);
      case SiteSettings():
        requiredFields([
          record.brandName,
          record.appTitle,
          record.browserTitle,
          record.description,
          record.cvPath,
          record.cvLabel,
          record.cvDownloadFilename,
        ]);
        for (final item in record.navigationLabels) {
          validate(item);
        }
      case NavigationLabel():
        requiredFields([record.label]);
      case SectionContent():
        requiredFields([record.heading]);
      default:
        break;
    }
  }
}
