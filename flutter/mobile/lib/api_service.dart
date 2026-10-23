import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {

  // Render URl
  static const String baseUrl = 'https://group-4-software-engineer.onrender.com';

  // Using the paramaters determined in create_post_page.dart, send post request to render
  static Future<Map<String, dynamic>> createPost({
    required String foodName,
    required String description,
    required int quantity,
    required DateTime pickupStart,
    required DateTime pickupEnd,
    required File imageFile,
  }) async {
    final url = Uri.parse('$baseUrl/api/listings');

    try {
    final request = http.MultipartRequest('POST', url);

    // Attach form fields
    request.fields['foodName'] = foodName;
    request.fields['description'] = description;
    request.fields['quantity'] = quantity.toString();
    request.fields['pickupStart'] = pickupStart.toIso8601String();
    request.fields['pickupEnd'] = pickupEnd.toIso8601String();
    request.fields['created_at'] = "string";
    request.fields['location'] = "Student Union";
    request.fields['organizationID'] = "67";

    //request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    // Attach image file
    final imageStream = http.ByteStream(imageFile.openRead());
    final imageLength = await imageFile.length();

    final multipartFile = http.MultipartFile(
      'image',
      imageStream,
      imageLength,
      filename: imageFile.path.split('/').last,
    );
    request.files.add(multipartFile);

    // Send the request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create listing: ${response.statusCode}: ${response.body}');
    } 
    }catch (e) {
      print('Error creating listing: $e');
      rethrow;
  }
  }

}