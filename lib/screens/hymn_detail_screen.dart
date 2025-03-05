import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'hymn_screen.dart';

class HymnDetailScreen extends StatefulWidget {
  const HymnDetailScreen({
    Key? key,
    required this.hymn,
    this.onBookmarkChanged,
  }) : super(key: key);
  final Hymn hymn;
  final Function(bool)? onBookmarkChanged;

  @override
  State<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends State<HymnDetailScreen> {
  void _shareHymn() {
    final text = '''
${widget.hymn.title} (Hymn #${widget.hymn.hymnNumber})
By ${widget.hymn.author}

${widget.hymn.lyrics}
''';
    Share.share(text);
  }

  void _toggleBookmark() {
    if (widget.onBookmarkChanged != null) {
      widget.onBookmarkChanged!(!widget.hymn.isBookmarked);
      setState(() {}); // Refresh UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Return true to refresh parent
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context, true); // Return true to refresh parent
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    widget.hymn.isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: Colors.white,
                  ),
                  onPressed: _toggleBookmark,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.share,
                    color: Colors.white,
                  ),
                  onPressed: _shareHymn,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.hymn.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0, // Reduced from default 20.0
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/hymnal_header.jpg',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Hymn #${widget.hymn.hymnNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'By ${widget.hymn.author}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildLyrics(widget.hymn.lyrics, widget.hymn.chorus),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyrics(List<List<String>> stanzas, List<String>? chorus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stanzas.length; i++) ...[
          if (i > 0) const SizedBox(height: 32), // Space between stanzas
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Verse ${i + 1}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...stanzas[i].map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.6,
                      ),
                    ),
                  )),
              if (chorus != null && i < stanzas.length - 1) ...[
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Chorus',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...chorus.map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
