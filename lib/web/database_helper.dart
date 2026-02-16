import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mycapstone_project/firebase_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    // On web, throw error since we shouldn't use SQLite
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite database is not supported on web. Use Firebase directly.',
      );
    }

    if (_database != null) return _database!;
    _database = await _initDB('checkup_records.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Check if diseaseType column already exists before adding
      try {
        final result = await db.rawQuery('PRAGMA table_info(checkup_records)');
        final columnExists = result.any(
          (column) => column['name'] == 'diseaseType',
        );

        if (!columnExists) {
          await db.execute(
            'ALTER TABLE checkup_records ADD COLUMN diseaseType TEXT DEFAULT "General"',
          );
        }
      } catch (e) {
        print('Error during database upgrade: $e');
        // Column might already exist, continue
      }
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

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
        synced $intType
      )
    ''');
  }

  // Insert record locally
  Future<String> insertRecord(Map<String, dynamic> record) async {
    final id = record['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    print('🔵 [DATABASE_HELPER] insertRecord called');
    print('🔵 [DATABASE_HELPER] Platform check - kIsWeb: $kIsWeb');
    print('🔵 [DATABASE_HELPER] Record ID: $id');
    print('🔵 [DATABASE_HELPER] Record patient: ${record['patient']}');

    // On web, save directly to Firebase
    if (kIsWeb) {
      try {
        // Check authentication status
        final currentUser = FirebaseAuth.instance.currentUser;
        print(
          '🔵 [DATABASE_HELPER] Authentication check - User logged in: ${currentUser != null}',
        );
        if (currentUser != null) {
          print('🔵 [DATABASE_HELPER] User ID: ${currentUser.uid}');
          print('🔵 [DATABASE_HELPER] User email: ${currentUser.email}');
        } else {
          print('⚠️ [DATABASE_HELPER] WARNING: No authenticated user!');
          print(
            '⚠️ [DATABASE_HELPER] If using OPTION 2 Firestore rules, this will fail!',
          );
        }

        print('🔵 [DATABASE_HELPER] Preparing Firestore write...');
        final recordWithId = {...record, 'id': id};
        print(
          '🔵 [DATABASE_HELPER] Writing to Firestore collection: checkup_records',
        );
        print('🔵 [DATABASE_HELPER] Document ID: $id');
        print('🔵 [DATABASE_HELPER] Record data: $recordWithId');
        print('🔵 [DATABASE_HELPER] Starting Firestore .set() operation...');

        final startTime = DateTime.now();
        print('🔵 [DATABASE_HELPER] Write started at: $startTime');

        await getFirestoreInstance()
            .collection('checkup_records')
            .doc(id)
            .set(recordWithId);

        final endTime = DateTime.now();
        final elapsed = endTime.difference(startTime).inMilliseconds;
        print('✅ [DATABASE_HELPER] Firestore write completed in ${elapsed}ms');

        print('✅ [DATABASE_HELPER] Firestore write completed successfully!');
        return id;
      } on FirebaseException catch (e) {
        print(
          '❌ [DATABASE_HELPER] FirebaseException: ${e.code} - ${e.message}',
        );
        if (e.code == 'permission-denied') {
          throw Exception(
            'Permission denied! Update your Firestore rules to allow writes.\n'
            'Go to: https://console.firebase.google.com/project/capstone-c98f9/firestore/rules\n'
            'See firestore_rules_needed.txt for correct rules.',
          );
        }
        rethrow;
      } catch (e, stackTrace) {
        print('❌ [DATABASE_HELPER] Error saving to Firebase on web: $e');
        print('❌ [DATABASE_HELPER] Error type: ${e.runtimeType}');
        print('❌ [DATABASE_HELPER] Stack trace: $stackTrace');
        rethrow;
      }
    }

    // On mobile, save to SQLite
    final db = await database;
    final recordWithId = {
      ...record,
      'id': id,
      'synced': 0, // 0 = not synced, 1 = synced
    };

    await db.insert(
      'checkup_records',
      recordWithId,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Try to sync immediately if online
    _syncToFirebase();

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
    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      return await getAllRecords();
    });
  }

  // Get all records
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
            .update(updatedRecord)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException(
                  'Firestore update timed out after 30 seconds',
                );
              },
            );
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
            .delete()
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException(
                  'Firestore delete timed out after 30 seconds',
                );
              },
            );
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
        final data = doc.data();
        data['id'] = doc.id;
        data['synced'] = 1;

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

  // Close database
  Future close() async {
    // No database to close on web
    if (kIsWeb) return;

    final db = await database;
    db.close();
  }
}
