import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/local_storage.dart';
import '../../category/domain/category.dart';
import '../../category/presentation/edit_banner_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SecretScreen(),
    );
  }
}

class SecretScreen extends StatefulWidget {
  @override
  _SecretScreenState createState() => _SecretScreenState();
}

class _SecretScreenState extends State<SecretScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _posters = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPosters();
  }

  Future<void> _fetchPosters({String keyword = "", bool applyFilter = false}) async {
    setState(() => _isLoading = true);

    try {
      String? categoryId;
      if (applyFilter) {
        categoryId = await getSearchCategoryClickId();
        print("Applying Filter - Selected Category ID: $categoryId");
      }

      _posters = await ApiService().searchPosters(
        keyword: keyword,
        categoryId: categoryId,
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);

      showErrorPopup(
        context,
        "Network Error",
            () {
          _fetchPosters(keyword: keyword, applyFilter: applyFilter);
        },
      );
    }
  }

  // Helper method to safely parse integers from dynamic values
  int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
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
                  "Please confirm your internet connection is active.",
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
        backgroundColor: SharedColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Categories", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _fetchPosters(keyword: value),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.white),
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _posters.isEmpty
                ? Center(child: Text("No posters found", style: TextStyle(color: Colors.white)))
                : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: _posters.length,
              itemBuilder: (context, index) {
                final poster = _posters[index];
                String imageUrl = poster["poster"] ?? "assets/images/category_p2.png";
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SocialMediaDetailsPage(
                          assetPath: imageUrl,
                          categoryId: poster["categoryId"] ?? "", // Add category ID
                          posterId: poster["id"] ?? "",         // Add poster ID
                          // Add the missing fields here
                          initialPosition: poster["position"] ?? "RIGHT",
                          topDefNum: _parseIntSafely(poster["topDefNum"]),
                          selfDefNum: _parseIntSafely(poster["selfDefNum"]),
                          bottomDefNum: _parseIntSafely(poster["bottomDefNum"]),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset("assets/images/category_p2.png", fit: BoxFit.cover);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => FilterBottomSheet(),
    );

    _fetchPosters(applyFilter: true);
  }
}

class FilterBottomSheet extends StatefulWidget {
  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  List<Category> categories = [];
  bool isLoading = true;
  Map<String, bool> selectedCategories = {};
  bool politicalPoster = false;
  bool trending = false;
  bool newPoster = false;
  bool oldPoster = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    fetchCategories();
    loadSavedFilters();
  }

  Future<void> fetchCategories() async {
    try {
      categories = await _apiService.fetchCategoriesSearch();
      setState(() => isLoading = false);
    } catch (e) {
      print("Error fetching categories: $e");
      setState(() => isLoading = false);

      showErrorPopup(
        context,
        "Network Error",
            () {
          setState(() => isLoading = true);
          fetchCategories();
        },
      );
    }
  }

  Future<void> loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      politicalPoster = prefs.getBool('politicalPoster') ?? false;
      trending = prefs.getBool('trending') ?? false;
      newPoster = prefs.getBool('newPoster') ?? false;
      oldPoster = prefs.getBool('oldPoster') ?? false;
    });
  }

  Future<void> saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('politicalPoster', politicalPoster);
    prefs.setBool('trending', trending);
    prefs.setBool('newPoster', newPoster);
    prefs.setBool('oldPoster', oldPoster);
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
                  "Please confirm your internet connection is active.",
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              Text("Filters", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Divider(),
              if (isLoading)
                Center(child: CircularProgressIndicator())
              else
                ...categories.map((category) => CheckboxListTile(
                  title: Text(category.name),
                  value: selectedCategories[category.id] ?? false,
                  onChanged: (val) => setState(() => selectedCategories[category.id] = val!),
                )),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCategories.isNotEmpty) {
                    String selectedCategoryId = selectedCategories.keys.firstWhere(
                          (key) => selectedCategories[key] == true,
                    );

                    await saveSearchCategoryClickId(selectedCategoryId);
                    print("Saved Category ID: $selectedCategoryId");
                  }

                  await saveFilters();
                  Navigator.pop(context);
                },
                child: Text("Apply Filters"),
              ),
            ],
          ),
        );
      },
    );
  }
}