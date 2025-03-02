import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service.dart';
import '../verif_pembayaran/verifikasi_pembayaran_screen.dart';
import '../kelola_penyewa/verifikasi_penyewa.dart';

class NotifikasiScreen extends StatefulWidget {
  @override
  _NotifikasiScreenState createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupNotificationListeners();
    // Pastikan role tag admin sudah terpasang
    _setAdminRoleTag();
  }
  
  void _setupNotificationListeners() {
    try {
      // OneSignal notification click listener
      OneSignal.Notifications.addClickListener((event) {
        print('ADMIN NOTIFICATION CLICK LISTENER CALLED WITH EVENT: $event');
        final data = event.notification.additionalData;
        if (data != null) {
          final type = data['type']?.toString();
          _handleNavigationByType(type);
        }
      });

      // OneSignal foreground notification listener
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        print('ADMIN NOTIFICATION WILL DISPLAY: ${event.notification.jsonRepresentation()}');
        
        // Let it display
        event.notification.display();
        
        // Reload notifications from storage
        _loadNotifications();
      });
    } catch (e) {
      print('Error setting up notification listeners: $e');
    }
  }
  
  Future<void> _setAdminRoleTag() async {
    try {
      await OneSignal.User.addTagWithKey('role', 'admin');
      print('Set admin role tag in NotifikasiScreen');
      
      // Print all current tags to verify
      final tags = await OneSignal.User.getTags();
      print('Current OneSignal tags: $tags');
      
      // Status pendaftaran
      final status = OneSignal.User.pushSubscription.optedIn;
      final id = OneSignal.User.pushSubscription.id;
      print('Subscription status: $status, ID: $id');
    } catch (e) {
      print('Error setting admin role tag: $e');
    }
  }

  void _handleNavigationByType(String? type) {
    switch (type) {
      case 'payment_verification':
        _navigateToPaymentVerification();
        break;
      case 'tenant_verification':
        _navigateToTenantVerification();
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  void _navigateToPaymentVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VerifikasiPembayaranScreen()),
    ).then((_) => _loadNotifications());
  }

  void _navigateToTenantVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VerifikasiPenyewaScreen()),
    ).then((_) => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _notificationService.getNotifications();
      print('Loaded ${notifications.length} notifications');
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    try {
      if (notification.id != null) {
        await _notificationService.markAsRead(notification.id!.toString());
      }
      
      // Navigate based on notification type
      switch (notification.type) {
        case 'payment_verification':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VerifikasiPembayaranScreen()),
          ).then((_) => _loadNotifications());
          break;
        case 'tenant_verification':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VerifikasiPenyewaScreen()),
          ).then((_) => _loadNotifications());
          break;
        default:
          print('Unknown notification type: ${notification.type}');
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  @override
  void dispose() {
    // Make sure to dispose any resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Color(0xFFE7B789),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada notifikasi',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Dismissible(
                        key: Key(notification.id?.toString() ?? index.toString()),
                        background: Container(color: Colors.grey[200]),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          if (notification.id != null) {
                            _notificationService.markAsRead(notification.id!.toString());
                            setState(() {
                              _notifications.removeAt(index);
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1.0,
                              ),
                            ),
                            color: notification.isRead ? null : Color(0xFFFFE5CC),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: _getNotificationIcon(notification.type),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMMM yyyy • HH:mm')
                                      .format(notification.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _handleNotificationTap(notification),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  // Add icon for different notification types
  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'payment_verification':
        return CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.payment, color: Colors.blue),
        );
      case 'tenant_verification':
        return CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.person, color: Colors.green),
        );
      default:
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.notifications, color: Colors.grey),
        );
    }
  }
}