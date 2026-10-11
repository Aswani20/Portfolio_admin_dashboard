import 'dart:math';

abstract final class RecordIds {
  /// Generate once at creation. Never derive an ID from an editable title.
  static String create() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
