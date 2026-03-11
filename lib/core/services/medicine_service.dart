import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:string_similarity/string_similarity.dart';

class MedicineResult {
  final String originalLine;
  final String? medicineName;
  final String? dose;
  final String? duration;
  final double confidence;

  MedicineResult({
    required this.originalLine,
    this.medicineName,
    this.dose,
    this.duration,
    this.confidence = 0.0,
  });

  @override
  String toString() {
    if (medicineName == null) return originalLine;
    String result = medicineName!;
    if (dose != null) result += " ($dose)";
    if (duration != null) result += " - $duration";
    return result;
  }
}

class MedicineService {
  static final MedicineService _instance = MedicineService._internal();
  factory MedicineService() => _instance;
  MedicineService._internal();

  List<String> _medicineNames = [];
  bool _isLoaded = false;

  // Common Patterns
  final RegExp _doseRegex = RegExp(r'(\d\s?[\+\-]\s?\d\s?[\+\-]\s?\d)'); // 1+0+1, 1-0-1
  final RegExp _durationRegex = RegExp(r'(\d+\s?(days|day|month|months|week|weeks|দিন|মাস|সপ্তাহ))', caseSensitive: false);

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final String rawCsv = await rootBundle.loadString('assets/medicine.csv');
      List<List<dynamic>> rows = const CsvToListConverter().convert(rawCsv);
      
      for (var row in rows) {
        if (row.isNotEmpty) {
          _medicineNames.add(row[0].toString().trim());
        }
      }
      _isLoaded = true;
    } catch (e) {
      print("Error loading medicine CSV: $e");
    }
  }

  String _findBestMatch(String input, {double threshold = 0.6}) {
    if (!_isLoaded || _medicineNames.isEmpty || input.length < 3) return input;

    BestMatch match = input.bestMatch(_medicineNames);
    if (match.bestMatch.rating! > threshold) {
      return match.bestMatch.target!;
    }
    return input;
  }

  List<MedicineResult> processPrescriptionText(String rawText) {
    List<String> lines = rawText.split('\n');
    List<MedicineResult> results = [];

    for (var line in lines) {
      String trimmedLine = line.trim();
      if (trimmedLine.length < 3) continue;

      // Extract Dose (1+0+1)
      String? dose = _doseRegex.firstMatch(trimmedLine)?.group(0);
      
      // Extract Duration (5 days)
      String? duration = _durationRegex.firstMatch(trimmedLine)?.group(0);

      // Clean line for medicine name extraction
      String cleanForMatch = trimmedLine
          .replaceAll(_doseRegex, '')
          .replaceAll(_durationRegex, '')
          .replaceAll(RegExp(r'^(Tab\.|Cap\.|Syp\.|Inj\.|Susp\.|Tab|Cap|Syp|Inj|Susp)\s*', caseSensitive: false), '')
          .trim();

      // Usually the first 1-2 words are the medicine name
      List<String> words = cleanForMatch.split(' ');
      String searchName = words.isNotEmpty ? words[0] : "";
      if (words.length > 1 && words[1].length > 2) searchName += " ${words[1]}";

      String matchedName = _findBestMatch(searchName);
      
      results.add(MedicineResult(
        originalLine: trimmedLine,
        medicineName: matchedName.isNotEmpty ? matchedName : null,
        dose: dose,
        duration: duration,
        confidence: searchName.isNotEmpty ? StringSimilarity.compareTwoStrings(searchName, matchedName) : 0,
      ));
    }

    return results;
  }
}
