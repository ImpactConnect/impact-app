import 'package:flutter/material.dart';

import '../../models/community_user.dart';
import '../../services/community_auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../members/members_connect_screen.dart';
import 'community_posts_screen.dart';

class CommunityDashboardScreen extends StatefulWidget {
  const CommunityDashboardScreen({Key? key, required this.user})
      : super(key: key);
  final CommunityUser user;

  @override
  _CommunityDashboardScreenState createState() =>
      _CommunityDashboardScreenState();
}

class _CommunityDashboardScreenState extends State<CommunityDashboardScreen> {
  final CommunityAuthService _authService = CommunityAuthService();

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MembersConnectScreen()));
  }

  void _navigateToPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityPostsScreen(
          currentUser: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Profile Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          widget.user.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.user.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Role: ${widget.user.role}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Community Features Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                children: [
                  _buildFeatureCard(
                    context,
                    icon: Icons.chat,
                    title: 'Discussions',
                    onTap: _navigateToPosts,
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.event,
                    title: 'Community Events',
                    onTap: () {
                      // TODO: Navigate to Community Events Screen
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.group,
                    title: 'Members',
                    onTap: () {
                      // TODO: Navigate to Community Members Screen
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    onTap: () {
                      // TODO: Navigate to Notifications Screen
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          const BottomNavBar(currentIndex: 2), // Set to Community index
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
