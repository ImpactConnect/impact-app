import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/devotional.dart';
import '../services/devotional_service.dart';

class DevotionalDetailScreen extends StatefulWidget {
  const DevotionalDetailScreen({
    Key? key,
    required this.devotional,
  }) : super(key: key);
  final Devotional devotional;

  @override
  State<DevotionalDetailScreen> createState() => _DevotionalDetailScreenState();
}

class _DevotionalDetailScreenState extends State<DevotionalDetailScreen> {
  final DevotionalService _devotionalService = DevotionalService();
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _isBookmarked = _devotionalService.isBookmarked(widget.devotional);
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
      if (_isBookmarked) {
        _devotionalService.addBookmark(widget.devotional);
      } else {
        _devotionalService.removeBookmark(widget.devotional);
      }
    });
  }

  void _shareDevotional() {
    final text = '''
${widget.devotional.topic}

Bible Verse:
${widget.devotional.bibleVerse}

Message:
${widget.devotional.content}

Prayer Points:
${widget.devotional.prayerPoints.join('\n')}

Author: ${widget.devotional.author}
Date: ${widget.devotional.date.toString().split(' ')[0]}
''';

    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Devotional'),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _isBookmarked ? Theme.of(context).primaryColor : null,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareDevotional,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.devotional.topic,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.devotional.date.toString().split(' ')[0],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bible Verse',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.devotional.bibleVerse),
            ),
            const SizedBox(height: 24),
            Text(
              'Message',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.devotional.content,
              style: const TextStyle(height: 1.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Prayer Points',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.devotional.prayerPoints.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${index + 1}. '),
                      Expanded(
                        child: Text(widget.devotional.prayerPoints[index]),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Author: ${widget.devotional.author}',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
