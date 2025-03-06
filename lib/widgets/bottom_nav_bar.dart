import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/library/library_screen.dart';
import '../screens/report_bug_screen.dart';
import '../screens/sermon_screen.dart';
import '../screens/settings_screen.dart';
import '../services/ad_service.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    this.items,
  }) : super(key: key);
  
  final int currentIndex;
  final List<BottomNavigationBarItem>? items;

  void _onItemTapped(BuildContext context, int index) async {
    if (index == currentIndex) return;
    
    // Show interstitial ad when navigating between screens (with 30% probability)
    final adService = AdService();
    final shouldShowAd = index != 0 && // Don't show ad when going to home
                         (index == 3 || // Always show ad when going to settings
                          DateTime.now().millisecondsSinceEpoch % 10 < 3); // 30% chance for other screens
    
    if (shouldShowAd) {
      // Show ad before navigation
      await adService.showInterstitialAd();
    }
    
    // Special handling for ebook to audio navigation
    if (currentIndex == 2 && index == 1) {
      // Pop the current screen first
      Navigator.of(context).pop();
      
      // Then push the sermon screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SermonScreen(
            sermonService: MyApp.of(context).sermonService,
            audioPlayerService: MyApp.of(context).audioPlayerService,
          ),
        ),
      );
      return;
    }
    
    // For all other navigation
    switch (index) {
      case 0:
        // Home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
        break;
      case 1:
        // Audio/Sermons
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => SermonScreen(
              sermonService: MyApp.of(context).sermonService,
              audioPlayerService: MyApp.of(context).audioPlayerService,
            ),
          ),
          (route) => false,
        );
        break;
      case 2:
        // Library
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LibraryScreen()),
          (route) => false,
        );
        break;
      case 3:
        // Settings
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
          (route) => false,
        );
        break;
      case 4:
        // Report Bug
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ReportBugScreen()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.headphones),
        label: 'Sermons',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.book),
        label: 'Library',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bug_report),
        label: 'Report Bug',
      ),
    ];

    return BottomNavigationBar(
      items: items ?? defaultItems,
      currentIndex: currentIndex,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      onTap: (index) => _onItemTapped(context, index),
      type: BottomNavigationBarType.fixed,
    );
  }
}
