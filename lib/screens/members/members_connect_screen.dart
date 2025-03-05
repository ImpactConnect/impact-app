import 'package:church_mobile/models/announcement.dart';
import 'package:church_mobile/models/member.dart';
import 'package:church_mobile/models/testimony.dart';
import 'package:church_mobile/screens/members/members_directory_screen.dart';
import 'package:church_mobile/widgets/members/member_details_dialog.dart';
import 'package:church_mobile/widgets/testimony_details_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/bottom_nav_bar.dart';
import '../community/community_login_screen.dart';

class MembersConnectScreen extends StatefulWidget {
  const MembersConnectScreen({Key? key}) : super(key: key);

  @override
  State<MembersConnectScreen> createState() => _MembersConnectScreenState();
}

class _MembersConnectScreenState extends State<MembersConnectScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() {});
    await Future.delayed(const Duration(seconds: 2));
  }

  Widget _buildCelebrationCard(Member member, bool isBirthday) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => MemberDetailsDialog(member: member),
          );
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage:
                member.imageUrl != null ? NetworkImage(member.imageUrl!) : null,
            child: member.imageUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text(member.name),
          subtitle:
              Text(isBirthday ? 'Birthday Today!' : 'Wedding Anniversary'),
          trailing: Icon(
            isBirthday ? Icons.cake : Icons.celebration,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDateTime(announcement.timePosted),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonyCard(Testimony testimony) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => TestimonyDetailsDialog(testimony: testimony),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: testimony.imageUrl != null
                        ? NetworkImage(testimony.imageUrl!)
                        : null,
                    child: testimony.imageUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testimony.testifier,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDate(testimony.dateShared),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                testimony.testimony,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCommunityLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CommunityLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Members Connect',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/members_hero.jpg',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Theme.of(context).primaryColor.withOpacity(0.8),
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search members by name or occupation...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    if (_searchQuery.isNotEmpty)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('members')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text('Something went wrong');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final members = snapshot.data!.docs
                              .map((doc) => Member.fromFirestore(doc))
                              .where((member) =>
                                  member.name
                                      .toLowerCase()
                                      .contains(_searchQuery) ||
                                  (member.occupation
                                          ?.toLowerCase()
                                          .contains(_searchQuery) ??
                                      false))
                              .toList();

                          if (members.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No members found'),
                            );
                          }

                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final member = members[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: member.imageUrl != null
                                        ? NetworkImage(member.imageUrl!)
                                        : null,
                                    child: member.imageUrl == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Text(member.name),
                                  subtitle: Text(member.occupation ?? ''),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          MemberDetailsDialog(member: member),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Celebrants',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('members')
                            .snapshots(),
                        builder: (context, birthdaySnapshot) {
                          if (birthdaySnapshot.hasError) {
                            return const Text('Something went wrong');
                          }

                          if (birthdaySnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final List<Widget> celebrationCards = [];
                          final now = DateTime.now();

                          // Check birthdays
                          for (var doc in birthdaySnapshot.data!.docs) {
                            final member = Member.fromFirestore(doc);
                            if (member.birthDate != null) {
                              final birthday = member.birthDate!;
                              if (birthday.month == now.month &&
                                  birthday.day == now.day) {
                                celebrationCards
                                    .add(_buildCelebrationCard(member, true));
                              }
                            }
                            if (member.weddingDate != null) {
                              final anniversary = member.weddingDate!;
                              if (anniversary.month == now.month &&
                                  anniversary.day == now.day) {
                                celebrationCards
                                    .add(_buildCelebrationCard(member, false));
                              }
                            }
                          }

                          if (celebrationCards.isEmpty) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No celebrants today'),
                              ),
                            );
                          }

                          return Column(children: celebrationCards);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Announcements'),
                      Tab(text: 'Testimonies'),
                    ],
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Announcements Tab
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('announcements')
                              .orderBy('timePosted', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Center(
                                  child: Text('Something went wrong'));
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final announcements = snapshot.data!.docs
                                .map((doc) => Announcement.fromFirestore(doc))
                                .toList();

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: announcements.length,
                              itemBuilder: (context, index) {
                                return _buildAnnouncementCard(
                                    announcements[index]);
                              },
                            );
                          },
                        ),
                        // Testimonies Tab
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('testimonies')
                              .orderBy('dateShared', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Center(
                                  child: Text('Something went wrong'));
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final testimonies = snapshot.data!.docs
                                .map((doc) => Testimony.fromFirestore(doc))
                                .toList();

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: testimonies.length,
                              itemBuilder: (context, index) {
                                return _buildTestimonyCard(testimonies[index]);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildActionButton(
                              icon: Icons.group,
                              label: 'Community Forum',
                              color: Colors.blue,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CommunityLoginScreen(),
                                ),
                              ),
                            ),
                            _buildActionButton(
                              icon: Icons.people,
                              label: 'Members Directory',
                              color: Colors.green,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MembersDirectoryScreen(),
                                ),
                              ),
                            ),
                            _buildActionButton(
                              icon: Icons.chat,
                              label: 'Prayer Request',
                              color: Colors.red,
                              onTap: () {},
                            ),
                            _buildActionButton(
                              icon: Icons.calendar_today,
                              label: 'Church Calendar',
                              color: Colors.cyan,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BottomNavBar(currentIndex: 2), // Set to Members index
    );
  }
}
