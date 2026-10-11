import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_transfer.dart';
import 'package:portfolio_admin_dashboard/services/transfer_files.dart';
import 'package:portfolio_admin_dashboard/widgets/data_transfer_panel.dart';

import 'fixture_repository.dart';

class Files implements TransferFiles {
  String? input;
  String? saved;
  bool? backup;
  @override
  Future<String?> open() async => input;
  @override
  Future<String?> save(String document, {required bool backup}) async {
    saved = document;
    this.backup = backup;
    return 'test-export.json';
  }
}

class Repository extends FixtureRepository {
  Repository() : super(fixtureContent());
  int replacements = 0;
  bool? withMedia;
  @override
  Future<String> exportData({bool includeMedia = false}) async {
    withMedia = includeMedia;
    return PortfolioTransfer.encode(content, {});
  }

  @override
  Future<String> replaceData(
    String document, {
    required String expectedFingerprint,
  }) async {
    expect(expectedFingerprint, PortfolioTransfer.fingerprint(content));
    replacements++;
    content = PortfolioTransfer.decode(document).content;
    return 'automatic-backup.json';
  }
}

void main() {
  testWidgets(
    'Import validates before confirmation; cancel makes no changes; confirm notifies parent',
    (tester) async {
      final repository = Repository();
      final files = Files();
      var notifications = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataTransferPanel(
              repository: repository,
              files: files,
              onContentChanged: (_) => notifications++,
            ),
          ),
        ),
      );
      files.input = '{';
      await tester.tap(find.text('Import / Restore'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('FormatException'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.replacements, 0);
      files.input = PortfolioTransfer.encode(repository.content, {});
      await tester.tap(find.text('Import / Restore'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Replace local portfolio content?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repository.replacements, 0);
      await tester.tap(find.text('Import / Restore'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('confirm-data-replace')));
      await tester.pumpAndSettle();
      expect(repository.replacements, 1);
      expect(notifications, 1);
      expect(find.textContaining('automatic-backup.json'), findsOneWidget);
    },
  );

  testWidgets('Export and backup request the appropriate media policy', (
    tester,
  ) async {
    final repository = Repository();
    final files = Files();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DataTransferPanel(
            repository: repository,
            files: files,
            onContentChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Export JSON'));
    await tester.pumpAndSettle();
    expect(repository.withMedia, false);
    expect(files.backup, false);
    expect(
      PortfolioTransfer.decode(files.saved!).content.projects.length,
      repository.content.projects.length,
    );
    await tester.tap(find.text('Create backup'));
    await tester.pumpAndSettle();
    expect(repository.withMedia, true);
    expect(files.backup, true);
    expect(find.textContaining('Saved to test-export.json'), findsOneWidget);
  });
}
