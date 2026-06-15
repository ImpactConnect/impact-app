import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/book.dart';
import '../../services/book_service.dart';
import '../../utils/url_utils.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({
    Key? key,
    required this.book,
  }) : super(key: key);
  final Book book;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final BookService _bookService = BookService();
  late Future<Map<String, int>> _progressFuture;
  bool _isLoading = true;
  bool _hasError = false;
  int _viewMode = 0; // 0: Google Docs, 1: Direct, 2: External
  late WebViewController _webViewController;
  late String _processedUrl;

  @override
  void initState() {
    super.initState();
    _progressFuture = _bookService.getReadingProgress(widget.book.id);
    _processedUrl = UrlUtils.processUrlForViewing(widget.book.pdfUrl);
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
        ),
      );

    // Start with Google Docs viewer
    _loadWithGoogleDocsViewer();
  }

  void _loadWithGoogleDocsViewer() {
    String urlToLoad;
    
    if (UrlUtils.isGoogleDriveUrl(widget.book.pdfUrl)) {
      // For Google Drive URLs, try the preview URL first
      urlToLoad = UrlUtils.getGoogleDrivePreviewUrl(widget.book.pdfUrl);
    } else {
      // For regular PDFs, use Google Docs viewer
      final encodedUrl = Uri.encodeComponent(_processedUrl);
      urlToLoad = 'https://docs.google.com/viewer?url=$encodedUrl&embedded=true';
    }
    
    _webViewController.loadRequest(Uri.parse(urlToLoad));
    setState(() {
      _viewMode = 0;
    });
  }

  void _loadDirectPdf() {
    _webViewController.loadRequest(Uri.parse(_processedUrl));
    setState(() {
      _viewMode = 1;
    });
  }

  Future<void> _openExternalPdf() async {
    setState(() {
      _viewMode = 2;
    });

    final Uri url = Uri.parse(_processedUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open PDF externally'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _saveProgress(int pageNumber) {
    _bookService.updateReadingProgress(widget.book.id, pageNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          // Bookmark button
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              _saveProgress(
                  1); // Default to page 1 since we can't track pages reliably
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reading progress saved'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          // View mode selector
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert),
            onSelected: (int result) {
              switch (result) {
                case 0:
                  _loadWithGoogleDocsViewer();
                  break;
                case 1:
                  _loadDirectPdf();
                  break;
                case 2:
                  _openExternalPdf();
                  break;
                case 3:
                  // Try original URL for Google Drive files
                  _webViewController.loadRequest(Uri.parse(widget.book.pdfUrl));
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              final isGoogleDrive = UrlUtils.isGoogleDriveUrl(widget.book.pdfUrl);
              
              return <PopupMenuEntry<int>>[
                PopupMenuItem<int>(
                  value: 0,
                  child: Text(isGoogleDrive ? 'Google Drive Preview' : 'Google Docs Viewer'),
                ),
                PopupMenuItem<int>(
                  value: 1,
                  child: Text(isGoogleDrive ? 'Direct Download' : 'Direct PDF (WebView)'),
                ),
                const PopupMenuItem<int>(
                  value: 2,
                  child: Text('Open in External App'),
                ),
                if (isGoogleDrive)
                  const PopupMenuItem<int>(
                    value: 3,
                    child: Text('Try Original URL'),
                  ),
              ];
            },
          ),
        ],
      ),
      body: _viewMode == 2
          ? _buildExternalViewPlaceholder()
          : Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (_hasError) _buildErrorWidget(),
              ],
            ),
    );
  }

  Widget _buildErrorWidget() {
    final isGoogleDrive = UrlUtils.isGoogleDriveUrl(widget.book.pdfUrl);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            'Failed to load PDF',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (isGoogleDrive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'This appears to be a Google Drive file. Make sure the file is publicly accessible or try opening it externally.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 20),
          if (!isGoogleDrive) ...[
            ElevatedButton(
              onPressed: _loadWithGoogleDocsViewer,
              child: const Text('Try Google Docs Viewer'),
            ),
            const SizedBox(height: 10),
          ],
          ElevatedButton(
            onPressed: _loadDirectPdf,
            child: Text(isGoogleDrive ? 'Try Direct Access' : 'Try Direct PDF'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _openExternalPdf,
            child: const Text('Open in External App'),
          ),
          if (isGoogleDrive) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                _webViewController.loadRequest(Uri.parse(widget.book.pdfUrl));
              },
              child: const Text('Try Original URL'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExternalViewPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          Text(
            widget.book.title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'PDF opened in external application',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _openExternalPdf,
            child: const Text('Open Again'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _loadWithGoogleDocsViewer,
            child: const Text('Return to In-App Viewer'),
          ),
        ],
      ),
    );
  }
}
