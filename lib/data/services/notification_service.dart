import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:proyekkos/core/constants/api_constants.dart';
import 'package:proyekkos/data/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'kamar_service.dart';

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
      
      // Hanya gunakan foreground notification handler
      OneSignal.Notifications.addForegroundWillDisplayListener(_handleForegroundNotification);
      
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
      Timer.periodic(Duration(hours: 6), (timer) {
        checkAndSendCheckoutReminders();
      });

      Future.delayed(Duration(seconds: 5), () {
        checkAndSendCheckoutReminders();
      });
      // Also run it once at startup
      checkAndSendCheckoutReminders();

      // In the initialize() method of NotificationService, add this:
// Schedule daily check for expiring rooms
      Timer.periodic(Duration(hours: 12), (timer) {
       checkAndNotifyAdminsAboutExpiringRooms();
        });

// Also run it once at startup with a delay to ensure backend services are ready
Future.delayed(Duration(seconds: 10), () {
  checkAndNotifyAdminsAboutExpiringRooms();
});
      
      // Update unread count on startup
      _updateUnreadCount();
      await setupNotificationHandling();
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

// Update the _handleForegroundNotification method in notification_service.dart
// Update the _handleForegroundNotification method
void _handleForegroundNotification(OSNotificationWillDisplayEvent event) async {
  try {
    // Get notification data
    final notification = event.notification;
    final data = notification.additionalData;
    
    print('Received foreground notification: ${notification.jsonRepresentation()}');
    
    // Allow the notification to display
    notification.display();
    
    // Save notification locally
    if (data != null) {
      final userRole = await _getCurrentUserRole();
      
      // Extract target information from data - check both camelCase and snake_case versions
      // since different parts of your code might use different conventions
      String? targetRole = data['targetRole']?.toString() ?? 
                         data['target_role']?.toString();
                         
      String? targetUserId = data['targetUserId']?.toString() ?? 
                           data['target_user_id']?.toString();
      
      // For admin notifications related to verification, explicitly set targetRole if missing
      String? type = data['type']?.toString();
      if (targetRole == null && 
          (type == 'payment_verification' || type == 'tenant_verification')) {
        targetRole = 'admin';
      }
      
      print('Processing notification with role: $userRole');
      print('Notification type: $type, targetRole: $targetRole, targetUserId: $targetUserId');
      
      // Create the notification model
      final notificationModel = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch,  // Use integer timestamp
        title: notification.title ?? '',
        message: notification.body ?? '',
        type: type ?? '',
        createdAt: DateTime.now(),
        data: data,
        targetRole: targetRole,
        targetUserId: targetUserId,
      );
      
      await _saveNotificationLocally(notificationModel);
      _updateUnreadCount();
      
      print('Notification saved locally');
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

  // Update the sendNotificationToAdmins method
Future<bool> sendNotificationToAdmins({
  required String title,
  required String message,
  required String type,
  Map<String, dynamic>? data,
}) async {
  try {
    print('Sending notification to admins: $title - $message');
    
    // Prepare data with proper targeting
    final Map<String, dynamic> notificationData = {
      'type': type,
      'targetRole': 'admin',  // Make sure this is set
      ...?data,
    };
    
    // Save locally ONLY if the current user is an admin
    final userRole = await _getCurrentUserRole();
    if (userRole == 'admin') {
      final localNotification = NotificationModel(
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        data: notificationData,
        targetRole: 'admin',  // Make sure this is set
      );
      
      await _saveNotificationLocally(localNotification);
      _updateUnreadCount();
      print('Saved admin notification locally');
    }
    
    // Rest of the method remains the same...
    final Uri apiUrl = Uri.parse('https://onesignal.com/api/v1/notifications');
    final String restApiKey = "os_v2_app_d6nhgxhb4zhm7bxpgbf247azyklrqxifs3je5446pplbivecyk22tl2svxafm4kb7ra4iqysbbgne3u323gh3zu3izezfzmtebage5q"; 
    
    final Map<String, String> headers = {
      'Authorization': 'Basic $restApiKey',
      'Content-Type': 'application/json',
    };
    
    final Map<String, dynamic> requestBody = {
      "app_id": "1f9a735c-e1e6-4ecf-86ef-304bae7c19c2",
      "filters": [
        {"field": "tag", "key": "role", "relation": "=", "value": "admin"}
      ],
      "headings": {"en": title},
      "contents": {"en": message},
      "data": notificationData
    };
    
    final response = await http.post(
      apiUrl,
      headers: headers,
      body: jsonEncode(requestBody),
    );
    
    print('OneSignal API Response: ${response.statusCode} - ${response.body}');
    
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

// Update the showNotification method
Future<void> showNotification({
  required String type,
  required String title,
  required String message,
  Map<String, dynamic>? data,
  String? targetRole,
  String? targetUserId,
}) async {
  try {
    // If no targetRole is provided, use current user's role
    final userRole = targetRole ?? await _getCurrentUserRole();
    
    // Create notification model
    final notification = NotificationModel(
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      data: data,
      targetRole: userRole,
      targetUserId: targetUserId,
    );
    
    // Save locally
    await _saveNotificationLocally(notification);
    _updateUnreadCount();
    
    print('Local notification created: $title (type: $type, target: $userRole, userId: $targetUserId)');
  } catch (e) {
    print('Error showing notification: $e');
  }
}
  // Navigation logic
  void _navigateBasedOnType(String? type, dynamic id) async {
    if (navigatorKey.currentState == null) return;
    
    // Get user role to determine appropriate navigation
    final userRole = await _getCurrentUserRole();
    
    print('Navigating based on notification type: $type for role: $userRole');
    
    // Role-specific navigation
    if (userRole == 'admin') {
      // Admin navigation paths
      switch(type) {
        case 'payment_verification':
          navigatorKey.currentState?.pushNamed('/admin/verifikasi-pembayaran');
          break;
        case 'tenant_verification':
          navigatorKey.currentState?.pushNamed('/admin/verifikasi-penyewa');
          break;
          case 'room_expiry_alert':
  // Navigate to admin dashboard to show expiring rooms
          navigatorKey.currentState?.pushNamed('/admin/dashboard');
          break;
        default:
          navigatorKey.currentState?.pushNamed('/admin/notifikasi');
      }
    } else {
      // User navigation paths
      switch(type) {
        case 'payment_verification':
        case 'payment_rejected':
          navigatorKey.currentState?.pushNamed('/user/histori-pembayaran');
          break;
        case 'order_verification':
          navigatorKey.currentState?.pushNamed('/user/order-history');
          break;
        case 'checkout_reminder':
          navigatorKey.currentState?.pushNamed('/user/bayar-sewa');
          break;
        default:
          navigatorKey.currentState?.pushNamed('/user/notifikasi');
      }
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

 // Update this method in NotificationService class
Future<void> checkAndSendCheckoutReminders() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('user_id');
    
    if (token == null || userId == null) {
      print('Skipping checkout reminder check - no auth token or user ID');
      return;
    }
    
    print('Checking checkout date reminders for user ID: $userId');
    
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/user/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    
    print('Profile response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Profile data: ${data['data']}');
      
      // Validate we're checking the right user's profile
      if (data['data'] != null && 
          data['data']['id_user'] != null && 
          data['data']['id_user'].toString() == userId) {
        
        if (data['status'] == true && data['data']['tanggal_keluar'] != null) {
          final checkoutDate = DateTime.parse(data['data']['tanggal_keluar']);
          final now = DateTime.now();
          final difference = checkoutDate.difference(now).inDays;
          
          print('Checkout date: $checkoutDate');
          print('Current date: $now');
          print('Days remaining: $difference');
          
          // Send reminder notifications for 7, 3, 2, 1, 0 days left
          if (difference <= 7 && difference >= 0) {
            await _createCheckoutReminderNotification(difference, userId);
            print('Checkout reminder notification created for user $userId with $difference days remaining');
          }
        } else {
          print('No checkout date found in profile data for user $userId');
        }
      } else {
        print('Profile mismatch - expected user $userId');
      }
    } else {
      print('Failed to fetch profile data: ${response.body}');
    }
  } catch (e) {
    print('Error checking checkout date: $e');
  }
}

Future<void> _createCheckoutReminderNotification(int daysLeft,  dynamic userId) async {
  String title = 'Masa Sewa Akan Berakhir';
  String message;
  
  if (daysLeft == 0) {
    message = 'Masa sewa kamar Anda berakhir HARI INI. Silakan perpanjang untuk melanjutkan.';
  } else if (daysLeft == 1) {
    message = 'Masa sewa kamar Anda akan berakhir BESOK. Silakan segera perpanjang.';
  } else {
    message = 'Masa sewa kamar Anda akan berakhir dalam $daysLeft hari lagi. Silakan segera perpanjang.';
  }
  
  // Create a notification that will show up in the system tray
  final notificationData = {
    'days_left': daysLeft,
    'type': 'checkout_reminder',
    'targetRole': 'user',
    'targetUserId': userId,
  };
  // Get current user ID to compare
  final currentUserId = await _getCurrentUserId();
  
  // Only create local notification if this is for the current user
  if (currentUserId == userId) {
    await showNotification(
      type: 'checkout_reminder',
      title: title,
      message: message,
      data: notificationData,
      targetRole: 'user',
      targetUserId: userId,
    );
  }
  
  // Send via OneSignal to the specific user
  await sendNotificationToSpecificUser(
    userId: userId,
    title: title,
    message: message,
    type: 'checkout_reminder',
    data: notificationData,
  );
}
  
// Update _saveNotificationLocally method in notification_service.dart
Future<void> _saveNotificationLocally(NotificationModel notification) async {
  try {
    final notifications = await getLocalNotifications();
    
    // Create a copy with a generated ID if none exists
    final updatedNotification = notification.id == null
        ? NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: notification.title,
            message: notification.message,
            type: notification.type,
            createdAt: notification.createdAt,
            isRead: notification.isRead,
            data: notification.data,
            targetRole: notification.targetRole,
            targetUserId: notification.targetUserId,
          )
        : notification;
    
    // Add to the beginning of the list
    notifications.insert(0, updatedNotification);
    
    // Save back to shared preferences
    await _saveNotificationsLocally(notifications);
    
    print('Notification saved locally: ${notification.title}, targetRole: ${notification.targetRole}, targetUserId: ${notification.targetUserId}');
    
  } catch (e) {
    print('Error saving notification locally: $e');
  }
}

 // Update the _saveNotificationsLocally method
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
      'data': n.data != null ? jsonEncode(n.data) : null,
      'target_role': n.targetRole,
      'target_user_id': n.targetUserId,
    })).toList();
    
    await prefs.setStringList(_notificationsKey, jsonList);
    print('Saved ${jsonList.length} notifications to local storage');
  } catch (e) {
    print('Error saving notifications locally: $e');
  }
}
// Replace the getLocalNotifications() method in notification_service.dart
Future<List<NotificationModel>> getLocalNotifications() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_notificationsKey) ?? [];
    final userRole = await _getCurrentUserRole();
    final userId = await _getCurrentUserId();
    
    print('Getting notifications for role: $userRole (ID: $userId)');
    print('Found ${jsonList.length} raw notifications in storage');
    
    final result = <NotificationModel>[];
    
    for (var jsonStr in jsonList) {
      try {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        final notification = NotificationModel(
          id: json['id'],
          title: json['title'] ?? '',
          message: json['message'] ?? '',
          type: json['type'] ?? '',
          createdAt: DateTime.parse(json['created_at']),
          isRead: json['is_read'] ?? false,
          data: json['data'] != null ? jsonDecode(json['data']) : null,
          targetRole: json['target_role'],
          targetUserId: json['target_user_id'],
        );
        
        // FIX: Improved filtering logic - different for admin vs user
        bool shouldInclude = false;
        
        if (userRole == 'admin') {
          // ADMIN FILTERING:
          // 1. Include notifications explicitly targeted to admin role
          // 2. Include notifications with type 'payment_verification' or 'tenant_verification'
          // 3. Include notifications with null targetRole (legacy notifications)
          shouldInclude = 
              notification.targetRole == 'admin' || 
              notification.targetRole == null ||
              notification.type == 'payment_verification' ||
              notification.type == 'tenant_verification';
        } else {
          // USER FILTERING:
          // 1. Include notifications targeted to any user
          // 2. Include notifications specifically targeted to this user ID
          // 3. Include notifications with null targetRole (legacy notifications)
          shouldInclude = 
              notification.targetRole == 'user' || 
              notification.targetRole == null ||
              notification.targetUserId == userId;
        }
        
        if (shouldInclude) {
          result.add(notification);
          print('Including notification: ${notification.title} (${notification.type})');
        } else {
          print('Filtering out notification: ${notification.title}, targetRole: ${notification.targetRole}, targetUserId: ${notification.targetUserId}, type: ${notification.type}');
        }
      } catch (e) {
        print('Error parsing notification JSON: $e');
      }
    }
    
    // Sort notifications by createdAt date (newest first)
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    print('Returning ${result.length} notifications after filtering');
    return result;
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

  // Update sendNotificationToSpecificUser method
