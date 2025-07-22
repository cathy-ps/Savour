import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleImageSearchService {
  final String apiKey;
  static const String cx = '9323d489475a64326'; // Custom Search Engine ID

  GoogleImageSearchService({required this.apiKey});

  /// Searches Google Custom Search API for an image matching the query and returns the image URL.
  Future<String?> searchImage(String query) async {
    final url = Uri.parse(
      'https://www.googleapis.com/customsearch/v1?q=${Uri.encodeComponent(query)}&searchType=image&num=1&key=$apiKey&cx=$cx',
    );
    print('[GoogleImageSearchService] Searching for: "$query"');
    print('[GoogleImageSearchService] URL: $url');
    final response = await http.get(url);
    print('[GoogleImageSearchService] Response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('[GoogleImageSearchService] Response body: ${response.body}');
      final data = jsonDecode(response.body);
      if (data['items'] != null && data['items'].isNotEmpty) {
        print('[GoogleImageSearchService] Found image: ${data['items'][0]['link']}');
        return data['items'][0]['link']; // Image URL
      } else {
        print('[GoogleImageSearchService] No items found in response.');
      }
    } else {
      print('[GoogleImageSearchService] HTTP ${response.statusCode}: ${response.body}');
    }
    return null;
  }
}
