class RadioChannel {
  RadioChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.streamUrl,
    required this.isLive,
    this.programs,
  });

  factory RadioChannel.fromJson(Map<String, dynamic> json) {
    return RadioChannel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      streamUrl: json['stream_url'],
      isLive: json['is_live'],
      programs: json['programs'] != null
          ? (json['programs'] as List)
              .map((program) => RadioProgram.fromJson(program))
              .toList()
          : null,
    );
  }
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String streamUrl;
  final bool isLive;
  final List<RadioProgram>? programs;
}

class RadioProgram {
  RadioProgram({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.audioUrl,
    required this.publishDate,
    required this.duration,
    required this.host,
    required this.tags,
    this.isDownloaded = false,
    this.isFavorite = false,
  });

  factory RadioProgram.fromJson(Map<String, dynamic> json) {
    return RadioProgram(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      audioUrl: json['audio_url'],
      publishDate: DateTime.parse(json['publish_date']),
      duration: Duration(seconds: json['duration']),
      host: json['host'],
      tags: List<String>.from(json['tags']),
      isDownloaded: json['is_downloaded'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
    );
  }
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String audioUrl;
  final DateTime publishDate;
  final Duration duration;
  final String host;
  final List<String> tags;
  bool isDownloaded;
  bool isFavorite;
}
