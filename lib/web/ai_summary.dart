import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mycapstone_project/firebase_helper.dart';

/// Extended AI-like summarizer that aggregates records across multiple
/// collections: checkup_records, patient_records, prenatal_records,
/// barangay_records, immunization_records, morbidity_records, mortality_records.

String _formatDouble(double v) => v.toStringAsFixed(1);

Map<String, Map<String, double>> _aggregateNumeric(List<Map<String, dynamic>> records) {
  final Map<String, double> sum = {};
  final Map<String, int> count = {};
  final Map<String, double> min = {};
  final Map<String, double> max = {};

  for (final r in records) {
    r.forEach((k, v) {
      if (v is num) {
        final val = v.toDouble();
        sum[k] = (sum[k] ?? 0) + val;
        count[k] = (count[k] ?? 0) + 1;
        if (min[k] == null || val < min[k]!) min[k] = val;
        if (max[k] == null || val > max[k]!) max[k] = val;
      }
    });
  }

  final Map<String, Map<String, double>> out = {};
  for (final k in sum.keys) {
    out[k] = {
      'avg': sum[k]! / (count[k] ?? 1),
      'min': min[k] ?? 0,
      'max': max[k] ?? 0,
      'count': (count[k] ?? 0).toDouble(),
    };
  }
  return out;
}

String _trendString(List<double> values) {
  if (values.length < 2) return 'stable';
  final first = values.first;
  final last = values.last;
  final delta = last - first;
  final pct = (first == 0) ? 0 : (delta / first) * 100;
  if (pct.abs() < 2) return 'stable';
  return pct > 0 ? 'increasing' : 'decreasing';
}

String _generateSummary(String title, List<Map<String, dynamic>> records) {
  if (records.isEmpty) return '$title: No data available.';

  final ag = _aggregateNumeric(records);
  final buffer = StringBuffer();
  buffer.writeln('$title Summary');
  buffer.writeln('Records aggregated: ${records.length}');

  // Priority list for medical vitals and common fields
  final priority = [
    'heart_rate',
    'blood_pressure_sys',
    'blood_pressure_dia',
    'temperature',
    'oxygen',
    'bmi',
    'weight',
    'steps',
    'cases',
    'mortality_count'
  ];

  final seen = <String>{};
  for (final p in priority) {
    if (ag.containsKey(p)) {
      final stats = ag[p]!;
      buffer.writeln('- ${p.replaceAll('_', ' ').toUpperCase()}: avg ${_formatDouble(stats['avg']!)} min ${_formatDouble(stats['min']!)} max ${_formatDouble(stats['max']!)}');
      seen.add(p);
    }
  }

  ag.keys.where((k) => !seen.contains(k)).forEach((k) {
    final stats = ag[k]!;
    buffer.writeln('- ${k.replaceAll('_', ' ').toUpperCase()}: avg ${_formatDouble(stats['avg']!)}');
  });

  // Detect notable deviations
  final anomalies = <String>[];
  ag.forEach((k, stats) {
    final avg = stats['avg']!;
    if (k == 'heart_rate' && (avg < 50 || avg > 100)) anomalies.add('heart rate (${_formatDouble(avg)})');
    if (k == 'temperature' && (avg < 36.0 || avg > 38.0)) anomalies.add('temperature (${_formatDouble(avg)})');
    if (k == 'oxygen' && avg < 92) anomalies.add('oxygen level (${_formatDouble(avg)})');
  });
  if (anomalies.isNotEmpty) {
    buffer.writeln('Notable: ${anomalies.join(', ')}');
  }

  // Trend analysis
  ag.forEach((k, stats) {
    final values = <double>[];
    for (final r in records) {
      final v = r[k];
      if (v is num) values.add(v.toDouble());
    }
    if (values.length >= 3) {
      final trend = _trendString(values);
      if (trend != 'stable') buffer.writeln('Trend: ${k.replaceAll('_', ' ')} is $trend.');
    }
  });

  return buffer.toString();
}

String generateDailySummary(DateTime day, List<Map<String, dynamic>> records) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final filtered = records.where((r) {
    final ts = r['timestamp'];
    if (ts is DateTime) return ts.isAfter(dayStart.subtract(const Duration(seconds: 1))) && ts.isBefore(dayEnd);
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts).isAfter(dayStart) && DateTime.fromMillisecondsSinceEpoch(ts).isBefore(dayEnd);
    return true;
  }).toList();
  return _generateSummary('Daily (${dayStart.toIso8601String().split('T').first})', filtered);
}

