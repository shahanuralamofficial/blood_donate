import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Cloudinary Dashboard theke 'Cloud Name' ti ekhane bosaun
  static const String cloudName = "dhbz88gjs";
  
  // Cloudinary Settings > Upload > Upload Presets theke 'Unsigned' preset name ekhane bosaun
  static const String uploadPreset = "blood_donate";

  static Future<String?> uploadFile(File file, {bool isVideo = false}) async {
    final String resourceType = isVideo ? "video" : "image";
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload");

    try {
      final request = http.MultipartRequest("POST", url);
      
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        print("Cloudinary Upload Error: ${jsonResponse['error']['message']}");
        return null;
      }
    } catch (e) {
      print("Cloudinary Catch Error: $e");
      return null;
    }
  }
}
