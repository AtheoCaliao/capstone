import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

// TFLite disabled due to package compatibility issues
// Using rule-based classification which works on all platforms
// import 'tflite_stub.dart'
//     if (dart.library.io) 'package:tflite_flutter/tflite_flutter.dart';

/// AI-powered health data classifier using rule-based analysis
/// Classifies symptoms and health records into categories with severity assessment
class HealthAIClassifier {
  static HealthAIClassifier? _instance;
  dynamic
  _interpreter; // TFLite disabled - using dynamic to avoid import issues
  bool _isInitialized = false;

  // Disease and condition categories
  static const List<String> categories = [
    'Communicable Disease',
    'Non-Communicable Disease',
    'Emergency',
    'Routine Checkup',
    'Prenatal Care',
    'Pediatric Care',
  ];

  // Severity levels
  static const List<String> severityLevels = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  // Medical treatment and recovery recommendations database
  static const Map<String, Map<String, dynamic>> treatmentDatabase = {
    'fever': {
      'medications': ['Paracetamol/Acetaminophen', 'Ibuprofen'],
      'home_care': [
        'Rest and stay hydrated',
        'Apply cool compress to forehead',
        'Take lukewarm bath',
        'Wear light, breathable clothing',
        'Monitor temperature every 4 hours',
      ],
      'precautions': ['Seek medical help if fever exceeds 39.4°C (103°F)'],
      'recovery_time': '3-7 days',
    },
    'cough': {
      'medications': ['Cough suppressants', 'Expectorants', 'Honey (natural)'],
      'home_care': [
        'Drink warm fluids (tea, soup)',
        'Use humidifier in room',
        'Avoid irritants (smoke, dust)',
        'Elevate head while sleeping',
        'Gargle with salt water',
      ],
      'precautions': ['See doctor if cough persists beyond 2 weeks'],
      'recovery_time': '1-3 weeks',
    },
    'chest pain': {
      'medications': ['As prescribed by emergency physician'],
      'home_care': ['SEEK IMMEDIATE MEDICAL ATTENTION'],
      'precautions': [
        'Call emergency services immediately',
        'Do not drive yourself',
        'Chew aspirin if not allergic',
      ],
      'recovery_time': 'Requires immediate medical evaluation',
    },
    'diabetes': {
      'medications': [
        'Metformin',
        'Insulin (as prescribed)',
        'Other oral hypoglycemics',
      ],
      'home_care': [
        'Monitor blood glucose regularly',
        'Follow diabetic diet (low sugar, high fiber)',
        'Exercise 30 minutes daily',
        'Maintain healthy weight',
        'Check feet daily for wounds',
      ],
      'precautions': ['Regular HbA1c testing every 3 months'],
      'recovery_time': 'Lifelong management',
    },
    'hypertension': {
      'medications': [
        'ACE inhibitors',
        'Beta blockers',
        'Calcium channel blockers',
      ],
      'home_care': [
        'Reduce sodium intake (<2000mg/day)',
        'DASH diet (fruits, vegetables, whole grains)',
        'Regular exercise (150 min/week)',
        'Limit alcohol consumption',
        'Manage stress through relaxation',
        'Monitor BP daily',
      ],
      'precautions': ['Never stop medications without doctor consultation'],
      'recovery_time': 'Lifelong management',
    },
    'pneumonia': {
      'medications': ['Antibiotics', 'Fever reducers', 'Pain relievers'],
      'home_care': [
        'Complete full course of antibiotics',
        'Rest adequately',
        'Drink plenty of fluids',
        'Use humidifier',
        'Practice deep breathing exercises',
      ],
      'precautions': ['Follow up chest X-ray after 6 weeks'],
      'recovery_time': '2-4 weeks',
    },
    'asthma': {
      'medications': [
        'Inhalers (bronchodilators)',
        'Corticosteroids',
        'Controller medications',
      ],
      'home_care': [
        'Identify and avoid triggers',
        'Use peak flow meter daily',
        'Keep rescue inhaler accessible',
        'Avoid smoke and air pollution',
        'Regular breathing exercises',
      ],
      'precautions': ['Have asthma action plan'],
      'recovery_time': 'Lifelong management',
    },
    'diarrhea': {
      'medications': [
        'Oral rehydration solution',
        'Loperamide (if appropriate)',
      ],
      'home_care': [
        'Stay well hydrated (ORS, clear fluids)',
        'BRAT diet (Bananas, Rice, Applesauce, Toast)',
        'Avoid dairy temporarily',
        'Maintain hand hygiene',
        'Rest adequately',
      ],
      'precautions': ['Seek help if blood in stool or severe dehydration'],
      'recovery_time': '2-7 days',
    },
    'pregnant': {
      'medications': ['Prenatal vitamins', 'Folic acid', 'Iron supplements'],
      'home_care': [
        'Regular prenatal checkups',
        'Balanced, nutritious diet',
        'Adequate rest and sleep',
        'Gentle exercise (walking, prenatal yoga)',
        'Stay hydrated',
        'Avoid alcohol and smoking',
      ],
      'precautions': ['Monitor for warning signs (bleeding, severe pain)'],
      'recovery_time': 'Throughout pregnancy',
    },
    'prenatal': {
      'medications': [
        'Prenatal vitamins',
        'Folic acid',
        'Iron supplements',
        'Calcium supplements',
      ],
      'home_care': [
        'Regular prenatal checkups every 4 weeks (1st-2nd trimester)',
        'Prenatal checkups every 2 weeks (3rd trimester)',
        'Balanced, nutritious diet rich in folate and iron',
        'Adequate rest and sleep (7-9 hours)',
        'Gentle exercise (walking, prenatal yoga, swimming)',
        'Stay well hydrated (8-10 glasses of water daily)',
        'Avoid alcohol, smoking, and caffeine',
        'Monitor fetal movement daily',
      ],
      'precautions': [
        'Monitor for warning signs (bleeding, severe pain, swelling)',
        'Watch for signs of preeclampsia (headaches, vision changes)',
        'Report decreased fetal movement immediately',
        'Avoid heavy lifting and strenuous activity',
      ],
      'recovery_time': 'Throughout pregnancy until delivery',
    },
    'gestational': {
      'medications': ['Prenatal vitamins', 'Iron supplements', 'Folic acid'],
      'home_care': [
        'Monitor gestational age milestones',
        'Attend all scheduled prenatal visits',
        'Track weight gain according to BMI guidelines',
        'Practice Kegel exercises for pelvic floor',
        'Prepare birth plan with healthcare provider',
      ],
      'precautions': [
        'Watch for signs of gestational diabetes',
        'Monitor blood pressure regularly',
        'Report any unusual symptoms promptly',
      ],
      'recovery_time': 'Full term: 37-42 weeks',
    },
    'maternal': {
      'medications': ['Prenatal vitamins', 'Folic acid', 'Iron supplements'],
      'home_care': [
        'Maintain a healthy, balanced diet',
        'Get regular moderate exercise',
        'Practice stress management techniques',
        'Attend all prenatal appointments',
        'Get adequate rest and sleep',
      ],
      'precautions': [
        'Monitor for signs of complications',
        'Report any bleeding or severe pain',
        'Watch for signs of infection',
      ],
      'recovery_time': 'Ongoing prenatal care',
    },
  };

