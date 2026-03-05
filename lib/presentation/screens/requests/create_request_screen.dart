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

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
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

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
  ];

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
    if (_selectedBloodGroup == null) return;

    final user = ref.read(currentUserDataProvider).value;
    if (user == null) return;

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
      whatsappNumber: _whatsappController.text.trim().isEmpty
          ? _phoneController.text.trim()
          : _whatsappController.text.trim(),
      division: _selectedDivision ?? '',
      district: _selectedDistrict ?? '',
      thana: _selectedThana ?? '',
      union: _selectedUnion ?? '',
      bloodBags: int.tryParse(_bagsController.text) ?? 1,
      donatedBags: 0,
      mapUrl: _mapUrlController.text.trim().isEmpty
          ? null
          : _mapUrlController.text.trim(),
      requiredDate: _selectedDate ?? DateTime.now(),
      createdAt: DateTime.now(),
    );

    try {
      // আবেদন তৈরি
      final String requestId = await ref.read(bloodRequestRepositoryProvider).createRequest(request);

      // নিকটস্থ দাতাদের নোটিফিকেশন পাঠানো
      NotificationService().notifyNearbyDonors(
        division: _selectedDivision ?? '',
        district: _selectedDistrict ?? '',
        thana: _selectedThana ?? '',
        bloodGroup: _selectedBloodGroup!,
        requestId: requestId,
      );

      // ইউজারের মোট আবেদনের সংখ্যা বাড়ানো
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
          const SnackBar(
            content: Text('আবেদনটি সফলভাবে পোস্ট করা হয়েছে'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'রক্তের আবেদন করুন',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('রক্তের তথ্য'),
                    const SizedBox(height: 8),
                    _buildBloodGroupSelector(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      _bagsController,
                      'রক্তের পরিমাণ (ব্যাগ)',
                      Icons.shopping_bag_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('রোগী ও যোগাযোগ'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _patientNameController,
                      'রোগীর নাম (ঐচ্ছিক)',
                      Icons.person_outline,
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _relationController,
                      'রোগীর সাথে আপনার সম্পর্ক',
                      Icons.people_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _phoneController,
                      'যোগাযোগের মোবাইল নম্বর',
                      Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _whatsappController,
                      'হোয়াটসঅ্যাপ নম্বর (ঐচ্ছিক)',
                      Icons.chat_bubble_outline,
                      keyboardType: TextInputType.phone,
                      isRequired: false,
                      hintText: 'খালি রাখলে ফোন নম্বরটিই ব্যবহৃত হবে',
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('হাসপাতালের তথ্য ও ঠিকানা'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _hospitalController,
                      'হাসপাতাল/ক্লিনিকের নাম',
                      Icons.local_hospital_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _problemController,
                      'রোগীর সমস্যা (রোগ)',
                      Icons.healing_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _mapUrlController,
                      'গুগল ম্যাপ লিঙ্ক বা অ্যাড্রেস (ঐচ্ছিক)',
                      Icons.location_on_outlined,
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _descriptionController,
                      'বিস্তারিত বিবরণ (ঐচ্ছিক)',
                      Icons.description_outlined,
                      maxLines: 3,
                      isRequired: false,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('অবস্থান নির্বাচন (Address)'),
                    const SizedBox(height: 12),
                    _buildLocationDropdowns(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('তারিখ ও গুরুত্ব'),
                    const SizedBox(height: 12),
                    _buildDatePicker(),
                    const SizedBox(height: 16),
                    _buildEmergencySwitch(),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'আবেদন সম্পন্ন করুন',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        alignLabelWithHint: true,
      ),
      validator: isRequired ? (v) => v!.isEmpty ? '$label লিখুন' : null : null,
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
      var districtData = districtsList.firstWhere(
        (e) => e['name'] == _selectedDistrict,
        orElse: () => null,
      );
      if (districtData != null) {
        var thanasList = districtData['thanas'] as List;
        thanas = thanasList.map((e) => e['name'].toString()).toList();
      }
    }
    List<String> unions = [];
    if (_selectedThana != null) {
      var districtsList = _allLocationData[_selectedDivision]['districts'] as List;
      var districtData = districtsList.firstWhere(
        (e) => e['name'] == _selectedDistrict,
        orElse: () => null,
      );
      var thanasList = districtData['thanas'] as List;
      var thanaData = thanasList.firstWhere(
        (e) => e['name'] == _selectedThana,
        orElse: () => null,
      );
      if (thanaData != null) {
        unions = List<String>.from(thanaData['unions']);
      }
    }
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedDivision,
          hint: const Text('বিভাগ'),
          items: divisions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() {
            _selectedDivision = v;
            _selectedDistrict = null;
            _selectedThana = null;
            _selectedUnion = null;
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedDistrict,
          hint: const Text('জেলা'),
          items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() {
            _selectedDistrict = v;
            _selectedThana = null;
            _selectedUnion = null;
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedThana,
          hint: const Text('থানা'),
          items: thanas.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() {
            _selectedThana = v;
            _selectedUnion = null;
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedUnion,
          hint: const Text('ইউনিয়ন (ঐচ্ছিক)'),
          items: unions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
          onChanged: (v) => setState(() => _selectedUnion = v),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? 'রক্তদানের সম্ভাব্য তারিখ'
                  : DateFormat('dd MMMM yyyy').format(_selectedDate!),
              style: TextStyle(
                color: _selectedDate == null ? Colors.grey.shade600 : Colors.black87,
              ),
            ),
            const Icon(Icons.calendar_month_rounded, color: Color(0xFFE53935)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySwitch() {
    return Container(
      decoration: BoxDecoration(
        color: _isEmergency ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEmergency ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: SwitchListTile(
        title: const Text(
          'এটি কি জরুরি (Emergency)?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        activeColor: Colors.red,
        value: _isEmergency,
        onChanged: (v) => setState(() => _isEmergency = v),
      ),
    );
  }

  Widget _buildBloodGroupSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _bloodGroups.map((bg) {
        bool isSelected = _selectedBloodGroup == bg;
        return InkWell(
          onTap: () => setState(() => _selectedBloodGroup = bg),
          child: Container(
            width: 70,
            height: 45,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE53935) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? const Color(0xFFE53935) : Colors.grey.shade300,
              ),
            ),
            child: Center(
              child: Text(
                bg,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.notoSansBengali(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey.shade700,
      ),
    );
  }
}
