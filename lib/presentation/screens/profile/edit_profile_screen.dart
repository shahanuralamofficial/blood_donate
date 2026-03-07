import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../../data/models/user_model.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  
  String? _selectedBloodGroup;
  String? _selectedGender;
  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedThana;
  bool _isAvailable = true;
  bool _isLoadingData = true;
  Map<String, dynamic> _allLocationData = {};

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _genderIds = ['male', 'female', 'others'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _whatsappController = TextEditingController(text: widget.user.whatsappNumber ?? widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedBloodGroup = widget.user.bloodGroup;
    _selectedGender = widget.user.gender;
    _isAvailable = widget.user.isAvailable;
    
    if (widget.user.address != null) {
      _selectedDivision = widget.user.address!['division'];
      _selectedDistrict = widget.user.address!['district'];
      _selectedThana = widget.user.address!['thana'];
    }
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = widget.user.uid;
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.tr('error_try_again')), backgroundColor: Colors.red));
      return;
    }

    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      final phone = _phoneController.text.trim();
      final whatsapp = _whatsappController.text.trim();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'phone': phone,
        'whatsappNumber': whatsapp.isEmpty ? phone : whatsapp,
        'email': _emailController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'gender': _selectedGender,
        'isAvailable': _isAvailable,
        'address': {
          'division': _selectedDivision,
          'district': _selectedDistrict,
          'thana': _selectedThana,
        }
      });

      if (mounted) {
        Navigator.pop(context); // Close loading
        ref.invalidate(currentUserDataProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.tr('profile_update_success'), style: GoogleFonts.notoSansBengali()), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ref.tr('error')}: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> divisions = _allLocationData.keys.toList();
    List<String> districts = [];
    if (_selectedDivision != null && _allLocationData.containsKey(_selectedDivision)) {
      var districtsList = _allLocationData[_selectedDivision]['districts'] as List;
      districts = districtsList.map((e) => e['name'].toString()).toList();
    }
    List<String> thanas = [];
    if (_selectedDistrict != null && _selectedDivision != null) {
      var districtsList = _allLocationData[_selectedDivision]['districts'] as List;
      var districtData = districtsList.firstWhere((e) => e['name'] == _selectedDistrict, orElse: () => null);
      if (districtData != null) {
        var thanasList = districtData['thanas'] as List;
        thanas = thanasList.map((e) => e['name'].toString()).toList();
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(ref.tr('edit_profile'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: _isLoadingData 
        ? const Center(child: CircularProgressIndicator(color: Colors.red))
        : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: ref.tr('personal_info'),
                icon: Icons.person_outline_rounded,
                child: Column(
                  children: [
                    _buildTextField(ref.tr('full_name'), _nameController, Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField(ref.tr('email_address'), _emailController, Icons.email_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              _buildSectionCard(
                title: ref.tr('contact'),
                icon: Icons.contact_phone_outlined,
                child: Column(
                  children: [
                    _buildTextField(ref.tr('phone_number'), _phoneController, Icons.phone_outlined, isPhone: true),
                    const SizedBox(height: 16),
                    _buildTextField(ref.tr('whatsapp_number'), _whatsappController, Icons.chat_bubble_outline, isPhone: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: '${ref.tr('blood_group')} & ${ref.tr('gender')}',
                icon: Icons.info_outline_rounded,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDropdown(ref.tr('group'), _bloodGroups, _selectedBloodGroup, (v) => setState(() => _selectedBloodGroup = v))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown(ref.tr('gender'), _genderIds, _selectedGender, (v) => setState(() => _selectedGender = v), isGender: true)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: ref.tr('address'),
                icon: Icons.location_on_outlined,
                child: Column(
                  children: [
                    _buildDropdown(ref.tr('division'), divisions, _selectedDivision, (v) => setState(() {
                      _selectedDivision = v; _selectedDistrict = null; _selectedThana = null;
                    })),
                    const SizedBox(height: 12),
                    _buildDropdown(ref.tr('district'), districts, _selectedDistrict, (v) => setState(() {
                      _selectedDistrict = v; _selectedThana = null;
                    })),
                    const SizedBox(height: 12),
                    _buildDropdown(ref.tr('thana'), thanas, _selectedThana, (v) => setState(() => _selectedThana = v)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: _isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _isAvailable ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: SwitchListTile(
                  title: Text(ref.tr('willing_to_donate'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(_isAvailable ? ref.tr('profile_visible_msg') : ref.tr('profile_hidden_msg'), style: const TextStyle(fontSize: 12)),
                  value: _isAvailable,
                  activeColor: Colors.green,
                  onChanged: (v) => setState(() => _isAvailable = v),
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 58),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  shadowColor: Colors.red.withOpacity(0.3),
                ),
                child: Text(ref.tr('save_changes'), style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.notoSansBengali(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
            ],
          ),
          const Divider(height: 24, thickness: 0.5),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPhone = false}) {
    String hint = '';
    if (label == ref.tr('full_name')) hint = ref.tr('name_hint');
    else if (label == ref.tr('email_address')) hint = ref.tr('email_hint');
    else if (label == ref.tr('phone_number')) hint = ref.tr('phone_hint');
    else if (label == ref.tr('whatsapp_number')) hint = ref.tr('whatsapp_hint');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.notoSansBengali(fontSize: 13, color: Colors.grey.shade400),
            prefixIcon: Icon(icon, size: 20, color: Colors.red.shade300),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
            errorStyle: const TextStyle(fontSize: 11),
          ),
          validator: (v) => (v == null || v.isEmpty) && label != ref.tr('email_address') && label != ref.tr('whatsapp_number') ? ref.tr('enter_info') : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selected, Function(String?) onChanged, {bool isGender = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: (selected != null && items.contains(selected)) ? selected : null,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          decoration: InputDecoration(
            prefixIcon: Icon(isGender ? Icons.person_outline : Icons.bloodtype_outlined, size: 20, color: Colors.red.shade300),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
            errorStyle: const TextStyle(fontSize: 11),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(isGender ? ref.tr(e) : e, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? ref.tr('select_info') : null,
        ),
      ],
    );
  }
}
