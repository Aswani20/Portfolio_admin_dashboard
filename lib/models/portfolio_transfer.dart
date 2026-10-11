import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'portfolio_content.dart';
import 'content_validation.dart';
import 'project_validation.dart';
import 'portfolio_models.dart';

/// Only allowlisted portfolio fields and referenced media are transferred.
class PortfolioTransfer {
  PortfolioTransfer._(this.content, this.files);
  static const maxBytes = 256 * 1024 * 1024;
  final PortfolioContent content;
  final Map<String, Uint8List> files;

  static String fingerprint(PortfolioContent content) =>
      sha256.convert(utf8.encode(jsonEncode(content.toJson()))).toString();

  static String encode(PortfolioContent content, Map<String, Uint8List> files) {
    final text = const JsonEncoder.withIndent('  ').convert({
      'format': 'portfolio-admin-transfer',
      'schemaVersion': 1,
      'content': content.toJson(),
      'mediaFiles': {
        for (final entry in files.entries)
          entry.key: {
            'sha256': sha256.convert(entry.value).toString(),
            'base64': base64Encode(entry.value),
          },
      },
    });
    if (utf8.encode(text).length > maxBytes) {
      throw const FormatException(
        'Transfer exceeds the 256 MB limit. Use a content-only export or reduce media size.',
      );
    }
    return text;
  }

  factory PortfolioTransfer.decode(String text) {
    if (utf8.encode(text).length > maxBytes) {
      throw const FormatException('Maximum transfer file size is 256 MB.');
    }
    final document = jsonObject(jsonDecode(text));
    if (document.length != 4 ||
        document['format'] != 'portfolio-admin-transfer' ||
        document['schemaVersion'] != 1) {
      throw const FormatException(
        'Unsupported transfer format or schema. Expected portfolio-admin-transfer schema 1 with content and mediaFiles.',
      );
    }
    _checkDuplicates(document['content'], 'content');
    // Typed decoding rejects unknown fields, duplicate IDs and broken references.
    final content = PortfolioContent.fromJson(jsonObject(document['content']));
    for (final record in <PortfolioRecord>[
      ...content.projects,
      ...content.education,
      ...content.experiences,
      ...content.skillCategories,
      ...content.profiles,
      ...content.settings,
      ...content.sectionContent,
    ]) {
      try {
        if (record is Project) ProjectValidation.validate(record);
        ContentValidation.validate(record);
      } on FormatException catch (error) {
        throw FormatException('Record ${record.id}: ${error.message}');
      }
    }
    final assets = {for (final asset in content.media) asset.id: asset};
    final files = <String, Uint8List>{};
    for (final entry in jsonObject(document['mediaFiles']).entries) {
      if (!assets.containsKey(entry.key)) {
        throw FormatException(
          'Media file ${entry.key} has no metadata record.',
        );
      }
      final value = jsonObject(entry.value);
      if (value.length != 2 ||
          value['base64'] is! String ||
          value['sha256'] is! String) {
        throw FormatException('Invalid media payload: ${entry.key}.');
      }
      final bytes = base64Decode(value['base64'] as String);
      if (sha256.convert(bytes).toString() != value['sha256']) {
        throw FormatException('Media checksum mismatch: ${entry.key}.');
      }
      files[entry.key] = bytes;
    }
    return PortfolioTransfer._(content, Map.unmodifiable(files));
  }

  String get summary =>
      '${content.projects.length} projects, '
      '${content.education.length} education entries, '
      '${content.experiences.length} experience entries, '
      '${content.skillCategories.length} skill categories, '
      '${content.profiles.length} profile, ${content.settings.length} settings record, '
      '${content.sectionContent.length} content sections, '
      '${content.media.length} media records; ${files.length} embedded files.';
}

void _checkDuplicates(Object? value, String path) {
  if (value is List) {
    final ids = <String>{};
    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      if (item is Map &&
          item['id'] is String &&
          !ids.add(item['id'] as String)) {
        throw FormatException(
          'Duplicate record ID "${item['id']}" in $path. Remove the duplicate before importing.',
        );
      }
      _checkDuplicates(item, '$path[$index]');
    }
  } else if (value is Map) {
    for (final entry in value.entries) {
      _checkDuplicates(entry.value, '$path.${entry.key}');
    }
  }
}
