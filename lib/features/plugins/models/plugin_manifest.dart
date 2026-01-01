class PluginManifest {
  final String id;
  final String version;
  final String name;
  final String description;
  final List<String> types;
  final List<String> idPrefixes;

  PluginManifest({
    required this.id,
    required this.version,
    required this.name,
    required this.description,
    required this.types,
    required this.idPrefixes,
  });

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      id: json['id'] as String,
      version: json['version'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      types: (json['types'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      idPrefixes: (json['idPrefixes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'name': name,
      'description': description,
      'types': types,
      'idPrefixes': idPrefixes,
    };
  }
}
