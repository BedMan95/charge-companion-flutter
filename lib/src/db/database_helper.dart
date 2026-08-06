import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('charge_companion.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE user_vehicles ADD COLUMN custom_battery_volt REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE user_vehicles ADD COLUMN custom_battery_ah REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE user_vehicles ADD COLUMN custom_efisiensi_charger REAL'); } catch (_) {}
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tuya_credentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT NOT NULL,
        client_secret TEXT NOT NULL,
        device_id TEXT NOT NULL,
        base_url TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pln_tariffs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tariff REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ev_models (
        id TEXT PRIMARY KEY,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        battery_volt INTEGER NOT NULL,
        battery_ah INTEGER NOT NULL,
        efisiensi_charger REAL NOT NULL,
        image_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_vehicles (
        id TEXT PRIMARY KEY,
        ev_model_id TEXT NOT NULL,
        name TEXT,
        image_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 0,
        calibration_usable_battery_kwh REAL,
        calibration_wall_energy_full_kwh REAL,
        calibration_full_charge_hours REAL,
        calibration_taper_start_percent REAL,
        custom_battery_volt REAL,
        custom_battery_ah REAL,
        custom_efisiensi_charger REAL,
        FOREIGN KEY (ev_model_id) REFERENCES ev_models (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE charging_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        persen_awal INTEGER NOT NULL,
        persen_target INTEGER NOT NULL,
        battery_volt INTEGER NOT NULL DEFAULT 72,
        battery_ah INTEGER NOT NULL DEFAULT 38,
        efisiensi_charger REAL NOT NULL DEFAULT 0.82,
        accumulated_energy REAL NOT NULL DEFAULT 0,
        last_fetch_time INTEGER,
        vehicle_id TEXT,
        FOREIGN KEY (vehicle_id) REFERENCES user_vehicles (id)
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
