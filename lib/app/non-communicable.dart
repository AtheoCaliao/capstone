import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycapstone_project/app/database_helper.dart';

const Color _primaryAqua = Color(0xFF00A8B5);
const Color _secondaryIceBlue = Color(0xFF1E5A7A);
const Color _darkDeepTeal = Color(0xFF0A1F24);
const Color _mutedCoolGray = Color(0xFF546E7A);
const Color _lightOffWhite = Color(0xFFF5F5F5);

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
      final completedCases = nonCommunicableRecords.where((r) => r['status'] == 'Completed').length;
      final controlRate = activeCases > 0 ? (completedCases / activeCases * 100) : 0.0;

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
          return patient['patientName'].toString().toLowerCase().contains(_searchQuery) ||
              patient['condition'].toString().toLowerCase().contains(_searchQuery) ||
              patient['currentStatus'].toString().toLowerCase().contains(_searchQuery);
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Non-Communicable Disease Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryAqua,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddPatientDialog();
            },
            tooltip: 'Add Patient',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadMetrics();
              _loadPatients();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadMetrics();
          await _loadPatients();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Overview
              _buildOverviewDashboard(),
              
              const SizedBox(height: 20),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBar(),
              ),

              const SizedBox(height: 20),

              // Patient Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPatientCards(),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: _darkDeepTeal,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              Icon(Icons.search_off, size: 64, color: _mutedCoolGray.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty ? 'No patients found' : 'No results for "$_searchQuery"',
                style: TextStyle(
                  fontSize: 16,
                  color: _mutedCoolGray,
                ),
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
                    patient['patientName'].toString().substring(0, 1).toUpperCase(),
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
                        style: TextStyle(
                          fontSize: 13,
                          color: _mutedCoolGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                if (patient['notes'] != null && patient['notes'].toString().isNotEmpty) ...[
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
              style: TextStyle(
                color: _darkDeepTeal,
                fontSize: 13,
              ),
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
