import 'dart:convert';
import 'package:http/http.dart' as http;

class YoutubeSearchService {
  final String apiKey;

  YoutubeSearchService(this.apiKey);

  /// Searches YouTube for the first recipe/cooking video (not a Short) matching the query and returns its URL.
  Future<String?> searchFirstVideoUrl(String query) async {
    // Refine query to prefer recipe/cooking/instruction videos
    final refinedQuery = '$query recipe cooking instruction';

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=5&q=${Uri.encodeComponent(refinedQuery)}&key=$apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['items'] != null && data['items'].isNotEmpty) {
        for (final item in data['items']) {
          final videoId = item['id']['videoId'];
          // Filter out YouTube Shorts (shorts have /shorts/ in their URL or are < 60s, but API doesn't give duration here)
          // So, filter by title/description for 'shorts' and prefer those that mention recipe/cooking
          final title =
              (item['snippet']['title'] as String?)?.toLowerCase() ?? '';
          final description =
              (item['snippet']['description'] as String?)?.toLowerCase() ?? '';
          final isShort =
              title.contains('shorts') || description.contains('shorts');
          final isRecipe =
              title.contains('recipe') ||
              title.contains('cook') ||
              description.contains('recipe') ||
              description.contains('cook');
          if (!isShort && isRecipe) {
            print(
              '[DEBUG] YoutubeSearchService: Found recipe/cooking videoId = $videoId',
            );
            return 'https://www.youtube.com/watch?v=$videoId';
          }
        }
        // Fallback: return first non-short video
        for (final item in data['items']) {
          final videoId = item['id']['videoId'];
          final title =
              (item['snippet']['title'] as String?)?.toLowerCase() ?? '';
          final description =
              (item['snippet']['description'] as String?)?.toLowerCase() ?? '';
          final isShort =
              title.contains('shorts') || description.contains('shorts');
          if (!isShort) {
            print(
              '[DEBUG] YoutubeSearchService: Fallback non-short videoId = $videoId',
            );
            return 'https://www.youtube.com/watch?v=$videoId';
          }
        }
      }
    } else {
      print(
        '[DEBUG] YoutubeSearchService: HTTP ${response.statusCode} - ${response.body}',
      );
    }
    return null;
  }
}
