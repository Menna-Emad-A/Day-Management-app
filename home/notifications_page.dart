import 'package:flutter/material.dart';

import '../login_pages/lib/database_helper.dart';


class NotificationPage extends StatefulWidget {
  final int userId;

  const NotificationPage({Key? key, required this.userId}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final dbHelper = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _notifications;

  @override
  void initState() {
    super.initState();
    // Fetch the notifications when the page is initialized
    _notifications = dbHelper.getUnreadNotifications(widget.userId);
  }

  // Delete the notification
  Future<void> _deleteNotification(int notificationId) async {
    await dbHelper.deleteNotification(notificationId);
    // Refresh the notifications list
    setState(() {
      _notifications = dbHelper.getUnreadNotifications(widget.userId);
    });
  }

  // Mark notification as read
  Future<void> _markNotificationAsRead(int notificationId) async {
    await dbHelper.markNotificationAsRead(notificationId);
    // Refresh the notifications list
    setState(() {
      _notifications = dbHelper.getUnreadNotifications(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(color: Colors.blue.shade800, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No notifications.'));
          } else {
            final notifications = snapshot.data!;

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final title = notification['NMessage'] ?? 'No Title';
                final description = notification['NType'] ?? 'No description';
                final date = notification['NDate'] ?? 'No date';

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.notifications, color: Colors.blue),
                      title: Text(
                        title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '$description\n$date',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              // Delete the notification
                              await _deleteNotification(notification['NID']);
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        // Mark notification as read
                        await _markNotificationAsRead(notification['NID']);
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}