import '../db/app_database.dart';

class SettingsKeys {
  static const activeTemplateId = 'active_template_id';
  static const weekStartDate = 'weekStartDate';
  static const remindersEnabled = 'reminders_enabled';
  static const startHour = 'start_hour';
  static const endHour = 'end_hour';
  static const restTimerAlertEnabled = 'rest_timer_alert_enabled';
  static const planVersion = 'plan_version';
}

class SettingsRepository {
  final AppDatabase db;
  SettingsRepository(this.db);

  Future<String?> get(String key) async {
    final row =
        await (db.select(db.appSettings)..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value),
        );
  }

  Stream<String?> watch(String key) {
    return (db.select(db.appSettings)..where((s) => s.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  Future<int?> getInt(String key) async {
    final v = await get(key);
    if (v == null) return null;
    return int.tryParse(v);
  }

  Stream<int?> watchInt(String key) =>
      watch(key).map((v) => v == null ? null : int.tryParse(v));

  Future<void> setInt(String key, int value) => set(key, value.toString());

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final v = await get(key);
    return v == 'true' ? true : (v == 'false' ? false : defaultValue);
  }

  Stream<bool> watchBool(String key, {bool defaultValue = false}) =>
      watch(key).map((v) => v == 'true' ? true : (v == 'false' ? false : defaultValue));

  Future<void> setBool(String key, bool value) => set(key, value ? 'true' : 'false');
}