String generateMonthlySummary(int year, int month, List<Map<String, dynamic>> records) {
  final start = DateTime(year, month, 1);
  final end = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  final filtered = records.where((r) {
    final ts = r['timestamp'];
    if (ts is DateTime) return ts.isAfter(start.subtract(const Duration(seconds: 1))) && ts.isBefore(end);
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts).isAfter(start) && DateTime.fromMillisecondsSinceEpoch(ts).isBefore(end);
    return true;
  }).toList();
  return _generateSummary('Monthly (${year}-${month.toString().padLeft(2, '0')})', filtered);
}

String generateYearlySummary(int year, List<Map<String, dynamic>> records) {
  final start = DateTime(year, 1, 1);
  final end = DateTime(year + 1, 1, 1);
  final filtered = records.where((r) {
    final ts = r['timestamp'];
    if (ts is DateTime) return ts.isAfter(start.subtract(const Duration(seconds: 1))) && ts.isBefore(end);
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts).isAfter(start) && DateTime.fromMillisecondsSinceEpoch(ts).isBefore(end);
    return true;
  }).toList();
  return _generateSummary('Yearly ($year)', filtered);
}

// ------------------------
// Firestore-aware helpers
// ------------------------

Map<String, dynamic> _normalizeRecord(Map<String, dynamic> doc) {
  final out = <String, dynamic>{};

  // Heart / pulse
  if (doc['heartRate'] is num) out['heart_rate'] = doc['heartRate'];
  if (doc['hr'] is num) out['heart_rate'] = doc['hr'];
  if (doc['pulse'] is num) out['heart_rate'] = doc['pulse'];

  // Temperature
  if (doc['bodyTemperature'] is num) out['temperature'] = doc['bodyTemperature'];
  if (doc['temperature'] is num) out['temperature'] = doc['temperature'];
  if (doc['temp'] is num) out['temperature'] = doc['temp'];

  // Oxygen / SpO2
  if (doc['oxygenSaturation'] is num) out['oxygen'] = doc['oxygenSaturation'];
  if (doc['oxygen'] is num) out['oxygen'] = doc['oxygen'];
  if (doc['spo2'] is num) out['oxygen'] = doc['spo2'];

  // BMI / weight
  if (doc['bmi'] is num) out['bmi'] = doc['bmi'];
  if (doc['weight'] is num) out['weight'] = doc['weight'];
  if (doc['wt'] is num) out['weight'] = doc['wt'];

  // Blood pressure
  if (doc['bpSystolic'] is num) out['blood_pressure_sys'] = doc['bpSystolic'];
  if (doc['systolic'] is num) out['blood_pressure_sys'] = doc['systolic'];
  if (doc['bp_systolic'] is num) out['blood_pressure_sys'] = doc['bp_systolic'];

  if (doc['bpDiastolic'] is num) out['blood_pressure_dia'] = doc['bpDiastolic'];
  if (doc['diastolic'] is num) out['blood_pressure_dia'] = doc['diastolic'];
  if (doc['bp_diastolic'] is num) out['blood_pressure_dia'] = doc['bp_diastolic'];

  // Steps
  if (doc['steps'] is num) out['steps'] = doc['steps'];
  if (doc['stepCount'] is num) out['steps'] = doc['stepCount'];

  // Cases / counts (for morbidity / mortality / barangay)
  if (doc['cases'] is num) out['cases'] = doc['cases'];
  if (doc['count'] is num) out['cases'] = doc['count'];
  if (doc['mortalityCount'] is num) out['mortality_count'] = doc['mortalityCount'];
  if (doc['deaths'] is num) out['mortality_count'] = doc['deaths'];

  // Timestamp handling
  final ts = doc['timestamp'] ?? doc['date'] ?? doc['registrationDate'] ?? doc['administrationDate'] ?? doc['createdAt'];
  if (ts is Timestamp) {
    out['timestamp'] = ts.toDate();
  } else if (ts is DateTime) {
    out['timestamp'] = ts;
  } else if (ts is int) {
    out['timestamp'] = DateTime.fromMillisecondsSinceEpoch(ts);
  } else if (ts is String) {
    try {
      out['timestamp'] = DateTime.parse(ts);
    } catch (_) {}
  }

  // Remove nulls
  out.removeWhere((k, v) => v == null);
  return out;
}

