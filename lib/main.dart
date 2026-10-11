import 'package:flutter/material.dart';

import 'data/open_local_portfolio.dart';
import 'repositories/portfolio_repository.dart';
import 'theme/dashboard_theme.dart';
import 'widgets/portfolio_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PortfolioAdminDashboardApp());
}

class PortfolioAdminDashboardApp extends StatelessWidget {
  const PortfolioAdminDashboardApp({
    super.key,
    this.openRepository = openLocalPortfolio,
  });
  final Future<PortfolioRepository> Function() openRepository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Portfolio Admin Dashboard',
    debugShowCheckedModeBanner: false,
    theme: DashboardTheme.light,
    home: PortfolioBootstrap(openRepository: openRepository),
  );
}
