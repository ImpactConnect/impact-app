import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/library/library_screen.dart';
import '../screens/report_bug_screen.dart';
import '../screens/sermon_screen.dart';
import '../screens/settings_screen.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    this.items,
  }) : super(key: key);
  
  final int currentIndex;
  final List<BottomNavigationBarItem>? items;

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;
    
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
          (route) => route.isFirst,
        );
        break;
      case 2:
        // Ebook/Library
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LibraryScreen()),
          (route) => route.isFirst,
        );
        break;
      case 3:
        // Report Bug
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ReportBugScreen()),
          (route) => route.isFirst,
        );
        break;
      case 4:
        // Settings
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
          (route) => route.isFirst,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultItems = const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.headset),
        label: 'Audio',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.book),
        label: 'Ebooks',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.bug_report),
        label: 'Report Bug',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: items ?? defaultItems,
      type: BottomNavigationBarType.fixed,
    );
  }
}
