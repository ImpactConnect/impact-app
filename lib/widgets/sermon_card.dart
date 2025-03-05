import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/sermon.dart';
import '../services/audio_player_service.dart';
import '../services/sermon_service.dart';

class SermonCard extends StatelessWidget {
  const SermonCard({
    Key? key,
    required this.sermon,
    required this.audioPlayerService,
    required this.sermonService,
    required this.onTap,
  }) : super(key: key);
  final Sermon sermon;
  final AudioPlayerService audioPlayerService;
  final SermonService sermonService;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: () {
          // Increment click count when sermon is tapped
          sermonService.incrementClickCount(sermon);
          onTap();
        },
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 50,
                height: 50,
                child: CachedNetworkImage(
                  imageUrl: sermon.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: StreamBuilder<PlayerState>(
                  stream: audioPlayerService.playerStateStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data?.playing ?? false;
                    final isThisSermon =
                        audioPlayerService.currentSermon?.id == sermon.id;

                    return Center(
                      child: Icon(
                        isThisSermon && isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        title: Text(
          sermon.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sermon.preacherName),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.play_circle_outline, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Text(
                  '${sermon.clickCount} plays',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.download_outlined, size: 14, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  '${sermon.downloadCount} downloads',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                switch (value) {
                  case 'download':
                    if (sermon.isDownloaded) {
                      await sermonService.deleteDownloadedSermon(sermon);
                    } else {
                      await sermonService.downloadSermon(sermon);
                    }
                    break;
                  case 'bookmark':
                    await sermonService.toggleBookmark(sermon);
                    break;
                  case 'share':
                    // Add share functionality here
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'download',
                  child: ListTile(
                    leading: Icon(
                      sermon.isDownloaded ? Icons.delete : Icons.download,
                      color: sermon.isDownloaded ? Colors.red : Colors.blue,
                    ),
                    title: Text(sermon.isDownloaded ? 'Delete' : 'Download'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'bookmark',
                  child: ListTile(
                    leading: Icon(
                      sermon.isBookmarked
                          ? Icons.bookmark_remove
                          : Icons.bookmark_add,
                      color: Colors.amber,
                    ),
                    title: Text(
                        sermon.isBookmarked ? 'Remove Bookmark' : 'Bookmark'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
