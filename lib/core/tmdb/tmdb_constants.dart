import 'package:flutter_dotenv/flutter_dotenv.dart';

class TmdbConstants {
  // static const String baseUrl = 'https://api.themoviedb.org/3';
  // Workaround for local DNS issue (api.themoviedb.org -> 127.0.0.1)
  static const String baseUrl = 'http://18.244.179.36/3';
  
  static String get apiKey {
    final key = dotenv.env['TMDB_API_KEY'];
    if (key == null || key.isEmpty) {
      // In a real app, you might throw an error or handle this gracefully
      return ''; 
    }
    return key;
  }
  
  static const String defaultRegion = 'TR';
  static const String defaultLanguage = 'tr-TR';

  // Watch Provider IDs (Prioritizing TR Region availability)
  static const Map<String, int> providers = {
    'Netflix': 8,
    'Amazon Prime': 119, // Amazon Prime Video
    'Disney+': 337,
    'Apple TV+': 350,
    'HBO Max': 384, // Not in TR yet officially, but kept for ref
    'Hulu': 15,
    'BluTV': 335,
    'MUBI': 11,
    'Gain': 569, // Verify ID if possible, using placeholder or known ID
    'Google Play Movies': 3,
  };

  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
}