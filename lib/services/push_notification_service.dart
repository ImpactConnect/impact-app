import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotificationService {
  static Future<void> initialize() async {
    // Remove this method call if you wish to manually show the prompt
    OneSignal.shared.promptUserForPushNotificationPermission();

    // Initialize OneSignal
    await OneSignal.shared.setAppId('YOUR_ONESIGNAL_APP_ID');

    // Called when the notification is received
    OneSignal.shared.setNotificationWillShowInForegroundHandler((OSNotificationReceivedEvent event) {
      // Display the notification
      event.complete(event.notification);
    });

    // Called when a notification is tapped
    OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) {
      // Handle notification tap
      debugPrint('Notification opened: ${result.notification.body}');
    });

    // Get the device state
    OneSignal.shared.getDeviceState().then((deviceState) {
      if (deviceState?.userId != null) {
        debugPrint('OneSignal User ID: ${deviceState?.userId}');
      }
    });
  }

  // Method to send a push notification
  static Future<void> sendPushNotification({
    required String title,
    required String body,
    String? deepLink,
  }) async {
    try {
      var notification = OSCreateNotification(
        playerIds: [], // Add specific player IDs or leave empty for all users
        content: body,
        heading: title,
        sendAfter: DateTime.now(),
        androidChannelId: 'church_mobile_channel',
      );

      await OneSignal.shared.postNotification(notification);
      debugPrint('Push notification sent successfully');
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }

  // Method to subscribe/unsubscribe to topics
  static Future<void> subscribeToTopic(String topic) async {
    await OneSignal.shared.sendTag(topic, 'subscribed');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await OneSignal.shared.deleteTag(topic);
  }
}
