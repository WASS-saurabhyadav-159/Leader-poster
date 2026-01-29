import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger(); // Initialize the logger

// Default App Master ID constant
const String defaultAppMasterId = '9f2c5b0a-0fab-4abc-bf56-c482f0beb60b';

/// Saves the authentication token to SharedPreferences.
Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);

  // Log the token being saved
  logger.i("Token saved: $token");
}

/// Logs out the user by removing the authentication token from SharedPreferences.
Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');

  // Log the action of logging out
  logger.i("Token removed on logout");
}

/// Retrieves the authentication token from SharedPreferences.
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');

  // Log the token being retrieved
  logger.i("Token retrieved: $token");

  return token;
}

/// Saves the clicked category ID to SharedPreferences.
Future<void> saveCategoryId(String categoryId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_clicked_category', categoryId);

  // Log the stored category ID
  logger.i("Category ID saved: $categoryId");
}

Future<String?> getCategoryId() async {
  final prefs = await SharedPreferences.getInstance();
  String? categoryId = prefs.getString('last_clicked_category');

  // Log the retrieved category ID
  logger.i("Retrieved Category ID: $categoryId");

  return categoryId;
}

/// Saves the clicked category ID to SharedPreferences.
Future<void> saveSearchCategoryClickId(String categoryId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('search_category_click_id', categoryId);
  logger.i("Search Category Click ID saved: $categoryId");
}

/// Retrieves the clicked category ID from SharedPreferences.
Future<String?> getSearchCategoryClickId() async {
  final prefs = await SharedPreferences.getInstance();
  String? categoryId = prefs.getString('search_category_click_id');
  logger.i("Retrieved Search Category Click ID: $categoryId");
  return categoryId;
}

/// Saves the app master ID to SharedPreferences.
/// If no custom ID is provided, uses the default app master ID.
Future<void> saveAppMasterId([String? customAppMasterId]) async {
  final prefs = await SharedPreferences.getInstance();
  final String appMasterIdToSave = customAppMasterId ?? defaultAppMasterId;

  await prefs.setString('app_master_id', appMasterIdToSave);
  logger.i("App Master ID saved: $appMasterIdToSave");
}

/// Retrieves the app master ID from SharedPreferences.
/// Returns the default app master ID if none is stored.
Future<String> getAppMasterId() async {
  final prefs = await SharedPreferences.getInstance();
  String? appMasterId = prefs.getString('app_master_id');

  // If no app master ID is stored, use the default one
  if (appMasterId == null) {
    appMasterId = defaultAppMasterId;
    // Optionally save the default ID for future use
    await saveAppMasterId(defaultAppMasterId);
  }

  logger.i("App Master ID retrieved: $appMasterId");
  return appMasterId;
}

/// Clears the custom app master ID and restores the default one
Future<void> resetAppMasterIdToDefault() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('app_master_id');

  // The next call to getAppMasterId() will automatically use the default
  logger.i("App Master ID reset to default: $defaultAppMasterId");
}

/// Checks if the current app master ID is the default one
Future<bool> isUsingDefaultAppMasterId() async {
  final currentId = await getAppMasterId();
  return currentId == defaultAppMasterId;
}