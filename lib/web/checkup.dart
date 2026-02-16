import 'package:flutter/material.dart';
import 'package:mycapstone_project/web/database_helper.dart';
import 'package:mycapstone_project/app/health_ai_classifier.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mycapstone_project/web/login.dart';
import 'package:mycapstone_project/web/homepage.dart';
import 'package:mycapstone_project/web/health_metrics.dart';
import 'package:mycapstone_project/web/analytics.dart';
import 'package:mycapstone_project/web/prenatal.dart';
import 'package:mycapstone_project/web/Immunization.dart';
import 'package:mycapstone_project/web/patient.dart';
import 'package:mycapstone_project/web/communicable.dart';
import 'package:mycapstone_project/web/non-communicable.dart';
import 'package:mycapstone_project/web/Mortality.dart';
import 'dart:async';
import 'dart:convert';

const Color _primaryAqua = Color(0xFF00A8B5);
const Color _secondaryIceBlue = Color(0xFF1E5A7A);
const Color _darkDeepTeal = Color(0xFF0A1F24);
const Color _mutedCoolGray = Color(0xFF546E7A);
const Color _lightOffWhite = Color(0xFFF5F5F5);
const Color _sidebarDark = Color(0xFF0E2F34);

class CheckUpPage extends StatefulWidget {
  const CheckUpPage({super.key});

  @override
  State<CheckUpPage> createState() => _CheckUpPageState();
}