Future<List<Map<String, dynamic>>> _fetchFromCollection(String collection, {String? userId, String? email}) async {
  final firestore = getFirestoreInstance();
  final List<Map<String, dynamic>> out = [];

  try {
    // Try doc id first
    if (userId != null && userId.isNotEmpty) {
      try {
        final doc = await firestore.collection(collection).doc(userId).get();
        if (doc.exists) out.add(_normalizeRecord(doc.data()!));
      } catch (_) {}

      // Try common id fields
      try {
        final snap = await firestore.collection(collection).where('patientId', isEqualTo: userId).get();
        for (final d in snap.docs) {
          out.add(_normalizeRecord(d.data() as Map<String, dynamic>));
        }
      } catch (_) {}

      try {
        final snap = await firestore.collection(collection).where('id', isEqualTo: userId).get();
        for (final d in snap.docs) {
          out.add(_normalizeRecord(d.data() as Map<String, dynamic>));
        }
      } catch (_) {}
    }

    if (email != null && email.isNotEmpty) {
      try {
        final snap = await firestore.collection(collection).where('emailAddress', isEqualTo: email).get();
        for (final d in snap.docs) {
          out.add(_normalizeRecord(d.data() as Map<String, dynamic>));
        }
      } catch (_) {}

      try {
        final snap = await firestore.collection(collection).where('email', isEqualTo: email).get();
        for (final d in snap.docs) {
          out.add(_normalizeRecord(d.data() as Map<String, dynamic>));
        }
      } catch (_) {}
    }

    // Fallback: get recent documents (limit 100) using a likely timestamp field
    if (out.isEmpty) {
      try {
        // Attempt common timestamp fields; if ordering fails, just limit without order
        Query q = firestore.collection(collection).limit(100);
        try {
          q = firestore.collection(collection).orderBy('timestamp', descending: true).limit(100);
        } catch (_) {
          try {
            q = firestore.collection(collection).orderBy('registrationDate', descending: true).limit(100);
          } catch (_) {
            q = firestore.collection(collection).limit(100);
          }
        }
        final snap = await q.get();
        for (final d in snap.docs) {
          out.add(_normalizeRecord(d.data() as Map<String, dynamic>));
        }
      } catch (_) {}
    }
  } catch (_) {}

  return out;
}

Future<List<Map<String, dynamic>>> fetchRecordsForUser({String? userId, String? email}) async {
  // Collections to include in the summary aggregation
  final collections = [
    'checkup_records',
    'patient_records',
    'prenatal_records',
    'barangay_records',
    'immunization_records',
    'morbidity_records',
    'mortality_records',
  ];

  final List<Map<String, dynamic>> all = [];
  for (final c in collections) {
    final res = await _fetchFromCollection(c, userId: userId, email: email);
    for (final r in res) {
      // annotate source if helpful
      r['source'] = c;
      all.add(r);
    }
  }

  // Deduplicate by timestamp + a few keys when possible
  final seen = <String>{};
  final unique = <Map<String, dynamic>>[];
  for (final r in all) {
    final key = '${r['timestamp']?.toIso8601String() ?? ''}-${r['heart_rate'] ?? r['weight'] ?? r['cases'] ?? ''}';
    if (!seen.contains(key)) {
      seen.add(key);
      unique.add(r);
    }
  }

  return unique;
}

Future<String> generateDailySummaryForCurrentUser(DateTime day) async {
  final user = FirebaseAuth.instance.currentUser;
  final records = await fetchRecordsForUser(userId: user?.uid, email: user?.email);
  return generateDailySummary(day, records);
}

Future<String> generateMonthlySummaryForCurrentUser(int year, int month) async {
  final user = FirebaseAuth.instance.currentUser;
  final records = await fetchRecordsForUser(userId: user?.uid, email: user?.email);
  return generateMonthlySummary(year, month, records);
}

Future<String> generateYearlySummaryForCurrentUser(int year) async {
  final user = FirebaseAuth.instance.currentUser;
  final records = await fetchRecordsForUser(userId: user?.uid, email: user?.email);
  return generateYearlySummary(year, records);
}
