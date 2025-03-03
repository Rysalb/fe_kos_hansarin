import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service.dart';
import '../pembayaran/bayar_sewa_screen.dart';
import '../pembayaran/histori_pembayaran_screen.dart';
import '../order_menu/order_history_screen.dart';

class UserNotificationScreen extends StatefulWidget {
  @override
  _UserNotificationScreenState createState() => _UserNotificationScreenState();
}

class _UserNotificationScreenState extends State<UserNotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _filteredNotifications = [];
  bool _isLoading = true;
  String _currentFilter = 'Semua'; // Default filter
  
  // Add filter options
  final List<String> _filterOptions = ['Semua', 'Pembayaran', 'Pesanan', 'Pengingat', 'Belum Dibaca'];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupNotificationListeners();
  }

  void _setupNotificationListeners() {
    try {
      // OneSignal notification click listener
      OneSignal.Notifications.addClickListener((event) {
        print('USER NOTIFICATION CLICK LISTENER CALLED WITH EVENT: $event');
        final data = event.notification.additionalData;
        if (data != null) {
          final type = data['type']?.toString();
          _handleNavigationByType(type, data);
        }
      });

      // OneSignal foreground notification listener
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        print('USER NOTIFICATION WILL DISPLAY LISTENER CALLED');
        // Prevent default display to handle it manually
        event.preventDefault();
        // Display notification after handling
        event.notification.display();
        // Refresh notification list
        _loadNotifications();
      });
    } catch (e) {
      print('Error setting up notification listeners: $e');
    }
  }

  void _handleNavigationByType(String? type, Map<String, dynamic>? data) {
    switch (type) {
      case 'payment_verification': 
        _navigateToPaymentHistory();
        break;
      case 'payment_rejected': // Add this case for rejected payments
        _showRejectionDialog(data);
        _navigateToPaymentHistory();
        break;
      case 'order_verification':
        _navigateToOrderHistory();
        break;
      case 'checkout_reminder':
        _navigateToBayarSewa();
        break;
      case 'tenant_verification': // Add this case
        // Navigate to user dashboard or another appropriate screen
        // For example, just show a message or navigate to main screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Akun Anda telah diverifikasi!'))
        );
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  void _navigateToPaymentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoriPembayaranScreen()),
    ).then((_) => _loadNotifications());
  }

  void _navigateToOrderHistory() {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
      ).then((_) => _loadNotifications());
    } catch (e) {
      print("Error navigating to order history: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka riwayat pesanan'))
      );
    }
  }

  void _navigateToBayarSewa() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BayarSewaScreen()),
    ).then((_) => _loadNotifications());
  }
  
  // Modify this method to apply filtering
  Future<void> _loadNotifications() async {
    try {
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _applyFilter(); // Apply filter when loading
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

  // Add this new method to apply filters
  void _applyFilter() {
    switch (_currentFilter) {
      case 'Pembayaran':
        _filteredNotifications = _notifications
            .where((notification) => 
                notification.type == 'payment_verification' || 
                notification.type == 'payment_rejected')
            .toList();
        break;
      case 'Pesanan':
        _filteredNotifications = _notifications
            .where((notification) => notification.type == 'order_verification')
            .toList();
        break;
      case 'Pengingat':
        _filteredNotifications = _notifications
            .where((notification) => notification.type == 'checkout_reminder')
            .toList();
        break;
      case 'Belum Dibaca':
        _filteredNotifications = _notifications
            .where((notification) => !notification.isRead)
            .toList();
        break;
      case 'Semua':
      default:
        _filteredNotifications = List.from(_notifications);
        break;
    }
  }

  // Add this method for deleting read notifications
  Future<void> _deleteReadNotifications() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Hapus semua notifikasi yang sudah dibaca?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _notificationService.deleteReadNotifications();
              await _loadNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notifikasi yang sudah dibaca telah dihapus')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'checkout_reminder':
        return Color(0xFFFFE0E0); // Light red for urgent reminders
      case 'payment_verification':
        return Color(0xFFE0F7FA); // Light blue for payment notifications
      case 'order_verification':
        return Color(0xFFF0F4C3); // Light yellow for food orders
      default:
        return Color(0xFFFFE5CC); // Default color
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    try {
      if (notification.id != null) {
        await _notificationService.markAsRead(notification.id!.toString());
      }
      
      // Navigate based on notification type
      _handleNavigationByType(notification.type, notification.data);
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  Widget _buildCheckoutReminderBadge(NotificationModel notification) {
    if (notification.type != 'checkout_reminder') {
      return SizedBox.shrink();
    }

    String daysLeft = "";
    if (notification.data != null && notification.data!.containsKey('days_left')) {
      daysLeft = notification.data!['days_left'].toString();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        daysLeft == "0" ? "HARI INI" : "$daysLeft HARI LAGI",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  // Add this new method to show rejection details
  void _showRejectionDialog(Map<String, dynamic>? data) {
    if (data == null) return;
    
    String reason = data['rejection_reason']?.toString() ?? 'Tidak ada alasan yang diberikan';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pembayaran Ditolak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alasan Penolakan:'),
            SizedBox(height: 8),
            Text(reason, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            SizedBox(height: 16),
            Text('Silahkan upload ulang bukti pembayaran sesuai dengan ketentuan.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPaymentHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A2F1C),
            ),
            child: Text('Lihat Riwayat Pembayaran'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up resources if needed
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
        actions: [
          // Add filter icon
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: Colors.black),
            tooltip: 'Filter notifikasi',
            onSelected: (value) {
              setState(() {
                _currentFilter = value;
                _applyFilter();
              });
            },
            itemBuilder: (context) => _filterOptions.map((option) {
              return PopupMenuItem<String>(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      _currentFilter == option ? Icons.check : null,
                      color: Color(0xFF4A2F1C),
                    ),
                    SizedBox(width: 8),
                    Text(option),
                  ],
                ),
              );
            }).toList(),
          ),
          // Add delete icon
          IconButton(
            icon: Icon(Icons.delete_sweep, color: Colors.black),
            tooltip: 'Hapus notifikasi yang sudah dibaca',
            onPressed: _deleteReadNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _filteredNotifications.isEmpty // Use filtered notifications here
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
                        if (_currentFilter != 'Semua')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Filter aktif: $_currentFilter',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredNotifications.length, // Use filtered notifications here
                    itemBuilder: (context, index) {
                      final notification = _filteredNotifications[index]; // Use filtered notifications
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
                            color: notification.isRead 
                                ? null 
                                : _getNotificationColor(notification.type),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: _getNotificationIcon(notification.type),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: notification.isRead 
                                          ? FontWeight.normal 
                                          : FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                _buildCheckoutReminderBadge(notification),
                              ],
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

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'payment_verification':
        return CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.payment, color: Colors.blue),
        );
      case 'checkout_reminder':
        return CircleAvatar(
          backgroundColor: Colors.red[100],
          child: Icon(Icons.access_time, color: Colors.red),
        );
      case 'order_verification':
        return CircleAvatar(
          backgroundColor: Colors.amber[100],
          child: Icon(Icons.fastfood, color: Colors.amber),
        );
      default:
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.notifications, color: Colors.grey),
        );
    }
  }
}