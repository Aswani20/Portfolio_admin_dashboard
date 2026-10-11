import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/content_validation.dart';
import '../../models/portfolio_models.dart';
import '../../models/record_ids.dart';
import '../../repositories/portfolio_repository.dart';
import '../media/media_library.dart';
import '../projects/project_image.dart';
import 'content_forms.dart';

class ContentEditor extends StatefulWidget {
  const ContentEditor({
    super.key,
    required this.title,
    required this.fields,
    required this.initial,
    required this.repository,
    required this.media,
    required this.save,
  });
  final String title;
  final List<ContentField> fields;
  final Map<String, dynamic> initial;
  final PortfolioRepository repository;
  final List<MediaAsset> media;
  final Future<PortfolioRecord> Function(Map<String, dynamic>) save;
  @override
  State<ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<ContentEditor> {
  final _form = GlobalKey<FormState>();
  late final _draft = _Draft(widget.fields, widget.initial);
  late List<MediaAsset> _media = widget.media;
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      setState(
        () => _error = 'Please complete required fields and correct the highlighted values.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.save(_draft.snapshot());
      if (mounted) Navigator.pop(context, result);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _saving = false;
        });
      }
    }
  }

  Future<void> _remove(String label, VoidCallback remove) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $label?'),
        content: const Text(
          'This change takes effect when you save the form. Media files are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-remove-item'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) setState(remove);
  }

  Future<void> _photo(TextEditingController controller) async {
    final result = await showMediaPicker(
      context,
      widget.repository,
      multiple: false,
    );
    try {
      final content = await widget.repository.read();
      if (mounted) {
        setState(() {
          _media = content.media;
          if (result != null && result.isNotEmpty) {
            controller.text = result.first.sourcePath;
          }
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Dialog(
      child: SizedBox(
        width: 880,
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
                  widget.title,
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
                          'Changes are saved locally. Required fields are marked *. Existing formatting is retained.',
                        ),
                        const SizedBox(height: 20),
                        ..._fields(_draft, ''),
                      ],
                    ),
                  ),
                ),
              ),
              if (_error != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 110),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _error!,
                            key: const ValueKey('content-save-error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const Text(
                            'Your entries are retained. For a conflict, cancel and reopen the latest record.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: const ValueKey('cancel-content'),
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      key: const ValueKey('save-content'),
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving...' : 'Save changes'),
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

  List<Widget> _fields(_Draft draft, String prefix) => [
    for (final field in draft.fields)
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _field(draft, field, '$prefix${field.name}'),
      ),
  ];

  Widget _field(_Draft draft, ContentField field, String path) {
    final label =
        '${field.label}${field.required && ![InputKind.toggle, InputKind.records, InputKind.strings].contains(field.kind) ? ' *' : ''}';
    if (field.kind == InputKind.toggle) {
      return SwitchListTile(
        key: ValueKey('field-$path'),
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: draft.values[field.name] as bool,
        onChanged: _saving
            ? null
            : (v) => setState(() => draft.values[field.name] = v),
      );
    }
    if (field.kind == InputKind.records || field.kind == InputKind.strings) {
      final records = draft.records[field.name];
      final strings = draft.strings[field.name];
      final length = records?.length ?? strings!.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: Theme.of(context).textTheme.titleMedium),
          if (field.help != null) Text(field.help!),
          const SizedBox(height: 10),
          if (length == 0) Text('No ${field.label.toLowerCase()} yet.'),
          for (var i = 0; i < length; i++)
            Card(
              key: ObjectKey(records?[i] ?? strings![i]),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            records == null
                                ? 'Item ${i + 1}'
                                : field.fixed
                                ? '${records[i].original['id']}'
                                : '${field.label} ${i + 1}',
                          ),
                        ),
                        if (!field.fixed) ...[
                          IconButton(
                            key: ValueKey('up-$path-$i'),
                            tooltip: 'Move earlier',
                            onPressed: _saving || i == 0
                                ? null
                                : () => setState(() {
                                    final list = records ?? strings!;
                                    final value = list.removeAt(i);
                                    list.insert(i - 1, value);
                                  }),
                            icon: const Icon(Icons.arrow_upward, size: 18),
                          ),
                          IconButton(
                            key: ValueKey('down-$path-$i'),
                            tooltip: 'Move later',
                            onPressed: _saving || i == length - 1
                                ? null
                                : () => setState(() {
                                    final list = records ?? strings!;
                                    final value = list.removeAt(i);
                                    list.insert(i + 1, value);
                                  }),
                            icon: const Icon(Icons.arrow_downward, size: 18),
                          ),
                          IconButton(
                            key: ValueKey('remove-$path-$i'),
                            tooltip: 'Remove item',
                            onPressed: _saving
                                ? null
                                : () => _remove('item', () {
                                    if (records != null) {
                                      records.removeAt(i).dispose();
                                    } else {
                                      strings!.removeAt(i).dispose();
                                    }
                                  }),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ],
                    ),
                    if (records != null)
                      ..._fields(records[i], '$path-$i-')
                    else if (field.mediaKind != null)
                      _mediaField(strings![i], field, '$path-$i', label: 'Icon')
                    else
                      TextFormField(
                        key: ValueKey('field-$path-$i'),
                        controller: strings![i],
                        enabled: !_saving,
                        minLines: 2,
                        maxLines: 5,
                        validator: ContentValidation.requiredText,
                        decoration: const InputDecoration(
                          labelText: 'Text *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (!field.fixed)
            OutlinedButton.icon(
              key: ValueKey('add-item-$path'),
              onPressed: _saving
                  ? null
                  : () => setState(() {
                      if (records != null) {
                        records.add(
                          _Draft(field.children, {
                            'id': RecordIds.create(),
                            'revision': 0,
                          }, nested: true),
                        );
                      } else {
                        strings!.add(TextEditingController());
                      }
                    }),
              icon: const Icon(Icons.add),
              label: Text('Add ${field.label.toLowerCase()}'),
            ),
        ],
      );
    }
    final controller = draft.controllers[field.name]!;
    if (field.kind == InputKind.media) {
      return _mediaField(controller, field, path, label: label);
    }
    if (field.kind == InputKind.choices) {
      return _dropdown(controller, field, path, {
        for (final option in field.options) option: option,
        if (controller.text.isNotEmpty) controller.text: controller.text,
      }, label);
    }
    return TextFormField(
      key: ValueKey('field-$path'),
      controller: controller,
      enabled: !_saving,
      minLines: field.kind == InputKind.paragraph ? 3 : 1,
      maxLines: field.kind == InputKind.paragraph ? 7 : 1,
      validator:
          field.validator ??
          (field.kind == InputKind.color
              ? ContentValidation.color
              : field.required
              ? ContentValidation.requiredText
              : null),
      decoration: InputDecoration(
        labelText: label,
        helperText: field.help,
        helperMaxLines: 4,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _dropdown(
    TextEditingController controller,
    ContentField field,
    String path,
    Map<String, String> options,
    String label,
  ) => Container(
    key: ValueKey('field-$path'),
    child: DropdownButtonFormField<String>(
      key: ValueKey(controller.text),
      initialValue: controller.text.isEmpty ? null : controller.text,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        helperText: field.help,
        helperMaxLines: 4,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final entry in options.entries)
          DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      validator: field.required ? ContentValidation.requiredText : null,
      onChanged: _saving
          ? null
          : (value) => setState(() => controller.text = value ?? ''),
    ),
  );
  Widget _mediaField(
    TextEditingController controller,
    ContentField field,
    String path, {
    required String label,
  }) {
    final options = {
      for (final a in _media.where((a) => a.kind == field.mediaKind))
        a.sourcePath: a.label,
    };
    if (controller.text.isNotEmpty && !options.containsKey(controller.text)) {
      options[controller.text] = controller.text;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dropdown(controller, field, path, options, label),
        if (field.mediaKind == 'image') ...[
          const SizedBox(height: 8),
          ProjectImage(
            repository: widget.repository,
            media: _media,
            path: controller.text,
          ),
          TextButton.icon(
            onPressed: _saving ? null : () => _photo(controller),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Browse / import photo'),
          ),
        ],
      ],
    );
  }
}