Future<bool> sendNotificationToSpecificUser({
  required String userId,
  required String title,
  required String message,
  required String type,
  Map<String, dynamic>? data,
}) async {
  try {
    print('Sending notification to user $userId: $title - $message');
    
    // Prepare data with proper targeting
    final Map<String, dynamic> notificationData = {
      'type': type,
      'targetRole': 'user',
      'targetUserId': userId,
      ...?data,
    };
    
    // Save locally only if this is for the current user
    final currentUserId = await _getCurrentUserId();
    if (currentUserId == userId) {
      final localNotification = NotificationModel(
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        data: notificationData,
        targetRole: 'user',
        targetUserId: userId,
      );
      
      await _saveNotificationLocally(localNotification);
      _updateUnreadCount();
    }
    
    // Rest of the method remains the same...
    final Uri apiUrl = Uri.parse('https://onesignal.com/api/v1/notifications');
    final String restApiKey = "os_v2_app_d6nhgxhb4zhm7bxpgbf247azyklrqxifs3je5446pplbivecyk22tl2svxafm4kb7ra4iqysbbgne3u323gh3zu3izezfzmtebage5q"; 
    
    final Map<String, String> headers = {
      'Authorization': 'Basic $restApiKey',
      'Content-Type': 'application/json',
    };
    
    final Map<String, dynamic> requestBody = {
      "app_id": "1f9a735c-e1e6-4ecf-86ef-304bae7c19c2",
      "filters": [
        {"field": "tag", "key": "user_id", "relation": "=", "value": userId}
      ],
      "headings": {"en": title},
      "contents": {"en": message},
      "data": notificationData
    };
    
    print('Sending OneSignal notification to user $userId with body: ${jsonEncode(requestBody)}');
    
    final response = await http.post(
      apiUrl,
      headers: headers,
      body: jsonEncode(requestBody),
    );
    
    print('OneSignal API Response (to user $userId): ${response.statusCode} - ${response.body}');
    
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

  Future<String?> _getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // Add this method to NotificationService.dart
Future<void> deleteReadNotifications() async {
  try {
    final notifications = await getLocalNotifications();
    final unreadNotifications = notifications.where((n) => !n.isRead).toList();
    await _saveNotificationsLocally(unreadNotifications);
    _updateUnreadCount();
  } catch (e) {
    print('Error deleting read notifications: $e');
  }
}

// Also add this method to register the routes with proper handlers
Future<void> setupNotificationHandling() async {
  // Setup click handler to process notifications that launch the app
  OneSignal.Notifications.addClickListener((event) async {
    try {
      final data = event.notification.additionalData;
      print('📱 Notification clicked with data: ${data.toString()}');
      
      if (data != null) {
        final type = data['type']?.toString();
        final id = data['id'];
        
        // Navigate based on notification type and user role
        _navigateBasedOnType(type, id);
      }
    } catch (e) {
      print('Error handling notification click: $e');
    }
  });

  // Register for foreground notifications at the global level
  OneSignal.Notifications.addForegroundWillDisplayListener(_handleForegroundNotification);
}

// Add this method to NotificationService
Future<void> checkAndNotifyAdminsAboutExpiringRooms() async {
  try {
    final KamarService _kamarService = KamarService();
    
    print('Checking for rooms with expiring leases for admin notification...');
    
    // Get list of rooms with expiring leases (within 7 days)
    List<Map<String, dynamic>> expiringRooms = await _kamarService.getExpiringRooms();
    
    if (expiringRooms.isEmpty) {
      print('No rooms with expiring leases found');
      return;
    }
    
    print('Found ${expiringRooms.length} rooms with expiring leases');
    
    // Format the message with room information
    String notificationMessage;
    
    if (expiringRooms.length == 1) {
      final room = expiringRooms.first;
      final tanggalKeluar = DateTime.parse(room['tanggal_keluar']);
      final daysLeft = tanggalKeluar.difference(DateTime.now()).inDays;
      
      notificationMessage = 'Kamar ${room['nomor_kamar']} akan berakhir masa sewanya dalam $daysLeft hari.';
    } else {
      notificationMessage = 'Ada ${expiringRooms.length} kamar yang akan berakhir masa sewanya dalam 7 hari ke depan.';
    }
    
    // Send notification to all admins
    await sendNotificationToAdmins(
      title: 'Peringatan Masa Sewa Kamar',
      message: notificationMessage,
      type: 'room_expiry_alert',
      data: {
        'expiring_rooms': expiringRooms.map((room) => {
          'nomor_kamar': room['nomor_kamar'],
          'tanggal_keluar': room['tanggal_keluar'],
          'nama_penyewa': room['nama_penyewa'] ?? 'Tidak diketahui',
        }).toList(),
        'count': expiringRooms.length,
      },
    );
    
    print('Admin notification about expiring rooms sent successfully');
    
  } catch (e) {
    print('Error checking and notifying about expiring rooms: $e');
  }
}
}