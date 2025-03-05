import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/home');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            NotificationItem(
              title: 'New Sermon Available',
              message: 'Watch the latest sermon from our Sunday service',
              time: '2 hours ago',
              isRead: false,
            ),
            NotificationItem(
              title: 'Upcoming Event',
              message: 'Youth Conference starts next week',
              time: '1 day ago',
              isRead: true,
            ),
            NotificationItem(
              title: 'Daily Verse',
              message: 'Your daily verse is ready for reading',
              time: '2 days ago',
              isRead: true,
            ),
          ],
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    Key? key,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
  }) : super(key: key);
  final String title;
  final String message;
  final String time;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isRead ? Colors.grey : Theme.of(context).primaryColor,
          child: const Icon(
            Icons.notifications,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(message),
        trailing: Text(
          time,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
