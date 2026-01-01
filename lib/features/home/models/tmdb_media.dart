class TmdbCast {
  final int id;
  final String name;
  final String character;
  final String? profilePath;

  TmdbCast({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  factory TmdbCast.fromJson(Map<String, dynamic> json) {
    return TmdbCast(
      id: json['id'],
      name: json['name'] ?? '',
      character: json['character'] ?? '',
      profilePath: json['profile_path'],
    );
  }
}

class TmdbMedia {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final String releaseDate;
  final double voteAverage;
  final String type; // 'movie' or 'tv'
  
  // Details
  final String? imdbId;
  final int? runtime;
  final List<TmdbCast>? cast;

  TmdbMedia({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.type,
    this.imdbId,
    this.runtime,
    this.cast,
  });

  factory TmdbMedia.fromJson(Map<String, dynamic> json, String type) {
    final title = type == 'movie' ? json['title'] : json['name'];
    final releaseDate = type == 'movie' ? json['release_date'] : json['first_air_date'];
    
    String? imdbId;
    if (json['external_ids'] != null) {
      imdbId = json['external_ids']['imdb_id'];
    }

    List<TmdbCast>? castList;
    if (json['credits'] != null && json['credits']['cast'] != null) {
      castList = (json['credits']['cast'] as List)
          .map((c) => TmdbCast.fromJson(c))
          .take(10) // Take top 10
          .toList();
    }

    return TmdbMedia(
      id: json['id'],
      title: title ?? 'Unknown Title',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      releaseDate: releaseDate ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      type: type,
      imdbId: imdbId,
      runtime: json['runtime'],
      cast: castList,
    );
  }

  // For storing in library (SharedPreferences)
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'overview': overview,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'release_date': releaseDate,
    'vote_average': voteAverage,
    'type': type,
    'imdb_id': imdbId,
    'runtime': runtime,
  };

  // For loading from library storage
  factory TmdbMedia.fromStorageJson(Map<String, dynamic> json) {
    return TmdbMedia(
      id: json['id'],
      title: json['title'] ?? 'Unknown Title',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      releaseDate: json['release_date'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 'movie',
      imdbId: json['imdb_id'],
      runtime: json['runtime'],
    );
  }
}
