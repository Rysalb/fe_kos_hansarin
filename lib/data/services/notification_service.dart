import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:proyekkos/core/constants/api_constants.dart';
import 'package:proyekkos/data/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Key for storing notifications locally
  static const String _notificationsKey = 'local_notifications';
  
  // Navigation Key for routing
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Stream controller for unread notification count
  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  
  // Initialize OneSignal
  Future<void> initialize() async {
    try {
      // Set logging level (verbose during development)
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.Debug.setAlertLevel(OSLogLevel.none);
      
      // Initialize OneSignal with your app ID
      OneSignal.initialize("1f9a735c-e1e6-4ecf-86ef-304bae7c19c2");
      
      // Request permission (new API style) and log the result
      final permissionResult = await OneSignal.Notifications.requestPermission(true);
      print('OneSignal permission request result: $permissionResult');
      
      // Set notification handlers (new API style)
      OneSignal.Notifications.addForegroundWillDisplayListener(_handleForegroundNotification);
      OneSignal.Notifications.addClickListener(_handleNotificationClicked);
      
      // Get OneSignal player ID and log it
      final onesignalId = await OneSignal.User.getOnesignalId();
      print('OneSignal ID: $onesignalId');
      
      if (onesignalId != null) {
        await _savePlayerId(onesignalId);
      }
      
      // Set up subscription observer and log the current state
      print('Current subscription state:');
      print('- Opted in: ${OneSignal.User.pushSubscription.optedIn}');
      print('- ID: ${OneSignal.User.pushSubscription.id}');
      print('- Token: ${OneSignal.User.pushSubscription.token}');
      
      OneSignal.User.pushSubscription.addObserver((state) {
        print('Push subscription changed:');
        print('- Opted in: ${OneSignal.User.pushSubscription.optedIn}');
        print('- ID: ${OneSignal.User.pushSubscription.id}');
        print('- Token: ${OneSignal.User.pushSubscription.token}');
      });

      // Schedule daily checkout date check at app startup
      Timer.periodic(Duration(hours: 24), (timer) {
        checkAndSendCheckoutReminders();
      });
      
      // Also run it once at startup
      checkAndSendCheckoutReminders();
      
      // Update unread count on startup
      _updateUnreadCount();
      
    } catch (e) {
      print('Error initializing OneSignal: $e');
    }
  }

  // Method to update unread count
  Future<void> _updateUnreadCount() async {
    try {
      final notifications = await getLocalNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      _unreadCountController.add(unreadCount);
    } catch (e) {
      print('Error updating unread count: $e');
      _unreadCountController.add(0);
    }
  }

  // Handler for foreground notifications (new API style)
  void _handleForegroundNotification(OSNotificationWillDisplayEvent event) async {
    try {
      // Get notification data
      final notification = event.notification;
      final data = notification.additionalData;
      
      print('📱 Received notification: ${notification.jsonRepresentation()}');
      
      // Allow the notification to display (new API style)
      notification.display();
      
      // Save notification locally
      if (data != null) {
        final notificationModel = NotificationModel(
          title: notification.title ?? '',
          message: notification.body ?? '',
          type: data['type']?.toString() ?? '',
          createdAt: DateTime.now(),
          data: data,
        );
        
        await _saveNotificationLocally(notificationModel);
        _updateUnreadCount();
      }
    } catch (e) {
      print('Error handling foreground notification: $e');
    }
  }

  // Handler for notification clicks (new API style)
  void _handleNotificationClicked(OSNotificationClickEvent event) {
    try {
      final data = event.notification.additionalData;
      print('📱 Notification clicked: ${data.toString()}');
      if (data != null) {
        final type = data['type']?.toString();
        final id = data['id'];
        
        // Navigate based on notification type
        _navigateBasedOnType(type, id);
      }
    } catch (e) {
      print('Error handling notification click: $e');
    }
  }

  // Send notification to all admin users using REST API
  Future<bool> sendNotificationToAdmins({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📱 Sending notification to admins: $title - $message');
      
      // First save locally for immediate feedback
      final localNotification = NotificationModel(
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        data: data,
      );
      
      await _saveNotificationLocally(localNotification);
      print('📱 Notification saved locally');
      _updateUnreadCount();
      
      // Send via OneSignal REST API
      final Uri apiUrl = Uri.parse('https://onesignal.com/api/v1/notifications');
      
      // Replace with your REST API key from OneSignal dashboard
      final String restApiKey = "os_v2_app_d6nhgxhb4zhm7bxpgbf247azyklrqxifs3je5446pplbivecyk22tl2svxafm4kb7ra4iqysbbgne3u323gh3zu3izezfzmtebage5q"; 
      
      final Map<String, String> headers = {
        'Authorization': 'Basic $restApiKey',
        'Content-Type': 'application/json',
      };
      
      // Create request body - specifically target admin role users
      final Map<String, dynamic> requestBody = {
        "app_id": "1f9a735c-e1e6-4ecf-86ef-304bae7c19c2", // Your OneSignal App ID
        "filters": [
          {"field": "tag", "key": "role", "relation": "=", "value": "admin"}
        ],
        "headings": {"en": title},
        "contents": {"en": message},
        "data": {
          "type": type,
          ...?data,
        }
      };
      
      final response = await http.post(
        apiUrl,
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      print('📱 OneSignal API Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print('OneSignal error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending notification to admins: $e');
      return false;
    }
  }

  // For normal notifications we can use the local approach
  Future<void> showNotification({
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Create notification model
      final notification = NotificationModel(
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        data: data,
      );
      
      // Save locally
      await _saveNotificationLocally(notification);
      
      // Instead of trying to create a local notification through OneSignal (which can be complex),
      // we'll just save it locally and update the badge count.
      // For actual push notifications, we'll use sendNotificationToSpecificUser or sendNotificationToAdmins
      _updateUnreadCount();
      
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  // Navigation logic
  void _navigateBasedOnType(String? type, dynamic id) {
    if (navigatorKey.currentState == null) return;
    
    switch(type) {
      case 'payment_verification':
        navigatorKey.currentState?.pushNamed('/admin/verifikasi-pembayaran');
        break;
      case 'tenant_verification':
        navigatorKey.currentState?.pushNamed('/admin/verifikasi-penyewa');
        break;
      case 'checkout_reminder':
        navigatorKey.currentState?.pushNamed('/pembayaran/bayar-sewa');
        break;
      default:
        navigatorKey.currentState?.pushNamed('/admin/notifikasi');
    }
  }

  // Save OneSignal player ID to backend and set tags for user role
  Future<void> _savePlayerId(String playerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userRole = prefs.getString('user_role');
      
      // Set user role tag for filtering notifications
      if (userRole != null) {
        await OneSignal.User.addTagWithKey('role', userRole);
        print('📱 Set user role tag: $userRole');
      }
      
      if (token == null) return;
      
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/user/onesignal-id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {
          'player_id': playerId,
        },
      );
    } catch (e) {
      print('Error saving player ID: $e');
    }
  }

  // Mark a notification as read (local implementation)
  Future<bool> markAsRead(String notificationId) async {
    try {
      // Update local notifications
      final notifications = await getLocalNotifications();
      final updatedNotifications = notifications.map((n) {
        if (n.id.toString() == notificationId) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            createdAt: n.createdAt,
            isRead: true,
            data: n.data,
          );
        }
        return n;
      }).toList();
      
      await _saveNotificationsLocally(updatedNotifications);
      _updateUnreadCount();
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Method to get notifications (now fully local)
  Future<List<NotificationModel>> getNotifications() async {
    try {
      return await getLocalNotifications();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> checkAndSendCheckoutReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null && data['data']['tanggal_keluar'] != null) {
          final checkoutDate = DateTime.parse(data['data']['tanggal_keluar']);
          final now = DateTime.now();
          final difference = checkoutDate.difference(now).inDays;
          
          // Send reminder notifications for 3, 2, 1, 0 days left
          if (difference <= 3 && difference >= 0) {
            await _createCheckoutReminderNotification(difference);
          }
        }
      }
    } catch (e) {
      print('Error checking checkout date: $e');
    }
  }

  Future<void> _createCheckoutReminderNotification(int daysLeft) async {
    String title = 'Masa Sewa Akan Berakhir';
    String message;
    
    if (daysLeft == 0) {
      message = 'Masa sewa kamar Anda berakhir hari ini. Silakan perpanjang untuk melanjutkan.';
    } else {
      message = 'Masa sewa kamar Anda akan berakhir dalam $daysLeft hari lagi. Silakan segera perpanjang.';
    }
    
    await showNotification(
      type: 'checkout_reminder',
      title: title,
      message: message,
      data: {'days_left': daysLeft},
    );
  }
  
  // Local storage methods
  Future<void> _saveNotificationLocally(NotificationModel notification) async {
    try {
      final notifications = await getLocalNotifications();
      
      // Create a copy with a generated ID if none exists
      final notificationWithId = notification.id == null 
          ? NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch,
              title: notification.title,
              message: notification.message,
              type: notification.type,
              createdAt: notification.createdAt,
              isRead: notification.isRead,
              data: notification.data,
            )
          : notification;
          
      notifications.insert(0, notificationWithId);
      
      await _saveNotificationsLocally(notifications);
    } catch (e) {
      print('Error saving notification locally: $e');
    }
  }

  // Save notifications to SharedPreferences
  Future<void> _saveNotificationsLocally(List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => jsonEncode({
        'id': n.id,
        'title': n.title,
        'message': n.message,
        'type': n.type,
        'created_at': n.createdAt.toIso8601String(),
        'is_read': n.isRead,
        'data': jsonEncode(n.data ?? {}),
      })).toList();
      
      await prefs.setStringList(_notificationsKey, jsonList);
    } catch (e) {
      print('Error saving notifications locally: $e');
    }
  }

  // Get notifications from SharedPreferences
  Future<List<NotificationModel>> getLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_notificationsKey) ?? [];
      
      return jsonList.map((jsonStr) {
        try {
          final Map<String, dynamic> json = jsonDecode(jsonStr);
          return NotificationModel(
            id: json['id'],
            title: json['title'] ?? '',
            message: json['message'] ?? '',
            type: json['type'] ?? '',
            createdAt: json['created_at'] != null 
                ? DateTime.parse(json['created_at']) 
                : DateTime.now(),
            isRead: json['is_read'] ?? false,
            data: json['data'] != null 
                ? jsonDecode(json['data']) 
                : null,
          );
        } catch (e) {
          print('Error parsing notification JSON: $e');
          return NotificationModel(
            title: 'Error',
            message: 'Could not parse notification',
            type: 'general',
            createdAt: DateTime.now(),
          );
        }
      }).toList();
    } catch (e) {
      print('Error getting local notifications: $e');
      return [];
    }
  }

  // Testing function
  Future<void> testNotification() async {
    try {
      await showNotification(
        type: 'test',
        title: 'Test Notification',
        message: 'This is a test notification',
        data: {'test': 'value'},
      );
      
      // Also test OneSignal direct notification
      await sendNotificationToAdmins(
        title: 'Test Admin Notification',
        message: 'This is a test notification to admins via OneSignal',
        type: 'test',
        data: {'test': 'value'},
      );
      
      print('Test notifications sent successfully');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }
  
  // Dispose method to close streams
  void dispose() {
    _unreadCountController.close();
  }

  Future<bool> sendNotificationToSpecificUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📱 Sending notification to user $userId: $title - $message');
      
      // Save locally for viewing in notifications list
      final localNotification = NotificationModel(
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        data: data,
      );
      
      await _saveNotificationLocally(localNotification);
      _updateUnreadCount();
      
      // Send via OneSignal REST API
      final Uri apiUrl = Uri.parse('https://onesignal.com/api/v1/notifications');
      
      // Your REST API key
      final String restApiKey = "os_v2_app_d6nhgxhb4zhm7bxpgbf247azyklrqxifs3je5446pplbivecyk22tl2svxafm4kb7ra4iqysbbgne3u323gh3zu3izezfzmtebage5q"; 
      
      final Map<String, String> headers = {
        'Authorization': 'Basic $restApiKey',
        'Content-Type': 'application/json',
      };
      
      // IMPORTANT: Use filter to target by user_id tag, not external ID
      final Map<String, dynamic> requestBody = {
        "app_id": "1f9a735c-e1e6-4ecf-86ef-304bae7c19c2",
        "filters": [
          {"field": "tag", "key": "user_id", "relation": "=", "value": userId}
        ],
        "headings": {"en": title},
        "contents": {"en": message},
        "data": {
          "type": type,
          ...?data,
        }
      };
      
      print('📱 Sending OneSignal notification with body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        apiUrl,
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      print('📱 OneSignal API Response (to user $userId): ${response.statusCode} - ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification to user $userId: $e');
      return false;
    }
  }

  Future<void> testUserNotification(String userId) async {
    try {
      // Check if user_id tag is set
      final tags = await OneSignal.User.getTags();
      print('Current user tags: $tags');
      
      // Set the user_id tag to ensure it's properly set
      await OneSignal.User.addTagWithKey('user_id', userId);
      print('Set user_id tag: $userId');
      
      // Send a test notification
      await sendNotificationToSpecificUser(
        userId: userId,
        title: 'Test Notification',
        message: 'This is a test notification to verify delivery',
        type: 'test',
        data: {'test': true},
      );
      
      print('Test notification sent to user $userId');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }
}