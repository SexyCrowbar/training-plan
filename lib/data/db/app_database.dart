import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

class Templates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

class TemplateBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId =>
      integer().references(Templates, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayId => integer()();
  TextColumn get blockId => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {templateId, dayId, blockId},
      ];
}

class TemplateExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get blockRefId =>
      integer().references(TemplateBlocks, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get exerciseId => text()();
  TextColumn get name => text()();
  IntColumn get sets => integer()();
  TextColumn get target => text()();
  IntColumn get restSeconds => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

class WorkoutLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer()(); // epoch millis
  IntColumn get templateId =>
      integer().nullable().references(Templates, #id, onDelete: KeyAction.setNull)();
  IntColumn get dayId => integer()();
  TextColumn get blockId => text()();
  TextColumn get blockName => text()();
  TextColumn get blockIcon => text()();
  TextColumn get theme => text()();
}

class ExerciseSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get logId =>
      integer().references(WorkoutLogs, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().withDefault(const Constant(''))();
  TextColumn get exerciseName => text()();
  IntColumn get setNumber => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get reps => integer().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

class GtgLogs extends Table {
  TextColumn get date => text()(); // "YYYY-MM-DD"
  IntColumn get dayId => integer()();
  IntColumn get count => integer()();

  @override
  Set<Column> get primaryKey => {date, dayId};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Templates,
    TemplateBlocks,
    TemplateExercises,
    WorkoutLogs,
    ExerciseSets,
    GtgLogs,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'protocol.db'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

    return NativeDatabase.createInBackground(file);
  });
}
