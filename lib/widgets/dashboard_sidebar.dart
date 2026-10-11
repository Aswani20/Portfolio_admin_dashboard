import 'package:flutter/material.dart';

import '../navigation/dashboard_destination.dart';
import '../theme/dashboard_theme.dart';
import 'dashboard_components.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.compact,
  });
  final DashboardDestination selected;
  final ValueChanged<DashboardDestination> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: compact ? 80 : 248,
    child: ColoredBox(
      color: DashboardTheme.sidebar,
      child: Column(
        children: [
          SizedBox(
            height: 88,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: DashboardTheme.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.dashboard_customize_outlined,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PORTFOLIO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'Admin workspace',
                              style: TextStyle(
                                color: Color(0xFFB4C1D4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final destination in DashboardDestination.values) ...[
                  if (!compact &&
                      (destination == DashboardDestination.projects ||
                          destination == DashboardDestination.media))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 24, 0, 10),
                      child: Text(
                        destination.group.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF93A5C0),
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _SidebarItem(
                      destination: destination,
                      active: selected == destination,
                      compact: compact,
                      onTap: () => onSelected(destination),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!compact)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StatusBadge('LOCAL WORKSPACE'),
                  const SizedBox(height: 10),
                  const Text(
                    'Your portfolio, organized.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Website publishing comes later.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: const Color(0xFFB4C1D4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.active,
    required this.compact,
    required this.onTap,
  });
  final DashboardDestination destination;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: active,
    child: Tooltip(
      message: compact ? destination.label : '',
      child: Material(
        color: active ? const Color(0xFF304777) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: ValueKey('nav-${destination.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 14,
              vertical: 14,
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  destination.icon,
                  size: 20,
                  color: active ? Colors.white : const Color(0xFFB4C1D4),
                  semanticLabel: compact ? destination.label : null,
                ),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destination.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? Colors.white : const Color(0xFFB4C1D4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
