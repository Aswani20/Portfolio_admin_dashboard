import 'package:flutter/material.dart';

import '../models/portfolio_content.dart';
import '../models/portfolio_transfer.dart';
import '../repositories/portfolio_repository.dart';
import '../services/transfer_files.dart';
import 'dashboard_components.dart';

class DataTransferPanel extends StatefulWidget {
  const DataTransferPanel({
    super.key,
    required this.repository,
    required this.onContentChanged,
    this.files = const NativeTransferFiles(),
  });
  final PortfolioRepository repository;
  final ValueChanged<PortfolioContent> onContentChanged;
  final TransferFiles files;
  @override
  State<DataTransferPanel> createState() => _DataTransferPanelState();
}

class _DataTransferPanelState extends State<DataTransferPanel> {
  bool _busy = false;
  String? _message;
  bool _error = false;
  Future<void> _run(Future<String?> Function() operation) async {
    setState(() {
      _busy = true;
      _message = null;
      _error = false;
    });
    try {
      final message = await operation();
      if (mounted) setState(() => _message = message);
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = '$error';
          _error = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _export(bool backup) async {
    final document = await widget.repository.exportData(includeMedia: backup);
    final transfer = PortfolioTransfer.decode(document);
    final path = await widget.files.save(document, backup: backup);
    if (path == null) return null;
    return 'Saved to $path. ${transfer.summary} '
        '${backup ? 'Media without embedded bytes was missing and could not be backed up.' : 'Content export does not contain physical media files.'}';
  }

  Future<String?> _import() async {
    final document = await widget.files.open();
    if (document == null) return null;
    final transfer = PortfolioTransfer.decode(document);
    final current = await widget.repository.read();
    final fingerprint = PortfolioTransfer.fingerprint(current);
    if (!mounted) return null;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Replace local portfolio content?'),
        content: SingleChildScrollView(
          child: Text(
            '${transfer.summary}\n\nAll current content collections will be replaced, including records absent from this file. IDs, relationships and display order are preserved; local revision tokens are renewed.\n\n'
            '${transfer.content.media.length - transfer.files.length} media records have no embedded file. Matching existing media can be reused; otherwise previews remain unavailable.\n\n'
            'An automatic backup of current content and available media will be created before replacement. Existing physical files are kept. The website is unchanged.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-data-replace'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Back up and replace'),
          ),
        ],
      ),
    );
    if (confirmed != true) return null;
    final backup = await widget.repository.replaceData(
      document,
      expectedFingerprint: fingerprint,
    );
    // Notify the shell even if navigation disposed this panel during the write.
    widget.onContentChanged(await widget.repository.read());
    return 'Content restored successfully. Previous content backup: $backup';
  }

  @override
  Widget build(BuildContext context) => DashboardPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import, export and backups',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Export JSON content, or create a backup including available media. Import / Restore validates the file before asking to replace content. Use a new filename when saving.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(() => _export(false)),
              icon: const Icon(Icons.download),
              label: const Text('Export JSON'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(() => _export(true)),
              icon: const Icon(Icons.backup_outlined),
              label: const Text('Create backup'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(_import),
              icon: const Icon(Icons.restore),
              label: const Text('Import / Restore'),
            ),
          ],
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SelectableText(
              _message!,
              style: TextStyle(
                color: _error ? Theme.of(context).colorScheme.error : null,
              ),
            ),
          ),
      ],
    ),
  );
}
