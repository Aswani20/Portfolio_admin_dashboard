import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/portfolio_models.dart';
import '../../repositories/media_repository.dart';

/// All media bytes are obtained through the repository, never a widget file read.
class ProjectImage extends StatefulWidget {
  const ProjectImage({
    super.key,
    required this.repository,
    required this.media,
    required this.path,
    this.width = 104,
    this.height = 70,
  });
  final MediaRepository repository;
  final List<MediaAsset> media;
  final String? path;
  final double width;
  final double height;
  @override
  State<ProjectImage> createState() => _ProjectImageState();
}

class _ProjectImageState extends State<ProjectImage> {
  Future<Uint8List>? _bytes;
  void _load() {
    final matches = widget.media.where(
      (asset) => asset.sourcePath == widget.path,
    );
    _bytes = matches.isEmpty
        ? null
        : widget.repository.readMedia(matches.first.id);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ProjectImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path ||
        widget.repository != oldWidget.repository ||
        widget.media != oldWidget.media) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: widget.width,
      height: widget.height,
      child: ColoredBox(
        color: const Color(0xFFEEF1F6),
        child: _bytes == null
            ? const Icon(Icons.image_outlined, color: Colors.blueGrey)
            : FutureBuilder<Uint8List>(
                future: _bytes,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Tooltip(
                      message: 'Image unavailable',
                      child: Icon(Icons.broken_image_outlined),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    cacheWidth:
                        (widget.width * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                    errorBuilder: (_, error, stack) => const Tooltip(
                      message: 'Image could not be decoded',
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  );
                },
              ),
      ),
    ),
  );
}
