import '../../models/list_browse_state.dart';
import '../../widgets/list_controls.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/image_import.dart' as inspection;
import '../../models/portfolio_content.dart';
import '../../models/portfolio_models.dart';
import '../../repositories/portfolio_repository.dart';
import '../../services/image_selection.dart';

Future<List<MediaAsset>?> showMediaPicker(
  BuildContext context,
  PortfolioRepository repository, {
  bool multiple = true,
}) => showDialog<List<MediaAsset>>(
  context: context,
  barrierDismissible: false,
  builder: (_) => Dialog(
    child: SizedBox(
      width: 960,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: MediaLibrary(
          repository: repository,
          selection: true,
          multiple: multiple,
        ),
      ),
    ),
  ),
);

class MediaLibrary extends StatefulWidget {
  const MediaLibrary({
    super.key,
    required this.repository,
    this.browseState,
    this.onContentChanged,
    this.selection = false,
    this.multiple = true,
    this.picker = selectImageFiles,
  });
  final PortfolioRepository repository;
  final ListBrowseState? browseState;
  final ValueChanged<PortfolioContent>? onContentChanged;
  final bool selection;
  final bool multiple;
  final ImageFilePicker picker;
  @override
  State<MediaLibrary> createState() => _MediaLibraryState();
}

class _MediaLibraryState extends State<MediaLibrary> {
  late final _browse = widget.browseState ?? ListBrowseState();
  List<MediaAsset>? _media;
  final _selected = <String>{};
  bool _busy = false;
  String? _error;
  String? _notice;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<bool> _reload() async {
    try {
      final content = await widget.repository.read();
      widget.onContentChanged?.call(content);
      if (mounted) {
        setState(() {
          _media = content.media;
          _selected.removeWhere((id) => !content.media.any((a) => a.id == id));
          _generation++;
        });
      }
      return true;
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
      return false;
    }
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final report = await importSelectedImages(
        widget.repository,
        picker: widget.picker,
      );
      final refreshed = await _reload();
      if (!mounted || !refreshed) return;
      setState(() {
        _error = report.errors.isEmpty ? null : report.errors.join('\n');
        _notice = report.assets.isEmpty
            ? null
            : '${report.assets.length} image(s) ready. Identical files reuse existing library entries.';
        if (widget.selection) {
          if (!widget.multiple) _selected.clear();
          _selected.addAll(
            (widget.multiple ? report.assets : report.assets.take(1)).map(
              (a) => a.id,
            ),
          );
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not select images: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _media
        ?.where((a) => !widget.selection || a.kind == 'image')
        .toList();
    final matched = all == null
        ? null
        : _browse.matching(
            all,
            searchText: (a) => '${a.label} ${a.sourcePath}',
            title: (a) => a.label,
            matchesFilter: (a, f) => a.kind == f,
          );
    final assets = matched == null ? null : _browse.slice(matched, size: 50);
    final browseName = widget.selection ? 'media-picker' : 'media';
    return PopScope(
      canPop: !_busy,
      child: Column(
        key: ValueKey(widget.selection ? 'media-picker' : 'page-media'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.selection ? 'Choose project images' : 'Media Library',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Local images · PNG, JPEG and WebP · up to 20 MB / 40 megapixels. Existing icons and documents are kept.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                key: const ValueKey('import-images'),
                onPressed: _busy ? null : _import,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_busy ? 'Importing…' : 'Import images'),
              ),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() => _error = null);
                        _reload();
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              if (widget.selection) ...[
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const ValueKey('use-images'),
                  onPressed: _busy || _selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, [
                          for (final id in _selected)
                            _media!.firstWhere((a) => a.id == id),
                        ]),
                  child: Text('Use ${_selected.length} image(s)'),
                ),
              ],
            ],
          ),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_notice!, key: const ValueKey('media-notice')),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SelectableText(
                _error!,
                key: const ValueKey('media-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),
          if (assets == null && _error == null)
            const Center(child: CircularProgressIndicator()),
          if (assets != null) ...[
            ListControls(
              name: browseName,
              state: _browse,
              onChanged: () => setState(() {}),
              enabled: !_busy,
              searchLabel: 'Search media by filename or reference',
              filterLabel: 'Media type',
              filters: widget.selection
                  ? const {}
                  : const {
                      'image': 'Images',
                      'icon': 'Icons',
                      'document': 'Documents',
                    },
              sorts: const {
                'order': 'Library order',
                'title': 'Filename A-Z',
                'title-desc': 'Filename Z-A',
              },
            ),
            ListPager(
              name: browseName,
              state: _browse,
              total: all!.length,
              matched: matched!.length,
              size: 50,
              enabled: !_busy,
              onChanged: () => setState(() {}),
            ),
          ],
          if (assets != null && assets.isEmpty)
            Text(
              all!.isEmpty ? 'No images yet. Import images to get started.' : 'No matching media. Try another search or reset your filters.',
            ),
          if (assets != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 230).floor().clamp(
                  1,
                  6,
                );
                final width =
                    (constraints.maxWidth - (columns - 1) * 16) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final asset in assets)
                      SizedBox(
                        width: width,
                        child: _MediaTile(
                          key: ValueKey('${asset.id}-$_generation'),
                          asset: asset,
                          repository: widget.repository,
                          selected: _selected.contains(asset.id),
                          onSelect: widget.selection && !_busy
                              ? () => setState(() {
                                  if (_selected.remove(asset.id)) return;
                                  if (!widget.multiple) _selected.clear();
                                  _selected.add(asset.id);
                                })
                              : null,
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 16),
          const Text(
            'Importing keeps a local copy. Removing a project reference never deletes library files. Imports remain available if a project edit is cancelled.',
          ),
        ],
      ),
    );
  }
}

