class StreamResponse {
  final String name; // e.g., "1080p HDR"
  final String description; // e.g., "Provider: YTS"
  final String url;
  final Map<String, String>? headers;
  final List<Subtitle>? subtitles;

  StreamResponse({
    required this.name,
    required this.description,
    required this.url,
    this.headers,
    this.subtitles,
  });

  factory StreamResponse.fromJson(Map<String, dynamic> json) {
    return StreamResponse(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      url: json['url'] as String,
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      subtitles: (json['subtitles'] as List<dynamic>?)
          ?.map((e) => Subtitle.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'url': url,
      'headers': headers,
      'subtitles': subtitles?.map((e) => e.toJson()).toList(),
    };
  }
}

class Subtitle {
  final String id;
  final String lang;
  final String url;

  Subtitle({
    required this.id,
    required this.lang,
    required this.url,
  });

  factory Subtitle.fromJson(Map<String, dynamic> json) {
    return Subtitle(
      id: json['id'] as String,
      lang: json['lang'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lang': lang,
      'url': url,
    };
  }
}