class _Draft {
  _Draft(this.fields, Map<String, dynamic> initial, {this.nested = false})
    : original = initial {
    for (final field in fields) {
      final value = initial[field.name];
      switch (field.kind) {
        case InputKind.toggle:
          values[field.name] = value ?? false;
        case InputKind.records:
          records[field.name] = [
            for (final item in (value as List? ?? []))
              _Draft(
                field.children,
                Map<String, dynamic>.from(item as Map),
                nested: true,
              ),
          ];
        case InputKind.strings:
          strings[field.name] = [
            for (final item in (value as List? ?? []))
              TextEditingController(text: item as String),
          ];
        default:
          controllers[field.name] = TextEditingController(
            text: field.kind == InputKind.color
                ? ((value as int?) ?? 0xFF4479A1)
                      .toRadixString(16)
                      .padLeft(8, '0')
                      .toUpperCase()
                : value as String? ?? '',
          );
      }
    }
  }
  final List<ContentField> fields;
  final Map<String, dynamic> original;
  final bool nested;
  final controllers = <String, TextEditingController>{};
  final values = <String, dynamic>{};
  final records = <String, List<_Draft>>{};
  final strings = <String, List<TextEditingController>>{};
  Map<String, dynamic> snapshot() {
    final result = {...original};
    for (final field in fields) {
      result[field.name] = switch (field.kind) {
        InputKind.toggle => values[field.name],
        InputKind.records =>
          records[field.name]!.map((d) => d.snapshot()).toList(),
        InputKind.strings => strings[field.name]!.map((c) => c.text).toList(),
        InputKind.color => int.parse(controllers[field.name]!.text, radix: 16),
        _ =>
          field.nullable && controllers[field.name]!.text.isEmpty
              ? (original[field.name] == '' ? '' : null)
              : controllers[field.name]!.text,
      };
    }
    if (nested && jsonEncode(result) != jsonEncode(original)) {
      result['revision'] = (original['revision'] as int) + 1;
    }
    return result;
  }

  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    for (final list in strings.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    for (final list in records.values) {
      for (final d in list) {
        d.dispose();
      }
    }
  }
}