class _MediaTile extends StatefulWidget {
  const _MediaTile({
    super.key,
    required this.asset,
    required this.repository,
    required this.selected,
    this.onSelect,
  });
  final MediaAsset asset;
  final PortfolioRepository repository;
  final bool selected;
  final VoidCallback? onSelect;
  @override
  State<_MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<_MediaTile> {
  late final _data = _load();
  Future<(Uint8List, inspection.ImageInfo?)> _load() async {
    final bytes = await widget.repository.readMedia(widget.asset.id);
    return (
      bytes,
      widget.asset.kind == 'image' ? inspection.ImageInfo.inspect(bytes) : null,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<(Uint8List, inspection.ImageInfo?)>(
    future: _data,
    builder: (context, snapshot) {
      final data = snapshot.data;
      final info = data?.$2;
      final unavailable = snapshot.hasError;
      Widget preview(double height) => SizedBox(
        height: height,
        width: double.infinity,
        child: unavailable
            ? const Center(child: Icon(Icons.broken_image_outlined, size: 36))
            : data == null
            ? const Center(child: CircularProgressIndicator())
            : info == null
            ? Center(
                child: Icon(
                  widget.asset.kind == 'document'
                      ? Icons.description_outlined
                      : Icons.code,
                  size: 36,
                ),
              )
            : Image.memory(
                data.$1,
                fit: BoxFit.contain,
                cacheWidth: height > 200 ? 1200 : 440,
                errorBuilder: (_, error, stack) =>
                    const Center(child: Text('Image preview unavailable')),
              ),
      );
      return Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: widget.selected
                ? Theme.of(context).colorScheme.primary
                : Colors.black12,
            width: widget.selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              preview(130),
              const SizedBox(height: 10),
              Text(
                widget.asset.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                unavailable
                    ? 'Missing or unreadable file'
                    : data == null
                    ? 'Loading…'
                    : '${info == null ? widget.asset.kind : '${info.width} × ${info.height}'} · ${(data.$1.length / 1024).toStringAsFixed(1)} KB',
              ),
              Wrap(
                spacing: 4,
                children: [
                  if (widget.onSelect != null)
                    TextButton.icon(
                      key: ValueKey('select-media-${widget.asset.id}'),
                      onPressed: unavailable || data == null
                          ? null
                          : widget.onSelect,
                      icon: Icon(
                        widget.selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                      ),
                      label: Text(widget.selected ? 'Selected' : 'Select'),
                    ),
                  TextButton(
                    onPressed: data == null && !unavailable
                        ? null
                        : () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(widget.asset.label),
                              content: SizedBox(
                                width: 680,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      preview(300),
                                      const SizedBox(height: 16),
                                      if (unavailable)
                                        const Text(
                                          'This file is missing or unreadable. Restore it from backup or choose a replacement image in the project editor.',
                                        ),
                                      if (info != null)
                                        Text(
                                          '${info.width} × ${info.height} pixels · ${info.byteLength} bytes',
                                        ),
                                      SelectableText(
                                        'Reference: ${widget.asset.sourcePath}',
                                      ),
                                      if (info == null && !unavailable)
                                        const Text(
                                          'Preview is available for raster images. This existing file is preserved.',
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          ),
                    child: const Text('Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
