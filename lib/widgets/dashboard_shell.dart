import '../models/list_browse_state.dart';
import '../pages/content/content_management_page.dart';
import '../pages/media/media_library.dart';
import '../repositories/portfolio_repository.dart';
import '../pages/projects/projects_page.dart';
import '../models/portfolio_content.dart';

import 'package:flutter/material.dart';

import '../navigation/dashboard_destination.dart';
import '../pages/overview_page.dart';
import '../pages/website_analytics_page.dart';
import '../theme/dashboard_theme.dart';
import 'dashboard_components.dart';
import 'dashboard_sidebar.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    required this.content,
    required this.repository,
  });
  final PortfolioContent content;
  final PortfolioRepository repository;
  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  late PortfolioContent _content = widget.content;
  final _browsing = <DashboardDestination, ListBrowseState>{};
  ListBrowseState get _browse =>
      _browsing.putIfAbsent(_selected, ListBrowseState.new);
  DashboardDestination _selected = DashboardDestination.overview;
  void _navigate(DashboardDestination destination) {
    if (_selected != destination) setState(() => _selected = destination);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 1100;
      return Scaffold(
        body: Row(
          children: [
            DashboardSidebar(
              selected: _selected,
              onSelected: _navigate,
              compact: compact,
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 76,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 20 : 32,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: DashboardTheme.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (!compact) ...[
                          const Text(
                            'Workspace',
                            style: TextStyle(
                              color: DashboardTheme.muted,
                              fontSize: 13,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: DashboardTheme.muted,
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            _selected.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (constraints.maxWidth >= 700) ...[
                          const StatusBadge('Local content'),
                          const SizedBox(width: 20),
                        ],
                        const Tooltip(
                          message: 'Portfolio Admin Dashboard',
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFEEF1FF),
                            child: Icon(
                              Icons.person_outline,
                              color: DashboardTheme.accent,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _PageViewport(
                      key: ValueKey(_selected),
                      padding: compact ? 20 : 32,
                      child: _selected == DashboardDestination.overview
                          ? OverviewPage(
                              onNavigate: _navigate,
                              content: _content,
                            )
                          : _selected == DashboardDestination.projects
                          ? ProjectsPage(
                              browseState: _browse,
                              repository: widget.repository,
                              onContentChanged: (content) {
                                if (mounted) setState(() => _content = content);
                              },
                            )
                          : _selected == DashboardDestination.media
                          ? MediaLibrary(
                              browseState: _browse,
                              repository: widget.repository,
                              onContentChanged: (content) {
                                if (mounted) setState(() => _content = content);
                              },
                            )
                          : _selected == DashboardDestination.analytics
                          ? const WebsiteAnalyticsPage()
                          : ContentManagementPage(
                              browseState: _browse,
                              destination: _selected,
                              repository: widget.repository,
                              onContentChanged: (content) {
                                if (mounted) setState(() => _content = content);
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PageViewport extends StatefulWidget {
  const _PageViewport({super.key, required this.child, required this.padding});
  final Widget child;
  final double padding;
  @override
  State<_PageViewport> createState() => _PageViewportState();
}

class _PageViewportState extends State<_PageViewport> {
  final _controller = ScrollController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _controller,
    thumbVisibility: true,
    child: SingleChildScrollView(
      controller: _controller,
      padding: EdgeInsets.all(widget.padding),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: widget.child,
        ),
      ),
    ),
  );
}
