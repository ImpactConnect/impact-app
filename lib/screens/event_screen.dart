import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../models/event.dart' as app_event;
import '../services/event_service.dart';
import '../utils/toast_utils.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({Key? key}) : super(key: key);

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();
  List<app_event.Event> _events = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _eventService.getUpcomingEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSampleEvents() async {
    setState(() => _isLoading = true);
    try {
      await _eventService.addSampleEvents();
      await _loadEvents(); // Reload events after adding samples
    } catch (e) {
      print('Error adding sample events: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchEvents(String query) async {
    setState(() => _isLoading = true);
    try {
      final events = await _eventService.searchEvents(query);
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching events: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEventDetails(app_event.Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EventDetailsSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/events_header.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: const Text(
                'Events',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  if (value.isEmpty) {
                    _loadEvents();
                  } else {
                    _searchEvents(value);
                  }
                },
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_events.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No upcoming events'
                          : 'No events found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    // const SizedBox(height: 16),
                    // ElevatedButton(
                    //   onPressed: _addSampleEvents,
                    //   child: const Text('Add Sample Events'),
                    // ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final event = _events[index];
                  return _EventCard(
                    event: event,
                    onTap: () => _showEventDetails(event),
                  );
                },
                childCount: _events.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    Key? key,
    required this.event,
    required this.onTap,
  }) : super(key: key);
  final app_event.Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              child: Image.network(
                event.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d, y').format(event.startDate),
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventDetailsSheet extends StatefulWidget {
  const _EventDetailsSheet({
    Key? key,
    required this.event,
  }) : super(key: key);
  final app_event.Event event;

  @override
  State<_EventDetailsSheet> createState() => _EventDetailsSheetState();
}

class _EventDetailsSheetState extends State<_EventDetailsSheet> {
  late final DeviceCalendarPlugin _deviceCalendarPlugin;

  @override
  void initState() {
    super.initState();
    _deviceCalendarPlugin = DeviceCalendarPlugin();
  }

  Future<bool> _requestCalendarPermissions() async {
    final status = await Permission.calendar.request();
    if (status.isDenied) {
      ToastUtils.showToast('Calendar permission is required to add events');
      return false;
    }
    if (status.isPermanentlyDenied) {
      ToastUtils.showToast('Please enable calendar permission in app settings');
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  Future<void> _addToCalendar() async {
    try {
      final hasPermission = await _requestCalendarPermissions();
      if (!hasPermission) {
        return;
      }

      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          ToastUtils.showToast('Calendar permission is required');
          return;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess) {
        ToastUtils.showToast('Failed to get calendars');
        return;
      }

      final calendars = calendarsResult.data;
      if (calendars == null || calendars.isEmpty) {
        ToastUtils.showToast('No calendars found');
        return;
      }

      // Use the first available calendar
      final calendar = calendars.first;

      final eventToCreate = Event(
        calendar.id,
        title: widget.event.title,
        description: widget.event.description,
        start: TZDateTime.from(widget.event.startDate, local),
        end: TZDateTime.from(widget.event.endDate, local),
        location: widget.event.venue,
      );

      final createEventResult =
          await _deviceCalendarPlugin.createOrUpdateEvent(eventToCreate);
      if (createEventResult?.isSuccess ?? false) {
        ToastUtils.showToast(
            '${widget.event.title} has been added to your calendar');
      } else {
        ToastUtils.showToast('Failed to add event to calendar');
      }
    } catch (e) {
      print('Error adding event to calendar: $e');
      ToastUtils.showToast('Failed to add event to calendar');
    }
  }

  void _shareEvent() {
    final String shareText = '''
${widget.event.title}

Date: ${DateFormat('MMM d, y').format(widget.event.startDate)}
Time: ${widget.event.programmeTime}
Venue: ${widget.event.venue}

${widget.event.description}
''';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    widget.event.imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DetailItem(
                          icon: Icons.calendar_today,
                          title: 'Start Date',
                          content: DateFormat('MMM d, y')
                              .format(widget.event.startDate),
                        ),
                        _DetailItem(
                          icon: Icons.calendar_today,
                          title: 'End Date',
                          content: DateFormat('MMM d, y')
                              .format(widget.event.endDate),
                        ),
                        _DetailItem(
                          icon: Icons.access_time,
                          title: 'Programme Time',
                          content: widget.event.programmeTime,
                        ),
                        _DetailItem(
                          icon: Icons.location_on,
                          title: 'Venue',
                          content: widget.event.venue,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.event.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ActionButton(
                              icon: Icons.share,
                              label: 'Share',
                              onTap: _shareEvent,
                            ),
                            _ActionButton(
                              icon: Icons.calendar_today,
                              label: 'Add to Calendar',
                              onTap: _addToCalendar,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.content,
  }) : super(key: key);
  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
