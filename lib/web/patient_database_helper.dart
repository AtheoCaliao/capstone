import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mycapstone_project/firebase_helper.dart';

class PatientDatabaseHelper {
  static final PatientDatabaseHelper instance = PatientDatabaseHelper._init();
  static Database? _database;

  PatientDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('patient_records.db');
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
      CREATE TABLE patient_records (
        id $idType,
        firstName $textType,
        surname $textType,
        mothersMaidenName $textType,
        dateOfBirth $textType,
        age $textType,
        placeOfBirth $textType,
        nationality $textType,
        civilStatus $textType,
        gender $textType,
        religion $textType,
        occupation $textType,
        educationalAttainment $textType,
        employeeStatus $textType,
        phoneNumber $textType,
        emailAddress $textType,
        alternativePhone $textType,
        guardian $textType,
        street $textType,
        barangay $textType,
        municipality $textType,
        province $textType,
        height $textType,
        weight $textType,
        bmi $textType,
        bloodType $textType,
        allergies $textType,
        immunizationStatus $textType,
        familyMedicalHistory $textType,
        pastMedicalHistory $textType,
        currentMedications $textType,
        chronicConditions $textType,
        chiefComplaint $textType,
        currentSymptoms $textType,
        bodyTemperature $textType,
        temperatureUnit $textType,
        bpSystolic $textType,
        bpDiastolic $textType,
        heartRate $textType,
        respiratoryRate $textType,
        oxygenSaturation $textType,
        disability $textType,
        mentalHealthStatus $textType,
        substanceUseHistory $textType,
        lastCheckup $textType,
        nextCheckup $textType,
        emergencyContactName $textType,
        emergencyRelationship $textType,
        emergencyContactPhone $textType,
        emergencyContactAddress $textType,
        smokingStatus $textType,
        exerciseFrequency $textType,
        alcoholConsumption $textType,
        dietaryRestrictions $textType,
        mentalHealthStatusLifestyle $textType,
        sleepQuality $textType,
        morbidityRiskLevel $textType,
        numberOfComorbidities $textType,
        functionalStatus $textType,
        mobilityStatus $textType,
        frailtyIndex $textType,
        polypharmacyRisk $textType,
        preventiveCareCompliance $textType,
        healthLiteracyLevel $textType,
        socialSupportLevel $textType,
        economicStatusImpact $textType,
        morbidityNotes $textType,
        insuranceProvider $textType,
        insuranceNumber $textType,
        insuranceExpiry $textType,
        monthlyIncome $textType,
        additionalInfo $textType,
        educationLevel $textType,
        preferredLanguage $textType,
        referralSource $textType,
        transportation $textType,
        consentGiven $textType,
        registrationDate $textType,
        registeredBy $textType,
        additionalNotes $textType,
        status $textType,
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
        final recordWithId = _prepareRecordData(record, id);
        recordWithId.remove('synced'); // Remove synced field for web
        await getFirestoreInstance()
            .collection('patient_records')
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
    final recordWithId = _prepareRecordData(record, id);
    recordWithId['synced'] = 0; // 0 = not synced, 1 = synced

    await db.insert(
      'patient_records',
      recordWithId,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Try to sync immediately if online
    _syncToFirebase();

    return id;
  }

  Map<String, dynamic> _prepareRecordData(Map<String, dynamic> record, String id) {
    return {
      'id': id,
      'firstName': record['firstName'] ?? '',
      'surname': record['surname'] ?? '',
      'mothersMaidenName': record['mothersMaidenName'] ?? '',
      'dateOfBirth': record['dateOfBirth'] ?? '',
      'age': record['age'] ?? '',
      'placeOfBirth': record['placeOfBirth'] ?? '',
      'nationality': record['nationality'] ?? '',
      'civilStatus': record['civilStatus'] ?? '',
      'gender': record['gender'] ?? '',
      'religion': record['religion'] ?? '',
      'occupation': record['occupation'] ?? '',
      'educationalAttainment': record['educationalAttainment'] ?? '',
      'employeeStatus': record['employeeStatus'] ?? '',
      'phoneNumber': record['phoneNumber'] ?? '',
      'emailAddress': record['emailAddress'] ?? '',
      'alternativePhone': record['alternativePhone'] ?? '',
      'guardian': record['guardian'] ?? '',
      'street': record['street'] ?? '',
      'barangay': record['barangay'] ?? '',
      'municipality': record['municipality'] ?? '',
      'province': record['province'] ?? '',
      'height': record['height'] ?? '',
      'weight': record['weight'] ?? '',
      'bmi': record['bmi'] ?? '',
      'bloodType': record['bloodType'] ?? '',
      'allergies': record['allergies'] ?? '',
      'immunizationStatus': record['immunizationStatus'] ?? '',
      'familyMedicalHistory': record['familyMedicalHistory'] ?? '',
      'pastMedicalHistory': record['pastMedicalHistory'] ?? '',
      'currentMedications': record['currentMedications'] ?? '',
      'chronicConditions': record['chronicConditions'] ?? '',
      'chiefComplaint': record['chiefComplaint'] ?? '',
      'currentSymptoms': record['currentSymptoms'] ?? '',
      'bodyTemperature': record['bodyTemperature'] ?? '',
      'temperatureUnit': record['temperatureUnit'] ?? '',
      'bpSystolic': record['bpSystolic'] ?? '',
      'bpDiastolic': record['bpDiastolic'] ?? '',
      'heartRate': record['heartRate'] ?? '',
      'respiratoryRate': record['respiratoryRate'] ?? '',
      'oxygenSaturation': record['oxygenSaturation'] ?? '',
      'disability': record['disability'] ?? '',
      'mentalHealthStatus': record['mentalHealthStatus'] ?? '',
      'substanceUseHistory': record['substanceUseHistory'] ?? '',
      'lastCheckup': record['lastCheckup'] ?? '',
      'nextCheckup': record['nextCheckup'] ?? '',
      'emergencyContactName': record['emergencyContactName'] ?? '',
      'emergencyRelationship': record['emergencyRelationship'] ?? '',
      'emergencyContactPhone': record['emergencyContactPhone'] ?? '',
      'emergencyContactAddress': record['emergencyContactAddress'] ?? '',
      'smokingStatus': record['smokingStatus'] ?? '',
      'exerciseFrequency': record['exerciseFrequency'] ?? '',
      'alcoholConsumption': record['alcoholConsumption'] ?? '',
      'dietaryRestrictions': record['dietaryRestrictions'] ?? '',
      'mentalHealthStatusLifestyle': record['mentalHealthStatusLifestyle'] ?? '',
      'sleepQuality': record['sleepQuality'] ?? '',
      'morbidityRiskLevel': record['morbidityRiskLevel'] ?? '',
      'numberOfComorbidities': record['numberOfComorbidities'] ?? '',
      'functionalStatus': record['functionalStatus'] ?? '',
      'mobilityStatus': record['mobilityStatus'] ?? '',
      'frailtyIndex': record['frailtyIndex'] ?? '',
      'polypharmacyRisk': record['polypharmacyRisk'] ?? '',
      'preventiveCareCompliance': record['preventiveCareCompliance'] ?? '',
      'healthLiteracyLevel': record['healthLiteracyLevel'] ?? '',
      'socialSupportLevel': record['socialSupportLevel'] ?? '',
      'economicStatusImpact': record['economicStatusImpact'] ?? '',
      'morbidityNotes': record['morbidityNotes'] ?? '',
      'insuranceProvider': record['insuranceProvider'] ?? '',
      'insuranceNumber': record['insuranceNumber'] ?? '',
      'insuranceExpiry': record['insuranceExpiry'] ?? '',
      'monthlyIncome': record['monthlyIncome'] ?? '',
      'additionalInfo': record['additionalInfo'] ?? '',
      'educationLevel': record['educationLevel'] ?? '',
      'preferredLanguage': record['preferredLanguage'] ?? '',
      'referralSource': record['referralSource'] ?? '',
      'transportation': record['transportation'] ?? '',
      'consentGiven': record['consentGiven'] ?? '',
      'registrationDate': record['registrationDate'] ?? '',
      'registeredBy': record['registeredBy'] ?? '',
      'additionalNotes': record['additionalNotes'] ?? '',
      'status': record['status'] ?? 'Active',
    };
  }

  // Get all records
  Future<List<Map<String, dynamic>>> getAllRecords() async {
    // On web, use Firebase directly
    if (kIsWeb) {
      try {
        final snapshot = await getFirestoreInstance()
            .collection('patient_records')
            .orderBy('registrationDate', descending: true)
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
      'patient_records',
      orderBy: 'registrationDate DESC',
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
        final updatedRecord = _prepareRecordData(record, id);
        updatedRecord.remove('synced');
        await getFirestoreInstance()
            .collection('patient_records')
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
    final updatedRecord = _prepareRecordData(record, id);
    updatedRecord['synced'] = 0; // Mark as unsynced after update

    final result = await db.update(
      'patient_records',
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
            .collection('patient_records')
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
      'patient_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (record.isNotEmpty && record.first['synced'] == 1) {
      try {
        await getFirestoreInstance()
            .collection('patient_records')
            .doc(id)
            .delete();
      } catch (e) {
        print('Error deleting from Firebase: $e');
      }
    }

    return await db.delete(
      'patient_records',
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
              .collection('patient_records')
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
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('No internet connection. Will sync later.');
        return;
      }

      final db = await database;
      final unsyncedRecords = await db.query(
        'patient_records',
        where: 'synced = ?',
        whereArgs: [0],
      );

      for (var record in unsyncedRecords) {
        try {
          final recordData = Map<String, dynamic>.from(record);
          recordData.remove('synced');
          
          await getFirestoreInstance()
              .collection('patient_records')
              .doc(record['id'] as String)
              .set(recordData);

          // Mark as synced
          await db.update(
            'patient_records',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [record['id']],
          );

          print('Synced patient record: ${record['id']}');
        } catch (e) {
          print('Error syncing patient record ${record['id']}: $e');
        }
      }
    } catch (e) {
      print('Error in sync process: $e');
    }
  }

  // Sync from Firebase to local
  Future<void> syncFromFirebase() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('No internet connection. Cannot sync from Firebase.');
        return;
      }

      final snapshot = await getFirestoreInstance()
          .collection('patient_records')
          .get();

      final db = await database;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['synced'] = 1;

        await db.insert(
          'patient_records',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('Synced ${snapshot.docs.length} patient records from Firebase');
    } catch (e) {
      print('Error syncing from Firebase: $e');
    }
  }

  // Listen to connectivity changes
  void startConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        print('Internet connection restored. Syncing patient data...');
        _syncToFirebase();
      }
    });
  }
}


