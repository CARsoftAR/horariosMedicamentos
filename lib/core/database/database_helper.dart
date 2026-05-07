import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';


/// [DatabaseHelper] es el punto de acceso central para la persistencia local.
/// Sigue el patrón Singleton para asegurar una única instancia de la base de datos.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Constructor interno para el patrón Singleton
  DatabaseHelper._internal();

  // Factory para retornar la instancia única
  factory DatabaseHelper() => _instance;

  /// Retorna la instancia de la base de datos, inicializándola si es necesario.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos en el almacenamiento local del dispositivo.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medication_app.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // Habilitar claves foráneas para integridad referencial
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  /// Define la estructura de las tablas al crear la base de datos.
  Future<void> _onCreate(Database db, int version) async {
    // Tabla de Medicamentos
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT,
        stock INTEGER DEFAULT 0,
        color INTEGER,
        icon INTEGER,
        frequency TEXT,
        alarm_sound TEXT,
        sound_uri TEXT
      )
    ''');

    // Tabla de Horarios (Schedules)
    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL,
        time TEXT NOT NULL,
        active INTEGER DEFAULT 1,
        FOREIGN KEY (med_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de Historial de Tomas (Intake History)
    await db.execute('''
      CREATE TABLE intake_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        user TEXT,
        FOREIGN KEY (med_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de Usuarios
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'User'
      )
    ''');

    // Insertar Admin por defecto
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'Admin'
    });
  }

  /// Maneja la actualización del esquema entre versiones.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE intake_history ADD COLUMN user TEXT');
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'User'
        )
      ''');
      await db.insert('users', {
        'username': 'admin',
        'password': 'admin123',
        'role': 'Admin'
      });
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE medications ADD COLUMN frequency TEXT');
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE medications ADD COLUMN alarm_sound TEXT');
      } catch (e) {
        debugPrint("Columna alarm_sound ya existe: $e");
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE medications ADD COLUMN sound_uri TEXT');
      } catch (e) {
        debugPrint("Columna sound_uri ya existe: $e");
      }
    }
  }



  // ==========================================
  // MÉTODOS DE AUTENTICACIÓN
  // ==========================================

  Future<Map<String, dynamic>?> login(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // ==========================================
  // MÉTODOS CRUD: MEDICATIONS
  // ==========================================

  Future<int> insertMedication(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('medications', data);
  }

  Future<List<Map<String, dynamic>>> getAllMedications() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    return await db.rawQuery('''
      SELECT m.*, s.time,
      (SELECT COUNT(*) FROM intake_history h WHERE h.med_id = m.id AND h.status = 'Tomada' AND h.timestamp LIKE '$today%') as is_taken_today
      FROM medications m
      LEFT JOIN schedules s ON m.id = s.med_id
      GROUP BY m.id
      ORDER BY s.time ASC
    ''');

  }


  Future<int> updateMedication(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'medications',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await database;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // MÉTODOS CRUD: SCHEDULES
  // ==========================================

  Future<int> insertSchedule(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('schedules', data);
  }

  Future<List<Map<String, dynamic>>> getSchedulesByMedication(int medId) async {
    final db = await database;
    return await db.query(
      'schedules',
      where: 'med_id = ?',
      whereArgs: [medId],
    );
  }

  Future<int> updateSchedule(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'schedules',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSchedule(int id) async {
    final db = await database;
    return await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Actualiza o inserta el horario para un medicamento.
  Future<void> updateMedicationSchedule(int medId, String time) async {
    final db = await database;
    // Por ahora, asumimos un único horario por medicamento para este flujo.
    final existing = await db.query('schedules', where: 'med_id = ?', whereArgs: [medId]);
    if (existing.isNotEmpty) {
      await db.update('schedules', {'time': time}, where: 'med_id = ?', whereArgs: [medId]);
    } else {
      await db.insert('schedules', {'med_id': medId, 'time': time, 'active': 1});
    }
  }

  // ==========================================
  // MÉTODOS CRUD: INTAKE HISTORY
  // ==========================================

  Future<int> insertIntakeHistory(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('intake_history', data);
  }

  /// Registra una toma y descuenta automáticamente el stock del medicamento.
  Future<void> recordIntake(int medId, String status, String timestamp, String? user) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // 1. Insertar en historial
      await txn.insert('intake_history', {
        'med_id': medId,
        'status': status,
        'timestamp': timestamp,
        'user': user,
      });

      // 2. Descontar stock
      await txn.execute(
        'UPDATE medications SET stock = MAX(0, stock - 1) WHERE id = ?',
        [medId],
      );
    });
  }

  Future<List<Map<String, dynamic>>> getAllIntakeHistory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT h.*, m.name as med_name, m.color as med_color
      FROM intake_history h
      JOIN medications m ON h.med_id = m.id
      ORDER BY h.timestamp DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getHistoryByMedication(int medId) async {
    final db = await database;
    return await db.query(
      'intake_history',
      where: 'med_id = ?',
      whereArgs: [medId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> updateIntakeStatus(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'intake_history',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteIntakeRecord(int id) async {
    final db = await database;
    return await db.delete(
      'intake_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Cierra la conexión de la base de datos cuando ya no es necesaria.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
