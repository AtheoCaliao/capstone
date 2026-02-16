import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycapstone_project/web/prenatal_database_helper.dart';
import 'package:mycapstone_project/app/health_ai_classifier.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mycapstone_project/web/login.dart';
import 'package:mycapstone_project/web/homepage.dart';
import 'package:mycapstone_project/web/checkup.dart';
import 'package:mycapstone_project/web/health_metrics.dart';
import 'package:mycapstone_project/web/Analytics.dart';
import 'package:mycapstone_project/web/Immunization.dart';
import 'package:mycapstone_project/web/patient.dart';
import 'package:mycapstone_project/web/communicable.dart';
import 'package:mycapstone_project/web/non-communicable.dart';
import 'package:mycapstone_project/web/Mortality.dart';

const Color _primaryAqua = Color(0xFF00A8B5);
const Color _secondaryIceBlue = Color(0xFF1E5A7A);
const Color _darkDeepTeal = Color(0xFF0A1F24);
const Color _mutedCoolGray = Color(0xFF546E7A);
const Color _lightOffWhite = Color(0xFFF5F5F5);
const Color _sidebarDark = Color(0xFF0E2F34);

class PrenatalPage extends StatefulWidget {
  const PrenatalPage({super.key});

  @override
  State<PrenatalPage> createState() => _PrenatalPageState();
}

