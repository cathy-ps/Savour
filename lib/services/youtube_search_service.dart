import 'dart:convert';
import 'package:http/http.dart' as http;

class YoutubeSearchService {
  final String apiKey;

  YoutubeSearchService(this.apiKey);

  /// Searches YouTube for the first recipe/cooking video (not a Short) matching the prompt-like query and returns its URL.
  Future<String?> searchFirstVideoUrl(String title) async {
    final promptQueries = [
      'How to cook $title recipe -short',
      '$title step by step cooking instructions -short',
    ];
    for (final refinedQuery in promptQueries) {
      final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=5&q=${Uri.encodeComponent(refinedQuery)}&key=$apiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          for (final item in data['items']) {
            final videoId = item['id']['videoId'];
            final ytTitle =
                (item['snippet']['title'] as String?)?.toLowerCase() ?? '';
            final description =
                (item['snippet']['description'] as String?)?.toLowerCase() ??
                '';
            final isShort =
                ytTitle.contains('shorts') || description.contains('shorts');
            final isRecipe =
                ytTitle.contains('recipe') ||
                ytTitle.contains('cook') ||
                description.contains('recipe') ||
                description.contains('cook');
            if (!isShort && isRecipe) {
              return 'https://www.youtube.com/watch?v=$videoId';
            }
          }
          // Fallback: return first non-short video
          for (final item in data['items']) {
            final videoId = item['id']['videoId'];
            final ytTitle =
                (item['snippet']['title'] as String?)?.toLowerCase() ?? '';
            final description =
                (item['snippet']['description'] as String?)?.toLowerCase() ??
                '';
            final isShort =
                ytTitle.contains('shorts') || description.contains('shorts');
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
    }
    return null;
  }
}
