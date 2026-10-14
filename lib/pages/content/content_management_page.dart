import '../../models/list_browse_state.dart';
import '../../widgets/list_controls.dart';
import '../../widgets/data_transfer_panel.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/article_export.dart';

import '../../models/portfolio_content.dart';
import '../../models/portfolio_models.dart';
import '../../models/record_ids.dart';
import '../../navigation/dashboard_destination.dart';
import '../../repositories/portfolio_repository.dart';
import '../../widgets/dashboard_components.dart';
import 'content_editor.dart';
import 'content_forms.dart';

class ContentManagementPage extends StatefulWidget {
  const ContentManagementPage({
    super.key,
    required this.destination,
    required this.repository,
    this.browseState,
    required this.onContentChanged,
  });
  final DashboardDestination destination;
  final PortfolioRepository repository;
  final ListBrowseState? browseState;
  final ValueChanged<PortfolioContent> onContentChanged;
  @override
  State<ContentManagementPage> createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> {
  late final _browse = widget.browseState ?? ListBrowseState();
  PortfolioContent? _content;
  String? _error;
  bool _loading = true, _busy = false;
  late ScaffoldMessengerState _messenger;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final content = await widget.repository.read();
      widget.onContentChanged(content);
      if (mounted) {
        setState(() {
          _content = content;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$error';
        });
      }
    }
  }

  void _message(String text) {
    if (_messenger.mounted) {
      _messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _edit<T extends PortfolioRecord>(
    String title,
    List<ContentField> fields,
    RecordRepository<T> repository,
    T Function(Map<String, dynamic>) decode, [
    T? record,
  ]) async {
    final initial =
        record?.toJson() ?? {'id': RecordIds.create(), 'revision': 0};
    final result = await showDialog<PortfolioRecord>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ContentEditor(
        title: title,
        fields: fields,
        initial: initial,
        repository: widget.repository,
        media: _content!.media,
        save: (document) => record == null
            ? repository.create(decode(document))
            : repository.update(
                decode(document),
                expectedRevision: record.revision,
              ),
      ),
    );
    if (result != null) _message('Changes saved locally.');
    // Photo imports persist even if the profile form is cancelled.
    await _reload();
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              key: const ValueKey('cancel-content-delete'),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('confirm-content-delete'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _delete<T extends PortfolioRecord>(
    RecordRepository<T> repository,
    T record,
    String label,
  ) async {
    if (!await _confirm(
      'Delete $label?',
      'This removes the local record and its nested content. Media files are kept. The website is unchanged.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await repository.delete(record.id, expectedRevision: record.revision);
      _message('Record deleted locally.');
      await _reload();
    } catch (error) {
      _message('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeCertificate(Education record) async {
    if (!await _confirm(
      'Remove certificate link?',
      'The education record will be kept. Only its certificate link is removed.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.education.update(
        Education.fromJson({...record.toJson(), 'certificateUrl': null}),
        expectedRevision: record.revision,
      );
      _message('Certificate link removed.');
      await _reload();
    } catch (error) {
      _message('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _isList => [
    DashboardDestination.articles,
    DashboardDestination.experience,
    DashboardDestination.skills,
    DashboardDestination.education,
    DashboardDestination.certifications,
  ].contains(widget.destination);
  OrderedCollection? get _ordered => switch (widget.destination) {
    DashboardDestination.articles => OrderedCollection.articles,
    DashboardDestination.experience => OrderedCollection.experiences,
    DashboardDestination.skills => OrderedCollection.skillCategories,
    DashboardDestination.education => OrderedCollection.education,
    _ => null,
  };
  List<PortfolioRecord> get _all => switch (widget.destination) {
    DashboardDestination.articles => _content!.articles,
    DashboardDestination.experience => _content!.experiences,
    DashboardDestination.skills => _content!.skillCategories,
    DashboardDestination.education ||
    DashboardDestination.certifications => _content!.education,
    _ => [],
  };
  List<PortfolioRecord> get _matched {
    final c = _content!;
    switch (widget.destination) {
      case DashboardDestination.articles:
        return _browse.matching<Article>(
          c.articles,
          searchText: (a) => '${a.title} ${a.summary} ${a.body}',
          title: (a) => a.title,
          secondary: (a) => a.publishedOn,
          current: (a) => a.isPublished,
          matchesFilter: (a, f) =>
              f == 'published' ? a.isPublished : f == 'draft' && !a.isPublished,
        );
      case DashboardDestination.experience:
        return _browse.matching<Experience>(
          c.experiences,
          searchText: (e) =>
              '${e.role} ${e.company} ${e.location} ${e.duration} ${e.highlights.join(' ')} ${e.milestones.map((m) => m.title).join(' ')}',
          title: (e) => e.role,
          secondary: (e) => e.company,
          current: (e) => e.isCurrent,
          matchesFilter: (e, f) =>
              f == 'current' ? e.isCurrent : f == 'past' && !e.isCurrent,
        );
      case DashboardDestination.skills:
        return _browse.matching<SkillCategory>(
          c.skillCategories,
          searchText: (c) =>
              '${c.title} ${c.skills.map((s) => s.label).join(' ')}',
          title: (c) => c.title,
          matchesFilter: (c, f) => c.id == f,
        );
      case DashboardDestination.education:
      case DashboardDestination.certifications:
        return _browse.matching<Education>(
          c.education,
          searchText: (e) =>
              '${e.degree} ${e.institution} ${e.duration} ${e.location}',
          title: (e) => e.degree,
          secondary: (e) => e.institution,
          current: (e) => e.isCurrent,
          matchesFilter: (e, f) => switch (f) {
            'current' => e.isCurrent,
            'past' => !e.isCurrent,
            'linked' => e.certificateUrl?.isNotEmpty ?? false,
            'unlinked' => !(e.certificateUrl?.isNotEmpty ?? false),
            _ => false,
          },
        );
      default:
        return [];
    }
  }

  Map<String, String> get _filters => switch (widget.destination) {
    DashboardDestination.articles => {
      'published': 'Included in export',
      'draft': 'Drafts',
    },
    DashboardDestination.skills => {
      for (final c in _content!.skillCategories) c.id: c.title,
    },
    DashboardDestination.certifications => {
      'linked': 'With certificate',
      'unlinked': 'Without certificate',
    },
    _ => {'current': 'Current', 'past': 'Not current'},
  };
  Widget _listControls() {
    final matched = _matched;
    _browse.slice(matched); // Clamp stale pages after deletion or a refresh.
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListControls(
            name: widget.destination.name,
            state: _browse,
            onChanged: () => setState(() {}),
            enabled: !_busy,
            searchLabel: widget.destination == DashboardDestination.skills
                ? 'Search categories or technologies'
                : widget.destination == DashboardDestination.articles
                ? 'Search articles'
                : 'Search titles, organizations or timeline details',
            filterLabel: widget.destination == DashboardDestination.skills
                ? 'Category'
                : 'Status',
            filters: _filters,
            sorts: {
              'order': 'Saved order',
              'title': 'Title A-Z',
              'title-desc': 'Title Z-A',
              if (widget.destination != DashboardDestination.skills)
                'secondary':
                    widget.destination == DashboardDestination.experience
                    ? 'Company A-Z'
                    : widget.destination == DashboardDestination.articles
                    ? 'Date oldest first'
                    : 'Institution A-Z',
              if (widget.destination != DashboardDestination.skills)
                'current': widget.destination == DashboardDestination.articles
                    ? 'Included first'
                    : 'Current first',
            },
          ),
          ListPager(
            name: widget.destination.name,
            state: _browse,
            total: _all.length,
            matched: matched.length,
            enabled: !_busy,
            onChanged: () => setState(() {}),
          ),
          if (_ordered != null)
            Text(
              _browse.canReorder
                  ? widget.destination == DashboardDestination.articles
                        ? 'Website: newest dates first. Saved order breaks ties between articles on the same date.'
                        : 'Arrows save the website display order. Sorting only changes this view.'
                  : 'Reset filters and choose Saved order to change website display order.',
            ),
          if (_all.isNotEmpty && matched.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'No matching records. Try another search or reset your filters.',
                key: ValueKey('no-matching-content'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _move(String id, int delta) async {
    if (!_browse.canReorder || _ordered == null) return;
    final all = _all;
    final ids = all.map((r) => r.id).toList();
    final from = ids.indexOf(id), to = ids.indexOf(id) + delta;
    if (from < 0 || to < 0 || to >= ids.length) return;
    ids.insert(to, ids.removeAt(from));
    setState(() => _busy = true);
    try {
      await widget.repository.reorderContent(
        _ordered!,
        ids,
        expectedRevisions: {for (final r in all) r.id: r.revision},
      );
      _browse.page = to ~/ 20;
      _message('Display order saved locally.');
      await _reload();
    } catch (error) {
      _message('Could not reorder content: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    key: ValueKey('page-${widget.destination.name}'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.destination == DashboardDestination.settings) ...[
        DataTransferPanel(
          repository: widget.repository,
          onContentChanged: (content) {
            widget.onContentChanged(content);
            if (mounted) setState(() => _content = content);
          },
        ),
        const SizedBox(height: 24),
      ],
      PageHeading(
        title: widget.destination.label,
        description: _description,
        badge: 'Local content',
      ),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          if (!_loading && _content != null && _add != null)
            FilledButton.icon(
              key: ValueKey('add-${widget.destination.name}'),
              onPressed: _busy ? null : _add,
              icon: const Icon(Icons.add),
              label: Text('Add $_recordLabel'),
            ),
          if (widget.destination == DashboardDestination.articles &&
              _content != null)
            OutlinedButton.icon(
              onPressed: _busy ? null : _exportArticles,
              icon: const Icon(Icons.copy),
              label: const Text('Copy website JSON'),
            ),
          OutlinedButton.icon(
            key: const ValueKey('refresh-content'),
            onPressed: _busy || _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (_loading)
        const Center(child: CircularProgressIndicator())
      else if (_error != null)
        SelectableText(
          _error!,
          key: const ValueKey('content-load-error'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        )
      else ...[
        if (_isList) _listControls(),
        ..._body(),
      ],
    ],
  );
  String get _description => switch (widget.destination) {
    DashboardDestination.articles => 'Write locally, then copy published articles into the website static JSON file and rebuild. Nothing is synchronized automatically.',
    DashboardDestination.personal => 'Hero, About Me, contact information and social links. One shared profile, with original formatting preserved.',
    DashboardDestination.experience =>
      'Roles, responsibilities and nested career milestones in website order.',
    DashboardDestination.skills =>
      'Technology categories, icons, colors and theme behavior.',
    DashboardDestination.education =>
      'Qualifications, institutions and optional certificate links.',
    DashboardDestination.certifications => 'Certificates belong to education records. Add, edit or remove their links here.',
    DashboardDestination.settings => 'Website identity, CV presentation, navigation labels and section headings.',
    _ => '',
  };
  String get _recordLabel => switch (widget.destination) {
    DashboardDestination.articles => 'article',
    DashboardDestination.experience => 'experience',
    DashboardDestination.skills => 'category',
    _ => 'education',
  };
  VoidCallback? get _add => switch (widget.destination) {
    DashboardDestination.articles => () => _edit(
      'Add article',
      articleFields,
      widget.repository.articles,
      Article.fromJson,
    ),
    DashboardDestination.experience => () => _edit(
      'Add experience',
      experienceFields,
      widget.repository.experiences,
      Experience.fromJson,
    ),
    DashboardDestination.skills => () => _edit(
      'Add skill category',
      categoryFields,
      widget.repository.skillCategories,
      SkillCategory.fromJson,
    ),
    DashboardDestination.education => () => _edit(
      'Add education',
      educationFields,
      widget.repository.education,
      Education.fromJson,
    ),
    _ => null,
  };
  List<Widget> _body() {
    final c = _content!;
    switch (widget.destination) {
      case DashboardDestination.articles:
        return [
          if (c.articles.isEmpty)
            const Text(
              'No articles yet. Add your first article; the website stays hidden until published articles are copied there.',
            ),
          for (final article in _browse.slice(_matched).cast<Article>())
            _card(
              article.id,
              article.title,
              [
                _text(
                  'Status',
                  article.isPublished ? 'Included in website export' : 'Draft',
                ),
                _text('Date', article.publishedOn),
                _text('Summary', article.summary),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(article.title),
                      content: SizedBox(
                        width: 680,
                        child: SingleChildScrollView(
                          child: SelectableText(article.body),
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
                  child: const Text('Read article'),
                ),
              ],
              () => _edit(
                'Edit article',
                articleFields,
                widget.repository.articles,
                Article.fromJson,
                article,
              ),
              remove: () =>
                  _delete(widget.repository.articles, article, article.title),
            ),
        ];
      case DashboardDestination.personal:
        final p = c.profiles.single;
        return [
          _card(
            p.id,
            p.name,
            [
              _text('Hero', '${p.heroName} ${p.heroTitle}'),
              _text('Tagline', p.tagline),
              _text('About Me', p.bio),
              _text('Contact email', p.email),
              _text('Contact phone', p.phone),
              _text('Contact location', p.location),
              for (final d in p.personalDetails) _text(d.label, d.value),
              if (p.socialLinks.isEmpty) const Text('No social links yet.'),
              for (final link in p.socialLinks) _text(link.label, link.url),
            ],
            () => _edit(
              'Edit personal information',
              profileFields,
              widget.repository.profiles,
              PersonalProfile.fromJson,
              p,
            ),
          ),
        ];
      case DashboardDestination.experience:
        return [
          if (c.experiences.isEmpty)
            const Text('No experience records yet. Add your first role.'),
          for (final e in _browse.slice(_matched).cast<Experience>())
            _card(
              e.id,
              e.role,
              [
                _text('Company', e.company),
                _text('Duration', e.duration),
                _text('Location', e.location),
                if (e.isCurrent) const Text('Current position'),
                for (final h in e.highlights) _text('Highlight', h),
                for (final m in e.milestones)
                  _text(
                    '${m.type}: ${m.title}',
                    '${m.duration}\n${m.highlights.join('\n')}',
                  ),
              ],
              () => _edit(
                'Edit experience',
                experienceFields,
                widget.repository.experiences,
                Experience.fromJson,
                e,
              ),
              remove: () => _delete(widget.repository.experiences, e, e.role),
            ),
        ];
      case DashboardDestination.skills:
        return [
          if (c.skillCategories.isEmpty)
            const Text('No skill categories yet. Add your first category.'),
          for (final category in _browse.slice(_matched).cast<SkillCategory>())
            _card(
              category.id,
              category.title,
              [
                if (category.skills.isEmpty)
                  const Text('No technologies in this category yet.'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final skill in category.skills)
                      Tooltip(
                        message:
                            '${skill.assetPath} · ${skill.themeAdaptive ? 'Theme adaptive' : 'Fixed color'}',
                        child: Chip(
                          avatar: CircleAvatar(
                            backgroundColor: Color(skill.colorValue),
                            radius: 7,
                          ),
                          label: Text(skill.label),
                        ),
                      ),
                  ],
                ),
              ],
              () => _edit(
                'Edit skill category',
                categoryFields,
                widget.repository.skillCategories,
                SkillCategory.fromJson,
                category,
              ),
              remove: () => _delete(
                widget.repository.skillCategories,
                category,
                category.title,
              ),
            ),
        ];
      case DashboardDestination.education:
      case DashboardDestination.certifications:
        final certificates =
            widget.destination == DashboardDestination.certifications;
        return [
          if (c.education.isEmpty)
            Text(
              certificates
                  ? 'No education records yet. Add one in Education to attach a certificate.'
                  : 'No education records yet. Add your first qualification.',
            ),
          if (certificates &&
              c.education.isNotEmpty &&
              !c.education.any((e) => e.certificateUrl?.isNotEmpty ?? false))
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'No certificate links yet. Choose an education record below to add one.',
              ),
            ),
          for (final e in _browse.slice(_matched).cast<Education>())
            _card(
              e.id,
              e.degree,
              [
                _text('Institution', e.institution),
                _text('Duration', e.duration),
                _text('Location', e.location),
                if (e.isCurrent) const Text('Currently studying'),
                _text(
                  'Certificate',
                  e.certificateUrl?.isNotEmpty == true
                      ? e.certificateUrl!
                      : 'No certificate link',
                ),
              ],
              () => _edit(
                certificates ? 'Edit certificate link' : 'Edit education',
                certificates ? certificateFields : educationFields,
                widget.repository.education,
                Education.fromJson,
                e,
              ),
              editLabel: certificates
                  ? e.certificateUrl?.isNotEmpty == true
                        ? 'Edit certificate'
                        : 'Add certificate'
                  : 'Edit',
              remove: certificates
                  ? e.certificateUrl?.isNotEmpty == true
                        ? () => _removeCertificate(e)
                        : null
                  : () => _delete(widget.repository.education, e, e.degree),
              deleteLabel: certificates ? 'Remove certificate' : 'Delete',
            ),
        ];
      case DashboardDestination.settings:
        final settings = c.settings.single;
        return [
          _card(
            settings.id,
            'Website identity and navigation',
            [
              _text('Brand', '${settings.brandName}${settings.brandSuffix}'),
              _text('Application title', settings.appTitle),
              _text('Browser title', settings.browserTitle),
              _text('Description', settings.description),
              _text(
                'CV',
                '${settings.cvLabel} · ${settings.cvDownloadFilename}',
              ),
              _text(
                'Navigation',
                settings.navigationLabels.map((n) => n.label).join(' / '),
              ),
            ],
            () => _edit(
              'Edit website settings',
              settingsFields,
              widget.repository.settings,
              SiteSettings.fromJson,
              settings,
            ),
          ),
          Text(
            'Section headings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (c.sectionContent.isEmpty)
            const Text('No section headings are available.'),
          for (final section in c.sectionContent)
            _card(
              section.id,
              section.heading,
              [
                _text('Website section', section.id),
                _text(
                  'Subtitle',
                  section.subtitle.isEmpty ? '(No subtitle)' : section.subtitle,
                ),
              ],
              () => _edit(
                'Edit ${section.id} heading',
                sectionFields,
                widget.repository.sectionContent,
                SectionContent.fromJson,
                section,
              ),
            ),
        ];
      default:
        return [];
    }
  }

  Future<void> _exportArticles() async {
    setState(() => _busy = true);
    try {
      final content = await widget.repository.read();
      await Clipboard.setData(
        ClipboardData(text: exportWebsiteArticles(content.articles)),
      );
      _message(
        'Copied published articles. Paste into portfolio_app/assets/content/articles.json, then rebuild the website.',
      );
    } catch (error) {
      _message('Could not copy articles: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _text(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SelectableText('$label: $value'),
  );
  Widget _card(
    String id,
    String title,
    List<Widget> body,
    VoidCallback edit, {
    VoidCallback? remove,
    String editLabel = 'Edit',
    String deleteLabel = 'Delete',
  }) => Padding(
    key: ValueKey('content-row-$id'),
    padding: const EdgeInsets.only(bottom: 20),
    child: DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...body,
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: ValueKey('edit-content-$id'),
                onPressed: _busy ? null : edit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(editLabel),
              ),
              if (_ordered != null) ...[
                IconButton(
                  key: ValueKey('order-up-$id'),
                  tooltip: 'Move earlier',
                  onPressed: _busy || !_browse.canReorder || _all.first.id == id
                      ? null
                      : () => _move(id, -1),
                  icon: const Icon(Icons.arrow_upward, size: 18),
                ),
                IconButton(
                  key: ValueKey('order-down-$id'),
                  tooltip: 'Move later',
                  onPressed: _busy || !_browse.canReorder || _all.last.id == id
                      ? null
                      : () => _move(id, 1),
                  icon: const Icon(Icons.arrow_downward, size: 18),
                ),
              ],
              if (remove != null)
                TextButton.icon(
                  key: ValueKey('delete-content-$id'),
                  onPressed: _busy ? null : remove,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(deleteLabel),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
