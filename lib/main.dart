import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart'; 
import 'package:cached_network_image/cached_network_image.dart';

import 'firebase_options.dart';
import 'models/sermon.dart';
import 'models/blog_post.dart';
import 'screens/bible_screen.dart';
import 'screens/blog/blog_list_screen.dart';
import 'screens/blog/blog_detail_screen.dart';
import 'screens/devotional_screen.dart';
import 'screens/hymn_screen.dart';
import 'screens/library/library_screen.dart';
import 'screens/media/gallery_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/sermon_screen.dart';
import 'screens/media/video_screen.dart';
import 'services/audio_player_service.dart';
import 'services/bible_service.dart';
import 'services/blog_service.dart';
import 'services/note_service.dart';
import 'services/onesignal_service.dart'; 
import 'services/sermon_service.dart';
import 'utils/data_migration.dart';
import 'utils/toast_utils.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/home_carousel.dart';
import 'widgets/sermon_card.dart';
import 'screens/report_bug_screen.dart';
import 'screens/live_stream_screen.dart';
import 'screens/settings_screen.dart'; // Import the SettingsScreen


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Initialize OneSignal
    await OneSignalService.initOneSignal();

    // Check notification permissions
    final hasPermission = await OneSignalService.checkNotificationPermissions();
    if (!hasPermission) {
      print('Notification permissions not granted');
    }

    // Test Firestore connection
    try {
      print('Testing Firestore connection...');
      await FirebaseFirestore.instance.collection('test').limit(1).get();
      print('Firestore connection successful');

      // Run data migrations
      print('Running data migrations...');
      await DataMigration.migrateCarouselItems();
      print('Data migrations completed');
    } catch (e) {
      print('Error connecting to Firestore: $e');
      ToastUtils.showToast('Error connecting to database');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
    ToastUtils.showToast('Error initializing app');
  }

  // Initialize audio service
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.church_mobile.channel.audio',
    androidNotificationChannelName: 'Church Mobile Audio',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  final bibleService = BibleService(prefs);
  final sermonService = SermonService();
  final audioPlayerService = AudioPlayerService();
  final noteService = NoteService(prefs);
  final blogService = BlogService();

  await bibleService.loadBible();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
      ],
      child: MyApp(
        prefs: prefs,
        bibleService: bibleService,
        sermonService: sermonService,
        audioPlayerService: audioPlayerService,
        noteService: noteService,
        blogService: blogService,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.prefs,
    required this.bibleService,
    required this.sermonService,
    required this.audioPlayerService,
    required this.noteService,
    required this.blogService,
  }) : super(key: key);
  final SharedPreferences prefs;
  final BibleService bibleService;
  final SermonService sermonService;
  final AudioPlayerService audioPlayerService;
  final NoteService noteService;
  final BlogService blogService;

  static MyApp of(BuildContext context) {
    final _MyAppScope scope =
        context.dependOnInheritedWidgetOfExactType<_MyAppScope>()!;
    return scope.data;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        return _MyAppScope(
          data: this,
          child: MaterialApp(
            scaffoldMessengerKey: ToastUtils.messengerKey,
            // title: 'Impact Connect',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: languageProvider.currentLocale,
            supportedLocales: LanguageProvider.supportedLocales.values,
            home: const SplashScreen(),
            routes: {
              '/home': (context) => const HomePage(),
              '/bible': (context) => BibleScreen(
                    bibleService: MyApp.of(context).bibleService,
                  ),
              '/notes': (context) => NotesScreen(
                    noteService: MyApp.of(context).noteService,
                  ),
              '/sermons': (context) => SermonScreen(
                    sermonService: MyApp.of(context).sermonService,
                    audioPlayerService: MyApp.of(context).audioPlayerService,
                  ),
              '/devotional': (context) => const DevotionalScreen(),
              '/hymns': (context) => const HymnScreen(),
              '/live': (context) => const LiveStreamScreen(),
              '/blog': (context) => const BlogListScreen(),
              '/library': (context) => const LibraryScreen(),
              '/videos': (context) => const VideoScreen(),
              '/gallery': (context) => const GalleryScreen(),
              '/blog/detail': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                final postId = args?['postId'] as String?;
                if (postId != null) {
                  return BlogDetailScreen(postId: postId);
                }
                return const BlogListScreen();
              },
              '/search': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                final query = args?['query'] as String? ?? '';
                return SearchScreen(initialQuery: query);
              },
              '/report_bug': (context) => const ReportBugScreen(),
              '/settings': (context) => const SettingsScreen(), // Add the settings route
            },
            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '');

              // Handle blog detail route
              if (uri.path == '/blog-detail') {
                final postId = uri.queryParameters['id'];
                if (postId != null) {
                  return MaterialPageRoute(
                    builder: (context) => BlogDetailScreen(postId: postId),
                  );
                }
              }

              // Handle sermon detail route
              if (uri.path.startsWith('/sermons/')) {
                final sermonId = uri.pathSegments.last;
                return MaterialPageRoute(
                  builder: (context) => SermonScreen(
                    sermonService: MyApp.of(context).sermonService,
                    audioPlayerService: MyApp.of(context).audioPlayerService,
                    initialSermonId: sermonId,
                  ),
                );
              }

              // If no matching route is found
              return MaterialPageRoute(
                builder: (context) => const SplashScreen(),
              );
            },
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Page Not Found')),
                  body: Center(
                    child: Text('Route ${settings.name} not found'),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MyAppScope extends InheritedWidget {
  const _MyAppScope({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);
  final MyApp data;

  @override
  bool updateShouldNotify(_MyAppScope oldWidget) => data != oldWidget.data;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Skip SharedPreferences initialization on web
      if (!kIsWeb) {
        await SharedPreferences.getInstance();
      }

      // Delay for splash screen
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing app: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/church_logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            Text(
              'Impact Connect',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Your spiritual companion for sermons, devotionals, and church resources',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BibleService? _bibleService;
  NoteService? _noteService;
  bool _isLoading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initServices();
      _initialized = true;
    }
  }

  Future<void> _initServices() async {
    try {
      setState(() => _isLoading = true);
      _bibleService = MyApp.of(context).bibleService;
      _noteService = MyApp.of(context).noteService;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  final List<Map<String, dynamic>> quickActions = [
    {
      'icon': Icons.live_tv,
      'label': 'Live Stream',
      'color': Colors.red,
      // Replace LiveStreamScreen with VideoScreen as a fallback
      'route': (BuildContext context) => const LiveStreamScreen(),
    },
    {
      'icon': Icons.play_circle_filled,
      'label': 'Sermons',
      'color': Colors.orange,
      'route': (BuildContext context) => SermonScreen(
            sermonService: MyApp.of(context).sermonService,
            audioPlayerService: MyApp.of(context).audioPlayerService,
          ),
    },
    {
      'icon': Icons.menu_book,
      'label': 'Bible',
      'color': Colors.blue,
      'route': (BuildContext context) => BibleScreen(
            bibleService: MyApp.of(context).bibleService,
          ),
    },
    {
      'icon': Icons.note_alt,
      'label': 'Notes',
      'color': Colors.green,
      'route': (BuildContext context) => NotesScreen(
            noteService: MyApp.of(context).noteService,
          ),
    },
    {
      'icon': Icons.book,
      'label': 'Devotional',
      'color': Colors.purple,
      'route': (BuildContext context) => const DevotionalScreen(),
    },
  ];

  final List<Map<String, dynamic>> mediaButtons = [
    {
      'icon': Icons.video_library,
      'label': 'Videos',
      'color': Colors.red,
      'route': (BuildContext context) => const VideoScreen(),
    },
    {
      'icon': Icons.radio,
      'label': 'Radio',
      'color': Colors.blue,
      'route': null,
    },
    {
      'icon': Icons.rss_feed,
      'label': 'Blog',
      'color': Colors.orange,
      'route': (BuildContext context) => const BlogListScreen(),
    },
    {
      'icon': Icons.local_library,
      'label': 'Library',
      'color': Colors.brown,
      'route': (BuildContext context) => const LibraryScreen(),
    },
  ];

  final List<Map<String, dynamic>> engagementButtons = [
    {
      'icon': Icons.book,
      'label': 'Devotionals',
      'color': Colors.teal,
      'route': (BuildContext context) => const DevotionalScreen(),
    },
    {
      'icon': Icons.music_note,
      'label': 'Hymns',
      'color': Colors.indigo,
      'route': (BuildContext context) => const HymnScreen(),
    },
    {
      'icon': Icons.monetization_on,
      'label': 'Donation',
      'color': Colors.green,
      'route': null,
    },
    {
      'icon': Icons.bug_report,
      'label': 'Report Bug',
      'color': Colors.red,
      'route': (BuildContext context) => const ReportBugScreen(),
    },
  ];

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: quickActions.length,
        itemBuilder: (context, index) {
          final action = quickActions[index];
          return Container(
            width: 72,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              onTap: () {
                if (action['route'] != null) {
                  final routeBuilder = action['route'] as Function;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => routeBuilder(context),
                    ),
                  );
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: action['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      action['label'] as String,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtonGrid(List<Map<String, dynamic>> buttons) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: buttons.map((button) {
        return InkWell(
          onTap: () {
            if (button['route'] != null) {
              final routeBuilder = button['route'] as Function;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => routeBuilder(context),
                ),
              );
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (button['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  button['icon'] as IconData,
                  color: button['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  button['label'] as String,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreachersRow() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Swipe to see more',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.swipe,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('preachers').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${snapshot.error}'),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No preachers available'),
                ),
              );
            }

            final preachers = snapshot.data!.docs;

            return Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[100]!,
                    Colors.white,
                    Colors.grey[100]!,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: preachers.length,
                itemBuilder: (context, index) {
                  final preacher = preachers[index];
                  final preacherName = preacher.get('name') as String;
                  String? imageUrl;
                  try {
                    imageUrl = preacher.get('imageUrl') as String?;
                  } catch (e) {
                    // Field doesn't exist, use null
                    imageUrl = null;
                  }
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SermonScreen(
                            sermonService: MyApp.of(context).sermonService,
                            audioPlayerService: MyApp.of(context).audioPlayerService,
                            initialPreacher: preacherName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 100, // Increased width for better text display
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(35),
                                child: imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: 65,
                                      height: 65,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.person, color: Colors.grey),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      ),
                                    )
                                  : Container(
                                      width: 65,
                                      height: 65,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.person, color: Colors.grey),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              preacherName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12, // Slightly increased font size
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                                height: 1.2, // Better line height for two lines
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSermonCategoriesGrid() {
    return FutureBuilder<List<Sermon>>(
      future: MyApp.of(context).sermonService.getSermons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No sermon categories available'),
            ),
          );
        }

        // Extract unique categories from sermons
        final categories = snapshot.data!
            .map((sermon) => sermon.category)
            .toSet()
            .toList()
          ..sort();

        // Create a map of category icons
        final Map<String, IconData> categoryIcons = {
          'Teaching': Icons.school,
          'Worship': Icons.music_note,
          'Prayer': Icons.volunteer_activism,
          'Testimony': Icons.record_voice_over,
          'Bible Study': Icons.menu_book,
          'Youth': Icons.groups,
          'Family': Icons.family_restroom,
          'Leadership': Icons.trending_up,
          'Evangelism': Icons.public,
          'Missions': Icons.flight_takeoff,
        };

        // Create a map of category colors
        final Map<String, Color> categoryColors = {
          'Teaching': Colors.blue,
          'Worship': Colors.purple,
          'Prayer': Colors.teal,
          'Testimony': Colors.orange,
          'Bible Study': Colors.indigo,
          'Youth': Colors.pink,
          'Family': Colors.green,
          'Leadership': Colors.amber,
          'Evangelism': Colors.red,
          'Missions': Colors.cyan,
        };

        // Create category buttons
        final categoryButtons = categories.map((category) {
          return {
            'icon': categoryIcons[category] ?? Icons.label,
            'label': category,
            'color': categoryColors[category] ?? Colors.grey,
            'route': (BuildContext context) => SermonScreen(
                  sermonService: MyApp.of(context).sermonService,
                  audioPlayerService: MyApp.of(context).audioPlayerService,
                  initialCategory: category,
                ),
          };
        }).toList();

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: categoryButtons.map((category) {
            return InkWell(
              onTap: () {
                if (category['route'] != null) {
                  final routeBuilder = category['route'] as Function;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => routeBuilder(context),
                    ),
                  );
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (category['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: category['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      category['label'] as String,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLatestSermonsSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest Sermons',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/sermons');
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text(
                'Stream sermons online or download for offline use',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        FutureBuilder<List<Sermon>>(
          future: MyApp.of(context).sermonService.getSermons(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Error: ${snapshot.error}'),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No sermons available'),
                ),
              );
            }

            // Get the 3 latest sermons
            final sermons = snapshot.data!.take(3).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sermons.length,
              itemBuilder: (context, index) {
                final sermon = sermons[index];
                return SermonCard(
                  sermon: sermon,
                  audioPlayerService: MyApp.of(context).audioPlayerService,
                  sermonService: MyApp.of(context).sermonService,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SermonScreen(
                          sermonService: MyApp.of(context).sermonService,
                          audioPlayerService: MyApp.of(context).audioPlayerService,
                          initialSermonId: sermon.id,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentBlogPostsSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Blog Posts',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BlogListScreen(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<List<BlogPost>>(
          stream: BlogService().getBlogPosts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${snapshot.error}'),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No blog posts available'),
                ),
              );
            }

            // Get the 3 most recent blog posts
            final blogPosts = snapshot.data!.take(3).toList();

            return Container(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: blogPosts.length,
                itemBuilder: (context, index) {
                  final post = blogPosts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlogDetailScreen(
                            postId: post.id,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.network(
                              post.thumbnailUrl,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              post.title,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/search');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light 
                ? Colors.grey[200] 
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2.0,
                spreadRadius: 0.5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Theme.of(context).brightness == Brightness.light 
                  ? Colors.grey[800] 
                  : Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Search sermons, blogs, preachers...',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light 
                      ? Colors.grey[800] 
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              // title: const Text('Impact Connect'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue[800]!,
                      Colors.blue[600]!,
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/home_hero.jpg',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.pushNamed(context, '/search');
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _buildSearchBar(),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('carousel_config')
                      .doc('collections')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final paths =
                          List<String>.from(snapshot.data!.get('paths') ?? []);
                      return Column(
                        children: [
                          for (final path in paths) ...[
                            HomeCarousel(collectionPath: '$path/items'),
                            const SizedBox(height: 16),
                          ],
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                _buildSectionTitle('Quick Actions'),
                _buildQuickActions(),
                _buildLatestSermonsSection(),
                _buildSectionTitle('Media'),
                _buildButtonGrid(mediaButtons),
                _buildSectionTitle('Browse Messages by Preacher'),
                _buildPreachersRow(),
                _buildSectionTitle('Browse Sermons by Categories'),
                _buildSermonCategoriesGrid(),
                _buildRecentBlogPostsSection(),
                _buildSectionTitle('Engagement'),
                _buildButtonGrid(engagementButtons),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
