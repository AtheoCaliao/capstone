import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mycapstone_project/firebase_helper.dart';

class ImmunizationDatabaseHelper {
  static final ImmunizationDatabaseHelper instance =
      ImmunizationDatabaseHelper._init();
  static Database? _database;

  ImmunizationDatabaseHelper._init();

  Future<Database> get database async {
    // On web, throw error since we shouldn't use SQLite
    if (kIsWeb) {
      throw UnsupportedError('SQLite database is not supported on web. Use Firebase directly.');
    }
    
    if (_database != null) return _database!;
    _database = await _initDB('immunization_records.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE immunization_records (
        id $idType,
        time $textType,
        patientName $textType,
        patientId $textType,
        age $textType,
        contactNumber $textType,
        vaccine $textType,
        vaccineBrand $textType,
        batchNumber $textType,
        expirationDate $textType,
        administrationDate $textType,
        administrationTime $textType,
        doseNumber $textType,
        routeOfAdministration $textType,
        injectionSite $textType,
        administeredBy $textType,
        adverseEvents $textType,
        nextDoseDueDate $textType,
        status $textType,
        date $textType,
        synced $intType
      )
    ''');
  }

  // Insert record locally
  Future<String> insertRecord(Map<String, dynamic> record) async {
    final id = record['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    // On web, save directly to Firebase
    if (kIsWeb) {
      try {
        final recordWithId = {
          'id': id,
          'time': record['time'] ?? '',
          'patientName': record['patientName'] ?? '',
          'patientId': record['patientId'] ?? '',
          'age': record['age'] ?? '',
          'contactNumber': record['contactNumber'] ?? '',
          'vaccine': record['vaccine'] ?? '',
          'vaccineBrand': record['vaccineBrand'] ?? '',
          'batchNumber': record['batchNumber'] ?? '',
          'expirationDate': record['expirationDate'] ?? '',
          'administrationDate': record['administrationDate'] ?? '',
          'administrationTime': record['administrationTime'] ?? '',
          'doseNumber': record['doseNumber'] ?? '',
          'routeOfAdministration': record['routeOfAdministration'] ?? '',
          'injectionSite': record['injectionSite'] ?? '',
          'administeredBy': record['administeredBy'] ?? '',
          'adverseEvents': record['adverseEvents'] ?? '',
          'nextDoseDueDate': record['nextDoseDueDate'] ?? '',
          'status': record['status'] ?? '',
          'date': record['date'] ?? '',
        };
        await getFirestoreInstance()
            .collection('immunization_records')
            .doc(id)
            .set(recordWithId);
        return id;
      } catch (e) {
        print('Error saving to Firebase on web: $e');
        rethrow;
      }
    }

    // On mobile, save to SQLite
    final db = await database;
    final recordWithId = {
      'id': id,
      'time': record['time'] ?? '',
      'patientName': record['patientName'] ?? '',
      'patientId': record['patientId'] ?? '',
      'age': record['age'] ?? '',
      'contactNumber': record['contactNumber'] ?? '',
      'vaccine': record['vaccine'] ?? '',
      'vaccineBrand': record['vaccineBrand'] ?? '',
      'batchNumber': record['batchNumber'] ?? '',
      'expirationDate': record['expirationDate'] ?? '',
      'administrationDate': record['administrationDate'] ?? '',
      'administrationTime': record['administrationTime'] ?? '',
      'doseNumber': record['doseNumber'] ?? '',
      'routeOfAdministration': record['routeOfAdministration'] ?? '',
      'injectionSite': record['injectionSite'] ?? '',
      'administeredBy': record['administeredBy'] ?? '',
      'adverseEvents': record['adverseEvents'] ?? '',
      'nextDoseDueDate': record['nextDoseDueDate'] ?? '',
      'status': record['status'] ?? '',
      'date': record['date'] ?? '',
      'synced': 0, // 0 = not synced, 1 = synced
    };

    await db.insert(
      'immunization_records',
      recordWithId,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Try to sync immediately if online
    _syncToFirebase();

    return id;
  }

  // Get all records
  Future<List<Map<String, dynamic>>> getAllRecords() async {
    // On web, use Firebase directly
    if (kIsWeb) {
      try {
        final snapshot = await getFirestoreInstance()
            .collection('immunization_records')
            .orderBy('administrationDate', descending: true)
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
    final result = await db.query(
      'immunization_records',
      orderBy: 'administrationDate DESC, administrationTime DESC',
    );

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
        final updatedRecord = {
          ...record,
          'id': id,
        };
        await getFirestoreInstance()
            .collection('immunization_records')
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
      'immunization_records',
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
            .collection('immunization_records')
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
      'immunization_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (record.isNotEmpty && record.first['synced'] == 1) {
      try {
        await getFirestoreInstance()
            .collection('immunization_records')
            .doc(id)
            .delete();
      } catch (e) {
        print('Error deleting from Firebase: $e');
      }
    }

    return await db.delete(
      'immunization_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete multiple records
  Future<void> deleteRecords(List<String> ids) async {
    // On web, delete directly from Firebase
    if (kIsWeb) {
      for (String id in ids) {
        try {
          await getFirestoreInstance()
              .collection('immunization_records')
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
    // On web, data is saved directly to Firebase, no sync needed
    if (kIsWeb) {
      return;
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('No internet connection. Will sync later.');
        return;
      }

      final db = await database;
      final unsyncedRecords = await db.query(
        'immunization_records',
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
              .collection('immunization_records')
              .doc(id)
              .set(recordData, SetOptions(merge: true));

          // Mark as synced
          await db.update(
            'immunization_records',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [id],
          );

          print('Synced immunization record: $id');
        } catch (e) {
          print('Error syncing immunization record: $e');
        }
      }
    } catch (e) {
      print('Error during immunization sync: $e');
    }
  }

  // Pull data from Firebase (for initial sync or when logging in)
  Future<void> syncFromFirebase() async {
    // On web, data is already in Firebase, no sync needed
    if (kIsWeb) {
      print('Running on web - data is already in Firebase');
      return;
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('No internet connection. Using offline data.');
        return;
      }

      final snapshot = await getFirestoreInstance()
          .collection('immunization_records')
          .get();

      final db = await database;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['synced'] = 1;

        // Ensure all fields exist with default values
        final completeData = {
          'id': data['id'],
          'time': data['time'] ?? '',
          'patientName': data['patientName'] ?? '',
          'patientId': data['patientId'] ?? '',
          'age': data['age'] ?? '',
          'contactNumber': data['contactNumber'] ?? '',
          'vaccine': data['vaccine'] ?? '',
          'vaccineBrand': data['vaccineBrand'] ?? '',
          'batchNumber': data['batchNumber'] ?? '',
          'expirationDate': data['expirationDate'] ?? '',
          'administrationDate': data['administrationDate'] ?? '',
          'administrationTime': data['administrationTime'] ?? '',
          'doseNumber': data['doseNumber'] ?? '',
          'routeOfAdministration': data['routeOfAdministration'] ?? '',
          'injectionSite': data['injectionSite'] ?? '',
          'administeredBy': data['administeredBy'] ?? '',
          'adverseEvents': data['adverseEvents'] ?? '',
          'nextDoseDueDate': data['nextDoseDueDate'] ?? '',
          'status': data['status'] ?? '',
          'date': data['date'] ?? '',
          'synced': 1,
        };

        await db.insert(
          'immunization_records',
          completeData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print(
        'Synced ${snapshot.docs.length} immunization records from Firebase',
      );
    } catch (e) {
      print('Error syncing immunization records from Firebase: $e');
    }
  }

  // Start listening for connectivity changes
  void startConnectivityListener() {
    // On web, no need for connectivity listener since data is always in Firebase
    if (kIsWeb) {
      return;
    }

    Connectivity().onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        print('Internet connected! Syncing immunization data...');
        _syncToFirebase();
        syncFromFirebase();
      }
    });
  }

  // Close database
  Future close() async {
    final db = await database;
    db.close();
  }
}


