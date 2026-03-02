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
  final _passwordController = TextEditingController();
  String? _selectedBloodGroup;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রক্তের গ্রুপ নির্বাচন করুন')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = UserModel(
        uid: '', 
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: 'user', 
        bloodGroup: _selectedBloodGroup, // ব্লাড গ্রুপ এখানে পাস করা হয়েছে
      );

      await ref.read(authRepositoryProvider).signUpWithEmail(
            user,
            _passwordController.text.trim(),
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('রেজিস্ট্রেশন সফল হয়েছে। এখন লগইন করুন।'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('রেজিস্ট্রেশন করুন', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'নতুন অ্যাকাউন্ট তৈরি করুন',
                style: GoogleFonts.notoSansBengali(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'পুরো নাম', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v!.isEmpty ? 'নাম লিখুন' : null,
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'ইমেইল', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => v!.isEmpty ? 'ইমেইল লিখুন' : null,
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'ফোন নম্বর', prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) => v!.isEmpty ? 'ফোন নম্বর লিখুন' : null,
              ),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                items: _bloodGroups
                    .map((bg) => DropdownMenuItem(
                          value: bg,
                          child: Text(bg),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBloodGroup = v),
                decoration: const InputDecoration(labelText: 'আপনার রক্তের গ্রুপ', prefixIcon: Icon(Icons.bloodtype_outlined)),
                validator: (v) => v == null ? 'রক্তের গ্রুপ বাছাই করুন' : null,
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'পাসওয়ার্ড',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v!.length < 6 ? 'কমপক্ষে ৬ ডিজিট দিন' : null,
              ),
              const SizedBox(height: 35),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.red))
              else
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
                  child: Text('রেজিস্ট্রেশন সম্পন্ন করুন', style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ইতিমধ্যে অ্যাকাউন্ট আছে? '),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('লগইন করুন', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
