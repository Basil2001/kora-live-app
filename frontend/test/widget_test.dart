import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kora/main.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kora_test_hive');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('matches_cache');
    await Hive.openBox('news_cache');
    await Hive.openBox('standings_cache');
    await Hive.openBox('cache_meta');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('KoraApp smoke test - renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KoraApp(),
      ),
    );
    expect(find.byType(KoraApp), findsOneWidget);
  });
}
