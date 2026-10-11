import '../media/media_library.dart';

import 'package:flutter/material.dart';

import '../../models/portfolio_models.dart';
import '../../models/project_validation.dart';
import '../../models/record_ids.dart';
import '../../repositories/portfolio_repository.dart';
import 'project_image.dart';

class ProjectEditor extends StatefulWidget {
  const ProjectEditor({
    super.key,
    required this.repository,
    required this.media,
    this.project,
  });
  final PortfolioRepository repository;
  final List<MediaAsset> media;
  final Project? project;
  @override
  State<ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends State<ProjectEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.project?.title ?? '');
  late final _description = TextEditingController(
    text: widget.project?.description ?? '',
  );
  late final _technologies = TextEditingController(
    text: widget.project?.techStack.join('\n') ?? '',
  );
  late final _github = TextEditingController(
    text: widget.project?.githubUrl ?? '',
  );
  late final _live = TextEditingController(text: widget.project?.liveUrl ?? '');
  late final List<String> _images = [...?widget.project?.imagePaths];
  // Retain the ID across failed save attempts.
  late final _id = widget.project?.id ?? RecordIds.create();
  late List<MediaAsset> _media = widget.media;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _technologies,
      _github,
      _live,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _preserve(String value, String? previous) =>
      value == previous ? previous! : value.trim();
  String? _url(String value, String? previous) => value == (previous ?? '')
      ? previous
      : value.trim().isEmpty
      ? null
      : value.trim();

  Future<void> _chooseImages({int? replace, bool cover = false}) async {
    final selected = await showMediaPicker(
      context,
      widget.repository,
      multiple: replace == null && !cover,
    );
    try {
      final content = await widget.repository.read();
      if (!mounted) return;
      setState(() {
        _media = content.media;
        if (selected == null || selected.isEmpty) return;
        final paths = selected.map((a) => a.sourcePath).toList();
        if (cover) {
          _images.remove(paths.first);
          _images.insert(0, paths.first);
        } else if (replace != null) {
          // If already present, swap positions to keep gallery references unique.
          final existing = _images.indexOf(paths.first);
          if (existing >= 0) _images[existing] = _images[replace];
          _images[replace] = paths.first;
        } else {
          _images.addAll(paths.where((p) => !_images.contains(p)));
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final old = widget.project;
    final project = Project(
      id: _id,
      revision: old?.revision ?? 0,
      title: _preserve(_title.text, old?.title),
      description: _preserve(_description.text, old?.description),
      imagePaths: _images,
      techStack: _technologies.text == old?.techStack.join('\n')
          ? old!.techStack
          : _technologies.text
                .split('\n')
                .map((v) => v.trim())
                .where((v) => v.isNotEmpty)
                .toList(),
      githubUrl: _url(_github.text, old?.githubUrl),
      liveUrl: _url(_live.text, old?.liveUrl),
    );
    try {
      final saved = old == null
          ? await widget.repository.projects.create(project)
          : await widget.repository.projects.update(
              project,
              expectedRevision: old.revision,
            );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 820,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height - 64,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.project == null ? 'Add project' : 'Edit project',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saved locally. Website publishing is not connected.',
                        ),
                        const SizedBox(height: 20),
                        _field(
                          _title,
                          'Title *',
                          'project-title',
                          validator: (v) =>
                              ProjectValidation.requiredText(v, 'Title'),
                        ),
                        const SizedBox(height: 16),
                        _field(
                          _description,
                          'Description *',
                          'project-description',
                          lines: 5,
                          validator: (v) =>
                              ProjectValidation.requiredText(v, 'Description'),
                          helper: 'The website shows a shortened preview of this single description.',
                        ),
                        const SizedBox(height: 16),
                        _field(
                          _technologies,
                          'Technologies',
                          'project-technologies',
                          lines: 3,
                          helper:
                              'One technology per line. Order is preserved.',
                        ),
                        const SizedBox(height: 16),
                        _field(
                          _github,
                          'GitHub URL',
                          'project-github',
                          validator: ProjectValidation.optionalUrl,
                          helper: 'Optional · full http:// or https:// link',
                        ),
                        const SizedBox(height: 16),
                        _field(
                          _live,
                          'Live demo / release URL',
                          'project-live',
                          validator: ProjectValidation.optionalUrl,
                          helper:
                              'Optional · leave blank to hide the website link',
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Screenshots',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Choose existing local images. The first image is the cover; the gallery uses this order. No images shows the website’s image placeholder.',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              key: const ValueKey('browse-project-media'),
                              onPressed: _saving ? null : () => _chooseImages(),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Browse / import screenshots'),
                            ),
                            OutlinedButton.icon(
                              key: const ValueKey('choose-project-cover'),
                              onPressed: _saving
                                  ? null
                                  : () => _chooseImages(cover: true),
                              icon: const Icon(Icons.image_outlined),
                              label: const Text('Choose thumbnail'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < _images.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                ProjectImage(
                                  repository: widget.repository,
                                  media: _media,
                                  path: _images[i],
                                  width: 64,
                                  height: 44,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${i + 1}. ${_images[i].split('/').last}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  key: ValueKey('replace-image-$i'),
                                  tooltip: 'Replace image reference',
                                  onPressed: _saving
                                      ? null
                                      : () => _chooseImages(replace: i),
                                  icon: const Icon(Icons.swap_horiz, size: 18),
                                ),
                                IconButton(
                                  key: ValueKey('image-up-$i'),
                                  tooltip: 'Move screenshot earlier',
                                  onPressed: _saving || i == 0
                                      ? null
                                      : () => setState(() {
                                          final value = _images.removeAt(i);
                                          _images.insert(i - 1, value);
                                        }),
                                  icon: const Icon(
                                    Icons.arrow_upward,
                                    size: 18,
                                  ),
                                ),
                                IconButton(
                                  key: ValueKey('image-down-$i'),
                                  tooltip: 'Move screenshot later',
                                  onPressed: _saving || i == _images.length - 1
                                      ? null
                                      : () => setState(() {
                                          final value = _images.removeAt(i);
                                          _images.insert(i + 1, value);
                                        }),
                                  icon: const Icon(
                                    Icons.arrow_downward,
                                    size: 18,
                                  ),
                                ),
                                IconButton(
                                  key: ValueKey('remove-image-$i'),
                                  tooltip: 'Remove screenshot',
                                  onPressed: _saving
                                      ? null
                                      : () =>
                                            setState(() => _images.removeAt(i)),
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ),
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              key: const ValueKey('project-save-error'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          const Text(
                            'Your entries are still here. If another edit changed this project, cancel, refresh the list and reopen it.',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: const ValueKey('cancel-project'),
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      key: const ValueKey('save-project'),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_saving ? 'Saving…' : 'Save project'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    String key, {
    int lines = 1,
    String? helper,
    String? Function(String?)? validator,
  }) => TextFormField(
    key: ValueKey(key),
    controller: controller,
    enabled: !_saving,
    maxLines: lines,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 3,
      border: const OutlineInputBorder(),
    ),
  );
}
