import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/donor_model.dart';
import '../../providers/auth_provider.dart';

class DonorProfileScreen extends ConsumerStatefulWidget {
  const DonorProfileScreen({super.key});

  @override
  ConsumerState<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends ConsumerState<DonorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _availability = true;
  String? _selectedBloodGroup;
  
  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedThana;
  String? _selectedUnion;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  final Map<String, List<String>> _districts = {
    'ঢাকা': ['ঢাকা', 'গাজীপুর', 'নারায়ণগঞ্জ', 'সাভার'],
    'রাজশাহী': ['নওগাঁ', 'বগুড়া', 'রাজশাহী', 'নাটোর', 'জয়পুরহাট'],
    'চট্টগ্রাম': ['চট্টগ্রাম', 'কক্সবাজার', 'কুমিল্লা', 'ফেনী'],
  };

  final Map<String, List<String>> _thanas = {
    'নওগাঁ': ['পত্নীতলা', 'ধামইরহাট', 'মহাদেবপুর', 'সাপাহার'],
    'বগুড়া': ['বগুড়া সদর', 'শেরপুর', 'শাজাহানপুর', 'দুপচাঁচিয়া'],
    'ঢাকা': ['মিরপুর', 'গুলশান', 'ধানমন্ডি', 'উত্তরা'],
  };

  final Map<String, List<String>> _unions = {
    'পত্নীতলা': ['ঘোষনগর', 'নির্মইল', 'আকবরপুর', 'পত্নীতলা সদর'],
  };

  final List<String> _divisions = ['ঢাকা', 'চট্টগ্রাম', 'রাজশাহী', 'খুলনা', 'বরিশাল', 'সিলেট', 'রংপুর', 'ময়মনসিংহ'];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() async {
    final userAuth = FirebaseAuth.instance.currentUser;
    if (userAuth == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userAuth.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _selectedBloodGroup = data['bloodGroup'];
        
        if (data['address'] != null) {
          String? div = data['address']['division'];
          String? dist = data['address']['district'];
          String? th = data['address']['thana'];
          String? un = data['address']['union'];

          setState(() {
            _selectedDivision = _divisions.contains(div) ? div : null;
            _selectedDistrict = (_districts[_selectedDivision] ?? []).contains(dist) ? dist : null;
            _selectedThana = (_thanas[_selectedDistrict] ?? []).contains(th) ? th : null;
            _selectedUnion = (_unions[_selectedThana] ?? []).contains(un) ? un : null;
          });
        }
      }

      final donorDoc = await FirebaseFirestore.instance.collection('donors').doc(userAuth.uid).get();
      if (donorDoc.exists) {
        final donor = DonorModel.fromMap(donorDoc.data()!);
        setState(() {
          _availability = donor.availability;
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('লগআউট'),
        content: const Text('আপনি কি নিশ্চিত যে আপনি লগআউট করতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('না')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authRepositoryProvider).signOut();
              Navigator.pop(context); 
            },
            child: const Text('হ্যাঁ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userAuth = FirebaseAuth.instance.currentUser;
    if (userAuth == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    try {
      final String uid = userAuth.uid;

      final Map<String, dynamic> donorData = {
        'uid': uid,
        'availability': _availability,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'address': {
          'division': _selectedDivision,
          'district': _selectedDistrict,
          'thana': _selectedThana,
          'union': _selectedUnion,
        }
      };

      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.set(FirebaseFirestore.instance.collection('donors').doc(uid), donorData, SetOptions(merge: true));
      batch.set(FirebaseFirestore.instance.collection('users').doc(uid), userData, SetOptions(merge: true));

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Close loading
        ref.invalidate(currentUserDataProvider); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('প্রোফাইল সফলভাবে সংরক্ষিত হয়েছে!')));
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context); 
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('এরর: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল সেটিংস'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _showLogoutDialog,
            tooltip: 'লগআউট',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('আপনার নাম ও মোবাইল'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'পুরো নাম', prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'নাম লিখুন' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'মোবাইল নম্বর', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'নম্বর দিন' : null,
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('রক্তের গ্রুপ'),
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                hint: const Text('রক্তের গ্রুপ নির্বাচন করুন'),
                items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                onChanged: (v) => setState(() => _selectedBloodGroup = v),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.bloodtype), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('বর্তমান ঠিকানা'),
              _buildLocationDropdowns(),
              
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: SwitchListTile(
                  title: const Text('রক্ত দিতে পারবেন?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  value: _availability,
                  activeColor: Colors.red,
                  onChanged: (v) => setState(() => _availability = v),
                ),
              ),
              
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('প্রোফাইল সংরক্ষণ করুন'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDropdowns() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedDivision,
          hint: const Text('বিভাগ'),
          items: _divisions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() { _selectedDivision = v; _selectedDistrict = null; _selectedThana = null; _selectedUnion = null; }),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedDistrict,
          hint: const Text('জেলা'),
          items: (_districts[_selectedDivision] ?? []).map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() { _selectedDistrict = v; _selectedThana = null; _selectedUnion = null; }),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedThana,
          hint: const Text('থানা'),
          items: (_thanas[_selectedDistrict] ?? []).map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() { _selectedThana = v; _selectedUnion = null; }),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedUnion,
          hint: const Text('ইউনিয়ন (ঐচ্ছিক)'),
          items: (_unions[_selectedThana] ?? []).map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
          onChanged: (v) => setState(() => _selectedUnion = v),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }
}
