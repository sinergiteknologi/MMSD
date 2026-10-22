import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/history_unit.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  static const tables = [
    'M_VERSION',
    'M_LOGIN',
    'HISTORYUNIT',
    'M_BRAND',
    'M_TYPE',
    'M_COLOR',
    'M_FLEET',
    'M_ACTIVITY',
    'M_MODEL',
    'M_CITY',
    'M_DISTRICT',
    'M_SUBACTIVITY',
    'T_TRANACT',
    'M_FGOC',
    'M_TOP',
    'M_FGOCContect',
  ];

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = kIsWeb
        ? 'mmsd_database.db'
        : join(await getDatabasesPath(), 'mmsd_database.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        await _onCreate(db, newVersion);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE IF NOT EXISTS M_VERSION(Version TEXT)');
    await db.execute('''CREATE TABLE IF NOT EXISTS M_LOGIN(
        Login TEXT, UserNam TEXT, UserPwd TEXT, BranchCode TEXT, BranchName TEXT,
        SalesCode TEXT, SalesName TEXT, BranchAut TEXT, UserAut TEXT,
        UserGroup TEXT, UserStatus TEXT, BranchNameAut TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS HISTORYUNIT(
        BrandCode TEXT, BrandName TEXT, TypeCode TEXT, TypeName TEXT,
        ModelCode TEXT, ModelName TEXT, ColourCode TEXT, ColourName TEXT,
        ActivityCode TEXT, ActivityName TEXT, Qty TEXT, ProvinceCode TEXT,
        CityCode TEXT, DistrictCode TEXT, SubActivityCode TEXT, ACTNumber TEXT,
        FleetType TEXT, FleetCode TEXT)''');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS M_BRAND(BrandCode TEXT, BrandName TEXT)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS M_TYPE(TypeCode TEXT, TypeName TEXT)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS M_COLOR(ColorCode TEXT, ColorName TEXT)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS M_FLEET(FleetCode TEXT, FleetName TEXT)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS M_TOP(TOPCode TEXT, TOPName TEXT)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS M_ACTIVITY(ActivityCode TEXT, ActivityName TEXT)',
    );
    await db.execute('''CREATE TABLE IF NOT EXISTS M_SUBACTIVITY(
        ActivityCode TEXT, SubActivityCode TEXT, SubActivityName TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS T_TRANACT(
        ACTNumber TEXT, ACTName TEXT, ActivityCode TEXT, SubActivityCode TEXT,
        ProvinceCode TEXT, CityCode TEXT, DistrictCode TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS M_MODEL(
        BrandCode TEXT, TypeCode TEXT, ModelCode TEXT, ModelName TEXT,
        PRIMARY KEY (BrandCode, TypeCode, ModelCode))''');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS M_CITY(ProvinceCode TEXT, CityCode TEXT, CityName TEXT)',
    );
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS M_DISTRICT(
        ProvinceCode TEXT, CityCode TEXT, DistrictCode TEXT, DistrictName TEXT)''',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS M_FGOC(FGOCCode TEXT, FGOCName TEXT, Description TEXT)',
    );
    await db.execute('''CREATE TABLE IF NOT EXISTS M_FGOCContect(
        FGOCName TEXT, FGOCTelp TEXT, FGOCPosition TEXT, FGOCCode TEXT)''');
  }

  Future<void> insertBatch(
    String table,
    List<Map<String, dynamic>> dataList,
  ) async {
    final db = await database;
    final batch = db.batch();
    for (final data in dataList) {
      batch.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> replaceTablesAtomically(
    Map<String, List<Map<String, dynamic>>> dataByTable,
  ) async {
    final unknownTables = dataByTable.keys.where(
      (table) => !tables.contains(table),
    );
    if (unknownTables.isNotEmpty) {
      throw ArgumentError('Unknown tables: ${unknownTables.join(', ')}');
    }
    final db = await database;
    await db.transaction((transaction) async {
      final batch = transaction.batch();
      for (final entry in dataByTable.entries) {
        batch.delete(entry.key);
        for (final row in entry.value) {
          batch.insert(
            entry.key,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, dynamic>>> queryTable(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }

  Future<void> clearTables(List<String> tableNames) async {
    final db = await database;
    for (final table in tableNames) {
      await db.delete(table);
    }
  }

  Future<void> clearAllTables() async {
    await clearTables(tables);
  }

  Future<bool> isDuplicate({
    required String table,
    required Map<String, String> where,
  }) async {
    final clauses = where.keys.map((key) => '$key = ?').join(' AND ');
    final rows = await queryTable(
      table,
      where: clauses,
      whereArgs: where.values.toList(),
    );
    return rows.isNotEmpty;
  }

  Future<void> addLogin(Map<String, dynamic> data) async {
    await insertBatch('M_LOGIN', [data]);
  }

  Future<void> addHistoryUnit(HistoryUnit unit) async {
    await insertBatch('HISTORYUNIT', [unit.toMap()]);
  }

  Future<List<HistoryUnit>> getHistoryUnits() async {
    final rows = await queryTable('HISTORYUNIT');
    return rows.map(HistoryUnit.fromMap).toList();
  }

  Future<void> replaceHistoryUnits(List<HistoryUnit> units) async {
    await clearTable('HISTORYUNIT');
    await insertBatch(
      'HISTORYUNIT',
      units.map((unit) => unit.toMap()).toList(),
    );
  }

  Future<void> deleteHistoryUnitAt(int index) async {
    final units = await getHistoryUnits();
    if (index < 0 || index >= units.length) return;
    units.removeAt(index);
    await replaceHistoryUnits(units);
  }

  Future<void> addVersion(String version) async {
    await insertBatch('M_VERSION', [
      {'Version': version},
    ]);
  }
}
