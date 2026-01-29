import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../config/colors.dart';
import '../../../core/models/TodaySpecial.dart';

class TodaySpecialSection extends StatelessWidget {
  final List<TodaySpecial> todaySpecialList;
  final VoidCallback onViewAll;
  final Function(TodaySpecial)? onItemTap; // Make it optional

  const TodaySpecialSection({
    super.key,
    required this.todaySpecialList,
    required this.onViewAll,
    this.onItemTap, // Make it optional
  });

  @override
  Widget build(BuildContext context) {
    if (todaySpecialList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + View All
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Special",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Container(
                  decoration: BoxDecoration(
                    color: SharedColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: const Text(
                    "View All",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Poster list
        SizedBox(
          height: 114,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: todaySpecialList.length,
            itemBuilder: (context, index) {
              final item = todaySpecialList[index];
              return GestureDetector(
                onTap: () => onItemTap?.call(item), // Use safe call operator
                child: Container(
                  width: 114,
                  margin: const EdgeInsets.symmetric(horizontal: 0.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Stack(
                        children: [
                          // Poster image
                          CachedNetworkImage(
                            imageUrl: item.poster,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.error),
                            ),
                          ),

                          // Date label inside poster at bottom-left
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(6),
                                  bottomLeft: Radius.circular(6),
                                ),
                              ),
                              child: Text(
                                _formatDate(item.date),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Converts date string into `10 Sep`
  String _formatDate(String rawDate) {
    try {
      // Handle the specific case: "10 September" → "10 Sep"
      if (RegExp(r'^\d{1,2}\s+[A-Za-z]+$').hasMatch(rawDate.trim())) {
        final parts = rawDate.trim().split(' ');
        if (parts.length == 2) {
          final day = parts[0];
          final month = parts[1];

          // Convert full month name to abbreviated format (first 3 letters)
          String abbreviatedMonth = month.length > 3 ? month.substring(0, 3) : month;

          return '$day $abbreviatedMonth';
        }
      }

      // case 1: backend sends standard format `yyyy-MM-dd`
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)) {
        final parsed = DateTime.parse(rawDate);
        return DateFormat("d MMM").format(parsed);
      }

      // case 2: backend sends `10 September 2025`
      try {
        final parsed = DateFormat("d MMMM yyyy").parse(rawDate);
        return DateFormat("d MMM").format(parsed);
      } catch (_) {}

      // case 3: backend sends `September 10, 2025`
      try {
        final parsed = DateFormat("MMMM d, yyyy").parse(rawDate);
        return DateFormat("d MMM").format(parsed);
      } catch (_) {}

      // fallback (show as-is)
      return rawDate;
    } catch (e) {
      return rawDate;
    }
  }
}