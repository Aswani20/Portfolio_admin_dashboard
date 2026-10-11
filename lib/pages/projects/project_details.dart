import 'package:flutter/material.dart';

import '../../models/portfolio_models.dart';
import '../../repositories/portfolio_repository.dart';
import 'project_image.dart';

class ProjectDetails extends StatelessWidget {
  const ProjectDetails({
    super.key,
    required this.project,
    required this.repository,
    required this.media,
    required this.position,
  });
  final Project project;
  final PortfolioRepository repository;
  final List<MediaAsset> media;
  final int position;
  @override
  Widget build(BuildContext context) => Dialog(
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Project details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('close-project-details'),
                    tooltip: 'Close details',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      project.title,
                      key: const ValueKey('details-title'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Display position $position · ${project.imagePaths.length} screenshots',
                    ),
                    const SizedBox(height: 20),
                    SelectableText(project.description),
                    const SizedBox(height: 20),
                    Text(
                      'Technologies',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (project.techStack.isEmpty)
                      const Text('No technologies specified.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tech in project.techStack)
                            Chip(label: Text(tech)),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'GitHub',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SelectableText(project.githubUrl ?? 'Not provided'),
                    const SizedBox(height: 12),
                    Text(
                      'Live demo / release',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SelectableText(project.liveUrl ?? 'Not provided'),
                    const SizedBox(height: 24),
                    Text(
                      'Screenshot gallery',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (project.imagePaths.isEmpty)
                      const Text('No screenshots selected.')
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 16,
                        children: [
                          for (var i = 0; i < project.imagePaths.length; i++)
                            SizedBox(
                              width: 210,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ProjectImage(
                                    repository: repository,
                                    media: media,
                                    path: project.imagePaths[i],
                                    width: 210,
                                    height: 130,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${i + 1}. ${project.imagePaths[i].split('/').last}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    SelectableText(
                      'Record ID: ${project.id}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
