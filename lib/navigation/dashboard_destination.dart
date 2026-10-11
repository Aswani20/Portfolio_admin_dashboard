import 'package:flutter/material.dart';

/// UI destinations only; no persisted content or website connection.
enum DashboardDestination {
  overview('Overview', Icons.space_dashboard_outlined, 'Workspace'),
  projects('Projects', Icons.work_outline_rounded, 'Portfolio'),
  personal('Personal Information', Icons.person_outline_rounded, 'Portfolio'),
  experience('Experience', Icons.business_center_outlined, 'Portfolio'),
  skills('Skills', Icons.auto_awesome_outlined, 'Portfolio'),
  education('Education', Icons.school_outlined, 'Portfolio'),
  certifications('Certifications', Icons.verified_outlined, 'Portfolio'),
  media('Media Library', Icons.photo_library_outlined, 'Workspace'),
  analytics('Website Analytics', Icons.bar_chart_rounded, 'Workspace'),
  settings('Settings', Icons.settings_outlined, 'Workspace');

  const DashboardDestination(this.label, this.icon, this.group);
  final String label;
  final IconData icon;
  final String group;
}