class _CheckUpPageState extends State<CheckUpPage> {
  DateTime? _selectedDate;
  String _filterType = 'All'; // All, Day, Month, Year

  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};
  bool _isDeleteDialogShowing = false;
  bool _isLoading = true;

  // Database-backed records
  List<Map<String, dynamic>> _records = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  StreamSubscription<List<Map<String, dynamic>>>? _recordsSubscription;

  // Dashboard metrics
  int _totalCheckups = 0;
  int _thisMonthCheckups = 0;
  int _vitalRecordsCount = 0;

  // AI Classifier
  final HealthAIClassifier _aiClassifier = HealthAIClassifier.instance;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
    _dbHelper.startConnectivityListener();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    await _aiClassifier.initialize();
  }

  void _setupRealtimeListener() {
    // Listen to real-time updates from Firestore
    _recordsSubscription = _dbHelper.getRecordsStream().listen((records) {
      _updateRecordsWithMetrics(records);
    });
  }

  void _updateRecordsWithMetrics(List<Map<String, dynamic>> records) {
    // Calculate metrics
    final now = DateTime.now();
    final thisMonthCount = records.where((record) {
      try {
        final datetime = DateTime.parse(record['datetime'] ?? '');
        return datetime.year == now.year && datetime.month == now.month;
      } catch (e) {
        return false;
      }
    }).length;

    // Count records with vital signs
    final vitalRecords = records.where((record) {
      final details = record['details']?.toString() ?? '';
      return details.contains('BP:') ||
          details.contains('Temp:') ||
          details.contains('HR:');
    }).length;

    if (mounted) {
      setState(() {
        _records = records;
        _totalCheckups = records.length;
        _thisMonthCheckups = thisMonthCount;
        _vitalRecordsCount = vitalRecords;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _recordsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    // This method is kept for compatibility but real-time listener
    // will automatically update the UI
    print('🔄 [CHECKUP] Manual load requested...');
    await _dbHelper.syncFromFirebase();
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_selectedDate == null || _filterType == 'All') {
      return _records;
    }

    return _records.where((record) {
      try {
        final recordDate = DateTime.parse(
          record['datetime']?.split(' ')[0] ?? '',
        );

        switch (_filterType) {
          case 'Day':
            return recordDate.year == _selectedDate!.year &&
                recordDate.month == _selectedDate!.month &&
                recordDate.day == _selectedDate!.day;
          case 'Month':
            return recordDate.year == _selectedDate!.year &&
                recordDate.month == _selectedDate!.month;
          case 'Year':
            return recordDate.year == _selectedDate!.year;
          default:
            return true;
        }
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      backgroundColor: _lightOffWhite,
      body: Row(
        children: [
          // Sidebar Navigation
          _buildSidebar(context, userName),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(context),
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _primaryAqua),
                        )
                      : Stack(
                          children: [
                            SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _CheckUpDashboardHeader(
                                      totalCheckups: _totalCheckups,
                                      thisMonthCheckups: _thisMonthCheckups,
                                      vitalRecordsCount: _vitalRecordsCount,
                                    ),
                                    const SizedBox(height: 24),

                                    // Filter Section
                                    _buildFilterSection(),
                                    const SizedBox(height: 24),

                                    // Action Menu Button
                                    _buildActionMenuButton(),
                                    const SizedBox(height: 24),

                                    // Records Table
                                    _CheckUpTable(
                                      records: _filteredRecords,
                                      isSelectionMode: _isSelectionMode,
                                      selectedIndices: _selectedIndices,
                                      onSelectionChanged: (index, selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedIndices.add(index);
                                          } else {
                                            _selectedIndices.remove(index);
                                          }
                                        });
                                      },
                                      onEdit: (record) {
                                        Future.microtask(() {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) =>
                                                _EditCheckUpFullScreenModal(
                                                  record: record,
                                                  aiClassifier: _aiClassifier,
                                                  onSave: (updatedRecord) async {
                                                    try {
                                                      // Update in database
                                                      final id =
                                                          updatedRecord['id']
                                                              ?.toString() ??
                                                          '';
                                                      if (id.isEmpty) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Error: Record ID not found',
                                                            ),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                        return;
                                                      }
                                                      await _dbHelper
                                                          .updateRecord(
                                                            id,
                                                            updatedRecord,
                                                          );
                                                      // Reload from database
                                                      await _loadRecords();
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Record updated successfully',
                                                            ),
                                                            backgroundColor:
                                                                Colors.green,
                                                          ),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Error updating record: $e',
                                                            ),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            _buildSelectionActionCard(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          (_isDeleteDialogShowing ||
              (_isSelectionMode && _selectedIndices.isNotEmpty))
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _primaryAqua,
              foregroundColor: _darkDeepTeal,
              icon: const Icon(Icons.add),
              label: const Text('New Check Up'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => _NewCheckUpFullScreenModal(
                    aiClassifier: _aiClassifier,
                    onSave: (newRecord) async {
                      print('🎯 [CHECKUP CALLBACK] onSave callback triggered!');
                      print('📝 [CHECKUP] Patient: ${newRecord['patient']}');

                      // Just save to database - don't reload or show messages here
                      // The modal will handle closing, then we reload after
                      await _dbHelper.insertRecord(newRecord);
                      print('✅ [CHECKUP] Record saved to database');

                      // Return the disease type for the message
                      return newRecord['diseaseType'] ?? 'General';
                    },
                  ),
                ).then((diseaseType) async {
                  // This runs AFTER the modal closes
                  if (diseaseType != null) {
                    print('🔄 [CHECKUP] Modal closed, now reloading...');
                    await _loadRecords();

                    // Show success message
                    String message = 'Check-up record saved successfully!';
                    if (diseaseType == 'Communicable') {
                      message =
                          'Check-up saved! This communicable disease case has been recorded for tracking.';
                    } else if (diseaseType == 'Non-Communicable') {
                      message =
                          'Check-up saved! This non-communicable disease case has been recorded for management.';
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                });
              },
            ),
    );
  }

  Widget _buildSidebar(BuildContext context, String userName) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      width: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_sidebarDark, _sidebarDark.withOpacity(0.95)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryAqua, _secondaryIceBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryAqua.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/bg2.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: _primaryAqua,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent,
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _primaryAqua,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MAIN MENU',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              children: [
                _buildSidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  onTap: () => Get.to(() => const HomePage()),
                ),
                _buildSidebarItem(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Check-ups',
                  isActive: true,
                  onTap: () {},
                ),
                _buildSidebarItem(
                  icon: Icons.favorite_rounded,
                  label: 'Health Metrics',
                  onTap: () => Get.to(() => const HealthMetricsPage()),
                ),
                _buildSidebarItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  onTap: () => Get.to(() => const AnalyticsPage()),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _primaryAqua,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PATIENT CARE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.pregnant_woman_rounded,
                  label: 'Prenatal Care',
                  onTap: () => Get.to(() => const PrenatalPage()),
                ),
                _buildSidebarItem(
                  icon: Icons.vaccines_rounded,
                  label: 'Immunization',
                  onTap: () => Get.to(() => const ImmunizationPage()),
                ),
                _buildSidebarItem(
                  icon: Icons.person_rounded,
                  label: 'Patient Records',
                  onTap: () => Get.to(() => const PatientRecordPage()),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _primaryAqua,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DISEASE TRACKING',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.coronavirus_rounded,
                  label: 'Communicable',
                  onTap: () => Get.to(() => const CommunicablePage()),
                ),
                _buildSidebarItem(
                  icon: Icons.health_and_safety_rounded,
                  label: 'Non-Communicable',
                  onTap: () => Get.to(() => const NonCommunicablePage()),
                ),
                _buildSidebarItem(
                  icon: Icons.analytics_outlined,
                  label: 'Mortality',
                  onTap: () => Get.to(() => const MortalityPage()),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Get.offAll(() => const Login());
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade600, Colors.red.shade700],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withOpacity(0.08),
          splashColor: _primaryAqua.withOpacity(0.2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        _primaryAqua.withOpacity(0.15),
                        _primaryAqua.withOpacity(0.05),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: isActive ? _primaryAqua : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _primaryAqua.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: isActive
                        ? _primaryAqua
                        : Colors.white.withOpacity(0.8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.8),
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _primaryAqua,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.assignment_turned_in_rounded,
            color: _primaryAqua,
            size: 32,
          ),
          const SizedBox(width: 16),
          Text(
            'Check-up Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _darkDeepTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'View Data in Console',
            onPressed: () {
              print('=== CHECK-UP RECORDS DATA ===');
              print('Total Records: ${_records.length}');
              for (var i = 0; i < _records.length; i++) {
                print('\nRecord ${i + 1}:');
                _records[i].forEach((key, value) {
                  print('  $key: $value');
                });
              }
              print('=============================');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Data printed to console! Check Debug Console.',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            color: _mutedCoolGray,
            iconSize: 28,
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            color: _mutedCoolGray,
            iconSize: 28,
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
            color: _mutedCoolGray,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryAqua.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryAqua, _secondaryIceBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryAqua.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Records',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _darkDeepTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Refine your search criteria',
                    style: TextStyle(fontSize: 13, color: _mutedCoolGray),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date and Filter Controls
          Row(
            children: [
              // Date Picker
              Expanded(
                flex: 2,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: _primaryAqua,
                                onPrimary: Colors.white,
                                onSurface: _darkDeepTeal,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _primaryAqua.withOpacity(0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _lightOffWhite,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _primaryAqua.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: _primaryAqua,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _mutedCoolGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedDate != null
                                      ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
                                      : 'No date selected',
                                  style: TextStyle(
                                    color: _selectedDate != null
                                        ? _darkDeepTeal
                                        : _mutedCoolGray,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: _primaryAqua,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Filter Type Dropdown
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _primaryAqua.withOpacity(0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _lightOffWhite,
                  ),
                  child: DropdownButton<String>(
                    value: _filterType,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: _primaryAqua,
                    ),
                    items: ['All', 'Day', 'Month', 'Year'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: _darkDeepTeal,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _filterType = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Clear Filter Button
              if (_selectedDate != null)
                Container(
                  decoration: BoxDecoration(
                    color: _primaryAqua.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: _primaryAqua,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                        _filterType = 'All';
                      });
                    },
                    tooltip: 'Clear Filter',
                  ),
                ),
            ],
          ),

          // Filter Info
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryAqua.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: _primaryAqua, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing ${_filteredRecords.length} record(s) for $_filterType filter',
                        style: TextStyle(
                          color: _darkDeepTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionMenuButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: _isSelectionMode
            ? LinearGradient(
                colors: [
                  _primaryAqua.withOpacity(0.1),
                  _secondaryIceBlue.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _isSelectionMode ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSelectionMode
              ? _primaryAqua
              : _primaryAqua.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isSelectionMode
                ? _primaryAqua.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _isSelectionMode = !_isSelectionMode;
              if (!_isSelectionMode) {
                _selectedIndices.clear();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isSelectionMode
                          ? [Colors.red.shade400, Colors.red.shade600]
                          : [_primaryAqua, _secondaryIceBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (_isSelectionMode ? Colors.red : _primaryAqua)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isSelectionMode
                        ? Icons.close_rounded
                        : Icons.checklist_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSelectionMode
                            ? 'Selection Mode Active'
                            : 'Select Multiple Records',
                        style: TextStyle(
                          color: _darkDeepTeal,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isSelectionMode
                            ? 'Click to deactivate selection mode'
                            : 'Enable bulk operations',
                        style: TextStyle(fontSize: 12, color: _mutedCoolGray),
                      ),
                    ],
                  ),
                ),
                if (_isSelectionMode && _selectedIndices.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryAqua, _secondaryIceBlue],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryAqua.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_selectedIndices.length} Selected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _mutedCoolGray,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionActionCard() {
    if (!_isSelectionMode || _selectedIndices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primaryAqua.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: _darkDeepTeal.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selection count header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryAqua.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: _primaryAqua,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedIndices.length} record(s) selected',
                  style: TextStyle(
                    color: _darkDeepTeal,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        final allIndices = List.generate(
                          _filteredRecords.length,
                          (index) => index,
                        );
                        _selectedIndices.addAll(allIndices);
                      });
                    },
                    icon: Icon(Icons.select_all, size: 18),
                    label: Text('Select All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _confirmDelete,
                    icon: Icon(Icons.delete, size: 18),
                    label: Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedIndices.clear();
                      });
                    },
                    icon: Icon(Icons.close, size: 18),
                    label: Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _mutedCoolGray,
                      side: BorderSide(color: _mutedCoolGray, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    if (_selectedIndices.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No records selected'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isDeleteDialogShowing = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text('Confirm Delete'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedIndices.length} selected record(s)? This action cannot be undone.',
          style: TextStyle(color: _darkDeepTeal),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isDeleteDialogShowing = false;
              });
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: _mutedCoolGray,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedRecords();
              setState(() {
                _isDeleteDialogShowing = false;
              });
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).then((_) {
      // Ensure the state is reset if dialog is dismissed by tapping outside
      setState(() {
        _isDeleteDialogShowing = false;
      });
    });
  }

  void _deleteSelectedRecords() async {
    final count = _selectedIndices.length;

    // Get IDs of records to delete
    final idsToDelete = _selectedIndices
        .map(
          (index) => index < _filteredRecords.length
              ? _filteredRecords[index]['id'] as String?
              : null,
        )
        .whereType<String>()
        .toList();

    // Delete from database
    await _dbHelper.deleteRecords(idsToDelete);

    setState(() {
      _selectedIndices.clear();
      _isSelectionMode = false;
    });

    // Reload records
    await _loadRecords();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully deleted $count record(s)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _CheckUpDashboardHeader extends StatelessWidget {
  final int totalCheckups;
  final int thisMonthCheckups;
  final int vitalRecordsCount;

  const _CheckUpDashboardHeader({
    required this.totalCheckups,
    required this.thisMonthCheckups,
    required this.vitalRecordsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with Icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryAqua, _secondaryIceBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _primaryAqua.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Check-Up Records',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _darkDeepTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Comprehensive patient visit tracking and management',
                  style: TextStyle(fontSize: 14, color: _mutedCoolGray),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Metrics Grid - 3 columns on web
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1.6,
          children: [
            _buildDashboardMetricCard(
              title: 'Total Check-ups',
              value: '$totalCheckups',
              subtitle: 'All completed visits',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF4CAF50),
              trend: '+12%',
            ),
            _buildDashboardMetricCard(
              title: 'This Month',
              value: '$thisMonthCheckups',
              subtitle: 'Current month visits',
              icon: Icons.event_available_rounded,
              color: const Color(0xFFFF9800),
              trend: '+8%',
            ),
            _buildDashboardMetricCard(
              title: 'Vital Records',
              value: '$vitalRecordsCount',
              subtitle: 'With vital signs',
              icon: Icons.favorite_rounded,
              color: const Color(0xFFE91E63),
              trend: '+15%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _darkDeepTeal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: _mutedCoolGray.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// CheckUp Table Widget
class _CheckUpTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final bool isSelectionMode;
  final Set<int> selectedIndices;
  final Function(int, bool) onSelectionChanged;
  final Function(Map<String, dynamic>) onEdit;

  const _CheckUpTable({
    required this.records,
    required this.isSelectionMode,
    required this.selectedIndices,
    required this.onSelectionChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Text(
          'No records found.',
          style: TextStyle(color: _mutedCoolGray, fontSize: 16),
        ),
      );
    }

    return Column(
      children: List.generate(records.length, (index) {
        final isSelected = selectedIndices.contains(index);
        return _CheckUpCard(
          record: records[index],
          isSelectionMode: isSelectionMode,
          isSelected: isSelected,
          index: index,
          onSelectionChanged: onSelectionChanged,
          onEdit: onEdit,
        );
      }),
    );
  }
}

// Helper function to show checkup details
void _showCheckUpDetails(BuildContext context, Map<String, dynamic> record) {
  // Parse first name and surname
  final patientName = record['patient'] ?? 'Unknown';
  final nameParts = patientName.split(' ');
  final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
  final surname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryAqua, _primaryAqua.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('Patient Information', [
                      _buildDetailRow('First Name', firstName),
                      _buildDetailRow('Surname', surname),
                      _buildDetailRow('Age', record['age']),
                      _buildDetailRow('Address', record['address']),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailSection('Check-Up Details', [
                      _buildDetailRow('Date & Time', record['datetime']),
                      _buildDetailRow('Record Type', record['type']),
                      _buildDetailRow('Status', record['status']),
                      _buildDetailRow('Follow-up Date', record['followup']),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailSection('Vital Signs', [
                      _buildDetailRow('Vital Signs', record['vitalsigns']),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailSection('Symptoms & Assessment', [
                      _buildDetailRow('Symptoms', record['symptoms']),
                    ]),
                    const SizedBox(height: 16),
                    // AI Classification Section
                    if (record['ai_category'] != null) ...[
                      _buildAIClassificationSection(record),
                      const SizedBox(height: 16),
                    ],
                    _buildDetailSection('Treatment Plan', [
                      _buildDetailRow('Plan', record['plan']),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildDetailSection(String title, List<Widget> children) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _darkDeepTeal,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primaryAqua.withOpacity(0.2)),
        ),
        child: Column(children: children),
      ),
    ],
  );
}

Widget _buildDetailRow(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: _mutedCoolGray,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value?.toString() ?? 'N/A',
            style: TextStyle(
              color: _darkDeepTeal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: _mutedCoolGray),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: _mutedCoolGray,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          color: _darkDeepTeal,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

class _CheckUpCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final bool isSelectionMode;
  final bool isSelected;
  final int index;
  final Function(int, bool) onSelectionChanged;
  final Function(Map<String, dynamic>) onEdit;

  const _CheckUpCard({
    required this.record,
    required this.isSelectionMode,
    required this.isSelected,
    required this.index,
    required this.onSelectionChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Parse patient name into first name and surname
    final patientName = record['patient'] ?? 'Unknown';
    final nameParts = patientName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts[0] : 'N/A';
    final surname = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : 'N/A';
    final age = record['age'] ?? 'N/A';
    final address = record['address'] ?? 'N/A';
    final status = record['status'] ?? 'Pending';

    return GestureDetector(
      onTap: isSelectionMode
          ? () => onSelectionChanged(index, !isSelected)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primaryAqua : _primaryAqua.withOpacity(0.2),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _primaryAqua.withOpacity(0.2)
                  : _mutedCoolGray.withOpacity(0.08),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Name Header with Checkbox
              Row(
                children: [
                  if (isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) =>
                          onSelectionChanged(index, value ?? false),
                      activeColor: _primaryAqua,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryAqua.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medical_services,
                      color: _primaryAqua,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      patientName,
                      style: TextStyle(
                        color: _darkDeepTeal,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (status == 'Completed')
                          ? Colors.green.withOpacity(0.15)
                          : Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: (status == 'Completed')
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Patient Details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      icon: Icons.person_outline,
                      label: 'First Name',
                      value: firstName,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoRow(
                      icon: Icons.person,
                      label: 'Surname',
                      value: surname,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      icon: Icons.cake,
                      label: 'Age',
                      value: age,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoRow(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: address,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons
              if (!isSelectionMode)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showCheckUpDetails(context, record);
                        },
                        icon: Icon(Icons.visibility, size: 18),
                        label: Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryAqua,
                          foregroundColor: _darkDeepTeal,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onEdit(record),
                        icon: Icon(Icons.edit, size: 18),
                        label: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _secondaryIceBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewCheckUpFullScreenModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final HealthAIClassifier aiClassifier;

  const _NewCheckUpFullScreenModal({
    required this.onSave,
    required this.aiClassifier,
  });

  @override
  State<_NewCheckUpFullScreenModal> createState() =>
      _NewCheckUpFullScreenModalState();
}

class _NewCheckUpFullScreenModalState
    extends State<_NewCheckUpFullScreenModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Separate vital sign controllers
  final TextEditingController _bloodPressureController =
      TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _respiratoryRateController =
      TextEditingController();
  final TextEditingController _oxygenSaturationController =
      TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _planController = TextEditingController();
  DateTime? _followUpDate;
  final String _recordType = 'General';
  String _status = 'Pending';
  String _diseaseType = 'General'; // Communicable, Non-Communicable, or General
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      minChildSize: 0.7,
      maxChildSize: 0.98,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: _lightOffWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Check Up Record',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: _darkDeepTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add a new patient check-up record to the system',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: _mutedCoolGray),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _primaryAqua.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: _darkDeepTeal,
                          size: 24,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form sections
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Patient Information Section
                      _buildSectionCard(
                        context: context,
                        title: 'Patient Information',
                        icon: Icons.person,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: _buildInputDecoration(
                                      'First Name',
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _surnameController,
                                    decoration: _buildInputDecoration(
                                      'Surname',
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _ageController,
                                    decoration: _buildInputDecoration('Age'),
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _addressController,
                                    decoration: _buildInputDecoration(
                                      'Address',
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Vital Signs Section (Separated)
                      _buildSectionCard(
                        context: context,
                        title: 'Vital Signs',
                        icon: Icons.monitor_heart,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _bloodPressureController,
                                    decoration: _buildInputDecoration(
                                      'Blood Pressure (e.g., 120/80)',
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _temperatureController,
                                    decoration: _buildInputDecoration(
                                      'Temperature (°C)',
                                    ),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _heartRateController,
                                    decoration: _buildInputDecoration(
                                      'Heart Rate (bpm)',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _respiratoryRateController,
                                    decoration: _buildInputDecoration(
                                      'Respiratory Rate (brpm)',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _oxygenSaturationController,
                                    decoration: _buildInputDecoration(
                                      'Oxygen Saturation (%)',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _weightController,
                                    decoration: _buildInputDecoration(
                                      'Weight (kg)',
                                    ),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _heightController,
                              decoration: _buildInputDecoration('Height (cm)'),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Clinical Details Section
                      _buildSectionCard(
                        context: context,
                        title: 'Clinical Details',
                        icon: Icons.medical_services,
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _diseaseType,
                              decoration: _buildInputDecoration(
                                'Disease Classification',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'General',
                                  child: Text('General Check-up'),
                                ),
                                DropdownMenuItem(
                                  value: 'Communicable',
                                  child: Text('Communicable Disease'),
                                ),
                                DropdownMenuItem(
                                  value: 'Non-Communicable',
                                  child: Text('Non-Communicable Disease'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _diseaseType = val);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _symptomsController,
                              decoration: _buildInputDecoration(
                                'Symptoms / Complaints',
                              ),
                              maxLines: 3,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _planController,
                              decoration: _buildInputDecoration(
                                'Treatment Plan',
                              ),
                              maxLines: 3,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Follow-up and Status Section
                      _buildSectionCard(
                        context: context,
                        title: 'Follow-up & Status',
                        icon: Icons.schedule,
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _followUpDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _followUpDate = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: _buildInputDecoration(
                                  'Follow-up Date',
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: _primaryAqua,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _followUpDate != null
                                            ? "${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}"
                                            : 'Tap to select date',
                                        style: TextStyle(
                                          color: _followUpDate != null
                                              ? _darkDeepTeal
                                              : _mutedCoolGray,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: _buildInputDecoration(
                                'Record Status',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Pending',
                                  child: Text('Pending'),
                                ),
                                DropdownMenuItem(
                                  value: 'Completed',
                                  child: Text('Completed'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _status = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: _mutedCoolGray,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryAqua,
                              foregroundColor: _darkDeepTeal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              elevation: 4,
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.check_circle),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save Record',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    print(
                                      '🔘 [CHECKUP MODAL] Save button pressed',
                                    );

                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      print(
                                        '✅ [CHECKUP MODAL] Form validation passed',
                                      );
                                      setState(() => _isSaving = true);
                                      print(
                                        '🔄 [CHECKUP MODAL] Loading state set to true',
                                      );

                                      try {
                                        print(
                                          '📋 [CHECKUP MODAL] Building vital signs string...',
                                        );
                                        // Combine all vital signs into one string
                                        List<String> vitalSignsParts = [];

                                        if (_bloodPressureController
                                            .text
                                            .isNotEmpty) {
                                          vitalSignsParts.add(
                                            'BP: ${_bloodPressureController.text}',
                                          );
                                        }
                                        if (_temperatureController
                                            .text
                                            .isNotEmpty) {
                                          vitalSignsParts.add(
                                            'Temp: ${_temperatureController.text}°C',
                                          );
                                        }
                                        if (_heartRateController
                                            .text
                                            .isNotEmpty) {
                                          vitalSignsParts.add(
                                            'HR: ${_heartRateController.text} bpm',
                                          );
                                        }
                                        if (_respiratoryRateController
                                            .text
                                            .isNotEmpty) {
                                          vitalSignsParts.add(
                                            'RR: ${_respiratoryRateController.text} brpm',
                                          );
                                        }
                                        if (_oxygenSaturationController
                                            .text
                                            .isNotEmpty) {
                                          vitalSignsParts.add(
                                            'O2: ${_oxygenSaturationController.text}%',
                                          );
                                        }
                                        if (_weightController.text.isNotEmpty) {
                                          vitalSignsParts.add(
                                            'Weight: ${_weightController.text} kg',
                                          );
                                        }
                                        if (_heightController.text.isNotEmpty) {
                                          vitalSignsParts.add(
                                            'Height: ${_heightController.text} cm',
                                          );
                                        }

                                        String vitalSignsString =
                                            vitalSignsParts.join(', ');

                                        print(
                                          '✅ [CHECKUP MODAL] Vital signs built: $vitalSignsString',
                                        );

                                        // Create new record
                                        print(
                                          '📝 [CHECKUP MODAL] Creating new record object...',
                                        );
                                        final now = DateTime.now();
                                        final newRecord = {
                                          'datetime':
                                              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                                          'type': 'General',
                                          'diseaseType': _diseaseType,
                                          'patient':
                                              '${_firstNameController.text} ${_surnameController.text}',
                                          'age': _ageController.text,
                                          'address': _addressController.text,
                                          'vitalsigns': vitalSignsString,
                                          'symptoms': _symptomsController.text,
                                          'details': vitalSignsString.isNotEmpty
                                              ? '$vitalSignsString | ${_symptomsController.text}'
                                              : 'Age: ${_ageController.text}, ${_symptomsController.text}',
                                          'plan': _planController.text,
                                          'status': _status,
                                          'followup': _followUpDate != null
                                              ? '${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}'
                                              : 'N/A',
                                        };

                                        print(
                                          '✅ [CHECKUP MODAL] Record created for: ${newRecord['patient']}',
                                        );

                                        // AI Classification
                                        ClassificationResult? classification;
                                        try {
                                          print(
                                            '🤖 [AI] Starting classification...',
                                          );
                                          classification = await widget
                                              .aiClassifier
                                              .classify(newRecord);

                                          print(
                                            '✅ [AI] Classification complete:',
                                          );
                                          print(
                                            '  Category: ${classification.category}',
                                          );
                                          print(
                                            '  Severity: ${classification.severity}',
                                          );
                                          print(
                                            '  Confidence: ${classification.confidence}',
                                          );

                                          newRecord['ai_category'] =
                                              classification.category;
                                          newRecord['ai_severity'] =
                                              classification.severity;
                                          newRecord['ai_confidence'] =
                                              classification.confidence
                                                  .toString();
                                          newRecord['ai_method'] =
                                              classification.method;
                                          if (classification.keywords != null) {
                                            newRecord['ai_keywords'] =
                                                classification.keywords!.join(
                                                  ', ',
                                                );
                                          }
                                          if (classification.recoveryPlan !=
                                              null) {
                                            newRecord['ai_recovery_plan'] =
                                                jsonEncode(
                                                  classification.recoveryPlan,
                                                );
                                            print(
                                              '💊 Recovery plan stored in record',
                                            );
                                          }
                                        } catch (e) {
                                          print(
                                            '❌ AI classification failed: $e',
                                          );
                                        }

                                        print(
                                          '🚀 [CHECKUP MODAL] Calling parent onSave callback...',
                                        );

                                        // Call the callback to save the record
                                        await widget.onSave(newRecord);

                                        print(
                                          '✅ [CHECKUP MODAL] onSave callback completed successfully',
                                        );

                                        // Show AI Classification modal
                                        if (context.mounted &&
                                            classification != null) {
                                          setState(() => _isSaving = false);
                                          await _showAIClassificationModal(
                                            context,
                                            classification!,
                                          );
                                        }

                                        if (context.mounted) {
                                          print(
                                            '🚪 [CHECKUP MODAL] Closing modal with disease type...',
                                          );
                                          Navigator.of(
                                            context,
                                          ).pop(_diseaseType);
                                          print(
                                            '✅ [CHECKUP MODAL] Modal closed',
                                          );
                                        }
                                      } catch (e, stackTrace) {
                                        print(
                                          '❌ [CHECKUP MODAL] Error caught: $e',
                                        );
                                        print(
                                          '📍 [CHECKUP MODAL] Stack trace: $stackTrace',
                                        );
                                        setState(() => _isSaving = false);

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error saving record: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      print(
                                        '❌ [CHECKUP MODAL] Form validation failed',
                                      );
                                    }
                                  },
                          ),
                        ],
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

  // Show AI loading spinner then classification result modal
  Future<void> _showAIClassificationModal(
    BuildContext context,
    ClassificationResult classification,
  ) async {
    // Show loading spinner dialog for 3 seconds
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A1F24), Color(0xFF1E5A7A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryAqua.withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryAqua),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Analyzing Health Data...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI is classifying your record',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Wait 3 seconds then dismiss the loading dialog
      await Future.delayed(const Duration(seconds: 3));
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }

    final recoveryPlan = classification.recoveryPlan;

    // Show the actual AI classification result modal
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxHeight: 650),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1F24), Color(0xFF1E5A7A)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryAqua.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryAqua.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: _primaryAqua,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Classification Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Health record analyzed successfully',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 28,
                    ),
                  ],
                ),
              ),

              // Body - scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Severity Row
                      Row(
                        children: [
                          Expanded(
                            child: _aiInfoCard(
                              icon: Icons.category_rounded,
                              label: 'Category',
                              value: classification.category,
                              color: _getCategoryColor(classification.category),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _aiInfoCard(
                              icon: Icons.warning_amber_rounded,
                              label: 'Severity',
                              value: classification.severity,
                              color: _getSeverityColor(classification.severity),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Confidence & Keywords Row
                      Row(
                        children: [
                          Expanded(
                            child: _aiInfoCard(
                              icon: Icons.speed_rounded,
                              label: 'Confidence',
                              value:
                                  '${(classification.confidence * 100).toStringAsFixed(1)}%',
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _aiInfoCard(
                              icon: Icons.label_rounded,
                              label: 'Keywords',
                              value:
                                  classification.keywords?.join(', ') ?? 'None',
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),

                      // Recovery Plan
                      if (recoveryPlan != null) ...[
                        const SizedBox(height: 18),
                        const Text(
                          'Recovery Plan',
                          style: TextStyle(
                            color: _primaryAqua,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Medications
                        if (recoveryPlan['medications'] != null)
                          _recoverySection(
                            icon: Icons.medication_rounded,
                            title: 'Medications',
                            items: List<String>.from(
                              recoveryPlan['medications'],
                            ),
                            color: Colors.redAccent,
                          ),

                        // Home Care
                        if (recoveryPlan['home_care'] != null)
                          _recoverySection(
                            icon: Icons.home_rounded,
                            title: 'Home Care',
                            items: List<String>.from(recoveryPlan['home_care']),
                            color: Colors.tealAccent,
                          ),

                        // Precautions
                        if (recoveryPlan['precautions'] != null)
                          _recoverySection(
                            icon: Icons.shield_rounded,
                            title: 'Precautions',
                            items: List<String>.from(
                              recoveryPlan['precautions'],
                            ),
                            color: Colors.amberAccent,
                          ),

                        // Estimated Recovery
                        if (recoveryPlan['estimated_recovery'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _primaryAqua.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: _primaryAqua,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Estimated Recovery: ',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    recoveryPlan['estimated_recovery']
                                        .toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // General Advice
                        if (recoveryPlan['general_advice'] != null)
                          _recoverySection(
                            icon: Icons.tips_and_updates_rounded,
                            title: 'General Advice',
                            items: List<String>.from(
                              recoveryPlan['general_advice'],
                            ),
                            color: Colors.lightGreenAccent,
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryAqua,
                      foregroundColor: _darkDeepTeal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aiInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _recoverySection({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.circle,
                        color: color.withOpacity(0.6),
                        size: 6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Communicable Disease':
        return Colors.orangeAccent;
      case 'Non-Communicable Disease':
        return Colors.purpleAccent;
      case 'Emergency':
        return Colors.redAccent;
      case 'Prenatal Care':
        return Colors.pinkAccent;
      case 'Pediatric Care':
        return Colors.cyanAccent;
      case 'Routine Checkup':
        return Colors.greenAccent;
      default:
        return _primaryAqua;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.deepOrange;
      case 'Medium':
        return Colors.amber;
      case 'Low':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  // Helper method to build section cards
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryAqua.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryAqua.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _primaryAqua, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _darkDeepTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // Helper method for input decoration
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _mutedCoolGray),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryAqua, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _primaryAqua.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryAqua, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: _lightOffWhite,
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _addressController.dispose();

    // Dispose all vital sign controllers
    _bloodPressureController.dispose();
    _temperatureController.dispose();
    _heartRateController.dispose();
    _respiratoryRateController.dispose();
    _oxygenSaturationController.dispose();
    _weightController.dispose();
    _heightController.dispose();

    _symptomsController.dispose();
    _planController.dispose();
    super.dispose();
  }
}

// Edit Check Up Modal
class _EditCheckUpFullScreenModal extends StatefulWidget {
  final Map<String, dynamic> record;
  final Function(Map<String, dynamic>) onSave;
  final HealthAIClassifier aiClassifier;

  const _EditCheckUpFullScreenModal({
    required this.record,
    required this.onSave,
    required this.aiClassifier,
  });

  @override
  State<_EditCheckUpFullScreenModal> createState() =>
      _EditCheckUpFullScreenModalState();
}

class _EditCheckUpFullScreenModalState
    extends State<_EditCheckUpFullScreenModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _ageController;
  late final TextEditingController _addressController;

  // Separate vital sign controllers
  late final TextEditingController _bloodPressureController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _heartRateController;
  late final TextEditingController _respiratoryRateController;
  late final TextEditingController _oxygenSaturationController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;

  late final TextEditingController _symptomsController;
  late final TextEditingController _planController;
  DateTime? _followUpDate;
  final String _recordType = 'General';
  String _status = 'Pending';
  String _diseaseType = 'General';

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    final patientName = widget.record['patient'] ?? '';
    final nameParts = patientName.split(' ');
    _firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts[0] : '',
    );
    _surnameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    _ageController = TextEditingController(
      text: widget.record['age']?.toString() ?? '',
    );
    _addressController = TextEditingController(
      text: widget.record['address'] ?? '',
    );

    // Parse vital signs from the record
    final vitalSigns = widget.record['vitalsigns'] ?? '';
    final vitalParts = vitalSigns.split(', ');
    _bloodPressureController = TextEditingController(
      text: _extractVital(vitalParts, 'BP:'),
    );
    _temperatureController = TextEditingController(
      text: _extractVital(vitalParts, 'Temp:'),
    );
    _heartRateController = TextEditingController(
      text: _extractVital(vitalParts, 'HR:'),
    );
    _respiratoryRateController = TextEditingController(
      text: _extractVital(vitalParts, 'RR:'),
    );
    _oxygenSaturationController = TextEditingController(
      text: _extractVital(vitalParts, 'O2:'),
    );
    _weightController = TextEditingController(
      text: _extractVital(vitalParts, 'Weight:'),
    );
    _heightController = TextEditingController(
      text: _extractVital(vitalParts, 'Height:'),
    );

    _symptomsController = TextEditingController(
      text: widget.record['symptoms'] ?? '',
    );
    _planController = TextEditingController(text: widget.record['plan'] ?? '');

    // Initialize _diseaseType from record
    final availableDiseaseTypes = ['General', 'Communicable', 'Non-Communicable'];
    final diseaseType = widget.record['diseaseType'] ?? 'General';
    _diseaseType = availableDiseaseTypes.contains(diseaseType) ? diseaseType : 'General';

    // Validate _status against available options
    final availableStatuses = [
      'Pending',
      'Completed',
    ];
    final recordStatus = widget.record['status'] ?? 'Pending';
    _status = availableStatuses.contains(recordStatus)
        ? recordStatus
        : 'Pending';

    if (widget.record['followup'] != null &&
        widget.record['followup'] != 'N/A') {
      try {
        _followUpDate = DateTime.parse(widget.record['followup']);
      } catch (e) {
        _followUpDate = null;
      }
    }
  }

  String _extractVital(List<String> parts, String prefix) {
    for (var part in parts) {
      if (part.trim().startsWith(prefix)) {
        String value = part.trim().substring(prefix.length).trim();
        // Remove unit suffixes to prevent duplication on re-save
        value = value
            .replaceAll(RegExp(r'°C$'), '')
            .replaceAll(RegExp(r'\s*brpm$', caseSensitive: false), '')
            .replaceAll(RegExp(r'\s*bpm$', caseSensitive: false), '')
            .replaceAll(RegExp(r'%$'), '')
            .replaceAll(RegExp(r'\s*kg$', caseSensitive: false), '')
            .replaceAll(RegExp(r'\s*cm$', caseSensitive: false), '')
            .trim();
        return value;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      minChildSize: 0.7,
      maxChildSize: 0.98,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: _lightOffWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Check Up Record',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: _darkDeepTeal,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Update patient check-up information',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: _mutedCoolGray),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: _darkDeepTeal),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Same form fields as _NewCheckUpFullScreenModal
                  Text(
                    'Patient Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkDeepTeal,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: _buildInputDecoration('First Name'),
                          validator: (value) =>
                              value?.isEmpty == true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _surnameController,
                          decoration: _buildInputDecoration('Surname'),
                          validator: (value) =>
                              value?.isEmpty == true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          decoration: _buildInputDecoration('Age'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          decoration: _buildInputDecoration('Address'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Vital Signs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkDeepTeal,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bloodPressureController,
                          decoration: _buildInputDecoration('Blood Pressure'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _temperatureController,
                          decoration: _buildInputDecoration('Temperature (°C)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heartRateController,
                          decoration: _buildInputDecoration('Heart Rate (bpm)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _respiratoryRateController,
                          decoration: _buildInputDecoration('Respiratory Rate'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _oxygenSaturationController,
                          decoration: _buildInputDecoration(
                            'Oxygen Saturation (%)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          decoration: _buildInputDecoration('Weight (kg)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _heightController,
                    decoration: _buildInputDecoration('Height (cm)'),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Check-Up Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkDeepTeal,
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _diseaseType,
                    decoration: _buildInputDecoration('Disease Classification'),
                    items: const [
                      DropdownMenuItem(
                        value: 'General',
                        child: Text('General Check-up'),
                      ),
                      DropdownMenuItem(
                        value: 'Communicable',
                        child: Text('Communicable Disease'),
                      ),
                      DropdownMenuItem(
                        value: 'Non-Communicable',
                        child: Text('Non-Communicable Disease'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _diseaseType = value);
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: _buildInputDecoration('Record Status'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _symptomsController,
                    decoration: _buildInputDecoration('Symptoms'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _planController,
                    decoration: _buildInputDecoration('Treatment Plan'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _followUpDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _followUpDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: _buildInputDecoration('Follow-up Date'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _followUpDate != null
                                ? "${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}"
                                : 'Select Date',
                            style: TextStyle(
                              color: _followUpDate != null
                                  ? _darkDeepTeal
                                  : _mutedCoolGray,
                            ),
                          ),
                          const Icon(Icons.calendar_today, color: _primaryAqua),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final patientName =
                              '${_firstNameController.text} ${_surnameController.text}';

                          // Build vital signs string
                          List<String> vitalsList = [];
                          if (_bloodPressureController.text.isNotEmpty) {
                            vitalsList.add(
                              'BP: ${_bloodPressureController.text}',
                            );
                          }
                          if (_temperatureController.text.isNotEmpty) {
                            vitalsList.add(
                              'Temp: ${_temperatureController.text}°C',
                            );
                          }
                          if (_heartRateController.text.isNotEmpty) {
                            vitalsList.add(
                              'HR: ${_heartRateController.text} bpm',
                            );
                          }
                          if (_respiratoryRateController.text.isNotEmpty) {
                            vitalsList.add(
                              'RR: ${_respiratoryRateController.text} brpm',
                            );
                          }
                          if (_oxygenSaturationController.text.isNotEmpty) {
                            vitalsList.add(
                              'O2: ${_oxygenSaturationController.text}%',
                            );
                          }
                          if (_weightController.text.isNotEmpty) {
                            vitalsList.add(
                              'Weight: ${_weightController.text} kg',
                            );
                          }
                          if (_heightController.text.isNotEmpty) {
                            vitalsList.add(
                              'Height: ${_heightController.text} cm',
                            );
                          }

                          final vitalSigns = vitalsList.join(', ');

                          final updatedRecord = {
                            'id': widget.record['id'], // Keep the original ID
                            'patient': patientName,
                            'age': _ageController.text,
                            'address': _addressController.text,
                            'type': 'General',
                            'diseaseType': _diseaseType,
                            'datetime': widget
                                .record['datetime'], // Keep original datetime
                            'vitalsigns': vitalSigns,
                            'symptoms': _symptomsController.text,
                            'plan': _planController.text,
                            'status': _status,
                            'followup': _followUpDate != null
                                ? '${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}'
                                : 'N/A',
                          };

                          // AI Classification on edited record
                          ClassificationResult? classification;
                          try {
                            print('🤖 [AI] Starting classification on edited record...');
                            classification = await widget.aiClassifier.classify(updatedRecord);
                            print('✅ [AI] Classification complete: ${classification.category}');

                            updatedRecord['ai_category'] = classification.category;
                            updatedRecord['ai_severity'] = classification.severity;
                            updatedRecord['ai_confidence'] = classification.confidence.toString();
                            updatedRecord['ai_method'] = classification.method;
                            if (classification.keywords != null) {
                              updatedRecord['ai_keywords'] = classification.keywords!.join(', ');
                            }
                            if (classification.recoveryPlan != null) {
                              updatedRecord['ai_recovery_plan'] = jsonEncode(classification.recoveryPlan);
                            }
                          } catch (e) {
                            print('❌ AI classification failed on edit: $e');
                          }

                          await widget.onSave(updatedRecord);

                          // Show AI Classification modal with loading spinner
                          if (context.mounted && classification != null) {
                            await _showEditAIClassificationModal(context, classification!);
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryAqua,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Update Record',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _mutedCoolGray),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryAqua, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _primaryAqua.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryAqua, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: _lightOffWhite,
    );
  }

  // Show AI Classification result modal with loading spinner for edited records
  Future<void> _showEditAIClassificationModal(
    BuildContext context,
    ClassificationResult classification,
  ) async {
    // Show loading spinner dialog for 3 seconds
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A1F24), Color(0xFF1E5A7A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryAqua.withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryAqua),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Re-analyzing Health Data...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI is re-classifying your updated record',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }

    final recoveryPlan = classification.recoveryPlan;

    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxHeight: 650),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1F24), Color(0xFF1E5A7A)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryAqua.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryAqua.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: _primaryAqua,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Re-Classification Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Updated record analyzed successfully',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                  ],
                ),
              ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _editAiInfoCard(
                              icon: Icons.category_rounded,
                              label: 'Category',
                              value: classification.category,
                              color: _editGetCategoryColor(classification.category),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _editAiInfoCard(
                              icon: Icons.warning_amber_rounded,
                              label: 'Severity',
                              value: classification.severity,
                              color: _editGetSeverityColor(classification.severity),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _editAiInfoCard(
                              icon: Icons.speed_rounded,
                              label: 'Confidence',
                              value: '${(classification.confidence * 100).toStringAsFixed(1)}%',
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _editAiInfoCard(
                              icon: Icons.label_rounded,
                              label: 'Keywords',
                              value: classification.keywords?.join(', ') ?? 'None',
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),

                      if (recoveryPlan != null) ...[
                        const SizedBox(height: 18),
                        const Text(
                          'Recovery Plan',
                          style: TextStyle(
                            color: _primaryAqua,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (recoveryPlan['medications'] != null)
                          _editRecoverySection(
                            icon: Icons.medication_rounded,
                            title: 'Medications',
                            items: List<String>.from(recoveryPlan['medications']),
                            color: Colors.redAccent,
                          ),
                        if (recoveryPlan['home_care'] != null)
                          _editRecoverySection(
                            icon: Icons.home_rounded,
                            title: 'Home Care',
                            items: List<String>.from(recoveryPlan['home_care']),
                            color: Colors.tealAccent,
                          ),
                        if (recoveryPlan['precautions'] != null)
                          _editRecoverySection(
                            icon: Icons.shield_rounded,
                            title: 'Precautions',
                            items: List<String>.from(recoveryPlan['precautions']),
                            color: Colors.amberAccent,
                          ),
                        if (recoveryPlan['estimated_recovery'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _primaryAqua.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule, color: _primaryAqua, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Estimated Recovery: ',
                                    style: TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  Text(
                                    recoveryPlan['estimated_recovery'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (recoveryPlan['general_advice'] != null)
                          _editRecoverySection(
                            icon: Icons.tips_and_updates_rounded,
                            title: 'General Advice',
                            items: List<String>.from(recoveryPlan['general_advice']),
                            color: Colors.lightGreenAccent,
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryAqua,
                      foregroundColor: _darkDeepTeal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editAiInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _editRecoverySection({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(Icons.circle, color: color.withOpacity(0.6), size: 6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _editGetCategoryColor(String category) {
    switch (category) {
      case 'Communicable Disease': return Colors.orangeAccent;
      case 'Non-Communicable Disease': return Colors.purpleAccent;
      case 'Emergency': return Colors.redAccent;
      case 'Prenatal Care': return Colors.pinkAccent;
      case 'Pediatric Care': return Colors.cyanAccent;
      case 'Routine Checkup': return Colors.greenAccent;
      default: return _primaryAqua;
    }
  }

  Color _editGetSeverityColor(String severity) {
    switch (severity) {
      case 'Critical': return Colors.red;
      case 'High': return Colors.deepOrange;
      case 'Medium': return Colors.amber;
      case 'Low': return Colors.greenAccent;
      default: return Colors.white70;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _bloodPressureController.dispose();
    _temperatureController.dispose();
    _heartRateController.dispose();
    _respiratoryRateController.dispose();
    _oxygenSaturationController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _symptomsController.dispose();
    _planController.dispose();
    super.dispose();
  }
}

// AI Classification Display Methods
Widget _buildAIClassificationSection(Map<String, dynamic> record) {
  final category = record['ai_category']?.toString() ?? 'Unknown';
  final severity = record['ai_severity']?.toString() ?? 'Unknown';
  // Handle both double and string types for confidence
  final confidenceValue = record['ai_confidence'];
  final confidence = confidenceValue is double
      ? confidenceValue
      : (confidenceValue is String
            ? (double.tryParse(confidenceValue) ?? 0.0)
            : 0.0);
  final method = record['ai_method']?.toString() ?? 'unknown';
  final keywords = record['ai_keywords']?.toString();

  // Parse recovery plan if available
  Map<String, dynamic>? recoveryPlan;
  try {
    final recoveryData = record['ai_recovery_plan'];
    if (recoveryData is Map) {
      recoveryPlan = Map<String, dynamic>.from(recoveryData);
    } else if (recoveryData is String) {
      recoveryPlan = Map<String, dynamic>.from(jsonDecode(recoveryData));
    }
  } catch (e) {
    print('Error parsing recovery plan: $e');
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.psychology, color: _primaryAqua, size: 20),
          const SizedBox(width: 8),
          Text(
            'AI Classification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _darkDeepTeal,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: method == 'ml_model'
                  ? Colors.purple.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: method == 'ml_model' ? Colors.purple : Colors.blue,
                width: 1,
              ),
            ),
            child: Text(
              method == 'ml_model' ? 'ML Model' : 'Rule-Based',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: method == 'ml_model' ? Colors.purple : Colors.blue,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryAqua.withOpacity(0.05), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primaryAqua.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            // Category Badge
            Row(
              children: [
                Expanded(
                  child: _buildAIBadge(
                    label: 'Category',
                    value: category,
                    icon: Icons.category,
                    color: _getCategoryColor(category),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAIBadge(
                    label: 'Severity',
                    value: severity,
                    icon: Icons.warning_amber,
                    color: _getSeverityColor(severity),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Confidence Indicator
            Row(
              children: [
                Icon(Icons.speed, size: 16, color: _mutedCoolGray),
                const SizedBox(width: 8),
                Text(
                  'Confidence:',
                  style: TextStyle(
                    color: _mutedCoolGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: confidence,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      confidence > 0.7
                          ? Colors.green
                          : confidence > 0.4
                          ? Colors.orange
                          : Colors.red,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _darkDeepTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Keywords if available
            if (keywords != null && keywords.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: keywords.split(', ').take(5).map((keyword) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryAqua.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _primaryAqua.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      keyword,
                      style: TextStyle(
                        fontSize: 10,
                        color: _darkDeepTeal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      // Recovery Recommendations Section
      if (recoveryPlan != null) ...[
        const SizedBox(height: 16),
        _buildRecoveryRecommendations(recoveryPlan),
      ],
    ],
  );
}

Widget _buildRecoveryRecommendations(Map<String, dynamic> recoveryPlan) {
  final medications =
      (recoveryPlan['medications'] as List?)?.cast<String>() ?? [];
  final homeCare = (recoveryPlan['home_care'] as List?)?.cast<String>() ?? [];
  final precautions =
      (recoveryPlan['precautions'] as List?)?.cast<String>() ?? [];
  final estimatedRecovery = recoveryPlan['estimated_recovery']?.toString();
  final generalAdvice =
      (recoveryPlan['general_advice'] as List?)?.cast<String>() ?? [];

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.green.shade50, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.green.shade300),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.healing, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'Recovery Recommendations',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Estimated Recovery Time
        if (estimatedRecovery != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimated Recovery: $estimatedRecovery',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Medications
        if (medications.isNotEmpty) ...[
          _buildRecommendationSection(
            '💊 Suggested Medications',
            medications,
            Colors.purple.shade700,
            Colors.purple.shade50,
          ),
          const SizedBox(height: 10),
        ],

        // Home Care
        if (homeCare.isNotEmpty) ...[
          _buildRecommendationSection(
            '🏠 Home Care Instructions',
            homeCare,
            Colors.orange.shade700,
            Colors.orange.shade50,
          ),
          const SizedBox(height: 10),
        ],

        // Precautions
        if (precautions.isNotEmpty) ...[
          _buildRecommendationSection(
            '⚠️ Important Precautions',
            precautions,
            Colors.red.shade700,
            Colors.red.shade50,
          ),
          const SizedBox(height: 10),
        ],

        // General Advice
        if (generalAdvice.isNotEmpty) ...[
          _buildRecommendationSection(
            '💡 General Advice',
            generalAdvice,
            Colors.teal.shade700,
            Colors.teal.shade50,
          ),
        ],

        // Disclaimer
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.amber.shade300, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade800, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'These are AI-generated suggestions. Always consult a healthcare professional.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.shade900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildRecommendationSection(
  String title,
  List<String> items,
  Color textColor,
  Color bgColor,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      const SizedBox(height: 6),
      ...items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 11,
                        color: _darkDeepTeal,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ],
  );
}

Widget _buildAIBadge({
  required String label,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3), width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: _mutedCoolGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Color _getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'emergency':
      return Colors.red;
    case 'communicable disease':
      return Colors.orange;
    case 'non-communicable disease':
      return Colors.blue;
    case 'prenatal care':
      return Colors.pink;
    case 'pediatric care':
      return Colors.purple;
    default:
      return Colors.green;
  }
}

Color _getSeverityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'critical':
      return Colors.red.shade700;
    case 'high':
      return Colors.orange.shade700;
    case 'medium':
      return Colors.yellow.shade700;
    default:
      return Colors.green.shade600;
  }
}
