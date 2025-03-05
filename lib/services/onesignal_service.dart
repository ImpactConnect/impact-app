import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static Future<void> initOneSignal() async {
    try {
      // Debug mode for OneSignal
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Initialize OneSignal
      OneSignal.initialize('44ffcdfa-336a-4785-acbf-b09a23ad8a91');

      // Prompt for push notification permission
      OneSignal.Notifications.requestPermission(true);

      // Configure notification handlers
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint('FOREGROUND NOTIFICATION RECEIVED');
        debugPrint('Notification: ${event.notification.body}');
        // Display the notification
        event.notification.display();
      });

      OneSignal.Notifications.addClickListener((event) {
        debugPrint('NOTIFICATION OPENED');
        debugPrint('Notification opened: ${event.notification.body}');
      });

      OneSignal.Notifications.addPermissionObserver((permission) {
        debugPrint('PERMISSION OBSERVER');
        debugPrint('Has permission: $permission');
      });

      // Log device state details
      final userId = await OneSignal.User.getOnesignalId();
      if (userId != null) {
        debugPrint('OneSignal User ID: $userId');
        debugPrint('Push Token: ${OneSignal.User.pushSubscription.id}');
      } else {
        debugPrint('Failed to get device state');
      }
    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
    }
  }

  // Method to send a push notification with comprehensive error handling
  static Future<bool> sendNotification({
    required String title,
    required String body,
    String? deepLink,
    List<String>? playerIds,
  }) async {
    try {
      // Get current device state
      final userId = await OneSignal.User.getOnesignalId();
      
      if (userId == null) {
        debugPrint('No valid OneSignal User ID found');
        return false;
      }

      // For OneSignal 5.3.0, we can't directly send notifications from the client
      // This would typically be done from a server-side implementation
      debugPrint('Note: Direct notification sending is not supported in OneSignal 5.3.0 client SDK');
      debugPrint('Notifications should be sent from your server using the OneSignal REST API');
      
      return false;
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      return false;
    }
  }

  // Get the current device's push token with more detailed logging
  static Future<String?> getDeviceToken() async {
    try {
      final userId = await OneSignal.User.getOnesignalId();
      
      if (userId == null) {
        debugPrint('Device state is null');
        return null;
      }

      debugPrint('Device User ID: $userId');
      debugPrint('Push Subscription ID: ${OneSignal.User.pushSubscription.id}');
      
      return userId;
    } catch (e) {
      debugPrint('Error getting device token: $e');
      return null;
    }
  }

  // Method to check notification permissions
  static Future<bool> checkNotificationPermissions() async {
    return await OneSignal.Notifications.permission;
  }

  // Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    OneSignal.User.addTags({topic: 'subscribed'});
  }

  // Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    OneSignal.User.removeTags([topic]);
  }
}
