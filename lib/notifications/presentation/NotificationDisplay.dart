import 'package:flutter/material.dart';
import '../../config/colors.dart';

class NotificationDisplay extends StatelessWidget {
  final String title;
  final String description;
  final bool isRead; // Read status

  const NotificationDisplay({
    required this.title,
    required this.description,
    required this.isRead,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[200] : Colors.white, // Read = Grey, Unread = White
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SharedColors.categoryHighlightBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            "assets/notification_icon.png",
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: SharedColors.hintColor,
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
