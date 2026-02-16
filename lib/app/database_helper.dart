import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mycapstone_project/firebase_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('checkup_records.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE checkup_records ADD COLUMN diseaseType TEXT DEFAULT "General"',
        );
      } catch (e) {
        print('Error adding diseaseType column: $e');
      }
    }

    if (oldVersion < 3) {
      // Add new columns for version 3
      try {
        await db.execute('ALTER TABLE checkup_records ADD COLUMN address TEXT');
      } catch (e) {
        print('Error adding address column: $e');
      }

      try {
        await db.execute(
          'ALTER TABLE checkup_records ADD COLUMN vitalsigns TEXT',
        );
      } catch (e) {
        print('Error adding vitalsigns column: $e');
      }

      try {
        await db.execute(
          'ALTER TABLE checkup_records ADD COLUMN symptoms TEXT',
        );
      } catch (e) {
        print('Error adding symptoms column: $e');
      }

      try {
        await db.execute(
          'ALTER TABLE checkup_records ADD COLUMN followup TEXT',
        );
      } catch (e) {
        print('Error adding followup column: $e');
      }

      try {
        await db.execute('ALTER TABLE checkup_records ADD COLUMN age TEXT');
      } catch (e) {
        print('Error adding age column: $e');
      }
    }

    if (oldVersion < 4) {
      // Recreate table without NOT NULL constraints for version 4
      try {
        // Create a temporary table with new schema
        await db.execute('''
          CREATE TABLE checkup_records_new (
            id TEXT PRIMARY KEY,
            datetime TEXT,
            type TEXT,
            diseaseType TEXT DEFAULT 'General',
            patient TEXT,
            details TEXT,
            plan TEXT,
            status TEXT,
            address TEXT,
            vitalsigns TEXT,
            symptoms TEXT,
            followup TEXT,
            age TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');

        // Copy existing data
        await db.execute('''
          INSERT INTO checkup_records_new 
          SELECT id, datetime, type, diseaseType, patient, details, plan, status,
                 address, vitalsigns, symptoms, followup, age, synced
          FROM checkup_records
        ''');

        // Drop old table
        await db.execute('DROP TABLE checkup_records');

        // Rename new table
        await db.execute(
          'ALTER TABLE checkup_records_new RENAME TO checkup_records',
        );

        print('✅ Database upgraded to version 4: Removed NOT NULL constraints');
      } catch (e) {
        print('Error upgrading to version 4: $e');
      }
    }

    if (oldVersion < 5) {
      // Add new columns for version 5
      try {
        await db.execute(
          'ALTER TABLE checkup_records ADD COLUMN createdBy TEXT',
        );
      } catch (e) {
        print('Error adding createdBy column: $e');
      }

      try {
        await db.execute(
          'ALTER TABLE checkup_records ADD COLUMN testRecord INTEGER DEFAULT 0',
        );
      } catch (e) {
        print('Error adding testRecord column: $e');
      }
    }

    if (oldVersion < 6) {
      // Add AI classification columns for version 6
      try {
        await db.execute(
          'ALTER TABLE checkup_records ADD COLUMN ai_category TEXT',
        );
      } catch (e) {
        print('Error adding ai_category column: $e');
      }

      try {
        await db.execute(
          'ALTER TABLE checkup_records ADD COLUMN ai_severity TEXT',
        );
      } catch (e) {
        print('Error adding ai_severity column: $e');
      }

      try {
        await db.execute(
          'ALTER TABLE checkup_records ADD COLUMN ai_confidence TEXT',
        );
      } catch (e) {
        print('Error adding ai_confidence column: $e');
      }

      try {
        await db.execute(
          'ALTER TABLE checkup_records ADD COLUMN ai_method TEXT',
        );
      } catch (e) {
        print('Error adding ai_method column: $e');
      }

      try {
        await db.execute(
          'ALTER TABLE checkup_records ADD COLUMN ai_keywords TEXT',
        );
      } catch (e) {
        print('Error adding ai_keywords column: $e');
      }

      try {
        await db.execute(
          'ALTER TABLE checkup_records ADD COLUMN ai_recovery_plan TEXT',
        );
      } catch (e) {
        print('Error adding ai_recovery_plan column: $e');
      }

      print(
        '✅ Database upgraded to version 6: Added AI classification columns',
      );
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const intType = 'INTEGER';

    await db.execute('''
      CREATE TABLE checkup_records (
        id $idType,
        datetime $textType,
        type $textType,
        diseaseType TEXT DEFAULT 'General',
        patient $textType,
        details $textType,
        plan $textType,
        status $textType,
        address TEXT,
        vitalsigns TEXT,
        symptoms TEXT,
        followup TEXT,
        age TEXT,
        createdBy TEXT,
        testRecord $intType DEFAULT 0,
        synced $intType DEFAULT 0,
        ai_category TEXT,
        ai_severity TEXT,
        ai_confidence TEXT,
        ai_method TEXT,
        ai_keywords TEXT,
        ai_recovery_plan TEXT
      )
    ''');
  }

  // Insert record locally
  Future<String> insertRecord(Map<String, dynamic> record) async {
    final id = record['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    // On web, save directly to Firebase
    if (kIsWeb) {
      try {
        final recordWithId = {...record, 'id': id};
        await getFirestoreInstance()
            .collection('checkup_records')
            .doc(id)
            .set(recordWithId);
        return id;
      } catch (e) {
        print('Error saving to Firebase on web: $e');
        rethrow;
      }
    }

    // On mobile, check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    final db = await database;

    // Convert ai_recovery_plan from Map to JSON string for SQLite
    final recordForDb = Map<String, dynamic>.from(record);
    if (recordForDb['ai_recovery_plan'] is Map) {
      recordForDb['ai_recovery_plan'] = jsonEncode(
        recordForDb['ai_recovery_plan'],
      );
    }

    final recordWithId = {
      ...recordForDb,
      'id': id,
      'synced': hasInternet ? 1 : 0, // Mark as synced if we have internet
    };

    // Save to local database first
    await db.insert(
      'checkup_records',
      recordWithId,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // If online, immediately save to Firestore
    if (hasInternet) {
      try {
        final firestoreData = Map<String, dynamic>.from(recordWithId);
        firestoreData.remove('synced'); // Don't save synced flag to Firestore

        await getFirestoreInstance()
            .collection('checkup_records')
            .doc(id)
            .set(firestoreData);

        print('✅ Record $id saved to Firestore immediately');
      } catch (e) {
        print('⚠️ Failed to save to Firestore, will retry later: $e');
        // Mark as unsynced so it will retry later
        await db.update(
          'checkup_records',
          {'synced': 0},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } else {
      print('📴 Offline: Record $id saved locally, will sync when online');
    }

    return id;
  }

  // Get real-time stream of records (for live updates)
  Stream<List<Map<String, dynamic>>> getRecordsStream() {
    // On web, use Firestore real-time listener
    if (kIsWeb) {
      return getFirestoreInstance()
          .collection('checkup_records')
          .orderBy('datetime', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
          });
    }

    // On mobile, return a stream that updates when data changes
    // This is a simple implementation - for better real-time sync,
    // you might want to use Firestore snapshots and merge with local data
    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      return await getAllRecords();
    });
  }

  // Get all records (one-time fetch)
  Future<List<Map<String, dynamic>>> getAllRecords() async {
    // On web, use Firebase directly
    if (kIsWeb) {
      try {
        final snapshot = await getFirestoreInstance()
            .collection('checkup_records')
            .orderBy('datetime', descending: true)
            .get();
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      } catch (e) {
        print('Error fetching from Firebase on web: $e');
        return [];
      }
    }

    // On mobile, use SQLite
    final db = await database;
    final result = await db.query('checkup_records', orderBy: 'datetime DESC');

    return result.map((record) {
      final map = Map<String, dynamic>.from(record);
      map.remove('synced'); // Remove synced flag from UI data

      // Decode ai_recovery_plan from JSON string to Map
      if (map['ai_recovery_plan'] is String && (map['ai_recovery_plan'] as String).isNotEmpty) {
        try {
          map['ai_recovery_plan'] = jsonDecode(map['ai_recovery_plan']);
        } catch (e) {
          // Silently provide a safe default recovery plan format
          map['ai_recovery_plan'] = {
            'medications': [],
            'home_care': [],
            'precautions': [],
            'estimated_recovery': 'Varies by condition',
            'general_advice': [
              '[OK] Follow healthcare provider instructions',
              '[OK] Complete full course of medications',
              '[OK] Report any worsening symptoms',
              '[OK] Maintain healthy lifestyle habits',
            ],
          };
        }
      }

      return map;
    }).toList();
  }

  // Update record
  Future<int> updateRecord(String id, Map<String, dynamic> record) async {
    // On web, update directly in Firebase
    if (kIsWeb) {
      try {
        final updatedRecord = {...record, 'id': id};
        await getFirestoreInstance()
            .collection('checkup_records')
            .doc(id)
            .update(updatedRecord);
        return 1;
      } catch (e) {
        print('Error updating Firebase on web: $e');
        return 0;
      }
    }

    // On mobile, update in SQLite
    final db = await database;
    final updatedRecord = {
      ...record,
      'id': id,
      'synced': 0, // Mark as unsynced after update
    };

    final result = await db.update(
      'checkup_records',
      updatedRecord,
      where: 'id = ?',
      whereArgs: [id],
    );

    _syncToFirebase();
    return result;
  }

  // Delete record
  Future<int> deleteRecord(String id) async {
    // On web, delete directly from Firebase
    if (kIsWeb) {
      try {
        await getFirestoreInstance()
            .collection('checkup_records')
            .doc(id)
            .delete();
        return 1;
      } catch (e) {
        print('Error deleting from Firebase on web: $e');
        return 0;
      }
    }

    // On mobile, delete from SQLite
    final db = await database;

    // Delete from Firebase if synced
    final record = await db.query(
      'checkup_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (record.isNotEmpty && record.first['synced'] == 1) {
      try {
        await getFirestoreInstance()
            .collection('checkup_records')
            .doc(id)
            .delete();
      } catch (e) {
        print('Error deleting from Firebase: $e');
      }
    }

    return await db.delete('checkup_records', where: 'id = ?', whereArgs: [id]);
  }

  // Delete multiple records
  Future<void> deleteRecords(List<String> ids) async {
    // On web, delete directly from Firebase
    if (kIsWeb) {
      for (String id in ids) {
        try {
          await getFirestoreInstance()
              .collection('checkup_records')
              .doc(id)
              .delete();
        } catch (e) {
          print('Error deleting from Firebase on web: $e');
        }
      }
      return;
    }

    // On mobile, delete from local database
    for (String id in ids) {
      await deleteRecord(id);
    }
  }

  // Sync local data to Firebase
  Future<void> _syncToFirebase() async {
    // On web, data is already in Firebase
    if (kIsWeb) return;

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('No internet connection. Will sync later.');
        return;
      }

      final db = await database;
      final unsyncedRecords = await db.query(
        'checkup_records',
        where: 'synced = ?',
        whereArgs: [0],
      );

      for (var record in unsyncedRecords) {
        try {
          final recordData = Map<String, dynamic>.from(record);
          final id = recordData['id'];
          recordData.remove('synced');
          recordData.remove('id');

          await getFirestoreInstance()
              .collection('checkup_records')
              .doc(id)
              .set(recordData, SetOptions(merge: true));

          // Mark as synced
          await db.update(
            'checkup_records',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [id],
          );

          print('Synced record: $id');
        } catch (e) {
          print('Error syncing record: $e');
        }
      }
    } catch (e) {
      print('Error during sync: $e');
    }
  }

  // Pull data from Firebase (for initial sync or when logging in)
  Future<void> syncFromFirebase() async {
    // On web, data is already from Firebase
    if (kIsWeb) return;

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('No internet connection. Using offline data.');
        return;
      }

      final snapshot = await getFirestoreInstance()
          .collection('checkup_records')
          .get();

      final db = await database;

      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        data['synced'] = 1;

        // Convert boolean values to integers for SQLite
        data.forEach((key, value) {
          if (value is bool) {
            data[key] = value ? 1 : 0;
          }
        });

        await db.insert(
          'checkup_records',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('Synced ${snapshot.docs.length} records from Firebase');
    } catch (e) {
      print('Error syncing from Firebase: $e');
    }
  }

  // Start listening for connectivity changes
  void startConnectivityListener() {
    // On web, no need for sync listener
    if (kIsWeb) return;

    Connectivity().onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        print('Internet connected! Syncing data...');
        _syncToFirebase();
        syncFromFirebase();
      }
    });
  }

  // Migrate recovery plans from old UTF-8 format to safe ASCII format
  Future<void> migrateRecoveryPlans() async {
    if (kIsWeb) return; // Skip migration on web
    
    try {
      final db = await database;
      
      // Check if database is writable by attempting a test transaction
      try {
        await db.transaction((txn) async {
          // If this succeeds, database is writable
        });
      } catch (e) {
        // Database is read-only, skip migration silently
        return;
      }
      
      final List<Map<String, dynamic>> records = await db.query('checkup_records');
      
      final safeDefault = {
        'medications': [],
        'home_care': [],
        'precautions': [],
        'estimated_recovery': 'Varies by condition',
        'general_advice': [
          '[OK] Follow healthcare provider instructions',
          '[OK] Complete full course of medications',
          '[OK] Report any worsening symptoms',
          '[OK] Maintain healthy lifestyle habits',
        ],
      };
      
      int migratedCount = 0;
      
      for (var record in records) {
        bool needsUpdate = false;
        
        // Check if ai_recovery_plan needs migration
        if (record['ai_recovery_plan'] is String) {
          final planStr = record['ai_recovery_plan'] as String;
          
          // Look for UTF-8 emoji markers that indicate old format
          if (planStr.contains('\u2705') || planStr.contains('\ud83d\udccb')) {
            // Old UTF-8 format detected, replace with safe default
            record['ai_recovery_plan'] = jsonEncode(safeDefault);
            needsUpdate = true;
          } else if (planStr.isNotEmpty) {
            // Try to decode; if it fails, replace with safe default
            try {
              jsonDecode(planStr);
            } catch (e) {
              record['ai_recovery_plan'] = jsonEncode(safeDefault);
              needsUpdate = true;
            }
          }
        }
        
        // Update the record if needed
        if (needsUpdate) {
          try {
            await db.update(
              'checkup_records',
              record,
              where: 'id = ?',
              whereArgs: [record['id']],
            );
            migratedCount++;
          } catch (e) {
            // Silently skip records that can't be updated
          }
        }
      }
      
      if (migratedCount > 0) {
        print('✓ Migrated $migratedCount recovery plan records to ASCII-safe format');
      }
    } catch (e) {
      // Migration is non-critical, silently fail
    }
  }

  // Close database
  Future close() async {
    // No database to close on web
    if (kIsWeb) return;

    final db = await database;
    db.close();
  }
}
