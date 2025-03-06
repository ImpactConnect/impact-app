import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../widgets/ads/banner_ad_widget.dart';
import '../widgets/home_carousel.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _carouselCollections = [];
  final AdService _adService = AdService();
  bool _showTimedAd = false;

  @override
  void initState() {
    super.initState();
    _loadCarouselCollections();
    
    // Check for timed ads every minute
    Future.delayed(const Duration(minutes: 1), _checkForTimedAd);
  }
  
  void _checkForTimedAd() {
    if (_adService.shouldShowTimedAd()) {
      _adService.showInterstitialAd();
    }
    
    // Check again after a minute
    if (mounted) {
      Future.delayed(const Duration(minutes: 1), _checkForTimedAd);
    }
  }

  Future<void> _loadCarouselCollections() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('carousel_config')
          .doc('collections')
          .get();

      if (snapshot.exists) {
        setState(() {
          _carouselCollections =
              List<String>.from(snapshot.data()?['paths'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading carousel collections: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadCarouselCollections,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Impact Connect',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/church_header.jpg',
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
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Quick Actions Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        // Quick action buttons here
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildQuickActionButton(
                              context,
                              Icons.headset,
                              'Sermons',
                              () => Navigator.pushNamed(context, '/sermons'),
                            ),
                            _buildQuickActionButton(
                              context,
                              Icons.book,
                              'Library',
                              () => Navigator.pushNamed(context, '/library'),
                            ),
                            _buildQuickActionButton(
                              context,
                              Icons.event,
                              'Events',
                              () => Navigator.pushNamed(context, '/events'),
                            ),
                            _buildQuickActionButton(
                              context,
                              Icons.monetization_on,
                              'Give',
                              () => Navigator.pushNamed(context, '/give'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Banner Ad between Quick Actions and Latest Sermons
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: BannerAdWidget(adSize: AdSize.banner),
                  ),
                  
                  // Latest Sermons Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latest Sermons',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        // Latest sermons list here
                      ],
                    ),
                  ),
                  
                  // Browse by Preacher Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Browse by Preacher',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        // Preacher list here
                      ],
                    ),
                  ),
                  
                  // Banner Ad between Browse by Preacher and Browse by Category
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: BannerAdWidget(adSize: AdSize.banner),
                  ),
                  
                  // Browse by Category Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Browse by Category',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        // Category list here
                      ],
                    ),
                  ),
                  
                  // Build carousels with ads in between
                  for (int i = 0; i < _carouselCollections.length; i++) ...[
                    HomeCarousel(collectionPath: _carouselCollections[i]),
                    const SizedBox(height: 16),
                    // Show an ad after every second carousel
                    if (i % 2 == 1 && i < _carouselCollections.length - 1) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: BannerAdWidget(adSize: AdSize.banner),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  // Add a banner ad at the bottom of the home screen
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: BannerAdWidget(adSize: AdSize.largeBanner),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
  
  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
