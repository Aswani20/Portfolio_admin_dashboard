import 'package:flutter/material.dart';

import '../navigation/dashboard_destination.dart';
import '../theme/dashboard_theme.dart';
import '../widgets/dashboard_components.dart';

typedef _Section = ({String title, String description, IconData icon});
typedef _PageDetails = ({
  String description,
  String note,
  List<_Section> sections,
});

/// Describes future content scope, not editable records or persisted data.
const _details = <DashboardDestination, _PageDetails>{
  DashboardDestination.projects: (
    description: 'Showcase the work that defines your portfolio.',
    note: 'The website contains 8 static project entries. This page is a UI placeholder; project records are not loaded or editable.',
    sections: [
      (
        title: 'Project details',
        description:
            'Titles, descriptions and technology tags for each project.',
        icon: Icons.work_outline,
      ),
      (
        title: 'Project galleries',
        description: 'Ordered screenshots for single-image and multi-image project cards.',
        icon: Icons.collections_outlined,
      ),
      (
        title: 'External links',
        description:
            'Optional GitHub repositories and live demo or release links.',
        icon: Icons.link,
      ),
    ],
  ),
  DashboardDestination.personal: (
    description: 'Your introduction, biography and ways to get in touch.',
    note: 'Combines the existing Hero, About and Contact website sections. Contact uses the visitor’s email app; there is no message inbox.',
    sections: [
      (
        title: 'Hero & introduction',
        description: 'Name, professional title, tagline, profile photo and call-to-action labels.',
        icon: Icons.person_outline,
      ),
      (
        title: 'About you',
        description: 'Biography and shared personal details displayed in the About section.',
        icon: Icons.badge_outlined,
      ),
      (
        title: 'Contact & social links',
        description:
            'Email, phone, location and GitHub, LinkedIn and WhatsApp links.',
        icon: Icons.alternate_email,
      ),
    ],
  ),
  DashboardDestination.experience: (
    description: 'Your professional journey, roles and career milestones.',
    note: 'The website contains 3 experience entries and 1 nested career milestone. This preview does not load or edit those records.',
    sections: [
      (
        title: 'Roles & organizations',
        description:
            'Role, company, duration, location and current-position status.',
        icon: Icons.business_center_outlined,
      ),
      (
        title: 'Highlights',
        description: 'Responsibilities and achievements presented on each timeline entry.',
        icon: Icons.format_list_bulleted,
      ),
      (
        title: 'Career milestones',
        description: 'Nested career progression with titles, dates, types and highlights.',
        icon: Icons.timeline,
      ),
    ],
  ),
  DashboardDestination.skills: (
    description: 'The technologies and tools behind your work.',
    note: 'Source snapshot: 15 skills in 4 categories. Skills remain static maps in the website; no content connection is configured.',
    sections: [
      (
        title: 'Mobile Development',
        description: 'Flutter, Dart and Firebase.',
        icon: Icons.phone_android,
      ),
      (
        title: 'Backend & Database',
        description: 'PHP, Laravel and MySQL.',
        icon: Icons.storage_outlined,
      ),
      (
        title: 'Game Development',
        description: 'Unity, Unreal Engine, C++, C# and Blueprint.',
        icon: Icons.sports_esports_outlined,
      ),
      (
        title: 'Tools',
        description: 'Git, GitHub, Figma and Postman.',
        icon: Icons.construction_outlined,
      ),
    ],
  ),
  DashboardDestination.education: (
    description: 'Academic background, diplomas and professional learning.',
    note: 'The website contains 5 education entries. Each may include a certificate link; those links are described under Certifications.',
    sections: [
      (
        title: 'Qualifications',
        description: 'Degree or course title and institution.',
        icon: Icons.school_outlined,
      ),
      (
        title: 'Timeline details',
        description: 'Duration, location and current-study status.',
        icon: Icons.event_outlined,
      ),
      (
        title: 'Display order',
        description: 'The order of entries in the existing education timeline.',
        icon: Icons.format_list_numbered,
      ),
    ],
  ),
  DashboardDestination.certifications: (
    description: 'Certificate links associated with your education.',
    note: 'The website has no standalone Certifications section. Its Education model supports an optional certificateUrl; none of the current entries supplies one.',
    sections: [
      (
        title: 'Education certificates',
        description: 'Future certificate links will belong to education entries, following the existing website model.',
        icon: Icons.verified_outlined,
      ),
      (
        title: 'No certificates connected',
        description: 'This is a placeholder for certificate links, not a list of earned certifications.',
        icon: Icons.link_off_outlined,
      ),
    ],
  ),
  DashboardDestination.media: (
    description: 'The images, icons and documents that tell your story.',
    note: 'Source snapshot: 22 raster images, 19 SVG icons and 1 CV PDF. Assets remain in the website; this is not a connected file browser.',
    sections: [
      (
        title: 'Images · 22',
        description: 'One profile photo and 21 project screenshots, including FindWay and Aflam Night galleries.',
        icon: Icons.image_outlined,
      ),
      (
        title: 'Icons · 19',
        description: 'Technology and social SVG icons used by the website.',
        icon: Icons.interests_outlined,
      ),
      (
        title: 'CV document · 1',
        description: 'The existing web/cv.pdf download. Uploading and replacing files are not available yet.',
        icon: Icons.description_outlined,
      ),
    ],
  ),
  DashboardDestination.analytics: (
    description: 'A future view of how people discover your portfolio.',
    note: 'Not connected. The existing website has no analytics integration. No visitor numbers, trends or traffic sources are available.',
    sections: [
      (
        title: 'Visitors · —',
        description: 'Unavailable. No visitor data is collected or loaded.',
        icon: Icons.people_outline,
      ),
      (
        title: 'Page views · —',
        description: 'Unavailable. No tracking source is configured.',
        icon: Icons.visibility_outlined,
      ),
      (
        title: 'Traffic sources · —',
        description:
            'Unavailable. No referral or acquisition data is connected.',
        icon: Icons.travel_explore,
      ),
    ],
  ),
  DashboardDestination.settings: (
    description: 'Shared website identity and workspace preferences.',
    note: 'Settings controls are not available yet. Imported site settings are stored locally; website files are unchanged.',
    sections: [
      (
        title: 'Website identity',
        description: 'Future controls for branding, navigation labels, browser title and description.',
        icon: Icons.language,
      ),
      (
        title: 'CV presentation',
        description: 'Future controls for the download label and filename.',
        icon: Icons.file_download_outlined,
      ),
      (
        title: 'Workspace preferences',
        description: 'Reserved for a later phase. Navigation currently lives only in memory.',
        icon: Icons.tune,
      ),
    ],
  ),
};

class ContentPage extends StatelessWidget {
  const ContentPage({super.key, required this.destination});
  final DashboardDestination destination;

  @override
  Widget build(BuildContext context) {
    final details = _details[destination]!;
    return Column(
      key: ValueKey('page-${destination.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          title: destination.label,
          description: details.description,
          badge: destination == DashboardDestination.analytics
              ? 'Not connected'
              : 'UI preview',
        ),
        DashboardPanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(destination.icon, size: 24, color: DashboardTheme.accent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current website scope',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(details.note),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          destination == DashboardDestination.analytics
              ? 'Data availability'
              : 'Section preview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ResponsiveCards(
          children: [
            for (final section in details.sections)
              ScopeCard(
                icon: section.icon,
                title: section.title,
                description: section.description,
              ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Preview only · Content management will be available in a later phase.',
          style: TextStyle(fontSize: 12, color: DashboardTheme.muted),
        ),
      ],
    );
  }
}
