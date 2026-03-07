import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/blood_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../providers/language_provider.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _relationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _problemController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bagsController = TextEditingController(text: '1');
  final _mapUrlController = TextEditingController();

  String? _selectedBloodGroup;
  bool _isEmergency = false;
  DateTime? _selectedDate;
  Map<String, dynamic> _allLocationData = {};
  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedThana;
  String? _selectedUnion;
  bool _isLoadingData = true;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final String response = await rootBundle.loadString('assets/unions.json');
      final List<dynamic> dataList = json.decode(response);
      Map<String, dynamic> tempMap = {};
      for (var div in dataList) {
        tempMap[div['name']] = div;
      }
      setState(() {
        _allLocationData = tempMap;
        _isLoadingData = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBloodGroup == null) {
      _showErrorSnackBar(ref.tr('select_blood_group'));
      return;
    }
    if (_selectedDivision == null || _selectedDistrict == null || _selectedThana == null) {
      _showErrorSnackBar(ref.tr('select_div_dist_thana'));
      return;
    }

    final user = ref.read(currentUserDataProvider).value;
    if (user == null) return;

    setState(() => _isLoadingData = true);
    
    final request = BloodRequestModel(
      requestId: '',
      requesterId: user.uid,
      bloodGroup: _selectedBloodGroup!,
      status: 'pending',
      isEmergency: _isEmergency,
      patientName: _patientNameController.text.trim(),
      relationWithPatient: _relationController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      hospitalName: _hospitalController.text.trim(),
      patientProblem: _problemController.text.trim(),
      description: _descriptionController.text.trim(),
      whatsappNumber: _whatsappController.text.trim().isEmpty ? _phoneController.text.trim() : _whatsappController.text.trim(),
      division: _selectedDivision ?? '',
      district: _selectedDistrict ?? '',
      thana: _selectedThana ?? '',
      union: _selectedUnion ?? '',
      bloodBags: int.tryParse(_bagsController.text) ?? 1,
      donatedBags: 0,
      mapUrl: _mapUrlController.text.trim().isEmpty ? null : _mapUrlController.text.trim(),
      requiredDate: _selectedDate ?? DateTime.now(),
      createdAt: DateTime.now(),
    );

    try {
      final String requestId = await ref.read(bloodRequestRepositoryProvider).createRequest(request);

      NotificationService().notifyNearbyDonors(
        division: _selectedDivision ?? '',
        district: _selectedDistrict ?? '',
        thana: _selectedThana ?? '',
        bloodGroup: _selectedBloodGroup!,
        requestId: requestId,
      );

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (snapshot.exists) {
          int currentRequests = snapshot.data()?['totalRequests'] ?? 0;
          transaction.update(userRef, {'totalRequests': currentRequests + 1});
        }
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.tr('request_submit_success'), style: GoogleFonts.notoSansBengali()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('${ref.tr('error')}: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.notoSansBengali()),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(ref.tr('blood_request_form'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingData && _allLocationData.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormCard(
                      title: ref.tr('blood_info'),
                      icon: Icons.bloodtype_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBloodGroupSelector(),
                          const SizedBox(height: 20),
                          _buildInputField(
                            controller: _bagsController,
                            label: ref.tr('blood_bags_count'),
                            icon: Icons.shopping_bag_outlined,
                            keyboardType: TextInputType.number,
                            hintText: ref.tr('bags_hint'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildFormCard(
                      title: ref.tr('patient_contact'),
                      icon: Icons.person_search_outlined,
                      child: Column(
                        children: [
                          _buildInputField(
                            controller: _patientNameController,
                            label: ref.tr('patient_name_opt'),
                            icon: Icons.person_outline,
                            isRequired: false,
                            hintText: ref.tr('patient_name_hint'),
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _relationController,
                            label: ref.tr('relation_with_patient'),
                            icon: Icons.people_outline,
                            hintText: ref.tr('relation_hint'),
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _phoneController,
                            label: ref.tr('contact_phone'),
                            icon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                            hintText: ref.tr('phone_hint'),
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _whatsappController,
                            label: ref.tr('whatsapp_num_opt'),
                            icon: Icons.chat_bubble_outline,
                            keyboardType: TextInputType.phone,
                            isRequired: false,
                            hintText: ref.tr('whatsapp_hint'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildFormCard(
                      title: ref.tr('hospital_info_address'),
                      icon: Icons.local_hospital_outlined,
                      child: Column(
                        children: [
                          _buildInputField(
                            controller: _hospitalController,
                            label: ref.tr('hospital_name'),
                            icon: Icons.apartment_outlined,
                            hintText: ref.tr('hospital_hint'),
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _problemController,
                            label: ref.tr('patient_problem'),
                            icon: Icons.healing_outlined,
                            hintText: ref.tr('problem_hint'),
                          ),
                          const SizedBox(height: 20),
                          _buildLocationDropdowns(),
                          const SizedBox(height: 20),
                          _buildInputField(
                            controller: _mapUrlController,
                            label: ref.tr('map_url_opt'),
                            icon: Icons.location_on_outlined,
                            isRequired: false,
                            hintText: ref.tr('map_url_hint'),
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _descriptionController,
                            label: ref.tr('detailed_description'),
                            icon: Icons.description_outlined,
                            maxLines: 3,
                            isRequired: false,
                            hintText: ref.tr('description_hint'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildFormCard(
                      title: ref.tr('date_and_urgency'),
                      icon: Icons.event_available_outlined,
                      child: Column(
                        children: [
                          _buildDatePicker(),
                          const SizedBox(height: 16),
                          _buildEmergencySwitch(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    if (_isLoadingData)
                      const Center(child: CircularProgressIndicator(color: Colors.red))
                    else
                      ElevatedButton(
                        onPressed: _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 58),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 2,
                          shadowColor: Colors.red.withOpacity(0.4),
                        ),
                        child: Text(
                          ref.tr('submit_request'),
                          style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFE53935), size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.notoSansBengali(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
              ),
            ],
          ),
          const Divider(height: 25, thickness: 0.5),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.red.shade400, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
        errorStyle: const TextStyle(fontSize: 11),
      ),
      validator: isRequired ? (v) => v!.isEmpty ? ref.tr('enter_value').replaceFirst('{}', label) : null : null,
    );
  }

  Widget _buildLocationDropdowns() {
    List<String> divisions = _allLocationData.keys.toList();
    List<String> districts = [];
    if (_selectedDivision != null && _allLocationData.containsKey(_selectedDivision)) {
      var districtsList = _allLocationData[_selectedDivision]['districts'] as List;
      districts = districtsList.map((e) => e['name'].toString()).toList();
    }
    List<String> thanas = [];
    if (_selectedDistrict != null) {
      var districtsList = _allLocationData[_selectedDivision]['districts'] as List;
      var districtData = districtsList.firstWhere((e) => e['name'] == _selectedDistrict, orElse: () => null);
      if (districtData != null) {
        var thanasList = districtData['thanas'] as List;
        thanas = thanasList.map((e) => e['name'].toString()).toList();
      }
    }
    List<String> unions = [];
    if (_selectedThana != null) {
      var districtsList = _allLocationData[_selectedDivision]['districts'] as List;
      var districtData = districtsList.firstWhere((e) => e['name'] == _selectedDistrict, orElse: () => null);
      var thanasList = districtData['thanas'] as List;
      var thanaData = thanasList.firstWhere((e) => e['name'] == _selectedThana, orElse: () => null);
      if (thanaData != null) unions = List<String>.from(thanaData['unions']);
    }

    return Column(
      children: [
        _buildDropdown(value: _selectedDivision, hint: ref.tr('select_division'), items: divisions, onChanged: (v) => setState(() {
          _selectedDivision = v; _selectedDistrict = null; _selectedThana = null; _selectedUnion = null;
        })),
        const SizedBox(height: 12),
        _buildDropdown(value: _selectedDistrict, hint: ref.tr('select_district'), items: districts, onChanged: (v) => setState(() {
          _selectedDistrict = v; _selectedThana = null; _selectedUnion = null;
        })),
        const SizedBox(height: 12),
        _buildDropdown(value: _selectedThana, hint: ref.tr('select_thana'), items: thanas, onChanged: (v) => setState(() {
          _selectedThana = v; _selectedUnion = null;
        })),
        const SizedBox(height: 12),
        _buildDropdown(value: _selectedUnion, hint: ref.tr('union_opt'), items: unions, onChanged: (v) => setState(() => _selectedUnion = v), isRequired: false),
      ],
    );
  }

  Widget _buildDropdown({required String? value, required String hint, required List<String> items, required Function(String?) onChanged, bool isRequired = true}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
      validator: isRequired ? (v) => v == null ? ref.tr('select_info') : null : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.redAccent, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53935))),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.red)), child: child!),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                Text(
                  _selectedDate == null ? ref.tr('probable_donation_date') : DateFormat('dd MMMM yyyy', ref.watch(languageProvider).languageCode).format(_selectedDate!),
                  style: TextStyle(color: _selectedDate == null ? Colors.grey.shade600 : Colors.black87, fontSize: 15),
                ),
              ],
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySwitch() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _isEmergency ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isEmergency ? Colors.red.shade300 : Colors.grey.shade200, width: 1),
      ),
      child: SwitchListTile(
        title: Text(ref.tr('is_emergency_question'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 14, color: _isEmergency ? Colors.red.shade900 : Colors.black87)),
        secondary: Icon(Icons.warning_amber_rounded, color: _isEmergency ? Colors.red : Colors.grey),
        activeColor: Colors.red,
        value: _isEmergency,
        onChanged: (v) => setState(() => _isEmergency = v),
      ),
    );
  }

  Widget _buildBloodGroupSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ref.tr('blood_group_select'), style: GoogleFonts.notoSansBengali(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _bloodGroups.map((bg) {
            bool isSelected = _selectedBloodGroup == bg;
            return InkWell(
              onTap: () => setState(() => _selectedBloodGroup = bg),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 65, height: 45,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE53935) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? const Color(0xFFE53935) : Colors.grey.shade300),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
                ),
                child: Center(
                  child: Text(bg, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