  // Comprehensive medical keyword database
  static const Map<String, List<String>> keywordDatabase = {
    'communicable': [
      'fever',
      'cough',
      'flu',
      'cold',
      'infection',
      'tuberculosis',
      'tb',
      'dengue',
      'covid',
      'coronavirus',
      'measles',
      'chickenpox',
      'mumps',
      'malaria',
      'pneumonia',
      'diarrhea',
      'cholera',
      'typhoid',
      'hepatitis',
      'rabies',
      'tetanus',
      'whooping cough',
      'pertussis',
      'influenza',
      'viral',
      'bacterial',
      'contagious',
      'transmissible',
      'infectious',
    ],
    'emergency': [
      'chest pain',
      'difficulty breathing',
      'severe bleeding',
      'hemorrhage',
      'unconscious',
      'unresponsive',
      'seizure',
      'convulsion',
      'stroke',
      'heart attack',
      'cardiac arrest',
      'severe pain',
      'trauma',
      'accident',
      'poisoning',
      'overdose',
      'shock',
      'severe burn',
      'head injury',
      'broken bone',
      'fracture',
      'severe headache',
      'loss of consciousness',
      'difficulty swallowing',
      'choking',
      'severe allergic reaction',
      'anaphylaxis',
      'acute',
      'emergency',
      'critical',
      'life-threatening',
    ],
    'non_communicable': [
      'diabetes',
      'hypertension',
      'high blood pressure',
      'asthma',
      'arthritis',
      'cancer',
      'tumor',
      'thyroid',
      'hyperthyroid',
      'hypothyroid',
      'cholesterol',
      'obesity',
      'kidney disease',
      'liver disease',
      'heart disease',
      'coronary',
      'cardiovascular',
      'chronic',
      'autoimmune',
      'lupus',
      'alzheimer',
      'dementia',
      'parkinson',
      'osteoporosis',
      'gout',
      'anemia',
      'migraine',
      'epilepsy',
    ],
    'prenatal': [
      'pregnant',
      'pregnancy',
      'prenatal',
      'antenatal',
      'maternal',
      'trimester',
      'ultrasound',
      'fetal',
      'gestational',
      'prenatal care',
      'morning sickness',
      'contractions',
      'labor',
      'delivery',
      'miscarriage',
    ],
    'pediatric': [
      'infant',
      'child',
      'baby',
      'newborn',
      'toddler',
      'pediatric',
      'vaccination',
      'immunization',
      'growth monitoring',
      'developmental',
    ],
    'vital_abnormal': [
      'high blood pressure',
      'low blood pressure',
      'tachycardia',
      'bradycardia',
      'hyperthermia',
      'hypothermia',
      'fever',
      'elevated temperature',
    ],
  };

