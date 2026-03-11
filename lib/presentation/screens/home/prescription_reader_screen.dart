import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/medicine_service.dart';
import '../../providers/medicine_reminder_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';
import 'medicine_reminder_screen.dart';

class PrescriptionReaderScreen extends ConsumerStatefulWidget {
  const PrescriptionReaderScreen({super.key});

  @override
  ConsumerState<PrescriptionReaderScreen> createState() => _PrescriptionReaderScreenState();
}

class _PrescriptionReaderScreenState extends ConsumerState<PrescriptionReaderScreen> {
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isProcessing = false;
  List<MedicineResult> _results = [];

  @override
  void initState() {
    super.initState();
    MedicineService().init();
  }

  Future<void> _processImage(ImageSource source) async {
    String? imagePath;

    if (source == ImageSource.camera) {
      bool isCameraGranted = await Permission.camera.request().isGranted;
      if (!isCameraGranted) return;

      final directory = await getTemporaryDirectory();
      imagePath = path.join(directory.path, "${DateTime.now().millisecondsSinceEpoch}.jpeg");

      try {
        bool success = await EdgeDetection.detectEdge(
          imagePath,
          canUseGallery: true,
          androidScanTitle: ref.tr('scan_prescription'),
          androidCropTitle: ref.tr('crop_prescription'),
          androidCropBlackWhiteTitle: ref.tr('black_white'),
          androidCropReset: ref.tr('reset'),
        );
        if (!success) return;
      } catch (e) {
        debugPrint("Edge Detection Error: $e");
        return;
      }
    } else {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;
      imagePath = image.path;
    }

    setState(() {
      _isProcessing = true;
      _results = [];
    });

    try {
      final File imageFile = File(imagePath!);
      final Uint8List bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage != null) {
        img.Image processedImage = img.grayscale(originalImage);
        processedImage = img.adjustColor(processedImage, contrast: 1.2);
        
        final directory = await getTemporaryDirectory();
        final processedPath = path.join(directory.path, "processed_${DateTime.now().millisecondsSinceEpoch}.jpg");
        await File(processedPath).writeAsBytes(img.encodeJpg(processedImage));
        imagePath = processedPath;
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      final cleanedLines = _parseAndCleanText(recognizedText.text);
      final processedResults = MedicineService().processPrescriptionText(cleanedLines);
      
      setState(() {
        _results = processedResults;
      });
      
      textRecognizer.close();
      
      if (_results.isNotEmpty) {
        _showResultDialog();
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

  // Helper to parse reminder times from dose (1+0+1)
  List<String> _parseTimesFromDose(String dose) {
    List<String> times = [];
    final parts = dose.split(RegExp(r'[\+\-]'));
    if (parts.isNotEmpty && parts[0].trim() != '0') times.add("08:00");
    if (parts.length >= 2 && parts[1].trim() != '0') times.add("14:00");
    if (parts.length >= 3 && parts[2].trim() != '0') times.add("20:00");
    return times.isEmpty ? ["09:00"] : times;
  }

  // Helper to parse duration (7 days)
  int _parseDuration(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    if (match != null) return int.parse(match.group(0)!);
    return 7;
  }

  String _parseAndCleanText(String rawText) {
    return rawText.split('\n')
        .map((line) => line.trim())
        .where((line) => line.length > 2)
        .join('\n');
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ref.tr('ai_analysis_result'), style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(ref.tr('edit_if_needed'), style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 15),
                  ...List.generate(_results.length, (index) {
                    final result = _results[index];
                    Color confidenceColor = Colors.red;
                    if (result.confidence > 0.8) confidenceColor = Colors.green;
                    else if (result.confidence > 0.5) confidenceColor = Colors.orange;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: confidenceColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: result.medicineName ?? result.originalLine,
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                                  onChanged: (val) => _results[index] = MedicineResult(
                                    originalLine: result.originalLine,
                                    medicineName: val,
                                    dose: result.dose,
                                    duration: result.duration,
                                    confidence: result.confidence,
                                  ),
                                ),
                              ),
                              Icon(Icons.edit_rounded, size: 14, color: Colors.grey.shade400),
                            ],
                          ),
                          if (result.dose != null || result.duration != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 8),
                              child: Row(
                                children: [
                                  if (result.dose != null)
                                    _buildInfoTag(result.dose!, Colors.blue),
                                  if (result.duration != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: _buildInfoTag(result.duration!, Colors.purple),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _flutterTts.stop();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(ref.tr('cancel'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _flutterTts.stop();
                      Navigator.pop(context);
                      
                      // Save reminders for detected medicines
                      for (var result in _results) {
                        if (result.medicineName != null) {
                          ref.read(medicineReminderProvider.notifier).addReminder(
                            name: result.medicineName!,
                            dose: result.dose ?? "1+0+1",
                            times: _parseTimesFromDose(result.dose ?? "1+0+1"),
                            duration: _parseDuration(result.duration ?? "7 days"),
                          );
                        }
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ref.tr('medicine_saved_with_reminder')),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: ref.tr('view'),
                            textColor: Colors.white,
                            onPressed: () {
                              // Navigator.push to MedicineReminderScreen
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(ref.tr('confirm'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(ref.tr('prescription_reader'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFE53935).withOpacity(0.05), Colors.white],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), shape: BoxShape.circle),
                ),
                Icon(Icons.document_scanner_rounded, size: 70, color: Colors.red.shade600),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              ref.tr('prescription_reader'),
              style: GoogleFonts.notoSansBengali(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              ref.tr('ai_reader_hint'),
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansBengali(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 50),
            if (_isProcessing)
              Column(
                children: [
                  const CircularProgressIndicator(color: Colors.red),
                  const SizedBox(height: 16),
                  Text(ref.tr('processing_image'), style: GoogleFonts.notoSansBengali(color: Colors.red, fontWeight: FontWeight.w600)),
                ],
              )
            else
              Column(
                children: [
                  _buildActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: ref.tr('camera'),
                    onTap: () => _processImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.photo_library_rounded,
                    label: ref.tr('gallery'),
                    onTap: () => _processImage(ImageSource.gallery),
                    isSecondary: true,
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MedicineReminderScreen()),
                      );
                    },
                    icon: const Icon(Icons.edit_note_rounded, color: Colors.grey),
                    label: Text(
                      ref.tr('add_reminder_manually'),
                      style: GoogleFonts.notoSansBengali(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, bool isSecondary = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isSecondary ? Colors.grey : Colors.red).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Text(label, style: GoogleFonts.notoSansBengali(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.white : const Color(0xFFE53935),
          foregroundColor: isSecondary ? Colors.black87 : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: isSecondary ? BorderSide(color: Colors.grey.shade200) : BorderSide.none,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
