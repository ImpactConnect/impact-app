import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/home_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _carouselCollections = [];

  @override
  void initState() {
    super.initState();
    _loadCarouselCollections();
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
                  for (final collection in _carouselCollections) ...[
                    HomeCarousel(collectionPath: collection),
                    const SizedBox(height: 24),
                  ],
                  // Add other home screen content below
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