  HealthAIClassifier._();

  static HealthAIClassifier get instance {
    _instance ??= HealthAIClassifier._();
    return _instance!;
  }

  /// Initialize the TensorFlow Lite model
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // TFLite is not supported on web
    if (kIsWeb) {
      debugPrint(
        'ℹ️ [AI] Running on web - using rule-based classification only',
      );
      _isInitialized = false;
      return false;
    }

    // TFLite disabled - using rule-based classification only
    debugPrint('⚠️ [AI] TFLite disabled, using rule-based classification');
    _isInitialized = false;
    return false;
  }

  /// Main classification method
  Future<ClassificationResult> classify(Map<String, dynamic> healthData) async {
    // Use rule-based classification (TFLite disabled)
    debugPrint('🤖 [AI] Starting classification...');
    final result = _ruleBasedClassify(healthData);

    debugPrint('✅ [AI] Classification complete:');
    debugPrint('  Category: ${result.category}');
    debugPrint('  Severity: ${result.severity}');
    debugPrint('  Confidence: ${result.confidence.toStringAsFixed(2)}');
    debugPrint('  Keywords: ${result.keywords?.join(", ")}');
    debugPrint(
      '  Recovery plan: ${result.recoveryPlan != null ? "Available" : "None"}',
    );

    return result;
  }

  /// Rule-based classification (fallback)
  ClassificationResult _ruleBasedClassify(Map<String, dynamic> healthData) {
    final symptoms = (healthData['symptoms'] ?? '').toString().toLowerCase();
    final details = (healthData['details'] ?? '').toString().toLowerCase();
    final age = int.tryParse(healthData['age']?.toString() ?? '0') ?? 0;

    // Build comprehensive text from all relevant fields
    // This ensures prenatal and other record types are properly analyzed
    final additionalFields =
        [
              healthData['preExistingConditions'],
              healthData['previousComplications'],
              healthData['additionalNote'],
              healthData['allergies'],
              healthData['riskLevel'],
              healthData['plan'],
            ]
            .where((v) => v != null && v.toString().isNotEmpty)
            .map((v) => v.toString().toLowerCase())
            .join(' ');

    final combinedText = '$symptoms $details $additionalFields'.trim();

    // Score each category
    final scores = <String, double>{};

    for (var category in categories) {
      scores[category] = _calculateCategoryScore(
        combinedText,
        category,
        age,
        healthData,
      );
    }

    // Get highest scoring category
    var maxCategory = categories[0];
    var maxScore = scores[maxCategory]!;

    for (var entry in scores.entries) {
      if (entry.value > maxScore) {
        maxCategory = entry.key;
        maxScore = entry.value;
      }
    }

    // Determine severity
    final severity = _determineSeverity(healthData, maxCategory);
    final confidence = min(maxScore / 10.0, 1.0); // Normalize to 0-1
    final matchedKeywords = _extractMatchedKeywords(
      combinedText,
      healthData: healthData,
    );
    final recoveryPlan = _generateRecoveryPlan(matchedKeywords);

    return ClassificationResult(
      category: maxCategory,
      severity: severity,
      confidence: confidence,
      categoryProbabilities: scores.map(
        (k, v) => MapEntry(k, min(v / 10.0, 1.0)),
      ),
      severityProbabilities: {severity: 1.0},
      method: 'rule_based',
      recommendedActions: _getRecommendedActions(maxCategory, severity),
      keywords: matchedKeywords,
      recoveryPlan: recoveryPlan,
    );
  }

  double _calculateCategoryScore(
    String text,
    String category,
    int age,
    Map<String, dynamic> healthData,
  ) {
    double score = 0.0;

    switch (category) {
      case 'Emergency':
        score = _countKeywordMatches(text, keywordDatabase['emergency']!);
        // Check vital signs for emergency indicators
        score += _checkVitalSignsEmergency(healthData) * 5;
        break;

      case 'Communicable Disease':
        score = _countKeywordMatches(text, keywordDatabase['communicable']!);
        break;

      case 'Non-Communicable Disease':
        score = _countKeywordMatches(
          text,
          keywordDatabase['non_communicable']!,
        );
        // Higher weight for older patients
        if (age > 40) score *= 1.3;
        break;

      case 'Prenatal Care':
        score = _countKeywordMatches(text, keywordDatabase['prenatal']!);
        // Detect prenatal-specific fields in the data
        // If these fields exist, it's almost certainly a prenatal record
        final prenatalFields = [
          'gravida',
          'para',
          'lmp',
          'edd',
          'gestationalAge',
          'aog',
          'fh',
          'dhb',
          'tcb',
        ];
        int prenatalFieldCount = 0;
        for (var field in prenatalFields) {
          if (healthData[field] != null &&
              healthData[field].toString().isNotEmpty) {
            prenatalFieldCount++;
          }
        }
        if (prenatalFieldCount > 0) {
          score += prenatalFieldCount * 2.0; // Strong boost per prenatal field
          // Also add base prenatal keywords to the match text
          // so recovery plan generation picks them up
        }
        // Check risk level for prenatal indicators
        final riskLevel = (healthData['riskLevel'] ?? '')
            .toString()
            .toLowerCase();
        if (riskLevel == 'high risk' ||
            riskLevel == 'moderate risk' ||
            riskLevel == 'low risk') {
          score += 3.0;
        }
        break;

      case 'Pediatric Care':
        score = _countKeywordMatches(text, keywordDatabase['pediatric']!);
        if (age < 18) score += 2;
        break;

      case 'Routine Checkup':
        // Default low score, will win if no other category matches
        score = 0.5;
        break;
    }

    return score;
  }

  double _countKeywordMatches(String text, List<String> keywords) {
    double count = 0.0;
    for (var keyword in keywords) {
      if (text.contains(keyword)) {
        count += 1.0;
        // Bonus for exact word match
        if (RegExp(r'\b' + RegExp.escape(keyword) + r'\b').hasMatch(text)) {
          count += 0.5;
        }
      }
    }
    return count;
  }

  double _checkVitalSignsEmergency(Map<String, dynamic> healthData) {
    final details = (healthData['details'] ?? '').toString();
    double score = 0.0;

    // Check blood pressure
    final bpMatch = RegExp(r'BP:\s*(\d+)/(\d+)').firstMatch(details);
    if (bpMatch != null) {
      final systolic = int.tryParse(bpMatch.group(1) ?? '0') ?? 0;
      final diastolic = int.tryParse(bpMatch.group(2) ?? '0') ?? 0;

      if (systolic > 180 ||
          systolic < 90 ||
          diastolic > 120 ||
          diastolic < 60) {
        score += 3.0;
      }
    }

    // Check temperature
    final tempMatch = RegExp(r'Temp:\s*(\d+\.?\d*)').firstMatch(details);
    if (tempMatch != null) {
      final temp = double.tryParse(tempMatch.group(1) ?? '0') ?? 0;
      if (temp > 40.0 || temp < 35.0) {
        score += 2.0;
      }
    }

    // Check heart rate
    final hrMatch = RegExp(r'HR:\s*(\d+)').firstMatch(details);
    if (hrMatch != null) {
      final hr = int.tryParse(hrMatch.group(1) ?? '0') ?? 0;
      if (hr > 120 || hr < 50) {
        score += 2.0;
      }
    }

    return score;
  }

  String _determineSeverity(Map<String, dynamic> healthData, String category) {
    final details = (healthData['details'] ?? '').toString();
    final symptoms = (healthData['symptoms'] ?? '').toString().toLowerCase();

    // Emergency is always critical
    if (category == 'Emergency') return 'Critical';

    // Check vital signs
    int severityScore = 0;

    // Blood pressure check - from details string (checkup format)
    final bpMatch = RegExp(r'BP:\s*(\d+)/(\d+)').firstMatch(details);
    if (bpMatch != null) {
      final systolic = int.tryParse(bpMatch.group(1) ?? '0') ?? 0;
      if (systolic > 160 || systolic < 90) {
        severityScore += 2;
      } else if (systolic > 140 || systolic < 100) {
        severityScore += 1;
      }
    }

    // Blood pressure check - from direct 'bp' field (prenatal format)
    final bpDirect = (healthData['bp'] ?? '').toString();
    if (bpDirect.isNotEmpty) {
      final bpDirectMatch = RegExp(r'(\d+)/(\d+)').firstMatch(bpDirect);
      if (bpDirectMatch != null) {
        final systolic = int.tryParse(bpDirectMatch.group(1) ?? '0') ?? 0;
        final diastolic = int.tryParse(bpDirectMatch.group(2) ?? '0') ?? 0;
        if (systolic > 160 || systolic < 90 || diastolic > 100) {
          severityScore += 2;
        } else if (systolic > 140 || systolic < 100 || diastolic > 90) {
          severityScore += 1;
        }
      }
    }

    // Temperature check - from details string (checkup format)
    final tempMatch = RegExp(r'Temp:\s*(\d+\.?\d*)').firstMatch(details);
    if (tempMatch != null) {
      final temp = double.tryParse(tempMatch.group(1) ?? '0') ?? 0;
      if (temp > 39.5) {
        severityScore += 2;
      } else if (temp > 38.0) {
        severityScore += 1;
      }
    }

    // Temperature check - from direct 'temp' field (prenatal format)
    final tempDirect = (healthData['temp'] ?? '').toString();
    if (tempDirect.isNotEmpty) {
      final temp = double.tryParse(tempDirect) ?? 0;
      if (temp > 39.5) {
        severityScore += 2;
      } else if (temp > 38.0) {
        severityScore += 1;
      }
    }

    // Prenatal risk level check
    if (category == 'Prenatal Care') {
      final riskLevel = (healthData['riskLevel'] ?? '')
          .toString()
          .toLowerCase();
      if (riskLevel.contains('high')) {
        severityScore += 3;
      } else if (riskLevel.contains('moderate')) {
        severityScore += 1;
      }
      // Check for prenatal complications
      final complications = (healthData['previousComplications'] ?? '')
          .toString()
          .toLowerCase();
      final preExisting = (healthData['preExistingConditions'] ?? '')
          .toString()
          .toLowerCase();
      if (complications.isNotEmpty || preExisting.isNotEmpty) {
        severityScore += 1;
      }
    }

    // Symptom severity keywords
    final allText =
        '$symptoms ${(healthData['preExistingConditions'] ?? '').toString().toLowerCase()} ${(healthData['previousComplications'] ?? '').toString().toLowerCase()}';
    final severeKeywords = [
      'severe',
      'acute',
      'intense',
      'unbearable',
      'extreme',
    ];
    for (var keyword in severeKeywords) {
      if (allText.contains(keyword)) severityScore += 1;
    }

    // Determine severity level
    if (severityScore >= 4) return 'Critical';
    if (severityScore >= 2) return 'High';
    if (severityScore >= 1) return 'Medium';
    return 'Low';
  }

  List<String> _getRecommendedActions(String category, String severity) {
    final actions = <String>[];

    if (severity == 'Critical' || category == 'Emergency') {
      actions.addAll([
        '🚨 Immediate medical attention required',
        '📞 Call emergency services or go to ER',
        '⚕️ Do not delay treatment',
      ]);
    } else if (severity == 'High') {
      actions.addAll([
        '⚠️ Urgent medical consultation needed',
        '📅 Schedule appointment within 24 hours',
        '📋 Monitor symptoms closely',
      ]);
    } else if (severity == 'Medium') {
      actions.addAll([
        '👨‍⚕️ Schedule medical consultation',
        '📊 Track symptoms for changes',
        '💊 Follow prescribed treatment',
      ]);
    }

    switch (category) {
      case 'Communicable Disease':
        actions.addAll([
          '😷 Practice isolation if necessary',
          '🧼 Maintain good hygiene',
          '👥 Limit contact with others',
        ]);
        break;
      case 'Non-Communicable Disease':
        actions.addAll([
          '💊 Continue prescribed medications',
          '🏃 Maintain healthy lifestyle',
          '📅 Regular follow-up appointments',
        ]);
        break;
      case 'Prenatal Care':
        actions.addAll([
          '🤰 Regular prenatal checkups',
          '💊 Take prenatal vitamins',
          '🥗 Maintain healthy diet',
        ]);
        break;
    }

    return actions;
  }

  /// Generate detailed recovery recommendations based on keywords
  Map<String, dynamic> _generateRecoveryPlan(List<String> keywords) {
    final medications = <String>{};
    final homeCare = <String>{};
    final precautions = <String>{};
    String? estimatedRecovery;

    // Collect recommendations from all matched keywords
    for (var keyword in keywords) {
      final treatment = treatmentDatabase[keyword];
      if (treatment != null) {
        if (treatment['medications'] != null) {
          medications.addAll((treatment['medications'] as List).cast<String>());
        }
        if (treatment['home_care'] != null) {
          homeCare.addAll((treatment['home_care'] as List).cast<String>());
        }
        if (treatment['precautions'] != null) {
          precautions.addAll((treatment['precautions'] as List).cast<String>());
        }
        if (estimatedRecovery == null && treatment['recovery_time'] != null) {
          estimatedRecovery = treatment['recovery_time'] as String;
        }
      }
    }

    // Add general recommendations if nothing specific found
    if (homeCare.isEmpty) {
      homeCare.addAll([
        'Get adequate rest and sleep',
        'Stay well hydrated',
        'Maintain balanced nutrition',
        'Monitor symptoms',
        'Follow medical advice',
      ]);
    }

    return {
      'medications': medications.toList(),
      'home_care': homeCare.toList(),
      'precautions': precautions.toList(),
      'estimated_recovery': estimatedRecovery ?? 'Varies by condition',
      'general_advice': [
        '[OK] Follow healthcare provider instructions',
        '[OK] Complete full course of medications',
        '[OK] Report any worsening symptoms',
        '[OK] Maintain healthy lifestyle habits',
      ],
    };
  }

  List<String> _extractMatchedKeywords(
    String text, {
    Map<String, dynamic>? healthData,
  }) {
    final matched = <String>[];

    for (var keywords in keywordDatabase.values) {
      for (var keyword in keywords) {
        if (text.contains(keyword) && !matched.contains(keyword)) {
          matched.add(keyword);
        }
      }
    }

    // For prenatal records, ensure prenatal keywords are included
    // even if not explicitly in the text
    if (healthData != null) {
      final prenatalFields = [
        'gravida',
        'para',
        'lmp',
        'edd',
        'gestationalAge',
        'aog',
        'fh',
      ];
      bool hasPrenatalFields = prenatalFields.any(
        (f) => healthData[f] != null && healthData[f].toString().isNotEmpty,
      );
      if (hasPrenatalFields) {
        if (!matched.contains('prenatal')) matched.add('prenatal');
        if (!matched.contains('pregnant')) matched.add('pregnant');
        if (!matched.contains('gestational')) matched.add('gestational');
        if (!matched.contains('maternal')) matched.add('maternal');
      }
    }

    return matched.take(10).toList();
  }

  /// Preprocess data for ML model input
  List<List<double>> _preprocessData(Map<String, dynamic> healthData) {
    // Create feature vector (size: 200)
    final features = List<double>.filled(200, 0.0);

    final symptoms = (healthData['symptoms'] ?? '').toString().toLowerCase();
    final details = (healthData['details'] ?? '').toString().toLowerCase();
    final age = int.tryParse(healthData['age']?.toString() ?? '0') ?? 0;
    final combinedText = '$symptoms $details';

    // Feature 0: Normalized age
    features[0] = age / 100.0;

    // Features 1-50: Keyword presence (binary encoding)
    int idx = 1;
    for (var entry in keywordDatabase.entries) {
      for (var keyword in entry.value.take(10)) {
        if (idx >= 51) break;
        features[idx++] = combinedText.contains(keyword) ? 1.0 : 0.0;
      }
    }

    // Features 51-53: Vital signs (normalized)
    final bpMatch = RegExp(r'BP:\s*(\d+)/(\d+)').firstMatch(details);
    if (bpMatch != null) {
      features[51] = (int.tryParse(bpMatch.group(1) ?? '0') ?? 0) / 200.0;
      features[52] = (int.tryParse(bpMatch.group(2) ?? '0') ?? 0) / 150.0;
    }

    final tempMatch = RegExp(r'Temp:\s*(\d+\.?\d*)').firstMatch(details);
    if (tempMatch != null) {
      features[53] = (double.tryParse(tempMatch.group(1) ?? '0') ?? 0) / 42.0;
    }

    // Features 54-199: Reserved for future expansion

    return [features];
  }

  int _argMax(List<double> list) {
    double maxValue = list[0];
    int maxIndex = 0;

    for (int i = 1; i < list.length; i++) {
      if (list[i] > maxValue) {
        maxValue = list[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  /// Helper method to reshape a flat list into a nested list
  List<List<T>> _reshape<T>(List<T> flatList, int rows, int cols) {
    if (flatList.length != rows * cols) {
      throw ArgumentError('List length must equal rows * cols');
    }
    return List.generate(
      rows,
      (i) => flatList.sublist(i * cols, (i + 1) * cols),
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

/// Classification result with detailed information
class ClassificationResult {
  final String category;
  final String severity;
  final double confidence;
  final Map<String, double> categoryProbabilities;
  final Map<String, double> severityProbabilities;
  final String method; // 'ml_model' or 'rule_based'
  final List<String> recommendedActions;
  final List<String>? keywords;
  final Map<String, dynamic>? recoveryPlan;

  ClassificationResult({
    required this.category,
    required this.severity,
    required this.confidence,
    required this.categoryProbabilities,
    required this.severityProbabilities,
    required this.method,
    required this.recommendedActions,
    this.keywords,
    this.recoveryPlan,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'severity': severity,
    'confidence': confidence,
    'category_probabilities': categoryProbabilities,
    'severity_probabilities': severityProbabilities,
    'method': method,
    'recommended_actions': recommendedActions,
    'keywords': keywords,
    'recovery_plan': recoveryPlan,
    'timestamp': DateTime.now().toIso8601String(),
  };

  @override
  String toString() {
    return 'ClassificationResult(category: $category, severity: $severity, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%, method: $method)';
  }
}
