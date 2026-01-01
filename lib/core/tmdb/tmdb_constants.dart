import 'package:flutter_dotenv/flutter_dotenv.dart';

class TmdbConstants {
  static const String baseUrl = 'https://api.themoviedb.org/3';
  
  static String get apiKey {
    final key = dotenv.env['TMDB_API_KEY'];
    if (key == null || key.isEmpty) {
      // In a real app, you might throw an error or handle this gracefully
      return ''; 
    }
    return key;
  }
  
  static const String defaultRegion = 'US';

  // Watch Provider IDs (US Region mostly, but often consistent)
  static const Map<String, int> providers = {
    'Netflix': 8,
    'Amazon Prime': 9,
    'Disney+': 337,
    'Apple TV+': 350,
    'HBO Max': 384,
    'Hulu': 15,
    'Peacock': 386,
    'Paramount+': 531,
  };

  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
}