import 'package:flutter/services.dart';

import '../repositories/local_portfolio_repository.dart';
import '../repositories/portfolio_repository.dart';
import 'json_portfolio_store.dart';

Future<PortfolioRepository> openLocalPortfolio() async {
  final store = JsonPortfolioStore(JsonPortfolioStore.applicationDirectory());
  await store.initialize(
    loadSeed: () => rootBundle.loadString('assets/seed/portfolio.json'),
    loadSeedMedia: (sourcePath) async {
      final data = await rootBundle.load('assets/seed/media/$sourcePath');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    },
  );
  return LocalPortfolioRepository(store);
}
