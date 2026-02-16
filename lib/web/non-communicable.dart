import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mycapstone_project/web/database_helper.dart';
import 'package:mycapstone_project/web/login.dart';
import 'package:mycapstone_project/web/homepage.dart';
import 'package:mycapstone_project/web/checkup.dart';
import 'package:mycapstone_project/web/health_metrics.dart';
import 'package:mycapstone_project/web/Analytics.dart';
import 'package:mycapstone_project/web/prenatal.dart';
import 'package:mycapstone_project/web/Immunization.dart';
import 'package:mycapstone_project/web/patient.dart';
import 'package:mycapstone_project/web/communicable.dart';
import 'package:mycapstone_project/web/Mortality.dart';

const Color _primaryAqua = Color(0xFF00A8B5);
const Color _secondaryIceBlue = Color(0xFF1E5A7A);
const Color _darkDeepTeal = Color(0xFF0A1F24);
const Color _mutedCoolGray = Color(0xFF546E7A);
const Color _lightOffWhite = Color(0xFFF5F5F5);
const Color _sidebarDark = Color(0xFF0E2F34);

class NonCommunicablePage extends StatefulWidget {
  const NonCommunicablePage({super.key});

  @override
  State<NonCommunicablePage> createState() => _NonCommunicablePageState();
}

