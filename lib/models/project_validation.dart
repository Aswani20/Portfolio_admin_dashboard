import 'portfolio_models.dart';

abstract final class ProjectValidation {
  static String? requiredText(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;

  static String? optionalUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        RegExp(r'\s').hasMatch(value.trim())) {
      return 'Enter a full http:// or https:// URL, or leave blank.';
    }
    return null;
  }

  static void validate(Project project) {
    final error =
        requiredText(project.title, 'Title') ??
        requiredText(project.description, 'Description') ??
        optionalUrl(project.githubUrl) ??
        optionalUrl(project.liveUrl);
    if (error != null) throw FormatException(error);
    if (project.techStack.any((item) => item.trim().isEmpty)) {
      throw const FormatException('Technology labels cannot be blank.');
    }
  }
}
