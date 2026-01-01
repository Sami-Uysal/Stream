import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageService {
  static const String _rpdbBaseUrl = 'https://api.ratingposterdb.com';
  static const String _tmdbBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static String? get rpdbKey => dotenv.env['RPDB_API_KEY'];

  static String getPosterUrl({required String? posterPath, required int tmdbId, String? mediaType}) {
    if (rpdbKey != null && rpdbKey!.isNotEmpty && tmdbId > 0) {
      return '$_rpdbBaseUrl/$rpdbKey/tmdb/poster-default/$tmdbId.jpg';
    }

    if (posterPath == null || posterPath.isEmpty) {
      return '';
    }

    if (posterPath.startsWith('/')) {
      return '$_tmdbBaseUrl$posterPath';
    }
    return '$_tmdbBaseUrl/$posterPath';
  }

  static bool hasValidPoster({String? posterPath, int? tmdbId}) {
    if (rpdbKey != null && rpdbKey!.isNotEmpty && tmdbId != null && tmdbId > 0) {
      return true;
    }
    return posterPath != null && posterPath.isNotEmpty;
  }

  static String getBackdropUrl(String? backdropPath) {
    if (backdropPath == null || backdropPath.isEmpty) return '';
    
    if (backdropPath.startsWith('/')) {
      return 'https://image.tmdb.org/t/p/w1280$backdropPath';
    }
    return 'https://image.tmdb.org/t/p/w1280/$backdropPath';
  }

  static String getProfileUrl(String? profilePath) {
    if (profilePath == null || profilePath.isEmpty) return '';
    
    if (profilePath.startsWith('/')) {
      return '$_tmdbBaseUrl$profilePath';
    }
    return '$_tmdbBaseUrl/$profilePath';
  }
}
