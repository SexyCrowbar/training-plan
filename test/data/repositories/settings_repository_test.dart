import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/data/db/app_database.dart';
import 'package:protocol/data/repositories/settings_repository.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SettingsKeys.onboardingSeen', () {
    test('defaults to false when never set', () async {
      final seen = await repo.getBool(
        SettingsKeys.onboardingSeen,
        defaultValue: false,
      );
      expect(seen, isFalse);
    });

    test('returns true after setBool(true)', () async {
      await repo.setBool(SettingsKeys.onboardingSeen, true);
      final seen = await repo.getBool(
        SettingsKeys.onboardingSeen,
        defaultValue: false,
      );
      expect(seen, isTrue);
    });
  });
}
