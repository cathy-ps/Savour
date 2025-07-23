import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PexelsService {
  final String apiKey = dotenv.env['pexels_api_key'] ?? '';

  Future<List<String>> searchImages(String query, {int perPage = 15}) async {
    final url = Uri.parse(
      'https://api.pexels.com/v1/search?query=$query&per_page=$perPage',
    );
    final response = await http.get(url, headers: {'Authorization': apiKey});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List photos = data['photos'];
      // Return a list of image URLs (medium size)
      return photos
          .map<String>((photo) => photo['src']['medium'] as String)
          .toList();
    } else {
      throw Exception('Failed to load images');
    }
  }
}
