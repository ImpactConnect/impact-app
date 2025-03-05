class VideoItem {
  const VideoItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.views,
    required this.likes,
    required this.postedDate,
  });
  final String id;
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final int views;
  final int likes;
  final DateTime postedDate;

  // Add copyWith method for easy state updates
  VideoItem copyWith({
    String? id,
    String? title,
    String? thumbnailUrl,
    String? videoUrl,
    int? views,
    int? likes,
    DateTime? postedDate,
  }) {
    return VideoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      postedDate: postedDate ?? this.postedDate,
    );
  }
}