class _PrenatalPageState extends State<PrenatalPage> {
  String _selectedStatusFilter = 'All Cases';
  final List<String> _statusFilterOptions = [
    'All Cases',
    'Active',
    'High Risk',
    'Follow Up',
    'Completed',
  ];

  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};
  bool _isDeleteDialogShowing = false;
  bool _isLoading = true;

  // Database-backed prenatal records
  List<Map<String, dynamic>> _prenatalRecords = [];
  final PrenatalDatabaseHelper _dbHelper = PrenatalDatabaseHelper.instance;

  // AI Classifier
  final HealthAIClassifier _aiClassifier = HealthAIClassifier.instance;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _dbHelper.startConnectivityListener();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    await _aiClassifier.initialize();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    // Load from local database
    final records = await _dbHelper.getAllRecords();

    // Try to sync from Firebase
    await _dbHelper.syncFromFirebase();

    // Reload after sync
    final updatedRecords = await _dbHelper.getAllRecords();

    setState(() {
      _prenatalRecords = updatedRecords;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      backgroundColor: _lightOffWhite,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context, userName),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(context),

                // Content Area
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _primaryAqua),
                        )
                      : Stack(
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Dashboard Header with Icon Badge
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _primaryAqua,
                                              _secondaryIceBlue,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primaryAqua.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.pregnant_woman_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Maternal Health Overview',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  color: _darkDeepTeal,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            'Comprehensive prenatal care monitoring',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _mutedCoolGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Dashboard Cards - 3 Columns
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDashboardCard(
                                          title: 'Active Cases',
                                          value: '${_prenatalRecords.length}',
                                          icon: Icons.pregnant_woman,
                                          color: _primaryAqua,
                                          trend: '+${_prenatalRecords.length}',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildDashboardCard(
                                          title: 'High Risk',
                                          value:
                                              '${_prenatalRecords.where((r) => r['status'] == 'High Risk').length}',
                                          icon: Icons.warning_rounded,
                                          color: Colors.orange,
                                          trend: 'Monitor',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildDashboardCard(
                                          title: 'Completed',
                                          value:
                                              '${_prenatalRecords.where((r) => r['status'] == 'Completed').length}',
                                          icon: Icons.check_circle_rounded,
                                          color: Colors.green,
                                          trend: 'Success',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),

                                  // Patients Section Header
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.pregnant_woman,
                                            color: _primaryAqua,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Prenatal Patients',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: _darkDeepTeal,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _primaryAqua.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '${_getFilteredRecords().length} Patients',
                                          style: TextStyle(
                                            color: _primaryAqua,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Date Filter
                                  _buildDateFilter(),
                                  const SizedBox(height: 16),

                                  // Action Menu Button
                                  _buildActionMenuButton(),
                                  const SizedBox(height: 16),

                                  // Patient Cards
                                  ..._getFilteredRecords().asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final record = entry.value;
                                    return _buildPatientCard(
                                      context: context,
                                      index: index,
                                      record: record,
                                    );
                                  }),
                                  const SizedBox(
                                    height: 80,
                                  ), // Space for floating action card
                                ],
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
              onPressed: () => _showNewPrenatalModal(context),
              backgroundColor: _primaryAqua,
              elevation: 4,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Prenatal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
    );
  }

  // Sidebar Navigation Widget
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
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
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
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 10,
              ),
              children: [
                _buildSidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  onTap: () => Get.to(() => const HomePage()),
                ),
                _buildSidebarItem(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Check-ups',
                  onTap: () => Get.to(() => const CheckUpPage()),
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
                  isActive: true,
                  onTap: () {},
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
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
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
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
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
            Icons.pregnant_woman_rounded,
            color: _primaryAqua,
            size: 32,
          ),
          const SizedBox(width: 16),
          Text(
            'Prenatal Care Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _darkDeepTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: _loadRecords,
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

  List<Map<String, dynamic>> _getFilteredRecords() {
    return _prenatalRecords.where((record) {
      // Status filter
      bool statusMatch = true;
      if (_selectedStatusFilter != 'All Cases') {
        statusMatch = record['status'] == _selectedStatusFilter;
      }

      // Date range filter
      bool dateMatch = true;
      if (_fromDate != null || _toDate != null) {
        final dueDate = DateTime.parse(record['dueDate']);
        if (_fromDate != null && dueDate.isBefore(_fromDate!)) {
          dateMatch = false;
        }
        if (_toDate != null && dueDate.isAfter(_toDate!)) {
          dateMatch = false;
        }
      }

      return statusMatch && dateMatch;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _clearDateFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  // Show AI Classification modal with loading spinner for prenatal records
  Future<void> _showPrenatalAIModal(
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
                    'Analyzing Prenatal Data...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI is classifying your prenatal record',
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
                            'AI Prenatal Analysis Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Prenatal record analyzed successfully',
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
                            child: _prenatalAiInfoCard(
                              icon: Icons.category_rounded,
                              label: 'Category',
                              value: classification.category,
                              color: _prenatalGetCategoryColor(classification.category),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _prenatalAiInfoCard(
                              icon: Icons.warning_amber_rounded,
                              label: 'Severity',
                              value: classification.severity,
                              color: _prenatalGetSeverityColor(classification.severity),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _prenatalAiInfoCard(
                              icon: Icons.speed_rounded,
                              label: 'Confidence',
                              value: '${(classification.confidence * 100).toStringAsFixed(1)}%',
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _prenatalAiInfoCard(
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
                          _prenatalRecoverySection(
                            icon: Icons.medication_rounded,
                            title: 'Medications',
                            items: List<String>.from(recoveryPlan['medications']),
                            color: Colors.redAccent,
                          ),
                        if (recoveryPlan['home_care'] != null)
                          _prenatalRecoverySection(
                            icon: Icons.home_rounded,
                            title: 'Home Care',
                            items: List<String>.from(recoveryPlan['home_care']),
                            color: Colors.tealAccent,
                          ),
                        if (recoveryPlan['precautions'] != null)
                          _prenatalRecoverySection(
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
                          _prenatalRecoverySection(
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

  Widget _prenatalAiInfoCard({
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

  Widget _prenatalRecoverySection({
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

  Color _prenatalGetCategoryColor(String category) {
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

  Color _prenatalGetSeverityColor(String severity) {
    switch (severity) {
      case 'Critical': return Colors.red;
      case 'High': return Colors.deepOrange;
      case 'Medium': return Colors.amber;
      case 'Low': return Colors.greenAccent;
      default: return Colors.white70;
    }
  }

  void _showNewPrenatalModal(BuildContext context) {
    // Text editing controllers
    final firstNameController = TextEditingController();
    final surnameController = TextEditingController();
    final ageController = TextEditingController();
    final addressController = TextEditingController();
    final patientIdController = TextEditingController();
    final contactNumberController = TextEditingController();
    final civilStatusController = TextEditingController();
    final philhealthNumberController = TextEditingController();
    final philhealthMemberController = TextEditingController();
    final religionController = TextEditingController();

    DateTime? lmpDate;
    DateTime? eddDate;
    DateTime? lastDeliveryDate;
    DateTime? registrationDate = DateTime.now();

    final gravidaController = TextEditingController();
    final paraController = TextEditingController();
    String selectedRiskLevel = 'Active';

    final bloodTypeController = TextEditingController();
    final allergiesController = TextEditingController();
    final preExistingConditionsController = TextEditingController();
    final previousComplicationsController = TextEditingController();

    // Medical measurements controllers
    final aogController = TextEditingController(); // Age of Gestation
    final wtController = TextEditingController(); // Weight
    final atController = TextEditingController(); // Abdominal Tenderness
    final tempController = TextEditingController(); // Temperature
    final bpController = TextEditingController(); // Blood Pressure
    final bmiController = TextEditingController(); // Body Mass Index
    final fhController = TextEditingController(); // Fundal Height
    final dhbController = TextEditingController(); // Fetal Heart Beat
    final tcbController = TextEditingController(); // Total Bilirubin

    final registeredByController = TextEditingController();
    final additionalNoteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: _lightOffWhite,
            ),
            child: Column(
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryAqua, _primaryAqua.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.pregnant_woman,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'New Prenatal Registration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient Information Area
                        _buildSectionHeader(
                          'Patient Information',
                          Icons.person,
                        ),
                        _buildFormCard([
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: firstNameController,
                                  label: 'First Name',
                                  icon: Icons.person_outline,
                                  hintText: 'Enter first name',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: surnameController,
                                  label: 'Surname',
                                  icon: Icons.person_outline,
                                  hintText: 'Enter surname',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: ageController,
                                  label: 'Age',
                                  icon: Icons.cake,
                                  hintText: 'Enter age',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: patientIdController,
                                  label: 'Patient ID',
                                  icon: Icons.badge,
                                  hintText: 'e.g., PAT-2026-001',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: addressController,
                            label: 'Address',
                            icon: Icons.home,
                            hintText: 'Enter complete address',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: contactNumberController,
                            label: 'Contact Number',
                            icon: Icons.phone,
                            hintText: 'e.g., +63 912 345 6789',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: civilStatusController,
                                  label: 'Civil Status',
                                  icon: Icons.favorite,
                                  hintText: 'e.g., Single, Married',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: religionController,
                                  label: 'Religion',
                                  icon: Icons.church,
                                  hintText: 'Enter religion',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: philhealthNumberController,
                                  label: 'Philhealth Number',
                                  icon: Icons.medical_information,
                                  hintText: 'Enter Philhealth #',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: philhealthMemberController,
                                  label: 'Philhealth Member',
                                  icon: Icons.card_membership,
                                  hintText: 'Member name',
                                ),
                              ),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Pregnancy Detail Area
                        _buildSectionHeader(
                          'Pregnancy Detail',
                          Icons.child_care,
                        ),
                        _buildFormCard([
                          _buildDatePickerField(
                            context: context,
                            label: 'Last Menstrual Period (LMP)',
                            date: lmpDate,
                            icon: Icons.calendar_today,
                            onTap: () async {
                              final picked = await _showDatePickerModal(
                                context,
                              );
                              if (picked != null) {
                                setModalState(() => lmpDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDatePickerField(
                            context: context,
                            label: 'Estimated Due Date (EDD)',
                            date: eddDate,
                            icon: Icons.event,
                            onTap: () async {
                              final picked = await _showDatePickerModal(
                                context,
                              );
                              if (picked != null) {
                                setModalState(() => eddDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDatePickerField(
                            context: context,
                            label: 'Last Date of Delivery',
                            date: lastDeliveryDate,
                            icon: Icons.child_friendly,
                            onTap: () async {
                              final picked = await _showDatePickerModal(
                                context,
                              );
                              if (picked != null) {
                                setModalState(() => lastDeliveryDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: gravidaController,
                                  label: 'Gravida (Number of Pregnancy)',
                                  icon: Icons.numbers,
                                  hintText: 'e.g., 1, 2, 3',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: paraController,
                                  label: 'Para (Number of Live Births)',
                                  icon: Icons.numbers,
                                  hintText: 'e.g., 0, 1, 2',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Risk Level',
                            value: selectedRiskLevel,
                            icon: Icons.warning_amber,
                            items: ['Active', 'Follow Up', 'High Risk'],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() => selectedRiskLevel = value);
                              }
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Medical History Area
                        _buildSectionHeader(
                          'Medical History',
                          Icons.medical_services,
                        ),
                        _buildFormCard([
                          _buildTextField(
                            controller: bloodTypeController,
                            label: 'Blood Type',
                            icon: Icons.bloodtype,
                            hintText: 'e.g., A+, B-, O+, AB+',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: allergiesController,
                            label: 'Allergies',
                            icon: Icons.health_and_safety,
                            hintText: 'List any known allergies',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: preExistingConditionsController,
                            label: 'Pre-existing Medical Conditions',
                            icon: Icons.local_hospital,
                            hintText: 'e.g., Diabetes, Hypertension, Asthma',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: previousComplicationsController,
                            label: 'Previous Pregnancy Complications',
                            icon: Icons.warning,
                            hintText:
                                'List any complications from previous pregnancies',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: aogController,
                                  label: 'AOG (Age of Gestation)',
                                  icon: Icons.calendar_view_week,
                                  hintText: 'e.g., 28 weeks',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: wtController,
                                  label: 'WT (Weight)',
                                  icon: Icons.monitor_weight,
                                  hintText: 'e.g., 65 kg',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: tempController,
                                  label: 'TEMP (Temperature)',
                                  icon: Icons.thermostat,
                                  hintText: 'e.g., 36.5°C',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: bpController,
                                  label: 'BP (Blood Pressure)',
                                  icon: Icons.favorite,
                                  hintText: 'e.g., 120/80',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: bmiController,
                                  label: 'BMI (Body Mass Index)',
                                  icon: Icons.assessment,
                                  hintText: 'e.g., 22.5',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: fhController,
                                  label: 'FH (Fundal Height)',
                                  icon: Icons.straighten,
                                  hintText: 'e.g., 28 cm',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: dhbController,
                                  label: 'DHB (Fetal Heart Beat)',
                                  icon: Icons.favorite_border,
                                  hintText: 'e.g., 140 bpm',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: atController,
                                  label: 'AT (Abdominal Tenderness)',
                                  icon: Icons.touch_app,
                                  hintText: 'e.g., None, Mild',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: tcbController,
                            label: 'TCB (Total Bilirubin)',
                            icon: Icons.science,
                            hintText: 'e.g., 0.8 mg/dL',
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Registration Details Area
                        _buildSectionHeader(
                          'Registration Details',
                          Icons.app_registration,
                        ),
                        _buildFormCard([
                          _buildDatePickerField(
                            context: context,
                            label: 'Registration Date',
                            date: registrationDate,
                            icon: Icons.calendar_month,
                            onTap: () async {
                              final picked = await _showDatePickerModal(
                                context,
                              );
                              if (picked != null) {
                                setModalState(() => registrationDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: registeredByController,
                            label: 'Registered By',
                            icon: Icons.person_pin,
                            hintText: 'Enter staff name or ID',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: additionalNoteController,
                            label: 'Additional Note',
                            icon: Icons.note,
                            hintText: 'Enter any additional notes or remarks',
                            maxLines: 4,
                          ),
                        ]),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Create new prenatal record
                              final newRecord = {
                                'patientName':
                                    '${firstNameController.text} ${surnameController.text}',
                                'age': ageController.text,
                                'address': addressController.text,
                                'patientId': patientIdController.text,
                                'contactNumber': contactNumberController.text,
                                'civilStatus': civilStatusController.text,
                                'religion': religionController.text,
                                'philhealthNumber':
                                    philhealthNumberController.text,
                                'philhealthMember':
                                    philhealthMemberController.text,
                                'lmpDate': lmpDate?.toIso8601String() ?? '',
                                'eddDate': eddDate?.toIso8601String() ?? '',
                                'lastDeliveryDate':
                                    lastDeliveryDate?.toIso8601String() ?? '',
                                'gravida': gravidaController.text,
                                'para': paraController.text,
                                'riskLevel': selectedRiskLevel,
                                'bloodType': bloodTypeController.text,
                                'allergies': allergiesController.text,
                                'preExistingConditions':
                                    preExistingConditionsController.text,
                                'previousComplications':
                                    previousComplicationsController.text,
                                'aog': aogController.text,
                                'wt': wtController.text,
                                'at': atController.text,
                                'temp': tempController.text,
                                'bp': bpController.text,
                                'bmi': bmiController.text,
                                'fh': fhController.text,
                                'dhb': dhbController.text,
                                'tcb': tcbController.text,
                                'registrationDate':
                                    registrationDate?.toIso8601String() ?? '',
                                'registeredBy': registeredByController.text,
                                'additionalNote': additionalNoteController.text,
                                'gestationalAge': aogController.text,
                                'dueDate': eddDate?.toIso8601String() ?? '',
                                'status': selectedRiskLevel,
                              };

                              // AI Classification
                              ClassificationResult? classification;
                              try {
                                print('🤖 [AI] Starting prenatal classification...');
                                classification = await _aiClassifier.classify(newRecord);
                                print('✅ [AI] Prenatal classification complete: ${classification.category}');

                                newRecord['ai_category'] = classification.category;
                                newRecord['ai_severity'] = classification.severity;
                                newRecord['ai_confidence'] = classification.confidence.toString();
                                newRecord['ai_method'] = classification.method;
                                if (classification.keywords != null) {
                                  newRecord['ai_keywords'] = classification.keywords!.join(', ');
                                }
                                if (classification.recoveryPlan != null) {
                                  newRecord['ai_recovery_plan'] = jsonEncode(classification.recoveryPlan);
                                }
                              } catch (e) {
                                print('❌ AI prenatal classification failed: $e');
                              }

                              // Save to database (offline + Firebase sync)
                              await _dbHelper.insertRecord(newRecord);

                              // Reload records
                              await _loadRecords();

                              // Show AI Classification modal with loading spinner
                              if (context.mounted && classification != null) {
                                await _showPrenatalAIModal(context, classification!);
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Prenatal registration saved successfully!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryAqua,
                              foregroundColor: _darkDeepTeal,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Register Prenatal Patient',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditPrenatalModal(
    BuildContext context,
    Map<String, dynamic> record,
  ) {
    // Parse existing data
    final patientName = record['patientName'] ?? '';
    final nameParts = patientName.split(' ');

    // Text editing controllers with existing data
    final firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts[0] : '',
    );
    final surnameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    final ageController = TextEditingController(
      text: record['age']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: record['address']?.toString() ?? '',
    );
    final patientIdController = TextEditingController(
      text: record['patientId']?.toString() ?? '',
    );
    final contactNumberController = TextEditingController(
      text: record['contactNumber']?.toString() ?? '',
    );
    final civilStatusController = TextEditingController(
      text: record['civilStatus']?.toString() ?? '',
    );
    final philhealthNumberController = TextEditingController(
      text: record['philhealthNumber']?.toString() ?? '',
    );
    final philhealthMemberController = TextEditingController(
      text: record['philhealthMember']?.toString() ?? '',
    );
    final religionController = TextEditingController(
      text: record['religion']?.toString() ?? '',
    );

    DateTime? lmpDate = _parseDate(record['lmpDate']);
    DateTime? eddDate = _parseDate(record['eddDate']);
    DateTime? lastDeliveryDate = _parseDate(record['lastDeliveryDate']);
    DateTime? registrationDate =
        _parseDate(record['registrationDate']) ?? DateTime.now();

    final gravidaController = TextEditingController(
      text: record['gravida']?.toString() ?? '',
    );
    final paraController = TextEditingController(
      text: record['para']?.toString() ?? '',
    );
    String selectedRiskLevel =
        record['riskLevel']?.toString() ??
        record['status']?.toString() ??
        'Active';

    final bloodTypeController = TextEditingController(
      text: record['bloodType']?.toString() ?? '',
    );
    final allergiesController = TextEditingController(
      text: record['allergies']?.toString() ?? '',
    );
    final preExistingConditionsController = TextEditingController(
      text: record['preExistingConditions']?.toString() ?? '',
    );
    final previousComplicationsController = TextEditingController(
      text: record['previousComplications']?.toString() ?? '',
    );

    // Medical measurements controllers
    final aogController = TextEditingController(
      text: record['aog']?.toString() ?? '',
    );
    final wtController = TextEditingController(
      text: record['wt']?.toString() ?? '',
    );
    final atController = TextEditingController(
      text: record['at']?.toString() ?? '',
    );
    final tempController = TextEditingController(
      text: record['temp']?.toString() ?? '',
    );
    final bpController = TextEditingController(
      text: record['bp']?.toString() ?? '',
    );
    final bmiController = TextEditingController(
      text: record['bmi']?.toString() ?? '',
    );
    final fhController = TextEditingController(
      text: record['fh']?.toString() ?? '',
    );
    final dhbController = TextEditingController(
      text: record['dhb']?.toString() ?? '',
    );
    final tcbController = TextEditingController(
      text: record['tcb']?.toString() ?? '',
    );

    final registeredByController = TextEditingController(
      text: record['registeredBy']?.toString() ?? '',
    );
    final additionalNoteController = TextEditingController(
      text: record['additionalNote']?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: _lightOffWhite,
            ),
            child: Column(
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryAqua, _secondaryIceBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.pregnant_woman,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Edit Prenatal Record',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
                

                // Form Content - Complete form with ALL fields
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient Information Section
                        _buildSectionHeader(
                          'Patient Information',
                          Icons.person,
                        ),
                        _buildFormCard([
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: firstNameController,
                                  label: 'First Name',
                                  icon: Icons.person_outline,
                                  hintText: 'Enter first name',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: surnameController,
                                  label: 'Surname',
                                  icon: Icons.person,
                                  hintText: 'Enter surname',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: ageController,
                                  label: 'Age',
                                  icon: Icons.cake,
                                  hintText: 'Enter age',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: patientIdController,
                                  label: 'Patient ID',
                                  icon: Icons.badge,
                                  hintText: 'e.g., PAT-2026-001',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: addressController,
                            label: 'Address',
                            icon: Icons.home,
                            hintText: 'Enter complete address',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: contactNumberController,
                            label: 'Contact Number',
                            icon: Icons.phone,
                            hintText: 'e.g., +63 912 345 6789',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: civilStatusController,
                                  label: 'Civil Status',
                                  icon: Icons.favorite,
                                  hintText: 'e.g., Single, Married',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: religionController,
                                  label: 'Religion',
                                  icon: Icons.church,
                                  hintText: 'Enter religion',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: philhealthNumberController,
                                  label: 'Philhealth Number',
                                  icon: Icons.medical_information,
                                  hintText: 'Enter Philhealth #',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: philhealthMemberController,
                                  label: 'Philhealth Member',
                                  icon: Icons.card_membership,
                                  hintText: 'Member name',
                                ),
                              ),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Pregnancy Detail Section
                        _buildSectionHeader(
                          'Pregnancy Detail',
                          Icons.child_care,
                        ),
                        _buildFormCard([
                          _buildDatePickerField(
                            context: context,
                            label: 'Last Menstrual Period (LMP)',
                            date: lmpDate,
                            icon: Icons.calendar_today,
                            onTap: () async {
                              final picked = await _showDatePickerModal(
                                context,
                              );
                              if (picked != null) {
                                setModalState(() => lmpDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDatePickerField(
                            context: context,
                            label: 'Estimated Due Date (EDD)',
                            date: eddDate,
                            icon: Icons.event,
                            onTap: () async {
                              final picked = await _showDatePickerModal(
                                context,
                              );
                              if (picked != null) {
                                setModalState(() => eddDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDatePickerField(
                            context: context,
                            label: 'Last Date of Delivery',
                            date: lastDeliveryDate,
                            icon: Icons.child_friendly,
                            onTap: () async {
                              final picked = await _showDatePickerModal(
                                context,
                              );
                              if (picked != null) {
                                setModalState(() => lastDeliveryDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: gravidaController,
                                  label: 'Gravida (Number of Pregnancy)',
                                  icon: Icons.numbers,
                                  hintText: 'e.g., 1, 2, 3',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: paraController,
                                  label: 'Para (Number of Live Births)',
                                  icon: Icons.numbers,
                                  hintText: 'e.g., 0, 1, 2',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Risk Level',
                            value: selectedRiskLevel,
                            icon: Icons.warning_amber,
                            items: ['Active', 'Follow Up', 'High Risk'],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() => selectedRiskLevel = value);
                              }
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Medical History Section
                        _buildSectionHeader(
                          'Medical History',
                          Icons.medical_services,
                        ),
                        _buildFormCard([
                          _buildTextField(
                            controller: bloodTypeController,
                            label: 'Blood Type',
                            icon: Icons.bloodtype,
                            hintText: 'e.g., A+, B-, O+, AB+',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: allergiesController,
                            label: 'Allergies',
                            icon: Icons.health_and_safety,
                            hintText: 'List any known allergies',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: preExistingConditionsController,
                            label: 'Pre-existing Medical Conditions',
                            icon: Icons.local_hospital,
                            hintText: 'e.g., Diabetes, Hypertension, Asthma',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: previousComplicationsController,
                            label: 'Previous Pregnancy Complications',
                            icon: Icons.warning,
                            hintText:
                                'List any complications from previous pregnancies',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: aogController,
                                  label: 'AOG (Age of Gestation)',
                                  icon: Icons.calendar_view_week,
                                  hintText: 'e.g., 28 weeks',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: wtController,
                                  label: 'WT (Weight)',
                                  icon: Icons.monitor_weight,
                                  hintText: 'e.g., 65 kg',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: tempController,
                                  label: 'TEMP (Temperature)',
                                  icon: Icons.thermostat,
                                  hintText: 'e.g., 36.5°C',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: bpController,
                                  label: 'BP (Blood Pressure)',
                                  icon: Icons.favorite,
                                  hintText: 'e.g., 120/80',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: bmiController,
                                  label: 'BMI (Body Mass Index)',
                                  icon: Icons.assessment,
                                  hintText: 'e.g., 22.5',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: fhController,
                                  label: 'FH (Fundal Height)',
                                  icon: Icons.straighten,
                                  hintText: 'e.g., 28 cm',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: dhbController,
                                  label: 'DHB (Fetal Heart Beat)',
                                  icon: Icons.favorite_border,
                                  hintText: 'e.g., 140 bpm',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: atController,
                                  label: 'AT (Abdominal Tenderness)',
                                  icon: Icons.touch_app,
                                  hintText: 'e.g., None, Mild',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: tcbController,
                            label: 'TCB (Total Bilirubin)',
                            icon: Icons.science,
                            hintText: 'e.g., 0.8 mg/dL',
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Registration Details Section
                        _buildSectionHeader(
                          'Registration Details',
                          Icons.app_registration,
                        ),
                        _buildFormCard([
                          _buildDatePickerField(
                            context: context,
                            label: 'Registration Date',
                            date: registrationDate,
                            icon: Icons.calendar_month,
                            onTap: () async {
                              final picked = await _showDatePickerModal(
                                context,
                              );
                              if (picked != null) {
                                setModalState(() => registrationDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: registeredByController,
                            label: 'Registered By',
                            icon: Icons.person_pin,
                            hintText: 'Enter staff name or ID',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: additionalNoteController,
                            label: 'Additional Note',
                            icon: Icons.note,
                            hintText: 'Enter any additional notes or remarks',
                            maxLines: 4,
                          ),
                        ]),
                        const SizedBox(height: 32),

                        // Update Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Update prenatal record
                              final updatedRecord = {
                                'id': record['id'], // Keep original ID
                                'patientName':
                                    '${firstNameController.text} ${surnameController.text}',
                                'age': ageController.text,
                                'address': addressController.text,
                                'patientId': patientIdController.text,
                                'contactNumber': contactNumberController.text,
                                'civilStatus': civilStatusController.text,
                                'religion': religionController.text,
                                'philhealthNumber':
                                    philhealthNumberController.text,
                                'philhealthMember':
                                    philhealthMemberController.text,
                                'lmpDate': lmpDate?.toIso8601String() ?? '',
                                'eddDate': eddDate?.toIso8601String() ?? '',
                                'lastDeliveryDate':
                                    lastDeliveryDate?.toIso8601String() ?? '',
                                'gravida': gravidaController.text,
                                'para': paraController.text,
                                'riskLevel': selectedRiskLevel,
                                'bloodType': bloodTypeController.text,
                                'allergies': allergiesController.text,
                                'preExistingConditions':
                                    preExistingConditionsController.text,
                                'previousComplications':
                                    previousComplicationsController.text,
                                'aog': aogController.text,
                                'wt': wtController.text,
                                'at': atController.text,
                                'temp': tempController.text,
                                'bp': bpController.text,
                                'bmi': bmiController.text,
                                'fh': fhController.text,
                                'dhb': dhbController.text,
                                'tcb': tcbController.text,
                                'registrationDate':
                                    registrationDate?.toIso8601String() ?? '',
                                'registeredBy': registeredByController.text,
                                'additionalNote': additionalNoteController.text,
                                'gestationalAge': aogController.text,
                                'dueDate': eddDate?.toIso8601String() ?? '',
                                'status': selectedRiskLevel,
                              };

                              // AI Classification on edited record
                              ClassificationResult? classification;
                              try {
                                print('🤖 [AI] Starting prenatal re-classification...');
                                classification = await _aiClassifier.classify(updatedRecord);
                                print('✅ [AI] Prenatal re-classification complete: ${classification.category}');

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
                                print('❌ AI prenatal re-classification failed: $e');
                              }

                              // Update in database
                              final id = record['id']?.toString() ?? '';
                              if (id.isNotEmpty) {
                                await _dbHelper.updateRecord(id, updatedRecord);
                                await _loadRecords();

                                // Show AI Classification modal with loading spinner
                                if (context.mounted && classification != null) {
                                  await _showPrenatalAIModal(context, classification!);
                                }

                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Prenatal record updated successfully!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: Record ID not found'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryAqua,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Update Prenatal Record',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
        },
      ),
    );
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null || dateValue.toString().isEmpty) return null;
    try {
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      return null;
    }
  }

  Future<DateTime?> _showDatePickerModal(BuildContext context) async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
            style: TextStyle(
              color: _darkDeepTeal,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryAqua.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _mutedCoolGray.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _mutedCoolGray,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            color: _darkDeepTeal,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: _mutedCoolGray.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(icon, color: _primaryAqua, size: 20),
            filled: true,
            fillColor: _lightOffWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _mutedCoolGray.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _mutedCoolGray.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primaryAqua, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _mutedCoolGray,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _lightOffWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: date != null
                    ? _primaryAqua
                    : _mutedCoolGray.withOpacity(0.3),
                width: date != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: _primaryAqua, size: 20),
                const SizedBox(width: 12),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Select Date',
                  style: TextStyle(
                    color: date != null ? _darkDeepTeal : _mutedCoolGray,
                    fontSize: 14,
                    fontWeight: date != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _mutedCoolGray,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _lightOffWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _mutedCoolGray.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: _primaryAqua, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: _primaryAqua),
                    style: TextStyle(
                      color: _darkDeepTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryAqua.withOpacity(0.1),
                  _secondaryIceBlue.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryAqua, _secondaryIceBlue],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryAqua.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.filter_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Filter & Search',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _darkDeepTeal,
                  ),
                ),
              ],
            ),
          ),

          // Filter Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Status Filter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _lightOffWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _primaryAqua.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        color: _primaryAqua,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatusFilter,
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: _primaryAqua,
                            ),
                            style: TextStyle(
                              color: _darkDeepTeal,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            items: _statusFilterOptions.map((String option) {
                              return DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedStatusFilter = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Date Range Header
                Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      color: _primaryAqua,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Due Date Range',
                      style: TextStyle(
                        color: _darkDeepTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_fromDate != null || _toDate != null)
                      InkWell(
                        onTap: _clearDateFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.clear, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerButton(
                        context: context,
                        label: 'From Date',
                        date: _fromDate,
                        isFromDate: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDatePickerButton(
                        context: context,
                        label: 'To Date',
                        date: _toDate,
                        isFromDate: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required bool isFromDate,
  }) {
    return InkWell(
      onTap: () => _selectDate(context, isFromDate),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _lightOffWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null
                ? _primaryAqua
                : _mutedCoolGray.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: _mutedCoolGray,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: date != null ? _primaryAqua : _mutedCoolGray,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select Date',
                    style: TextStyle(
                      color: date != null ? _darkDeepTeal : _mutedCoolGray,
                      fontSize: 13,
                      fontWeight: date != null
                          ? FontWeight.bold
                          : FontWeight.normal,
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

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
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
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: _mutedCoolGray,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard({
    required BuildContext context,
    required int index,
    required Map<String, dynamic> record,
  }) {
    final isSelected = _selectedIndices.contains(index);
    final patientName = record['patientName'] ?? 'Unknown';
    final nameParts = patientName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts[0] : 'N/A';
    final surname = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : 'N/A';
    final gestationalAge = record['gestationalAge'] ?? 'N/A';
    final dueDate = record['dueDate'] ?? 'N/A';
    final status = record['status'] ?? 'Active';
    final age = record['age'] ?? 'N/A';
    final address = record['address'] ?? 'N/A';
    final contactNumber = record['contactNumber'] ?? 'N/A';
    final riskLevel = record['riskLevel'] ?? status;

    return GestureDetector(
      onTap: _isSelectionMode
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedIndices.remove(index);
                } else {
                  _selectedIndices.add(index);
                }
              });
            }
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
                  if (_isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedIndices.add(index);
                          } else {
                            _selectedIndices.remove(index);
                          }
                        });
                      },
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
                      Icons.pregnant_woman,
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
                  _buildStatusChip(status),
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
              if (!_isSelectionMode)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showPatientDetails(context, record);
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
                        onPressed: () {
                          _showEditPrenatalModal(context, record);
                        },
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: _darkDeepTeal,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    switch (status) {
      case 'Active':
        statusColor = Colors.green;
        break;
      case 'Follow Up':
        statusColor = Colors.orange;
        break;
      case 'High Risk':
        statusColor = Colors.red;
        break;
      case 'Completed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = _mutedCoolGray;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPatientDetails(BuildContext context, Map<String, dynamic> record) {
    // Parse first name and surname
    final patientName = record['patientName'] ?? 'Unknown';
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
                    Icon(Icons.pregnant_woman, color: Colors.white, size: 28),
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
                      _buildDetailSection('Personal Information', [
                        _buildDetailRow('First Name', firstName),
                        _buildDetailRow('Surname', surname),
                        _buildDetailRow('Patient ID', record['patientId']),
                        _buildDetailRow('Age', record['age']),
                        _buildDetailRow('Address', record['address']),
                        _buildDetailRow(
                          'Contact Number',
                          record['contactNumber'],
                        ),
                        _buildDetailRow('Civil Status', record['civilStatus']),
                        _buildDetailRow('Religion', record['religion']),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Philhealth Information', [
                        _buildDetailRow(
                          'Philhealth Number',
                          record['philhealthNumber'],
                        ),
                        _buildDetailRow(
                          'Philhealth Member',
                          record['philhealthMember'],
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Pregnancy Details', [
                        _buildDetailRow(
                          'Gestational Age',
                          record['gestationalAge'],
                        ),
                        _buildDetailRow(
                          'LMP Date',
                          _formatDate(record['lmpDate']),
                        ),
                        _buildDetailRow(
                          'EDD Date',
                          _formatDate(record['eddDate']),
                        ),
                        _buildDetailRow(
                          'Due Date',
                          _formatDate(record['dueDate']),
                        ),
                        _buildDetailRow(
                          'Last Delivery',
                          _formatDate(record['lastDeliveryDate']),
                        ),
                        _buildDetailRow('Gravida', record['gravida']),
                        _buildDetailRow('Para', record['para']),
                        _buildDetailRow('Risk Level', record['riskLevel']),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Medical History', [
                        _buildDetailRow('Blood Type', record['bloodType']),
                        _buildDetailRow('Allergies', record['allergies']),
                        _buildDetailRow(
                          'Pre-existing Conditions',
                          record['preExistingConditions'],
                        ),
                        _buildDetailRow(
                          'Previous Complications',
                          record['previousComplications'],
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Vital Signs & Measurements', [
                        _buildDetailRow(
                          'Age of Gestation (AOG)',
                          record['aog'],
                        ),
                        _buildDetailRow('Weight (WT)', record['wt']),
                        _buildDetailRow(
                          'Abdominal Tenderness (AT)',
                          record['at'],
                        ),
                        _buildDetailRow('Temperature', record['temp']),
                        _buildDetailRow('Blood Pressure (BP)', record['bp']),
                        _buildDetailRow('BMI', record['bmi']),
                        _buildDetailRow('Fundal Height (FH)', record['fh']),
                        _buildDetailRow(
                          'Fetal Heart Beat (DHB)',
                          record['dhb'],
                        ),
                        _buildDetailRow('Total Bilirubin (TCB)', record['tcb']),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Registration Details', [
                        _buildDetailRow(
                          'Registration Date',
                          _formatDate(record['registrationDate']),
                        ),
                        _buildDetailRow(
                          'Registered By',
                          record['registeredBy'],
                        ),
                        _buildDetailRow('Status', record['status']),
                      ]),
                      if (record['additionalNote'] != null &&
                          record['additionalNote'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection('Additional Notes', [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _lightOffWhite,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              record['additionalNote'] ?? '',
                              style: TextStyle(color: _darkDeepTeal),
                            ),
                          ),
                        ]),
                      ],
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

  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return date.toString();
    }
  }

  Widget _buildActionMenuButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryAqua.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _mutedCoolGray.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _isSelectionMode = !_isSelectionMode;
              if (!_isSelectionMode) {
                _selectedIndices.clear();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  _isSelectionMode ? Icons.close : Icons.checklist,
                  color: _primaryAqua,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isSelectionMode
                        ? 'Selection Mode Active'
                        : 'Select Records',
                    style: TextStyle(
                      color: _darkDeepTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isSelectionMode && _selectedIndices.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryAqua,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedIndices.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Icon(Icons.chevron_right, color: _mutedCoolGray),
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
                          _getFilteredRecords().length,
                          (index) => index,
                        );
                        _selectedIndices.addAll(allIndices);
                      });
                    },
                    icon: Icon(Icons.select_all, size: 18),
                    label: Text('Select All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: _darkDeepTeal,
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
                      foregroundColor: _darkDeepTeal,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No records selected'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final filteredRecords = _getFilteredRecords();
    final idsToDelete = _selectedIndices
        .map(
          (index) => index < filteredRecords.length
              ? filteredRecords[index]['id'] as String?
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
