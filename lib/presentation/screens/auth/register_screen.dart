import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedBloodGroup;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBloodGroup == null) {
      _showErrorSnackBar('রক্তের গ্রুপ নির্বাচন করুন');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = UserModel(
        uid: '', 
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsappNumber: _whatsappController.text.trim().isEmpty ? _phoneController.text.trim() : _whatsappController.text.trim(),
        role: 'user', 
        bloodGroup: _selectedBloodGroup,
      );

      await ref.read(authRepositoryProvider).signUpWithEmail(
            user,
            _passwordController.text.trim(),
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('রেজিস্ট্রেশন সফল হয়েছে। এখন লগইন করুন।'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('ত্রুটি: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.notoSansBengali()),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'নতুন অ্যাকাউন্ট',
                  style: GoogleFonts.notoSansBengali(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  'নিচের তথ্যগুলো দিয়ে রেজিস্ট্রেশন সম্পন্ন করুন',
                  style: GoogleFonts.notoSansBengali(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),
                
                _buildInputField(
                  controller: _nameController,
                  label: 'পুরো নাম',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v!.isEmpty ? 'আপনার নাম লিখুন' : null,
                ),
                const SizedBox(height: 16),
                
                _buildInputField(
                  controller: _emailController,
                  label: 'ইমেইল এড্রেস',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'ইমেইল লিখুন' : null,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _phoneController,
                        label: 'ফোন নম্বর',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'ফোন নম্বর লিখুন' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildBloodDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildInputField(
                  controller: _whatsappController,
                  label: 'হোয়াটসঅ্যাপ নম্বর (ঐচ্ছিক)',
                  icon: Icons.chat_bubble_outline_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                
                _buildInputField(
                  controller: _passwordController,
                  label: 'পাসওয়ার্ড',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) => v!.length < 6 ? 'কমপক্ষে ৬ ডিজিট দিন' : null,
                ),
                
                const SizedBox(height: 40),
                
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.red))
                else
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('রেজিস্ট্রেশন সম্পন্ন করুন', style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ইতিমধ্যে অ্যাকাউন্ট আছে? ', style: GoogleFonts.notoSansBengali(color: Colors.grey.shade600)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('লগইন করুন', style: GoogleFonts.notoSansBengali(color: const Color(0xFFE53935), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.notoSansBengali(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.red.shade400, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey, size: 20),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.red, width: 1)),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ব্লাড গ্রুপ', style: GoogleFonts.notoSansBengali(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedBloodGroup,
          items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
          onChanged: (v) => setState(() => _selectedBloodGroup = v),
          validator: (v) => v == null ? 'নির্বাচন করুন' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.bloodtype_outlined, color: Colors.red.shade400, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.red, width: 1)),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
