import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../utils/toast_utils.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({Key? key}) : super(key: key);

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen>
    with WidgetsBindingObserver {
  final WebViewController _controller = WebViewController();
  bool _isFullScreen = false;
  bool _isLoading = true;
  bool _showControls = true;
  String? _currentUrl;
  String _currentPlatform = 'youtube';
  String? _errorMessage;
  String _streamTitle = '';
  Timer? _controlsTimer;
  StreamSubscription<DocumentSnapshot>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebView();
    _startControlsTimer();
    _setupStream();
  }

  Future<void> _setupStream() async {
    try {
      print('Fetching live stream data...');
      // Simplified query to only check isLive
      final snapshot = await FirebaseFirestore.instance
          .collection('live_streams')
          .where('isLive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No live stream documents found');
        setState(() {
          _errorMessage = 'No live stream available at the moment';
          _isLoading = false;
        });
        return;
      }

      // Find the most recent valid stream
      DocumentSnapshot? validStream;
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final Timestamp? endTime = data['endTime'];

        if (endTime != null && endTime.toDate().isAfter(now)) {
          validStream = doc;
          break;
        }
      }

      if (validStream == null) {
        print('No current live stream found');
        setState(() {
          _errorMessage = 'No live stream available at the moment';
          _isLoading = false;
        });
        return;
      }

      print('Found live stream document: ${validStream.id}');
      print('Stream data: ${validStream.data()}');
      _listenToStreamUrl(validStream.id);
    } catch (e) {
      print('Error setting up stream: $e');
      setState(() {
        _errorMessage = 'Unable to connect to live stream service';
        _isLoading = false;
      });
    }
  }

  void _listenToStreamUrl(String documentId) {
    print('Setting up listener for document: $documentId');
    _streamSubscription = FirebaseFirestore.instance
        .collection('live_streams')
        .doc(documentId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) {
        print('Live stream document no longer exists');
        setState(() {
          _errorMessage = 'No live stream available at the moment';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data();
      if (data == null) {
        print('Live stream document is empty');
        setState(() {
          _errorMessage = 'No live stream data available';
          _isLoading = false;
        });
        return;
      }

      // Check if stream is still live
      if (data['isLive'] != true) {
        print('Stream is no longer live');
        setState(() {
          _errorMessage = 'Stream has ended';
          _isLoading = false;
        });
        return;
      }

      final Timestamp? endTime = data['endTime'];
      if (endTime != null && endTime.toDate().isBefore(DateTime.now())) {
        print('Stream has ended (past end time)');
        setState(() {
          _errorMessage = 'Stream has ended';
          _isLoading = false;
        });
        return;
      }

      final String? url = data['url'];
      final String platform =
          (data['platform'] ?? 'youtube').toString().toLowerCase();

      print('Retrieved URL from Firestore: $url');
      print('Platform: $platform');

      if (url == null || url.isEmpty) {
        print('URL is null or empty');
        setState(() {
          _errorMessage = 'No live stream URL configured';
          _isLoading = false;
        });
        return;
      }

      if (data['title'] != null) {
        setState(() {
          _streamTitle = data['title'];
        });
      }

      setState(() => _errorMessage = null);

      if (url != _currentUrl) {
        print('Loading new URL: $url');
        _currentUrl = url;
        _currentPlatform = platform;
        _loadUrl(url, platform: platform);
      }
    }, onError: (error) {
      print('Error fetching stream URL: $error');
      setState(() {
        _errorMessage = 'Unable to access live stream settings';
        _isLoading = false;
      });
    });
  }

  String _getVideoId(String url) {
    final RegExp regExp = RegExp(
      r'^.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*',
    );

    final Match? match = regExp.firstMatch(url);
    return match?.group(1) ?? '';
  }

  String _getFacebookVideoUrl(String url) {
    // Convert to embedded format if it's not already
    if (!url.contains('embed')) {
      url = url
          .replaceAll('www.facebook.com', 'www.facebook.com/plugins/video.php')
          .replaceAll('fb.watch', 'www.facebook.com/plugins/video.php');
      if (!url.contains('?')) {
        url += '?';
      }
      url += '&show_text=false&width=100%&height=100%&autoplay=true';
    }
    return url;
  }

  void _loadUrl(String url, {String platform = 'youtube'}) {
    print('Loading WebView URL: $url for platform: $platform');

    String embedUrl;
    if (platform.toLowerCase() == 'youtube') {
      final videoId = _getVideoId(url);
      if (videoId.isEmpty) {
        print('Invalid YouTube URL: $url');
        setState(() {
          _errorMessage = 'Invalid video URL';
          _isLoading = false;
        });
        return;
      }
      embedUrl = 'https://www.youtube.com/embed/$videoId';
    } else if (platform.toLowerCase() == 'facebook') {
      embedUrl = _getFacebookVideoUrl(url);
    } else {
      embedUrl = url;
    }

    print('Using embed URL: $embedUrl');

    final customHtml = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <meta charset="utf-8">
        <style>
          body, html {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100vh;
            overflow: hidden;
            background-color: #000000;
          }
          #player-container {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: #000000;
          }
          iframe {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            border: 0;
          }
        </style>
      </head>
      <body>
        <div id="player-container">
          <iframe 
            src="${platform.toLowerCase() == 'youtube' ? '$embedUrl?autoplay=1&controls=1&showinfo=0&rel=0&modestbranding=1&playsinline=1&enablejsapi=1' : embedUrl}"
            frameborder="0"
            allowfullscreen="true"
            webkitallowfullscreen="true" 
            mozallowfullscreen="true"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            style="background: #000000;"
          ></iframe>
        </div>
        <script>
          function updateSize() {
            const container = document.getElementById('player-container');
            const iframe = document.querySelector('iframe');
            if (container && iframe) {
              const width = window.innerWidth;
              const height = window.innerHeight;
              container.style.width = width + 'px';
              container.style.height = height + 'px';
              iframe.style.width = width + 'px';
              iframe.style.height = height + 'px';
            }
          }

          // Initial setup
          document.addEventListener('DOMContentLoaded', function() {
            updateSize();
            // Force hardware acceleration
            document.body.style.transform = 'translateZ(0)';
            document.body.style.webkitTransform = 'translateZ(0)';
          });

          // Handle resize and orientation changes
          window.addEventListener('resize', updateSize);
          window.addEventListener('orientationchange', function() {
            setTimeout(updateSize, 100);
          });
        </script>
      </body>
      </html>
    ''';

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page load started: $url');
            if (!mounted) return;
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print('Page load finished: $url');
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description} (${error.errorCode})');
            if (!mounted) return;
            setState(() {
              _errorMessage = 'Error loading stream: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(customHtml);
  }

  void _initializeWebView() {
    print('Initializing WebView');

    // Configure Android-specific settings
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      final androidController =
          _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..enableZoom(false);
  }

  void _resetOrientation() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    if (_showControls) {
      _controlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    _startControlsTimer();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  @override
  void dispose() {
    // Cancel any pending operations
    _controlsTimer?.cancel();
    _streamSubscription?.cancel();

    // Clear WebView resources
    if (mounted) {
      _controller
        ..clearCache()
        ..clearLocalStorage()
        ..setJavaScriptMode(JavaScriptMode.disabled);
    }

    WidgetsBinding.instance.removeObserver(this);
    _resetOrientation();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!mounted) return;

    // Handle app lifecycle changes
    if (state == AppLifecycleState.paused) {
      // App is in background, pause video if playing
      _controller.runJavaScript('''
        try {
          var iframe = document.querySelector('iframe');
          if (iframe) {
            iframe.contentWindow.postMessage(JSON.stringify({
              'event': 'command',
              'func': 'pauseVideo',
              'args': ''
            }), '*');
          }
        } catch (e) {
          console.error('Error pausing video:', e);
        }
      ''');
    } else if (state == AppLifecycleState.resumed) {
      // App is in foreground, reload the page if needed
      if (_currentUrl != null) {
        _loadUrl(_currentUrl!, platform: _currentPlatform);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _setupStream,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: GestureDetector(
                      onTap: _toggleControls,
                      child: Stack(
                        children: [
                          ClipRRect(
                            child: WebViewWidget(
                              controller: _controller,
                            ),
                          ),
                          if (_isLoading)
                            Container(
                              color: Colors.black,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_isLoading && _errorMessage == null)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),

              // Controls Overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: _toggleControls,
                  child: Container(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        // Top Bar with Back Button and Title
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: SafeArea(
                              child: Row(
                                children: [
                                  if (!_isFullScreen)
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back,
                                          color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        _streamTitle,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bottom Controls Bar
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: SafeArea(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.refresh,
                                        color: Colors.white),
                                    onPressed: () {
                                      _controller.reload();
                                      ToastUtils.showToast(
                                          'Refreshing stream...');
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _isFullScreen
                                          ? Icons.fullscreen_exit
                                          : Icons.fullscreen,
                                      color: Colors.white,
                                    ),
                                    onPressed: _toggleFullScreen,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Live Indicator
                        Positioned(
                          top: 16,
                          right: 16,
                          child: SafeArea(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 4,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
