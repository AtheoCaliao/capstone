import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mycapstone_project/app/login.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:fl_chart/fl_chart.dart';
import 'package:mycapstone_project/app/checkup.dart';
import 'package:mycapstone_project/app/health_metrics.dart';
import 'package:mycapstone_project/app/analytics.dart';
import 'package:mycapstone_project/app/prenatal.dart';
import 'package:mycapstone_project/app/Immunization.dart';
import 'package:mycapstone_project/app/patient.dart';
import 'package:mycapstone_project/app/communicable.dart';
import 'package:mycapstone_project/app/non-communicable.dart';
import 'package:mycapstone_project/app/Mortality.dart';
import 'package:mycapstone_project/app/database_helper.dart';
import 'package:mycapstone_project/app/prenatal_database_helper.dart';
import 'package:mycapstone_project/app/immunization_database_helper.dart';
import 'package:mycapstone_project/app/patient_database_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const Color _primaryAqua = Color(0xFF00A8B5);
const Color _secondaryIceBlue = Color(0xFF1E5A7A);
const Color _darkDeepTeal = Color(0xFF0A1F24);
const Color _mutedCoolGray = Color(0xFF546E7A);
const Color _lightOffWhite = Color(0xFFF5F5F5);

class HomePage extends StatefulWidget {
  final User? user;
  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  Future<void> signout() async {
    await FirebaseAuth.instance.signOut();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _offlineSnackbarShown = false;

  // Database helpers
  final _checkupHelper = DatabaseHelper.instance;
  final _prenatalHelper = PrenatalDatabaseHelper.instance;
  final _immunizationHelper = ImmunizationDatabaseHelper.instance;
  final _patientHelper = PatientDatabaseHelper.instance;

  // Metrics data
  int _totalPatients = 0;
  int _checkupsThisMonth = 0;
  int _prenatalRecords = 0;
  int _immunizationRecords = 0;
  int _highRiskCases = 0;
  bool _isLoadingMetrics = true;

  // Recent activities
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingActivities = true;

  // Disease Trend data
  Map<String, Map<String, int>> _symptomDateData = {}; // symptom -> date -> count
  List<LineChartBarData> _chartLines = [];
  Map<String, Color> _symptomColors = {};
  List<String> _allDates = [];
  List<String> _allSymptoms = [];
  bool _isLoadingTrends = true;
  
  // Chart interaction
  double _chartZoom = 1.0;
  int? _selectedDotIndex;
  
  // Notification plugin and tracking
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  Set<String> _notifiedSymptoms = {}; // Track symptoms that already notified
  Map<String, String> _symptomRecommendations = {
    'fever': 'Increase monitoring. Ensure proper hydration and rest.',
    'cough': 'Monitor respiratory health. Consider air quality assessment.',
    'flu': 'Alert patients. Recommend flu testing and isolation.',
    'cold': 'Monitor symptoms. Increase hygiene standard protocols.',
    'infection': 'Alert healthcare providers. Increase patient follow-ups.',
    'tuberculosis': 'URGENT: Refer to TB specialist immediately.',
    'dengue': 'Alert local health authority. Initiate dengue control measures.',
    'covid': 'Alert infection control. Recommend testing & isolation.',
    'measles': 'URGENT: Isolate patients. Notify public health.',
    'chickenpox': 'Monitor cluster. Recommend vaccination drives.',
    'pneumonia': 'URGENT: Refer to specialist. Monitor oxygen levels.',
    'chest pain': 'URGENT: Cardiac assessment needed immediately.',
    'difficulty breathing': 'URGENT: Respiratory support may be needed.',
    'severe bleeding': 'URGENT: Emergency response required.',
    'unconscious': 'CRITICAL: Immediate emergency intervention.',
    'seizure': 'CRITICAL: Neurological emergency response.',
    'stroke': 'CRITICAL: Stroke response protocol activate.',
    'heart attack': 'CRITICAL: Cardiology emergency response.',
    'diabetes': 'Increase glucose monitoring. Nutritionist consultation recommended.',
    'hypertension': 'Medication review needed. Lifestyle modification counseling.',
    'asthma': 'Respiratory assessment. Inhalers availability check.',
    'arthritis': 'Physical therapy referral. Pain management review.',
    'cancer': 'Oncology referral. Treatment plan review.',
    'thyroid': 'Endocrinology assessment. Hormone level testing.',
    'cholesterol': 'Dietary counseling. Consider statin therapy review.',
    'obesity': 'Nutritionist referral. Exercise program recommended.',
    'pregnant': 'Prenatal checkup scheduling. Nutritional assessment.',
    'pregnancy': 'Ensure prenatal care pathway. Risk assessment.',
    'prenatal': 'Schedule comprehensive prenatal screening.',
    'antenatal': 'Antenatal care monitoring. Blood pressure check.',
    'maternal': 'Maternal health assessment. Postpartum planning.',
    'infant': 'Newborn screening. Vaccination schedule check.',
    'child': 'Pediatric assessment. Development milestones check.',
    'baby': 'Infant health monitoring. Feeding assessment.',
    'newborn': 'Newborn screening protocol. Health assessment.',
    'toddler': 'Developmental assessment. Nutrition review.',
  };

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadMetrics();
    _loadRecentActivities();
    _loadDiseaseTrends();
    
    // Migrate recovery plans from old UTF-8 format to ASCII-safe format
    _checkupHelper.migrateRecoveryPlans();
    _prenatalHelper.migrateRecoveryPlans();
  }
  
  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(initializationSettings);
  }
  
  Future<void> _showSymptomNotification(String symptom, int count) async {
    final recommendation = _symptomRecommendations[symptom] ?? 'Monitor closely.';
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'symptom_alerts',
          'Symptom Alerts',
          channelDescription: 'Alerts when symptoms reach threshold',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _notificationsPlugin.show(
      symptom.hashCode,
      '[ALERT] $symptom Alert',
      'Total: $count cases\n\n[INFO] Recommendation:\n$recommendation',
      platformChannelSpecifics,
    );
    
    _notifiedSymptoms.add(symptom);
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoadingMetrics = true;
    });

    try {
      // Load all database records
      final patients = await _patientHelper.getAllRecords();
      final checkups = await _checkupHelper.getAllRecords();
      final prenatal = await _prenatalHelper.getAllRecords();
      final immunizations = await _immunizationHelper.getAllRecords();

      // Calculate metrics
      final now = DateTime.now();
      final checkupsThisMonth = checkups.where((record) {
        try {
          final datetime = DateTime.parse(record['datetime'] ?? '');
          return datetime.year == now.year && datetime.month == now.month;
        } catch (e) {
          return false;
        }
      }).length;

      // Count high risk cases from prenatal records
      final highRiskCount = prenatal.where((record) {
        final riskLevel = (record['riskLevel'] ?? '').toString().toLowerCase();
        return riskLevel == 'high' || riskLevel == 'very high';
      }).length;

      setState(() {
        _totalPatients = patients.length;
        _checkupsThisMonth = checkupsThisMonth;
        _prenatalRecords = prenatal.length;
        _immunizationRecords = immunizations.length;
        _highRiskCases = highRiskCount;
        _isLoadingMetrics = false;
      });
    } catch (e) {
      print('Error loading metrics: $e');
      setState(() {
        _isLoadingMetrics = false;
      });
    }
  }

  Future<void> _loadRecentActivities() async {
    setState(() {
      _isLoadingActivities = true;
    });

    try {
      List<Map<String, dynamic>> activities = [];

      // Load recent checkups
      final checkups = await _checkupHelper.getAllRecords();
      for (var record in checkups.take(5)) {
        activities.add({
          'title': 'Patient Check-up',
          'subtitle': '${record['patient']} - ${record['type']}',
          'timestamp': record['datetime'] ?? '',
          'icon': Icons.assignment_turned_in,
          'color': _primaryAqua,
          'type': 'checkup',
        });
      }

      // Load recent prenatal records
      final prenatal = await _prenatalHelper.getAllRecords();
      for (var record in prenatal.take(3)) {
        activities.add({
          'title': 'Prenatal Care',
          'subtitle': '${record['patientName']} - Risk: ${record['riskLevel']}',
          'timestamp': record['registrationDate'] ?? '',
          'icon': Icons.pregnant_woman,
          'color': Color(0xFFD84315),
          'type': 'prenatal',
        });
      }

      // Load recent immunizations
      final immunizations = await _immunizationHelper.getAllRecords();
      for (var record in immunizations.take(3)) {
        activities.add({
          'title': 'Immunization',
          'subtitle': '${record['patientName']} - ${record['vaccine']}',
          'timestamp': record['administrationDate'] ?? '',
          'icon': Icons.vaccines,
          'color': Color(0xFF4CAF50),
          'type': 'immunization',
        });
      }

      // Load recent patient registrations
      final patients = await _patientHelper.getAllRecords();
      for (var record in patients.take(3)) {
        activities.add({
          'title': 'New Patient Registration',
          'subtitle': '${record['firstName']} ${record['surname']}',
          'timestamp': record['registrationDate'] ?? '',
          'icon': Icons.person_add,
          'color': Color(0xFF0097A7),
          'type': 'patient',
        });
      }

      // Sort by timestamp (most recent first)
      activities.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['timestamp'] ?? '');
          final dateB = DateTime.parse(b['timestamp'] ?? '');
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        _recentActivities = activities.take(10).toList();
        _isLoadingActivities = false;
      });
    } catch (e) {
      print('Error loading recent activities: $e');
      setState(() {
        _isLoadingActivities = false;
      });
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  Future<void> _loadDiseaseTrends() async {
    setState(() {
      _isLoadingTrends = true;
    });

    try {
      final checkups = await _checkupHelper.getAllRecords();
      final symptomDateMap = <String, Map<String, int>>{}; // symptom -> date -> count
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // List of all medical keywords to detect
      final allSymptoms = {
        'fever', 'cough', 'flu', 'cold', 'infection', 'tuberculosis',
        'dengue', 'covid', 'measles', 'chickenpox', 'pneumonia',
        'chest pain', 'difficulty breathing', 'severe bleeding',
        'unconscious', 'seizure', 'stroke', 'heart attack',
        'diabetes', 'hypertension', 'asthma', 'arthritis',
        'cancer', 'thyroid', 'cholesterol', 'obesity',
        'pregnant', 'pregnancy', 'prenatal', 'antenatal', 'maternal',
        'infant', 'child', 'baby', 'newborn', 'toddler',
      };

      // Initialize symptom maps
      for (var symptom in allSymptoms) {
        symptomDateMap[symptom] = {};
      }

      // Extract symptoms by date for each individual symptom
      for (var record in checkups) {
        try {
          final datetime = DateTime.parse(record['datetime'] ?? '');
          if (datetime.isAfter(thirtyDaysAgo)) {
            final dateStr = '${datetime.month.toString().padLeft(2, '0')}-${datetime.day.toString().padLeft(2, '0')}';
            
            final symptoms = (record['symptoms'] ?? '').toString().toLowerCase();
            final details = (record['details'] ?? '').toString().toLowerCase();
            final type = (record['type'] ?? '').toString().toLowerCase();
            final combinedText = '$symptoms $details $type';

            // Track each symptom individually
            for (var symptom in allSymptoms) {
              if (combinedText.contains(symptom)) {
                symptomDateMap[symptom]![dateStr] = (symptomDateMap[symptom]![dateStr] ?? 0) + 1;
              }
            }
          }
        } catch (e) {
          print('Error processing record: $e');
          continue;
        }
      }

      // Get all unique dates
      final allDatesSet = <String>{};
      for (var symptom in allSymptoms) {
        allDatesSet.addAll(symptomDateMap[symptom]!.keys);
      }
      final sortedDates = allDatesSet.toList()..sort();

      // Only keep symptoms that have data
      final symptomsWithData = <String>[];
      for (var symptom in allSymptoms) {
        if (symptomDateMap[symptom]!.isNotEmpty) {
          symptomsWithData.add(symptom);
        }
      }

      if (sortedDates.isEmpty || symptomsWithData.isEmpty) {
        if (mounted) {
          setState(() {
            _symptomDateData = {};
            _chartLines = [];
            _allDates = [];
            _allSymptoms = [];
            _isLoadingTrends = false;
          });
        }
        return;
      }

      // Generate color for each symptom
      final colors = [
        const Color(0xFF00A8B5), // aqua
        const Color(0xFFFF6B6B), // red
        const Color(0xFF4ECDC4), // teal
        const Color(0xFFFFE66D), // yellow
        const Color(0xFF95E1D3), // mint
        const Color(0xFFC7CEEA), // lavender
        const Color(0xFFFFB6C1), // pink
        const Color(0xFFA8E6CF), // green
      ];

      final symptomColors = <String, Color>{};
      for (var i = 0; i < symptomsWithData.length; i++) {
        symptomColors[symptomsWithData[i]] = colors[i % colors.length];
      }

      // Create line chart bars for each symptom
      final chartLines = <LineChartBarData>[];
      for (var symptom in symptomsWithData) {
        final spots = <FlSpot>[];
        for (var i = 0; i < sortedDates.length; i++) {
          final count = symptomDateMap[symptom]![sortedDates[i]] ?? 0;
          spots.add(FlSpot(i.toDouble(), count.toDouble()));
        }

        final color = symptomColors[symptom]!;
        chartLines.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: color,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _symptomDateData = symptomDateMap;
          _chartLines = chartLines;
          _symptomColors = symptomColors;
          _allDates = sortedDates;
          _allSymptoms = symptomsWithData;
          _isLoadingTrends = false;
        });
        
        // Check for symptoms reaching 10+ threshold and send notifications
        for (var symptom in symptomsWithData) {
          final totalCount = symptomDateMap[symptom]!.values.fold<int>(0, (sum, val) => sum + val);
          if (totalCount >= 10 && !_notifiedSymptoms.contains(symptom)) {
            await _showSymptomNotification(symptom, totalCount);
          }
        }
      }
    } catch (e) {
      print('Error loading disease trends: $e');
      if (mounted) {
        setState(() {
          _isLoadingTrends = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final args = Get.arguments;
    if (args != null && args['offline'] == true && !_offlineSnackbarShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You are now in offline mode.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
      _offlineSnackbarShown = true;
    }
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _darkDeepTeal,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(),
      ),
      drawer: SizedBox(
        width: 350,
        child: Drawer(
          backgroundColor: _darkDeepTeal,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
              // Profile Card
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _lightOffWhite.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _lightOffWhite.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.account_circle,
                        color: _lightOffWhite.withOpacity(0.15),
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn
                                ? (user.email?.split('@').first ?? 'User')
                                    .toUpperCase()
                                : 'GUEST',
                            style: TextStyle(
                              color: _lightOffWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLoggedIn ? 'Active' : 'Not Logged In',
                            style: TextStyle(
                              color: _lightOffWhite.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Patient Management Area
              Text(
                'Patient Management Area',
                style: TextStyle(
                  color: _lightOffWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.0,
                children: [
                  _buildDrawerCardButton(
                    icon: Icons.medical_services,
                    label: 'Check Up',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CheckUpPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerCardButton(
                    icon: Icons.healing,
                    label: 'Morbidity',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerCardButton(
                    icon: Icons.pregnant_woman,
                    label: 'Prenatal Care',
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.to(() => const PrenatalPage());
                    },
                  ),
                  _buildDrawerCardButton(
                    icon: Icons.vaccines,
                    label: 'Immunization',
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.to(() => const ImmunizationPage());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Record
              Text(
                'Record',
                style: TextStyle(
                  color: _lightOffWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.0,
                children: [
                  _buildDrawerCardButton(
                    icon: Icons.folder_shared,
                    label: 'Barangay Records',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerCardButton(
                    icon: Icons.folder_special,
                    label: 'Patient Records',
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.to(() => const PatientRecordPage());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Disease Monitoring
              Text(
                'Disease Monitoring',
                style: TextStyle(
                  color: _lightOffWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.0,
                children: [
                  _buildDrawerCardButton(
                    icon: Icons.coronavirus,
                    label: 'Communicable Disease',
                    onTap: () {
                      Navigator.pop(context);
                      Get.to(() => const CommunicablePage());
                    },
                  ),
                  _buildDrawerCardButton(
                    icon: Icons.sick,
                    label: 'Non Communicable Disease',
                    onTap: () {
                      Navigator.pop(context);
                      Get.to(() => const NonCommunicablePage());
                    },
                  ),
                  _buildDrawerCardButton(
                    icon: Icons.airline_seat_flat,
                    label: 'Mortality',
                    onTap: () {
                      Navigator.pop(context);
                      Get.to(() => const MortalityPage());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Sign Out / Sign In Button
              if (isLoggedIn) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await signout();
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const Login(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: _lightOffWhite,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const Login(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login, size: 20),
                    label: const Text('Sign In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryAqua,
                      foregroundColor: _darkDeepTeal,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      ),

      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: kIsWeb 
              ? const BoxConstraints(maxWidth: 1400)
              : const BoxConstraints(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header Card
                _buildHeaderCard(context, widget.user),
                const SizedBox(height: 28),
                
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: kIsWeb ? 32.0 : 16.0,
                    vertical: 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Key Metrics Overview
                      _buildKeyMetricsSection(context),
                      const SizedBox(height: 28),

                      // Primary Actions - Health Metrics & Analytics
                      Text(
                        'Primary Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _lightOffWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPrimaryActionsRow(context),
                      const SizedBox(height: 28),

                      // Disease Trend Section
                      _buildDiseaseTrendSection(context),
                      const SizedBox(height: 28),

                      // Footer
                      Center(
                        child: Text(
                          '© 2026 Healthcare Monitoring System. All rights reserved.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: _mutedCoolGray),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom Header Card with Drawer, Notification, Greeting, Username, Date, System Status, and Search
  Widget _buildHeaderCard(BuildContext context, User? user) {
    final userName = user?.email?.split('@').first ?? 'User';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';
    
    final now = DateTime.now();
    final formattedDate = '${_getMonthName(now.month)} ${now.day}, ${now.year}';
    final dayOfWeek = _getDayOfWeek(now.weekday);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _darkDeepTeal,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Drawer Button, Title, Notification Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Drawer Button
                  Container(
                    decoration: BoxDecoration(
                      color: _lightOffWhite.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _lightOffWhite.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: _lightOffWhite, size: 28),
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      tooltip: 'Menu',
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  // Title
                  Text(
                    'DSUHIS',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _lightOffWhite,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  // Notification Icon
                  Container(
                    decoration: BoxDecoration(
                      color: _lightOffWhite.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _lightOffWhite.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, color: _lightOffWhite, size: 28),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No new notifications'),
                                backgroundColor: _primaryAqua,
                              ),
                            );
                          },
                          tooltip: 'Notifications',
                          padding: const EdgeInsets.all(8),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Color(0xFFFF5252),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Greeting Message and User Info Card
              SizedBox(
                width: double.infinity,
                child: Card(
                  elevation: 0,
                  color: _primaryAqua.withOpacity(0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _primaryAqua.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Greeting and Username (Left side)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Greeting
                              Text(
                                greeting,
                                style: TextStyle(
                                  color: _lightOffWhite,
                                  fontSize: kIsWeb ? 24 : 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Username
                              Text(
                                userName.toUpperCase(),
                                style: TextStyle(
                                  color: _lightOffWhite.withOpacity(0.9),
                                  fontSize: kIsWeb ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Date (Right side)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _lightOffWhite.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _lightOffWhite.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: _lightOffWhite,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$dayOfWeek, $formattedDate',
                                style: TextStyle(
                                  color: _lightOffWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // System Status Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _lightOffWhite.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _primaryAqua.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xFF4CAF50).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Status: Online',
                            style: TextStyle(
                              color: _lightOffWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All systems operational',
                            style: TextStyle(
                              color: _lightOffWhite.withOpacity(0.75),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getDayOfWeek(int day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day - 1];
  }

  // Primary Actions Row (Health Metrics & Analytics)
  Widget _buildPrimaryActionsRow(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _buildActionCard(
          context: context,
          icon: Icons.monitor_heart,
          label: 'Summary',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HealthMetricsPage(),
              ),
            );
          },
        ),
        _buildActionCard(
          context: context,
          icon: Icons.bar_chart_rounded,
          label: 'Analytics & Insights',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AnalyticsPage()),
            );
          },
        ),
        _buildActionCard(
          context: context,
          icon: Icons.local_hospital,
          label: 'Check Up',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CheckUpPage()),
            );
          },
        ),
      ],
    );
  }

  // Action Card Button (for Primary Actions)
  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(80),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: _darkDeepTeal,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _darkDeepTeal.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _darkDeepTeal.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryAqua.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: _primaryAqua,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _lightOffWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Primary Action Button (Card-style)
  Widget _buildPrimaryActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                color.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _darkDeepTeal,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: 3,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Disease Trend Section
  Widget _buildDiseaseTrendSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 0,
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: _lightOffWhite.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryAqua, _primaryAqua.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryAqua.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.trending_up, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Disease Trend - Multiple Symptoms',
                                style: TextStyle(
                                  fontSize: kIsWeb ? 20 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: _lightOffWhite,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Individual symptom trends over the last 30 days',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _lightOffWhite.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Instructions
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _lightOffWhite.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _lightOffWhite.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: _lightOffWhite, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pinch to zoom • Tap dots to see symptom details',
                            style: TextStyle(
                              color: _lightOffWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: _isLoadingTrends
                        ? Center(
                            child: CircularProgressIndicator(color: _primaryAqua),
                          )
                        : _chartLines.isEmpty
                            ? Center(
                                child: Text(
                                  'No disease data available',
                                  style: TextStyle(color: _lightOffWhite.withOpacity(0.7), fontSize: 14),
                                ),
                              )
                            : GestureDetector(
                                onScaleUpdate: (details) {
                                  setState(() {
                                    _chartZoom *= details.scale;
                                    _chartZoom = _chartZoom.clamp(1.0, 5.0);
                                  });
                                },
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      horizontalInterval: 1,
                                      verticalInterval: 1,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: _lightOffWhite.withOpacity(0.1),
                                          strokeWidth: 1,
                                        );
                                      },
                                      getDrawingVerticalLine: (value) {
                                        return FlLine(
                                          color: _lightOffWhite.withOpacity(0.1),
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (double value, TitleMeta meta) {
                                            if (value.toInt() < _allDates.length) {
                                              return Text(
                                                _allDates[value.toInt()],
                                                style: TextStyle(
                                                  color: _lightOffWhite,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 1,
                                          getTitlesWidget: (double value, TitleMeta meta) {
                                            return Text(
                                              '${value.toInt()}',
                                              style: TextStyle(
                                                color: _lightOffWhite,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                          reservedSize: 32,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: _lightOffWhite.withOpacity(0.2),
                                        ),
                                        left: BorderSide(
                                          color: _lightOffWhite.withOpacity(0.2),
                                        ),
                                      ),
                                    ),
                                    minX: 0,
                                    maxX: (_allDates.length - 1).toDouble(),
                                    minY: 0,
                                    maxY: _chartLines.isNotEmpty
                                        ? _chartLines
                                            .map((line) => line.spots
                                                .map((spot) => spot.y)
                                                .reduce((a, b) => a > b ? a : b))
                                            .reduce((a, b) => a > b ? a : b) +
                                            2
                                        : 10,
                                    lineBarsData: _chartLines,
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                          if (touchedBarSpots.isEmpty) return [];
                                          
                                          final xIndex = touchedBarSpots.first.x.toInt();
                                          if (xIndex >= _allDates.length) return [];
                                          
                                          final date = _allDates[xIndex];
                                          return touchedBarSpots.map((barSpot) {
                                            final barIndex = barSpot.barIndex;
                                            if (barIndex >= 0 && barIndex < _allSymptoms.length) {
                                              final symptom = _allSymptoms[barIndex];
                                              final count = barSpot.y.toInt();
                                              return LineTooltipItem(
                                                '$symptom: $count',
                                                TextStyle(
                                                  color: _symptomColors[symptom] ?? Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                                children: [TextSpan(text: '')],
                                              );
                                            }
                                            return null;
                                          }).toList();
                                        },
                                        tooltipPadding: const EdgeInsets.all(8),
                                        tooltipMargin: 8,
                                      ),
                                      handleBuiltInTouches: true,
                                      touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                                        if (event is FlTapUpEvent) {
                                          if (response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
                                            final touchedSpot = response.lineBarSpots![0];
                                            final xIndex = touchedSpot.x.toInt();
                                            if (xIndex < _allDates.length) {
                                              final date = _allDates[xIndex];
                                              final symptom = _allSymptoms[touchedSpot.barIndex];
                                              final count = touchedSpot.y.toInt();
                                              
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '$symptom on $date: $count cases',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  backgroundColor: _symptomColors[symptom] ?? _primaryAqua,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                  ),
                  const SizedBox(height: 16),
                  // Legend showing symptoms and their colors
                  if (_allSymptoms.isNotEmpty)
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: _allSymptoms.map((symptom) {
                        final color = _symptomColors[symptom] ?? _primaryAqua;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              symptom,
                              style: TextStyle(
                                color: _lightOffWhite,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Key Metrics Section
  Widget _buildKeyMetricsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 0,
            color: _darkDeepTeal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: _darkDeepTeal.withOpacity(0.12),
                width: 1.5,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _darkDeepTeal.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryAqua, _primaryAqua.withOpacity(0.8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryAqua.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.dashboard, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Key Performance Metrics',
                                  style: TextStyle(
                                    fontSize: kIsWeb ? 23: 21,
                                    fontWeight: FontWeight.bold,
                                    color: _lightOffWhite,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Real-time system overview',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _lightOffWhite.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_isLoadingMetrics)
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(_primaryAqua),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _primaryAqua.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _primaryAqua.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.refresh_rounded, color: _primaryAqua, size: 24),
                              onPressed: _loadMetrics,
                              tooltip: 'Refresh metrics',
                              padding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 3.5,
                      children: [
                        _buildMetricCard(
                          title: 'Total Patients',
                          value: _isLoadingMetrics ? '...' : '$_totalPatients',
                          unit: 'Registered',
                          icon: Icons.people_rounded,
                          color: _primaryAqua,
                          trend: '+12%',
                          trendLabel: 'vs last month',
                          isPositiveTrend: true,
                        ),
                        _buildMetricCard(
                          title: 'Check-ups',
                          value: _isLoadingMetrics ? '...' : '$_checkupsThisMonth',
                          unit: 'This Month',
                          icon: Icons.assignment_turned_in_rounded,
                          color: _darkDeepTeal,
                          trend: '+8%',
                          trendLabel: 'from last month',
                          isPositiveTrend: true,
                        ),
                        _buildMetricCard(
                          title: 'Prenatal Care',
                          value: _isLoadingMetrics ? '...' : '$_prenatalRecords',
                          unit: 'Active Records',
                          icon: Icons.pregnant_woman_rounded,
                          color: Color(0xFFD84315),
                          trend: '+15%',
                          trendLabel: 'new this week',
                          isPositiveTrend: true,
                        ),
                        _buildMetricCard(
                          title: 'Immunizations',
                          value: _isLoadingMetrics ? '...' : '$_immunizationRecords',
                          unit: 'Administered',
                          icon: Icons.vaccines_rounded,
                          color: Color(0xFF4CAF50),
                          trend: '+10%',
                          trendLabel: 'completion rate',
                          isPositiveTrend: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Individual Metric Card
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String trend,
    String trendLabel = '',
    bool isPositiveTrend = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _primaryAqua.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryAqua.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -10,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon + Text
                  Flexible(
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                            // Value and Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    value,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: _lightOffWhite,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _lightOffWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    unit,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _lightOffWhite.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                  // Trend Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositiveTrend
                          ? Color(0xFF4CAF50).withOpacity(0.12)
                          : Color(0xFFF44336).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPositiveTrend
                            ? Color(0xFF4CAF50).withOpacity(0.3)
                            : Color(0xFFF44336).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPositiveTrend
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 14,
                          color: isPositiveTrend ? Color(0xFF4CAF50) : Color(0xFFF44336),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trend,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPositiveTrend ? Color(0xFF4CAF50) : Color(0xFFF44336),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recent Activity Section
  Widget _buildHealthMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: _mutedCoolGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, size: 28, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: _mutedCoolGray),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 24,
          color: _mutedCoolGray,
        ),
      ),
    );
  }

  // Helper method for user detail rows in drawer
  Widget _buildUserDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: _mutedCoolGray, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: _mutedCoolGray,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _darkDeepTeal,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        // Use WidgetsBinding.instance.addPostFrameCallback for safe navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onTap();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: _primaryAqua,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryAqua.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: _darkDeepTeal),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _darkDeepTeal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            color.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: color.withOpacity(0.15),
          highlightColor: color.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _darkDeepTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerCardButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 48,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _lightOffWhite.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _lightOffWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Data classes for community_charts_flutter
class BarData {
  final String label;
  final int value;
  BarData(this.label, this.value);
}

class LineData {
  final int day;
  final int value;
  LineData(this.day, this.value);
}

class PieData {
  final String label;
  final int value;
  final charts.Color color;
  PieData(this.label, this.value, this.color);
}

// Power BI-style graph card widget
Widget _buildGraphCard({required String title, required Widget child}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _darkDeepTeal,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
        ],
      ),
    ),
  );
}
