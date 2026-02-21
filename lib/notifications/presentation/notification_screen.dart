import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/colors.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/error_handler.dart';
import 'NotificationDisplay.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  Set<int> readNotifications = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final apiService = ApiService();
      final fetchedNotifications = await apiService.fetchNotifications(limit: 10, offset: 0);
      final readIds = await _loadReadNotifications();

      setState(() {
        notifications = fetchedNotifications;
        readNotifications = readIds;
        isLoading = false;
      });
    } catch (e) {
      final errorMsg = await ErrorHandler.getErrorMessage(e);
      setState(() {
        isLoading = false;
      });

      showErrorPopup(
        context,
        errorMsg,
            () {
          setState(() {
            isLoading = true;
          });
          _fetchNotifications();
        },
      );
    }
  }

  void _markAsRead(int id) async {
    setState(() {
      readNotifications.add(id);
    });
    await _saveReadNotifications();
  }

  Future<void> _saveReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('read_notifications', readNotifications.map((id) => id.toString()).toList());
  }

  Future<Set<int>> _loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedIds = prefs.getStringList('read_notifications');
    return savedIds?.map(int.parse).toSet() ?? {};
  }

  void showErrorPopup(BuildContext context, String message, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/error_icon.png',
                  height: 80,
                  width: 80,
                  color: Colors.red,
                ),
                SizedBox(height: 15),
                Text(
                  "PLEASE TRY AGAIN",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetry();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text("TRY AGAIN",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SharedColors.primaryDark,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
              ? const Center(child: Text("No notifications available"))
              : ListView.separated(
            itemCount: notifications.length,
            itemBuilder: (_, index) {
              final notification = notifications[index];
              final bool isRead =
              readNotifications.contains(notification["id"]);

              return GestureDetector(
                onTap: () {
                  _markAsRead(notification["id"]);
                },
                child: NotificationDisplay(
                  title: notification["title"] ?? "No Title",
                  description: notification["desc"] ?? "No Description",
                  isRead: isRead,
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
          ),
        ),
      ),
    );
  }
}