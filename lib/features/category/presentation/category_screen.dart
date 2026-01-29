import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/colors.dart';
import '../../../core/network/api_service.dart';
import '../presentation/events.dart';
import 'edit_banner_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with AutomaticKeepAliveClientMixin<CategoryScreen> {
  late List<String> events = [];
  late List<Map<String, dynamic>> fetchedPosters = [];
  late String categoryId;
  late String specialDayId;
  bool isLoading = true;
  bool isFetchingPosters = false;
  late List<Map<String, dynamic>> fetchedEvents;
  bool hasFetchedOnce = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchCategoryIdAndEvents();
  }

  Future<void> fetchCategoryIdAndEvents() async {
    if (hasFetchedOnce) return; // 🔁 Avoid re-fetching

    final prefs = await SharedPreferences.getInstance();
    categoryId = prefs.getString('last_clicked_category') ?? '';

    try {
      final eventsData = await ApiService().fetchEvents();
      if (mounted) {
        fetchedEvents = eventsData;
        events = fetchedEvents.map<String>((e) => "${e['date']} ${e['name']}").toList();
        if (events.isNotEmpty) {
          specialDayId = fetchedEvents[0]['specialDayId'] ?? '';
          await fetchPosters(specialDayId);
        }
        setState(() {
          isLoading = false;
          hasFetchedOnce = true;
        });
      }
    } catch (e) {
      print("❌ Error fetching events: $e");
      if (mounted) {
        setState(() => isLoading = false);
        showErrorPopup(context, "Network Error", () {
          setState(() => isLoading = true);
          fetchCategoryIdAndEvents();
        });
      }
    }
  }

  Future<void> fetchPosters(String specialDayId) async {
    if (specialDayId.isEmpty) return;

    setState(() {
      isFetchingPosters = true;
    });

    try {
      final posters = await ApiService().fetchPosters(
        categoryId: categoryId,
        // specialDayId: specialDayId,
      );

      if (mounted) {
        setState(() {
          fetchedPosters = posters;
          isFetchingPosters = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching posters: $e");
      if (mounted) {
        setState(() {
          fetchedPosters = [];
          isFetchingPosters = false;
        });
        showErrorPopup(context, "Network Error", () => fetchPosters(specialDayId));
      }
    }
  }

  void showErrorPopup(BuildContext context, String message, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/error_icon.png', height: 80, width: 80, color: Colors.red),
              const SizedBox(height: 15),
              const Text("PLEASE TRY AGAIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Please confirm your internet connection is active.", textAlign: TextAlign.center),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("TRY AGAIN", style: TextStyle(color: Colors.white, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }

  void refreshPosters(String selectedEvent) {
    final selectedEventData = fetchedEvents.firstWhere(
          (event) => "${event['date']} ${event['name']}".trim() == selectedEvent.trim(),
      orElse: () => {},
    );

    if (selectedEventData.isNotEmpty) {
      specialDayId = selectedEventData['specialDayId']?.toString() ??
          selectedEventData['id']?.toString() ?? '';

      if (specialDayId.isNotEmpty) {
        fetchPosters(specialDayId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SharedColors.primary,
        foregroundColor: Colors.white,
        title: const Text("Category Screen", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: EventSelector(
                events,
                onSelected: refreshPosters,
              ),
            ),
            Expanded(
              child: isFetchingPosters
                  ? const Center(child: CircularProgressIndicator())
                  : fetchedPosters.isEmpty
                  ? const Center(child: Text("No poster available for this event"))
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  itemCount: fetchedPosters.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (_, index) {
                    final poster = fetchedPosters[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SocialMediaDetailsPage(
                              assetPath: poster['poster'],
                              categoryId: categoryId,
                              posterId: poster['id'],
                              // Add the missing fields here
                              initialPosition: poster['position'] ?? 'RIGHT',
                              topDefNum: _parseIntSafely(poster['topDefNum']),
                              selfDefNum: _parseIntSafely(poster['selfDefNum']),
                              bottomDefNum: _parseIntSafely(poster['bottomDefNum']),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          poster['poster'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to safely parse integers from dynamic values
  int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}