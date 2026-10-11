import 'package:flutter/material.dart';

import '../models/portfolio_content.dart';
import '../repositories/portfolio_repository.dart';
import 'dashboard_shell.dart';

class PortfolioBootstrap extends StatefulWidget {
  const PortfolioBootstrap({super.key, required this.openRepository});
  final Future<PortfolioRepository> Function() openRepository;
  @override
  State<PortfolioBootstrap> createState() => _PortfolioBootstrapState();
}

class _PortfolioBootstrapState extends State<PortfolioBootstrap> {
  late Future<(PortfolioRepository, PortfolioContent)> _content;
  @override
  void initState() {
    super.initState();
    _content = _load();
  }

  Future<(PortfolioRepository, PortfolioContent)> _load() async {
    final repository = await widget.openRepository();
    return (repository, await repository.read());
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<(PortfolioRepository, PortfolioContent)>(
        future: _content,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return DashboardShell(
              repository: snapshot.data!.$1,
              content: snapshot.data!.$2,
            );
          }
          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Portfolio Admin Dashboard',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (snapshot.hasError) ...[
                        const Icon(Icons.folder_off_outlined, size: 40),
                        const SizedBox(height: 16),
                        const Text(
                          'Your local content could not be opened.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => setState(() {
                            _content = _load();
                          }),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ] else ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text('Opening your local portfolio…'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
