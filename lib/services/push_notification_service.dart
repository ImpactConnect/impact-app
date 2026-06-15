import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotificationService {
  static Future<void> initialize() async {
    // Initialize OneSignal with your app ID
    OneSignal.initialize('YOUR_ONESIGNAL_APP_ID');

    // Request notification permission
    await OneSignal.Notifications.requestPermission(true);

    // Called when the notification is received in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // Display the notification
      event.preventDefault();
      event.notification.display();
    });

    // Called when a notification is tapped
    OneSignal.Notifications.addClickListener((event) {
      // Handle notification tap
      debugPrint('Notification opened: ${event.notification.body}');
    });

    // Get the subscription ID (replaces user ID)
    final subscriptionId = OneSignal.User.pushSubscription.id;
    if (subscriptionId != null) {
      debugPrint('OneSignal Subscription ID: $subscriptionId');
    }
  }

  // Method to send a push notification (requires REST API call)
  static Future<void> sendPushNotification({
    required String title,
    required String body,
    String? deepLink,
  }) async {
    try {
      // Note: OneSignal v5 removed the postNotification method from the client SDK
      // Push notifications should be sent from your backend server using OneSignal REST API
      // This is a security best practice to keep your REST API key secure

      debugPrint(
          'Push notification sending should be handled by backend server');
      debugPrint('Title: $title, Body: $body');

      // If you need to send notifications from the client (not recommended),
      // you would need to use HTTP requests to OneSignal REST API
      // with proper authentication from your backend
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }

  // Method to subscribe/unsubscribe to topics using tags
  static Future<void> subscribeToTopic(String topic) async {
    OneSignal.User.addTags({'topic': 'subscribed'});
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    OneSignal.User.removeTag(topic);
  }

  // Additional helper methods for OneSignal v5
  static String? getSubscriptionId() {
    return OneSignal.User.pushSubscription.id;
  }

  static void setExternalUserId(String externalId) {
    OneSignal.login(externalId);
  }

  static void removeExternalUserId() {
    OneSignal.logout();
  }

  // Method to add email subscription
  static Future<void> addEmail(String email) async {
    OneSignal.User.addEmail(email);
  }

  // Method to remove email subscription
  static Future<void> removeEmail(String email) async {
    OneSignal.User.removeEmail(email);
  }
}
