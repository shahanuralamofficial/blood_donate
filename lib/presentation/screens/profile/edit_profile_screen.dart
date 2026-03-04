import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
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

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _genders = ['পুরুষ', 'মহিলা', 'অন্যান্য'];
  final List<String> _divisions = ['ঢাকা', 'চট্টগ্রাম', 'রাজশাহী', 'খুলনা', 'বরিশাল', 'সিলেট', 'রংপুর', 'ময়মনসিংহ'];

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

    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'whatsappNumber': _whatsappController.text.trim().isEmpty ? _phoneController.text.trim() : _whatsappController.text.trim(),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('প্রোফাইল আপডেট সফল হয়েছে!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('এরর: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('প্রোফাইল এডিট', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('পুরো নাম', _nameController, Icons.person_outline),
              const SizedBox(height: 20),
              _buildTextField('মোবাইল নম্বর', _phoneController, Icons.phone_outlined, isPhone: true),
              const SizedBox(height: 20),
              _buildTextField('হোয়াটসঅ্যাপ নম্বর', _whatsappController, Icons.chat_bubble_outline, isPhone: true),
              const SizedBox(height: 20),
              _buildTextField('ইমেইল', _emailController, Icons.email_outlined),
              const SizedBox(height: 24),
              Text('রক্তের গ্রুপ ও লিঙ্গ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDropdown('গ্রুপ', _bloodGroups, _selectedBloodGroup, (v) => setState(() => _selectedBloodGroup = v))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('লিঙ্গ', _genders, _selectedGender, (v) => setState(() => _selectedGender = v))),
                ],
              ),
              const SizedBox(height: 24),
              Text('ঠিকানা', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              _buildDropdown('বিভাগ', _divisions, _selectedDivision, (v) => setState(() => _selectedDivision = v)),
              const SizedBox(height: 16),
              _buildTextField('জেলা', TextEditingController(text: _selectedDistrict), Icons.location_city, onChanged: (v) => _selectedDistrict = v),
              const SizedBox(height: 16),
              _buildTextField('থানা', TextEditingController(text: _selectedThana), Icons.map_outlined, onChanged: (v) => _selectedThana = v),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isAvailable ? Colors.green.shade100 : Colors.red.shade100),
                ),
                child: SwitchListTile(
                  title: Text('আমি রক্ত দিতে ইচ্ছুক', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(_isAvailable ? 'আপনার প্রোফাইল রক্তদাতা হিসেবে প্রদর্শিত হবে' : 'আপনার প্রোফাইল বর্তমানে রক্তদাতা হিসেবে প্রদর্শিত হবে না', style: const TextStyle(fontSize: 12)),
                  value: _isAvailable,
                  activeColor: Colors.green,
                  onChanged: (v) => setState(() => _isAvailable = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('পরিবর্তন সংরক্ষণ করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPhone = false, Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (v) => v!.isEmpty ? 'তথ্য দিন' : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selected, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}
