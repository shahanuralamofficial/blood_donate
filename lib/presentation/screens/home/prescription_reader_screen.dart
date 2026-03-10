import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';

class PrescriptionReaderScreen extends ConsumerStatefulWidget {
  const PrescriptionReaderScreen({super.key});

  @override
  ConsumerState<PrescriptionReaderScreen> createState() => _PrescriptionReaderScreenState();
}

class _PrescriptionReaderScreenState extends ConsumerState<PrescriptionReaderScreen> {
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isProcessing = false;
  String _recognizedText = "";

  Future<void> _processImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _isProcessing = true;
      _recognizedText = "";
    });

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      setState(() {
        _recognizedText = recognizedText.text;
      });
      
      textRecognizer.close();
      
      if (_recognizedText.isNotEmpty) {
        _showResultDialog(_recognizedText);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.tr('no_data_found'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${ref.tr('error')}: $e")),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showResultDialog(String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.description_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text(ref.tr('prescription_reader')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ref.tr('prescription_disclaimer'),
                        style: const TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(text, style: GoogleFonts.poppins(fontSize: 14)),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.blue),
            onPressed: () => _flutterTts.speak(text),
          ),
          TextButton(
            onPressed: () {
              _flutterTts.stop();
              Navigator.pop(context);
            },
            child: Text(ref.tr('ok')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('prescription_reader')),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.document_scanner_rounded, size: 80, color: Colors.red.shade300),
            ),
            const SizedBox(height: 30),
            Text(
              ref.tr('prescription_reader'),
              style: GoogleFonts.notoSansBengali(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              ref.tr('tagline_text'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            if (_isProcessing)
              const CircularProgressIndicator(color: Colors.red)
            else
              Column(
                children: [
                  _buildActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: ref.tr('camera'),
                    onTap: () => _processImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 15),
                  _buildActionButton(
                    icon: Icons.photo_library_rounded,
                    label: ref.tr('gallery'),
                    onTap: () => _processImage(ImageSource.gallery),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
        ),
      ),
    );
  }
}
