import '../../models/list_browse_state.dart';
import '../../widgets/list_controls.dart';

import 'package:flutter/material.dart';

import '../../models/portfolio_content.dart';
import '../../models/portfolio_models.dart';
import '../../repositories/portfolio_repository.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/dashboard_components.dart';
import 'project_details.dart';
import 'project_editor.dart';
import 'project_image.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({
    super.key,
    required this.repository,
    this.browseState,
    required this.onContentChanged,
  });
  final PortfolioRepository repository;
  final ListBrowseState? browseState;
  final ValueChanged<PortfolioContent> onContentChanged;
  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late final _browse = widget.browseState ?? ListBrowseState();
  PortfolioContent? _content;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  late ScaffoldMessengerState _messenger;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void initState() {
    super.initState();
    _reload();
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
      if (!mounted) return;
      setState(() {
        _content = content;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _loading = false;
        });
      }
    }
  }

  void _message(String message) {
    if (!_messenger.mounted) return;
    _messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit([Project? project]) async {
    final result = await showDialog<Project>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProjectEditor(
        repository: widget.repository,
        media: _content!.media,
        project: project,
      ),
    );
    if (!mounted) return;
    if (result == null) {
      await _reload();
      return;
    }
    _message(
      project == null
          ? 'Project added locally.'
          : 'Project changes saved locally.',
    );
    await _reload();
  }

  Future<void> _delete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text(
          'Delete “${project.title}” from the local portfolio? Its image files will be kept. The website will not be changed.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel-delete'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete project'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.projects.delete(
        project.id,
        expectedRevision: project.revision,
      );
      _message('Project deleted locally.');
      await _reload();
    } catch (error) {
      _message('Could not delete project: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(Project project, int delta) async {
    final current = _content!.projects;
    final ids = current.map((p) => p.id).toList();
    final from = ids.indexOf(project.id);
    final to = from + delta;
    if (to < 0 || to >= ids.length) return;
    ids.insert(to, ids.removeAt(from));
    setState(() => _busy = true);
    try {
      await widget.repository.reorderProjects(
        ids,
        expectedRevisions: {for (final p in current) p.id: p.revision},
      );
      _browse.page = to ~/ 20;
      _message('Display order saved locally.');
      await _reload();
    } catch (error) {
      _message('Could not reorder projects: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _content?.projects ?? <Project>[];
    final matched = _browse.matching(
      all,
      searchText: (p) => p.title,
      title: (p) => p.title,
      matchesFilter: (p, filter) =>
          p.techStack.any((t) => t.trim().toLowerCase() == filter),
    );
    // Do not clamp the remembered page against an empty loading placeholder.
    final visible = _content == null ? <Project>[] : _browse.slice(matched);
    final technologies = <String, String>{};
    for (final p in all) {
      for (final t in p.techStack) {
        if (t.trim().isNotEmpty) {
          technologies.putIfAbsent(t.trim().toLowerCase(), () => t.trim());
        }
      }
    }
    final sortedTech = technologies.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final disabled = _busy || _loading || _content == null || _error != null;
    return Column(
      key: const ValueKey('page-projects'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          title: 'Projects',
          description:
              'Manage the work you showcase. Changes are saved locally.',
          badge: 'Local content',
        ),
        DashboardPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('add-project'),
                    onPressed: disabled ? null : () => _edit(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add project'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('refresh-projects'),
                    onPressed: _loading || _busy ? null : _reload,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                  Text('${matched.length} of ${all.length} projects'),
                ],
              ),
              const SizedBox(height: 20),
              ListControls(
                name: 'projects',
                state: _browse,
                onChanged: () => setState(() {}),
                enabled: !disabled,
                searchLabel: 'Search projects by title',
                filterLabel: 'Technology',
                filters: Map.fromEntries(sortedTech),
              ),
              ListPager(
                name: 'projects',
                state: _browse,
                total: all.length,
                matched: matched.length,
                enabled: !disabled,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              Text(
                _browse.canReorder
                    ? 'Use the arrows to change display order. New projects are added at the end. Website publishing is not connected.'
                    : 'Reset filters and choose Saved order to change website display order.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (_loading || _busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LinearProgressIndicator(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: DashboardPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projects could not be loaded',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_error!),
                  const SizedBox(height: 8),
                  const Text(
                    'Use Refresh to retry. Existing records have not been changed.',
                  ),
                ],
              ),
            ),
          ),
        if (!_loading && _error == null && visible.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: DashboardPanel(
              child: Column(
                children: [
                  const Icon(
                    Icons.work_outline,
                    size: 40,
                    color: DashboardTheme.muted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    all.isEmpty ? 'No projects yet' : 'No matching projects',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    all.isEmpty
                        ? 'Add your first project to start building your local portfolio.'
                        : 'Try a different title or reset your filters.',
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        for (final project in visible)
          Padding(
            key: ValueKey('project-row-${project.id}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: DashboardPanel(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProjectImage(
                        repository: widget.repository,
                        media: _content!.media,
                        path: project.imagePaths.firstOrNull,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${all.indexOf(project) + 1}. ${project.title}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              project.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${project.imagePaths.length} screenshots · ${project.techStack.length} technologies',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        key: ValueKey('view-${project.id}'),
                        onPressed: disabled
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                builder: (_) => ProjectDetails(
                                  project: project,
                                  repository: widget.repository,
                                  media: _content!.media,
                                  position: all.indexOf(project) + 1,
                                ),
                              ),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('View'),
                      ),
                      TextButton.icon(
                        key: ValueKey('edit-${project.id}'),
                        onPressed: disabled ? null : () => _edit(project),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                      TextButton.icon(
                        key: ValueKey('delete-${project.id}'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: disabled ? null : () => _delete(project),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                      ),
                      IconButton(
                        key: ValueKey('up-${project.id}'),
                        tooltip: 'Move project earlier',
                        onPressed:
                            disabled ||
                                !_browse.canReorder ||
                                all.first.id == project.id
                            ? null
                            : () => _move(project, -1),
                        icon: const Icon(Icons.arrow_upward, size: 18),
                      ),
                      IconButton(
                        key: ValueKey('down-${project.id}'),
                        tooltip: 'Move project later',
                        onPressed:
                            disabled ||
                                !_browse.canReorder ||
                                all.last.id == project.id
                            ? null
                            : () => _move(project, 1),
                        icon: const Icon(Icons.arrow_downward, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
