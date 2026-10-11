import '../models/portfolio_content.dart';

import 'package:flutter/material.dart';

import '../navigation/dashboard_destination.dart';
import '../theme/dashboard_theme.dart';
import '../widgets/dashboard_components.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({
    super.key,
    required this.onNavigate,
    required this.content,
  });
  final PortfolioContent content;
  final ValueChanged<DashboardDestination> onNavigate;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('page-overview'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        title: 'Overview',
        description: 'A clear view of your portfolio content and workspace.',
        badge: 'Local content',
      ),
      const DashboardPanel(
        padding: EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: DashboardTheme.accent, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Local content · Counts reflect your saved local portfolio. Counts update after saved changes. Website publishing is not connected.',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      ResponsiveCards(
        minWidth: 180,
        children: [
          _StatisticCard(
            label: 'Projects',
            value: content.projects.length.toString(),
            detail: 'Portfolio entries',
            destination: DashboardDestination.projects,
            onNavigate: onNavigate,
          ),
          _StatisticCard(
            label: 'Skills',
            value: content.skillCategories
                .fold<int>(
                  0,
                  (count, category) => count + category.skills.length,
                )
                .toString(),
            detail: 'Skills in saved categories',
            destination: DashboardDestination.skills,
            onNavigate: onNavigate,
          ),
          _StatisticCard(
            label: 'Experience',
            value: content.experiences.length.toString(),
            detail: 'Roles & career history',
            destination: DashboardDestination.experience,
            onNavigate: onNavigate,
          ),
          _StatisticCard(
            label: 'Education',
            value: content.education.length.toString(),
            detail: 'Saved education entries',
            destination: DashboardDestination.education,
            onNavigate: onNavigate,
          ),
          _StatisticCard(
            label: 'Certifications',
            value: content.education
                .where(
                  (entry) => entry.certificateUrl?.trim().isNotEmpty ?? false,
                )
                .length
                .toString(),
            detail: 'Education with certificate links',
            destination: DashboardDestination.certifications,
            onNavigate: onNavigate,
          ),
          _StatisticCard(
            label: 'Media assets',
            value: content.media.length.toString(),
            detail: 'Images, icons and documents',
            destination: DashboardDestination.media,
            onNavigate: onNavigate,
          ),
        ],
      ),
      const SizedBox(height: 32),
      LayoutBuilder(
        builder: (context, constraints) {
          final activity = _RecentActivity();
          final workspace = _WorkspaceStatus(onNavigate: onNavigate);
          if (constraints.maxWidth < 850) {
            return Column(
              children: [activity, const SizedBox(height: 20), workspace],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: activity),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: workspace),
            ],
          );
        },
      ),
      const SizedBox(height: 32),
      Text(
        'Explore your content',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 6),
      const Text(
        'Open a section to see what belongs in your portfolio workspace.',
      ),
      const SizedBox(height: 16),
      ResponsiveCards(
        minWidth: 220,
        children: [
          for (final destination in [
            DashboardDestination.personal,
            DashboardDestination.education,
            DashboardDestination.projects,
          ])
            DashboardPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(destination.icon, color: DashboardTheme.accent),
                  const SizedBox(height: 16),
                  Text(
                    destination.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    key: ValueKey('shortcut-${destination.name}'),
                    onPressed: () => onNavigate(destination),
                    label: const Text('Open section'),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    ],
  );
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.destination,
    required this.onNavigate,
  });
  final String label;
  final String value;
  final String detail;
  final DashboardDestination destination;
  final ValueChanged<DashboardDestination> onNavigate;
  @override
  Widget build(BuildContext context) => DashboardPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(destination.icon, color: DashboardTheme.accent, size: 22),
            const Spacer(),
            IconButton(
              tooltip: 'Open $label',
              onPressed: () => onNavigate(destination),
              icon: const Icon(Icons.north_east, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          key: ValueKey('stat-${destination.name}'),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: DashboardTheme.ink,
            letterSpacing: -1,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DashboardPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Recent activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const StatusBadge('Placeholders'),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Future content changes will appear here. No activity has been recorded.',
        ),
        const SizedBox(height: 20),
        for (final entry in [
          (Icons.work_outline, 'Project changes', 'Future project updates'),
          (
            Icons.photo_library_outlined,
            'Media changes',
            'Future image and document updates',
          ),
          (
            Icons.person_outline,
            'Profile changes',
            'Future personal information updates',
          ),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DashboardTheme.canvas,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(entry.$1, size: 20, color: DashboardTheme.muted),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.$2,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        entry.$3,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text('—', style: TextStyle(color: DashboardTheme.muted)),
              ],
            ),
          ),
      ],
    ),
  );
}

class _WorkspaceStatus extends StatelessWidget {
  const _WorkspaceStatus({required this.onNavigate});
  final ValueChanged<DashboardDestination> onNavigate;
  @override
  Widget build(BuildContext context) => DashboardPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Workspace status', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        const StatusBadge('Saved locally'),
        const SizedBox(height: 16),
        const Text(
          'Explore the dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: DashboardTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage your portfolio content and media locally. Website publishing is not connected.',
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 20),
        const Text(
          'Website analytics',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: DashboardTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Not connected. No visitor or traffic data is collected by this dashboard.',
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => onNavigate(DashboardDestination.analytics),
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('View analytics status'),
        ),
      ],
    ),
  );
}
