class TmdbMedia {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String mediaType;

  TmdbMedia({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.mediaType,
  });

  factory TmdbMedia.fromJson(Map<String, dynamic> json, String type) {
    return TmdbMedia(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? 'Unknown') as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      mediaType: type,
    );
  }
}
