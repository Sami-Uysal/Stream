class StreamRequest {
  final String type; // 'movie' or 'series'
  final Map<String, dynamic> ids; // e.g., {'imdb': 'tt123', 'tmdb': 550}
  final String title;
  final int? year;
  final int? season;
  final int? episode;

  StreamRequest({
    required this.type,
    required this.ids,
    required this.title,
    this.year,
    this.season,
    this.episode,
  });

  factory StreamRequest.fromJson(Map<String, dynamic> json) {
    return StreamRequest(
      type: json['type'] as String,
      ids: Map<String, dynamic>.from(json['ids'] as Map),
      title: json['title'] as String,
      year: json['year'] as int?,
      season: json['season'] as int?,
      episode: json['episode'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'ids': ids,
      'title': title,
      'year': year,
      'season': season,
      'episode': episode,
    };
  }
}
