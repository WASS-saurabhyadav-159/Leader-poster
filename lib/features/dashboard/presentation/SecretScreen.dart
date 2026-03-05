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
  FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _albumGroups = [];
  List<Map<String, dynamic>> _flatPosters = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _fetchPosters();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchPosters({String keyword = "", bool applyFilter = false}) async {
    setState(() => _isLoading = true);

    try {
      String? categoryId;
      if (applyFilter) {
        categoryId = await getSearchCategoryClickId();
        print("Applying Filter - Selected Category ID: $categoryId");
      }

      _albumGroups = await ApiService().searchPosters(
        keyword: keyword,
        categoryId: categoryId,
      );

      _flatPosters = [];
      Set<String> suggestionSet = {};
      
      for (var group in _albumGroups) {
        if (group['album'] != null && group['album']['name'] != null) {
          suggestionSet.add(group['album']['name']);
        }
        
        if (group['posters'] != null && group['posters'] is List) {
          for (var poster in group['posters']) {
            _flatPosters.add(poster);
            if (poster['title'] != null) {
              suggestionSet.add(poster['title']);
            }
          }
        }
      }
      
      _suggestions = suggestionSet.toList();

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
          // IconButton(
          //   icon: Icon(Icons.filter_list, color: Colors.white),
          //   onPressed: () => _showFilterBottomSheet(context),
          // ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  _fetchPosters(keyword: value);
                  setState(() => _showSuggestions = value.isNotEmpty);
                },
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  hintText: 'Search posters...',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.red, // 🔥 Theme highlight
                      width: 1.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_showSuggestions && _suggestions.isNotEmpty)
            Container(
              constraints: BoxConstraints(maxHeight: 200),
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length > 5 ? 5 : _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.search, size: 20, color: Colors.grey),
                    title: Text(suggestion, style: TextStyle(fontSize: 14)),
                    onTap: () {
                      _searchController.text = suggestion;
                      _fetchPosters(keyword: suggestion);
                      setState(() => _showSuggestions = false);
                      _searchFocusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _flatPosters.isEmpty
                ? Center(child: Text("No posters found", style: TextStyle(color: Colors.grey)))
                : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: _flatPosters.length,
              itemBuilder: (context, index) {
                final poster = _flatPosters[index];
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