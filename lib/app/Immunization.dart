import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycapstone_project/app/immunization_database_helper.dart';

const Color _primaryAqua = Color(0xFF00A8B5);
const Color _secondaryIceBlue = Color(0xFF1E5A7A);
const Color _darkDeepTeal = Color(0xFF0A1F24);
const Color _mutedCoolGray = Color(0xFF546E7A);
const Color _lightOffWhite = Color(0xFFF5F5F5);

class ImmunizationPage extends StatefulWidget {
  const ImmunizationPage({super.key});

  @override
  State<ImmunizationPage> createState() => _ImmunizationPageState();
}

class _ImmunizationPageState extends State<ImmunizationPage> {
  String _selectedVaccineFilter = 'All Vaccines';
  final List<String> _vaccineFilterOptions = [
    'All Vaccines',
    'BCG Vaccine',
    'Hepatitis B',
    'DPT Vaccine',
    'Polio Vaccine',
    'MMR Vaccine',
    'Varicella Vaccine',
  ];

  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};
  bool _isDeleteDialogShowing = false;
  bool _isLoading = true;

  // Database-backed immunization records
  List<Map<String, dynamic>> _immunizationRecords = [];
  final ImmunizationDatabaseHelper _dbHelper =
      ImmunizationDatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _dbHelper.startConnectivityListener();
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
      _immunizationRecords = updatedRecords;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightOffWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _darkDeepTeal, size: 24),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Immunization',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _darkDeepTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton:
          (_isDeleteDialogShowing ||
              (_isSelectionMode && _selectedIndices.isNotEmpty))
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showNewImmunizationModal(context),
              backgroundColor: _primaryAqua,
              elevation: 4,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Immunization',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryAqua))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dashboard Header
                      Text(
                        'Vaccination Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _darkDeepTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dashboard Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildDashboardCard(
                              title: 'Today\'s Schedule',
                              value: '${_getFilteredRecords().length}',
                              icon: Icons.calendar_today,
                              color: _primaryAqua,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDashboardCard(
                              title: 'Completed',
                              value:
                                  '${_getFilteredRecords().where((r) => r['status'] == 'Completed').length}',
                              icon: Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDashboardCard(
                              title: 'Scheduled',
                              value:
                                  '${_getFilteredRecords().where((r) => r['status'] == 'Scheduled').length}',
                              icon: Icons.schedule,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDashboardCard(
                              title: 'In Progress',
                              value:
                                  '${_getFilteredRecords().where((r) => r['status'] == 'In Progress').length}',
                              icon: Icons.hourglass_empty,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Immunization Records Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.vaccines,
                                color: _primaryAqua,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Immunization Records',
                                style: Theme.of(context).textTheme.titleLarge
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
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_getFilteredRecords().length} Records',
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

                      // Filters
                      _buildFilters(),
                      const SizedBox(height: 16),

                      // Action Menu Button
                      _buildActionMenuButton(),
                      const SizedBox(height: 16),

                      // Immunization Cards
                      ..._getFilteredRecords().asMap().entries.map((entry) {
                        final index = entry.key;
                        final record = entry.value;
                        return _buildImmunizationCard(
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
    );
  }

  List<Map<String, dynamic>> _getFilteredRecords() {
    return _immunizationRecords.where((record) {
      // Vaccine filter
      bool vaccineMatch = true;
      if (_selectedVaccineFilter != 'All Vaccines') {
        vaccineMatch = record['vaccine'] == _selectedVaccineFilter;
      }

      // Date range filter
      bool dateMatch = true;
      if (_fromDate != null || _toDate != null) {
        final recordDate = DateTime.parse(record['date']);
        if (_fromDate != null && recordDate.isBefore(_fromDate!)) {
          dateMatch = false;
        }
        if (_toDate != null && recordDate.isAfter(_toDate!)) {
          dateMatch = false;
        }
      }

      return vaccineMatch && dateMatch;
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

  void _showNewImmunizationModal(BuildContext context) {
    // Controllers
    final firstNameController = TextEditingController();
    final surnameController = TextEditingController();
    final patientIdController = TextEditingController();
    final ageController = TextEditingController();
    final contactNumberController = TextEditingController();

    String selectedVaccineType = 'BCG Vaccine';
    final vaccineBrandController = TextEditingController();
    final batchNumberController = TextEditingController();
    DateTime? expirationDate;

    DateTime? administrationDate = DateTime.now();
    TimeOfDay? administrationTime = TimeOfDay.now();
    final doseNumberController = TextEditingController();
    String selectedRouteOfAdministration = 'Intramuscular (IM)';
    String selectedInjectionSite = 'Left Upper Arm';
    final administeredByController = TextEditingController();
    final adverseEventsController = TextEditingController();
    DateTime? nextDoseDueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: _lightOffWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
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
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
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
                          Icons.vaccines,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'New Immunization Record',
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
                        // Patient Details
                        _buildSectionHeader('Patient Details', Icons.person),
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
                                  controller: patientIdController,
                                  label: 'Patient ID',
                                  icon: Icons.badge,
                                  hintText: 'e.g., PAT-2026-001',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: ageController,
                                  label: 'Age',
                                  icon: Icons.cake,
                                  hintText: 'Enter age',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: contactNumberController,
                            label: 'Contact Number',
                            icon: Icons.phone,
                            hintText: 'e.g., +63 912 345 6789',
                            keyboardType: TextInputType.phone,
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Vaccine Details
                        _buildSectionHeader(
                          'Vaccine Details',
                          Icons.medical_services,
                        ),
                        _buildFormCard([
                          _buildDropdownField(
                            label: 'Vaccine Type',
                            value: selectedVaccineType,
                            icon: Icons.vaccines,
                            items: [
                              'BCG Vaccine',
                              'Hepatitis B',
                              'DPT Vaccine',
                              'Polio Vaccine',
                              'MMR Vaccine',
                              'Varicella Vaccine',
                              'Influenza',
                              'Pneumococcal',
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(
                                  () => selectedVaccineType = value,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: vaccineBrandController,
                            label: 'Vaccine Brand',
                            icon: Icons.business,
                            hintText: 'Enter vaccine brand/manufacturer',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: batchNumberController,
                            label: 'Batch/Lot Number',
                            icon: Icons.numbers,
                            hintText: 'Enter batch or lot number',
                          ),
                          const SizedBox(height: 16),
                          _buildModalDatePickerField(
                            context: context,
                            label: 'Expiration Date',
                            date: expirationDate,
                            icon: Icons.event_busy,
                            onTap: () async {
                              final picked = await _showModalDatePicker(
                                context,
                              );
                              if (picked != null) {
                                setModalState(() => expirationDate = picked);
                              }
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Administration Details
                        _buildSectionHeader(
                          'Administration Details',
                          Icons.local_hospital,
                        ),
                        _buildFormCard([
                          Row(
                            children: [
                              Expanded(
                                child: _buildModalDatePickerField(
                                  context: context,
                                  label: 'Administration Date',
                                  date: administrationDate,
                                  icon: Icons.calendar_today,
                                  onTap: () async {
                                    final picked = await _showModalDatePicker(
                                      context,
                                    );
                                    if (picked != null) {
                                      setModalState(
                                        () => administrationDate = picked,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTimePickerField(
                                  context: context,
                                  label: 'Administration Time',
                                  time: administrationTime,
                                  icon: Icons.access_time,
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          administrationTime ?? TimeOfDay.now(),
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
                                      setModalState(
                                        () => administrationTime = picked,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: doseNumberController,
                            label: 'Dose Number',
                            icon: Icons.format_list_numbered,
                            hintText: 'e.g., 1st dose, 2nd dose',
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Route of Administration',
                            value: selectedRouteOfAdministration,
                            icon: Icons.medical_information,
                            items: [
                              'Intramuscular (IM)',
                              'Subcutaneous (SC)',
                              'Intradermal (ID)',
                              'Oral',
                              'Intranasal',
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(
                                  () => selectedRouteOfAdministration = value,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Injection Site',
                            value: selectedInjectionSite,
                            icon: Icons.place,
                            items: [
                              'Left Upper Arm',
                              'Right Upper Arm',
                              'Left Thigh',
                              'Right Thigh',
                              'Left Buttock',
                              'Right Buttock',
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(
                                  () => selectedInjectionSite = value,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: administeredByController,
                            label: 'Administered By',
                            icon: Icons.person_pin,
                            hintText: 'Enter staff name or ID',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: adverseEventsController,
                            label: 'Adverse Events/Reactions',
                            icon: Icons.warning,
                            hintText: 'Note any adverse reactions or events',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _buildModalDatePickerField(
                            context: context,
                            label: 'Next Dose Due Date',
                            date: nextDoseDueDate,
                            icon: Icons.event,
                            onTap: () async {
                              final picked = await _showModalDatePicker(
                                context,
                              );
                              if (picked != null) {
                                setModalState(() => nextDoseDueDate = picked);
                              }
                            },
                          ),
                        ]),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Create new immunization record
                              final newRecord = {
                                'time':
                                    '${administrationTime?.hour.toString().padLeft(2, '0')}:${administrationTime?.minute.toString().padLeft(2, '0')}',
                                'patientName': '${firstNameController.text} ${surnameController.text}'.trim(),
                                'patientId': patientIdController.text,
                                'age': ageController.text,
                                'contactNumber': contactNumberController.text,
                                'vaccine': selectedVaccineType,
                                'vaccineBrand': vaccineBrandController.text,
                                'batchNumber': batchNumberController.text,
                                'expirationDate':
                                    expirationDate?.toIso8601String() ?? '',
                                'administrationDate':
                                    administrationDate?.toIso8601String() ?? '',
                                'administrationTime':
                                    '${administrationTime?.hour.toString().padLeft(2, '0')}:${administrationTime?.minute.toString().padLeft(2, '0')}',
                                'doseNumber': doseNumberController.text,
                                'routeOfAdministration':
                                    selectedRouteOfAdministration,
                                'injectionSite': selectedInjectionSite,
                                'administeredBy': administeredByController.text,
                                'adverseEvents': adverseEventsController.text,
                                'nextDoseDueDate':
                                    nextDoseDueDate?.toIso8601String() ?? '',
                                'status': 'Completed',
                                'date':
                                    administrationDate?.toIso8601String() ?? '',
                              };

                              // Save to database (offline + Firebase sync)
                              await _dbHelper.insertRecord(newRecord);

                              // Reload records
                              await _loadRecords();

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Immunization record saved successfully!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
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
                              'Save Immunization Record',
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

  Future<DateTime?> _showModalDatePicker(BuildContext context) async {
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
              borderSide: BorderSide(color: _primaryAqua, width: 2),
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

  Widget _buildModalDatePickerField({
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

  Widget _buildTimePickerField({
    required BuildContext context,
    required String label,
    required TimeOfDay? time,
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
                color: time != null
                    ? _primaryAqua
                    : _mutedCoolGray.withOpacity(0.3),
                width: time != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: _primaryAqua, size: 20),
                const SizedBox(width: 12),
                Text(
                  time != null ? time.format(context) : 'Select Time',
                  style: TextStyle(
                    color: time != null ? _darkDeepTeal : _mutedCoolGray,
                    fontSize: 14,
                    fontWeight: time != null
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

  Widget _buildModalTimePickerField({
    required BuildContext context,
    required String label,
    required TimeOfDay? time,
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
                color: time != null
                    ? _primaryAqua
                    : _mutedCoolGray.withOpacity(0.3),
                width: time != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: _primaryAqua, size: 20),
                const SizedBox(width: 12),
                Text(
                  time != null ? time.format(context) : 'Select Time',
                  style: TextStyle(
                    color: time != null ? _darkDeepTeal : _mutedCoolGray,
                    fontSize: 14,
                    fontWeight: time != null
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

  Future<TimeOfDay?> _showModalTimePicker(
    BuildContext context,
    TimeOfDay? initialTime,
  ) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
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

  Widget _buildFilters() {
    return Column(
      children: [
        // Vaccine Filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primaryAqua.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _mutedCoolGray.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(Icons.vaccines, color: _primaryAqua, size: 20),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVaccineFilter,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: _primaryAqua),
                    style: TextStyle(
                      color: _darkDeepTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    items: _vaccineFilterOptions.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedVaccineFilter = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Date Range Filter
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primaryAqua.withOpacity(0.2),
              width: 1.5,
            ),
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
            children: [
              Row(
                children: [
                  Icon(Icons.date_range, color: _primaryAqua, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Filter by Date Range',
                    style: TextStyle(
                      color: _darkDeepTeal,
                      fontSize: 14,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _mutedCoolGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: _darkDeepTeal,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImmunizationCard({
    required BuildContext context,
    required int index,
    required Map<String, dynamic> record,
  }) {
    final isSelected = _selectedIndices.contains(index);
    final time = record['time'] ?? 'N/A';
    final patientName = record['patientName'] ?? 'N/A';
    final vaccine = record['vaccine'] ?? 'N/A';
    final status = record['status'] ?? 'N/A';

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
              // Time and Status Header with Selection Checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (_isSelectionMode) ...[
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) {
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryAqua.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: _primaryAqua,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        time,
                        style: TextStyle(
                          color: _darkDeepTeal,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 16),

              // Patient Name and Vaccine Info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: _mutedCoolGray),
                            const SizedBox(width: 6),
                            Text(
                              'Patient Name',
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
                          patientName,
                          style: TextStyle(
                            color: _darkDeepTeal,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.vaccines,
                              size: 16,
                              color: _mutedCoolGray,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Vaccine',
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
                          vaccine,
                          style: TextStyle(
                            color: _darkDeepTeal,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                          _showImmunizationDetails(
                            context,
                            record,
                          );
                        },
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text(
                          'View',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryAqua,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showEditDialog(context, record);
                        },
                        icon: Icon(Icons.edit, size: 16),
                        label: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryAqua,
                          side: BorderSide(color: _primaryAqua, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    switch (status) {
      case 'Completed':
        statusColor = Colors.green;
        break;
      case 'Scheduled':
        statusColor = Colors.orange;
        break;
      case 'In Progress':
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

  void _showImmunizationDetails(
    BuildContext context,
    Map<String, dynamic> record,
  ) {
    final patientName = record['patientName'] ?? 'N/A';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryAqua, _secondaryIceBlue],
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
                    Icon(Icons.vaccines, color: Colors.white, size: 28),
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
                      _buildDetailsSection('Patient Information', [
                        _buildDetailRowWithIcon(Icons.person, 'Patient Name', record['patientName']),
                        _buildDetailRowWithIcon(Icons.badge, 'Patient ID', record['patientId']),
                        _buildDetailRowWithIcon(Icons.cake, 'Age', record['age']),
                        _buildDetailRowWithIcon(Icons.phone, 'Contact Number', record['contactNumber']),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailsSection('Vaccine Information', [
                        _buildDetailRowWithIcon(Icons.vaccines, 'Vaccine Type', record['vaccine']),
                        _buildDetailRowWithIcon(Icons.business, 'Vaccine Brand', record['vaccineBrand']),
                        _buildDetailRowWithIcon(Icons.numbers, 'Batch/Lot Number', record['batchNumber']),
                        _buildDetailRowWithIcon(Icons.event_busy, 'Expiration Date', _formatDate(record['expirationDate'])),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailsSection('Administration Details', [
                        _buildDetailRowWithIcon(Icons.event, 'Administration Date', _formatDate(record['administrationDate'])),
                        _buildDetailRowWithIcon(Icons.access_time, 'Administration Time', record['administrationTime']),
                        _buildDetailRowWithIcon(Icons.filter_1, 'Dose Number', record['doseNumber']),
                        _buildDetailRowWithIcon(Icons.route, 'Route of Administration', record['routeOfAdministration']),
                        _buildDetailRowWithIcon(Icons.place, 'Injection Site', record['injectionSite']),
                        _buildDetailRowWithIcon(Icons.person_pin, 'Administered By', record['administeredBy']),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailsSection('Additional Information', [
                        _buildDetailRowWithIcon(Icons.warning_amber, 'Adverse Events', record['adverseEvents'] ?? 'None reported'),
                        _buildDetailRowWithIcon(Icons.event_available, 'Next Dose Due Date', _formatDate(record['nextDoseDueDate'])),
                        _buildDetailRowWithIcon(Icons.info, 'Status', record['status']),
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

  void _showEditDialog(BuildContext context, Map<String, dynamic> record) {
    // Parse patient name into first name and surname
    final patientName = record['patientName'] ?? '';
    final nameParts = patientName.split(' ');
    
    // Pre-fill controllers with existing data
    final firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts[0] : '',
    );
    final surnameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    final patientIdController = TextEditingController(text: record['patientId']);
    final ageController = TextEditingController(text: record['age']);
    final contactNumberController = TextEditingController(text: record['contactNumber']);

    String selectedVaccineType = record['vaccine'] ?? 'BCG Vaccine';
    final vaccineBrandController = TextEditingController(text: record['vaccineBrand']);
    final batchNumberController = TextEditingController(text: record['batchNumber']);
    DateTime? expirationDate;
    try {
      expirationDate = record['expirationDate'] != null && record['expirationDate'].isNotEmpty
          ? DateTime.parse(record['expirationDate'])
          : null;
    } catch (e) {
      expirationDate = null;
    }

    DateTime? administrationDate;
    try {
      administrationDate = record['administrationDate'] != null && record['administrationDate'].isNotEmpty
          ? DateTime.parse(record['administrationDate'])
          : DateTime.now();
    } catch (e) {
      administrationDate = DateTime.now();
    }
    
    TimeOfDay? administrationTime;
    try {
      final timeString = record['administrationTime'];
      if (timeString != null && timeString.isNotEmpty) {
        final parts = timeString.split(':');
        administrationTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else {
        administrationTime = TimeOfDay.now();
      }
    } catch (e) {
      administrationTime = TimeOfDay.now();
    }

    final doseNumberController = TextEditingController(text: record['doseNumber']);
    String selectedRouteOfAdministration = record['routeOfAdministration'] ?? 'Intramuscular (IM)';
    String selectedInjectionSite = record['injectionSite'] ?? 'Left Upper Arm';
    final administeredByController = TextEditingController(text: record['administeredBy']);
    final adverseEventsController = TextEditingController(text: record['adverseEvents']);
    DateTime? nextDoseDueDate;
    try {
      nextDoseDueDate = record['nextDoseDueDate'] != null && record['nextDoseDueDate'].isNotEmpty
          ? DateTime.parse(record['nextDoseDueDate'])
          : null;
    } catch (e) {
      nextDoseDueDate = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: _lightOffWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
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
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
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
                          Icons.edit,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Edit Immunization Record',
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
                        // Patient Details
                        _buildSectionHeader('Patient Details', Icons.person),
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
                                  controller: patientIdController,
                                  label: 'Patient ID',
                                  icon: Icons.badge,
                                  hintText: 'e.g., PAT-2026-001',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: ageController,
                                  label: 'Age',
                                  icon: Icons.cake,
                                  hintText: 'Enter age',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: contactNumberController,
                            label: 'Contact Number',
                            icon: Icons.phone,
                            hintText: 'e.g., +63 912 345 6789',
                            keyboardType: TextInputType.phone,
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Vaccine Details
                        _buildSectionHeader(
                          'Vaccine Details',
                          Icons.medical_services,
                        ),
                        _buildFormCard([
                          _buildDropdownField(
                            label: 'Vaccine Type',
                            value: selectedVaccineType,
                            icon: Icons.vaccines,
                            items: [
                              'BCG Vaccine',
                              'Hepatitis B',
                              'DPT Vaccine',
                              'Polio Vaccine',
                              'MMR Vaccine',
                              'Varicella Vaccine',
                              'Influenza',
                              'Pneumococcal',
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(
                                  () => selectedVaccineType = value,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: vaccineBrandController,
                            label: 'Vaccine Brand',
                            icon: Icons.business,
                            hintText: 'Enter vaccine brand/manufacturer',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: batchNumberController,
                            label: 'Batch/Lot Number',
                            icon: Icons.numbers,
                            hintText: 'Enter batch or lot number',
                          ),
                          const SizedBox(height: 16),
                          _buildModalDatePickerField(
                            context: context,
                            label: 'Expiration Date',
                            date: expirationDate,
                            icon: Icons.event_busy,
                            onTap: () async {
                              final picked = await _showModalDatePicker(
                                context,
                              );
                              if (picked != null) {
                                setModalState(() => expirationDate = picked);
                              }
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Administration Details
                        _buildSectionHeader(
                          'Administration Details',
                          Icons.medical_information,
                        ),
                        _buildFormCard([
                          _buildModalDatePickerField(
                            context: context,
                            label: 'Administration Date',
                            date: administrationDate,
                            icon: Icons.event,
                            onTap: () async {
                              final picked = await _showModalDatePicker(
                                context,
                              );
                              if (picked != null) {
                                setModalState(
                                  () => administrationDate = picked,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModalTimePickerField(
                            context: context,
                            label: 'Administration Time',
                            time: administrationTime,
                            icon: Icons.access_time,
                            onTap: () async {
                              final picked = await _showModalTimePicker(
                                context,
                                administrationTime,
                              );
                              if (picked != null) {
                                setModalState(
                                  () => administrationTime = picked,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: doseNumberController,
                            label: 'Dose Number',
                            icon: Icons.filter_1,
                            hintText: 'e.g., 1, 2, 3',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Route of Administration',
                            value: selectedRouteOfAdministration,
                            icon: Icons.route,
                            items: [
                              'Intramuscular (IM)',
                              'Subcutaneous (SC)',
                              'Intradermal (ID)',
                              'Oral',
                              'Intranasal',
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(
                                  () => selectedRouteOfAdministration = value,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Injection Site',
                            value: selectedInjectionSite,
                            icon: Icons.place,
                            items: [
                              'Left Upper Arm',
                              'Right Upper Arm',
                              'Left Thigh',
                              'Right Thigh',
                              'Abdomen',
                              'Buttocks',
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(
                                  () => selectedInjectionSite = value,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: administeredByController,
                            label: 'Administered By',
                            icon: Icons.person_pin,
                            hintText: 'Name of healthcare provider',
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Additional Information
                        _buildSectionHeader(
                          'Additional Information',
                          Icons.info_outline,
                        ),
                        _buildFormCard([
                          _buildTextField(
                            controller: adverseEventsController,
                            label: 'Adverse Events',
                            icon: Icons.warning_amber,
                            hintText: 'Any adverse reactions observed',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _buildModalDatePickerField(
                            context: context,
                            label: 'Next Dose Due Date',
                            date: nextDoseDueDate,
                            icon: Icons.event_available,
                            onTap: () async {
                              final picked = await _showModalDatePicker(
                                context,
                              );
                              if (picked != null) {
                                setModalState(
                                  () => nextDoseDueDate = picked,
                                );
                              }
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Update immunization record
                              final updatedRecord = {
                                'time':
                                    '${administrationTime?.hour.toString().padLeft(2, '0')}:${administrationTime?.minute.toString().padLeft(2, '0')}',
                                'patientName': '${firstNameController.text} ${surnameController.text}'.trim(),
                                'patientId': patientIdController.text,
                                'age': ageController.text,
                                'contactNumber': contactNumberController.text,
                                'vaccine': selectedVaccineType,
                                'vaccineBrand': vaccineBrandController.text,
                                'batchNumber': batchNumberController.text,
                                'expirationDate':
                                    expirationDate?.toIso8601String() ?? '',
                                'administrationDate':
                                    administrationDate?.toIso8601String() ?? '',
                                'administrationTime':
                                    '${administrationTime?.hour.toString().padLeft(2, '0')}:${administrationTime?.minute.toString().padLeft(2, '0')}',
                                'doseNumber': doseNumberController.text,
                                'routeOfAdministration':
                                    selectedRouteOfAdministration,
                                'injectionSite': selectedInjectionSite,
                                'administeredBy': administeredByController.text,
                                'adverseEvents': adverseEventsController.text,
                                'nextDoseDueDate':
                                    nextDoseDueDate?.toIso8601String() ?? '',
                                'status': record['status'] ?? 'Completed',
                                'date':
                                    administrationDate?.toIso8601String() ?? '',
                              };

                              // Update in database
                              final id = record['id']?.toString() ?? '';
                              if (id.isNotEmpty) {
                                await _dbHelper.updateRecord(id, updatedRecord);
                              }

                              // Reload records
                              await _loadRecords();

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Immunization record updated successfully!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
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
                              'Update Immunization Record',
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

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _mutedCoolGray,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
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

  Widget _buildDetailsSection(String title, List<Widget> children) {
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

  Widget _buildDetailRowWithIcon(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _primaryAqua),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: _mutedCoolGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value?.toString() ?? 'N/A',
                  style: TextStyle(
                    fontSize: 14,
                    color: _darkDeepTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
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
                  _isSelectionMode ? Icons.close : Icons.check_circle_outline,
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
                      color: _primaryAqua.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedIndices.length} selected',
                      style: TextStyle(
                        color: _primaryAqua,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Icon(Icons.arrow_drop_down, color: _primaryAqua),
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
                Expanded(
                  child: Text(
                    '${_selectedIndices.length} Record${_selectedIndices.length > 1 ? 's' : ''} Selected',
                    style: TextStyle(
                      color: _darkDeepTeal,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Select All Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndices.clear();
                        for (int i = 0; i < _getFilteredRecords().length; i++) {
                          _selectedIndices.add(i);
                        }
                      });
                    },
                    icon: Icon(Icons.select_all, size: 18),
                    label: Text(
                      'Select All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Delete Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _confirmDelete();
                    },
                    icon: Icon(Icons.delete, size: 18),
                    label: Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Cancel Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedIndices.clear();
                      });
                    },
                    icon: Icon(Icons.close, size: 18),
                    label: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