class _NonCommunicablePageState extends State<NonCommunicablePage> {
  // State variables for metrics
  int _activeCases = 0;
  Map<String, int> _diseaseTypes = {};
  double _controlRate = 0.0;
  bool _isLoadingMetrics = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Data from check-up database
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _dbHelper.startConnectivityListener();
    _loadMetrics();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoadingMetrics = true;
    });

    try {
      // Load actual metrics from database
      final allRecords = await _dbHelper.getAllRecords();
      final nonCommunicableRecords = allRecords.where((record) {
        return record['diseaseType'] == 'Non-Communicable';
      }).toList();

      // Calculate metrics
      final activeCases = nonCommunicableRecords.length;
      final completedCases = nonCommunicableRecords
          .where((r) => r['status'] == 'Completed')
          .length;
      final controlRate = activeCases > 0
          ? (completedCases / activeCases * 100)
          : 0.0;

      setState(() {
        _activeCases = activeCases;
        _diseaseTypes = {}; // Could parse from details if needed
        _controlRate = controlRate;
        _isLoadingMetrics = false;
      });
    } catch (e) {
      print('Error loading metrics: $e');
      setState(() {
        _isLoadingMetrics = false;
      });
    }
  }

  String _extractAge(String details) {
    final ageMatch = RegExp(r'Age: (\d+)').firstMatch(details);
    return ageMatch?.group(1) ?? 'N/A';
  }

  Future<void> _loadPatients() async {
    try {
      // Sync from Firebase first
      await _dbHelper.syncFromFirebase();

      // Load non-communicable disease records from check-up database
      final allRecords = await _dbHelper.getAllRecords();

      // Filter for non-communicable diseases only
      final nonCommunicableRecords = allRecords.where((record) {
        return record['diseaseType'] == 'Non-Communicable';
      }).toList();

      setState(() {
        _patients = nonCommunicableRecords.map((record) {
          return {
            'id': record['id'] ?? '',
            'patientName': record['patient'] ?? 'Unknown',
            'age': _extractAge(record['details'] ?? ''),
            'gender': 'N/A',
            'condition': record['details'] ?? 'No details',
            'lastVisit': record['datetime']?.split(' ')[0] ?? 'N/A',
            'nextVisit': 'N/A',
            'currentStatus': record['status'] ?? 'Pending',
            'treatment': record['plan'] ?? 'No treatment plan',
            'notes': '',
          };
        }).toList();
        _filteredPatients = List.from(_patients);
      });
    } catch (e) {
      print('Error loading patients: $e');
    }
  }

  void _filterPatients(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredPatients = List.from(_patients);
      } else {
        _filteredPatients = _patients.where((patient) {
          return patient['patientName'].toString().toLowerCase().contains(
                _searchQuery,
              ) ||
              patient['condition'].toString().toLowerCase().contains(
                _searchQuery,
              ) ||
              patient['currentStatus'].toString().toLowerCase().contains(
                _searchQuery,
              );
        }).toList();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'stable':
      case 'recovering':
        return const Color(0xFF4CAF50);
      case 'under treatment':
        return const Color(0xFF2196F3);
      case 'critical':
        return const Color(0xFFD84315);
      default:
        return _mutedCoolGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      backgroundColor: _lightOffWhite,
      body: Row(
        children: [
          _buildSidebar(context, userName),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadMetrics();
                      await _loadPatients();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverviewDashboard(),
                          const SizedBox(height: 20),
                          _buildSearchBar(),
                          const SizedBox(height: 20),
                          _buildPatientCards(),
                          const SizedBox(height: 20),
                        ],
                      ),
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
                  isActive: true,
                  onTap: () {},
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
            Icons.health_and_safety_rounded,
            color: _primaryAqua,
            size: 32,
          ),
          const SizedBox(width: 16),
          Text(
            'Non-Communicable Disease Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _darkDeepTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Patient',
            onPressed: () => _showAddPatientDialog(),
            color: _primaryAqua,
            iconSize: 28,
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: () {
              _loadMetrics();
              _loadPatients();
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

  // Overview Dashboard Section
  Widget _buildOverviewDashboard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryAqua,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NCD Overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoadingMetrics)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Active Cases',
                          value: _activeCases.toString(),
                          icon: Icons.people,
                          color: Colors.white,
                          textColor: _primaryAqua,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Control Rate',
                          value: '${_controlRate.toStringAsFixed(1)}%',
                          icon: Icons.trending_up,
                          color: Colors.white,
                          textColor: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDiseaseTypeCard(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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
              Icon(icon, color: textColor, size: 28),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: textColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseTypeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_hospital, color: _primaryAqua, size: 24),
              const SizedBox(width: 8),
              Text(
                'Disease Types',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _darkDeepTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._diseaseTypes.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(fontSize: 14, color: _darkDeepTeal),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryAqua.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _primaryAqua,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterPatients,
        decoration: InputDecoration(
          hintText: 'Search by patient name, condition, or status...',
          hintStyle: TextStyle(color: _mutedCoolGray),
          prefixIcon: Icon(Icons.search, color: _primaryAqua),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: _mutedCoolGray),
                  onPressed: () {
                    _searchController.clear();
                    _filterPatients('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // Patient Cards
  Widget _buildPatientCards() {
    if (_filteredPatients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: _mutedCoolGray.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'No patients found'
                    : 'No results for "$_searchQuery"',
                style: TextStyle(fontSize: 16, color: _mutedCoolGray),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _filteredPatients.map((patient) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPatientCard(patient),
        );
      }).toList(),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryAqua.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _primaryAqua,
                  child: Text(
                    patient['patientName']
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient['patientName'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkDeepTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${patient['age']} years • ${patient['gender']}',
                        style: TextStyle(fontSize: 13, color: _mutedCoolGray),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(patient['currentStatus']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    patient['currentStatus'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Patient Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.medical_information,
                  label: 'Condition',
                  value: patient['condition'],
                  color: const Color(0xFFD84315),
                ),
                const Divider(height: 20),
                _buildDetailRow(
                  icon: Icons.medication,
                  label: 'Treatment',
                  value: patient['treatment'],
                  color: const Color(0xFF7B1FA2),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Last Visit',
                        value: _formatDate(patient['lastVisit']),
                        color: _primaryAqua,
                        isCompact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDetailRow(
                        icon: Icons.event,
                        label: 'Next Visit',
                        value: _formatDate(patient['nextVisit']),
                        color: const Color(0xFF4CAF50),
                        isCompact: true,
                      ),
                    ),
                  ],
                ),
                if (patient['notes'] != null &&
                    patient['notes'].toString().isNotEmpty) ...[
                  const Divider(height: 20),
                  _buildDetailRow(
                    icon: Icons.note,
                    label: 'Notes',
                    value: patient['notes'],
                    color: const Color(0xFF607D8B),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.visibility,
                  label: 'View',
                  color: _primaryAqua,
                  onTap: () => _viewPatientDetails(patient),
                ),
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  color: const Color(0xFF7B1FA2),
                  onTap: () => _editPatient(patient),
                ),
                _buildActionButton(
                  icon: Icons.medical_services,
                  label: 'Treatment',
                  color: const Color(0xFF4CAF50),
                  onTap: () => _manageTreatment(patient),
                ),
                _buildActionButton(
                  icon: Icons.history,
                  label: 'History',
                  color: const Color(0xFFFFA726),
                  onTap: () => _viewHistory(patient),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isCompact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: isCompact ? 18 : 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  color: _mutedCoolGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isCompact ? 13 : 14,
                  color: _darkDeepTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Action Methods
  void _showAddPatientDialog() {
    Get.snackbar(
      'Add Patient',
      'Patient registration form coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _primaryAqua,
      colorText: Colors.white,
    );
  }

  void _viewPatientDetails(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          patient['patientName'],
          style: TextStyle(color: _darkDeepTeal, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem('Patient ID', patient['id']),
              _buildInfoItem('Age', '${patient['age']} years'),
              _buildInfoItem('Gender', patient['gender']),
              _buildInfoItem('Condition', patient['condition']),
              _buildInfoItem('Status', patient['currentStatus']),
              _buildInfoItem('Treatment', patient['treatment']),
              _buildInfoItem('Last Visit', patient['lastVisit']),
              _buildInfoItem('Next Visit', patient['nextVisit']),
              if (patient['notes'] != null)
                _buildInfoItem('Notes', patient['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _primaryAqua)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _mutedCoolGray,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: _darkDeepTeal, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _editPatient(Map<String, dynamic> patient) {
    Get.snackbar(
      'Edit Patient',
      'Editing ${patient['patientName']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF7B1FA2),
      colorText: Colors.white,
    );
  }

  void _manageTreatment(Map<String, dynamic> patient) {
    Get.snackbar(
      'Manage Treatment',
      'Treatment plan for ${patient['patientName']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
    );
  }

  void _viewHistory(Map<String, dynamic> patient) {
    Get.snackbar(
      'Medical History',
      'Viewing history for ${patient['patientName']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFFFA726),
      colorText: Colors.white,
    );
  }
}
