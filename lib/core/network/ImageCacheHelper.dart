import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImageCacheHelper {
  static final Dio _dio = Dio();
  static final Map<String, File> _memoryCache = {}; // 🔥 keep in memory
  static final Map<String, Completer<File?>> _loadingCompleters = {};
  static final Set<String> _currentlyLoading = {};

  /// Get cached image file (memory → disk → network)
  static Future<File?> getCachedImage(String imageUrl) async {
    try {
      // ✅ Step 1: memory cache
      if (_memoryCache.containsKey(imageUrl)) {
        return _memoryCache[imageUrl];
      }

      // ✅ Step 2: disk cache
      final tempDir = await getTemporaryDirectory();
      final fileName = _getFileName(imageUrl);
      final file = File('${tempDir.path}/$fileName');
      if (await file.exists()) {
        _memoryCache[imageUrl] = file;
        return file;
      }

      // ✅ Step 3: network download
      if (imageUrl.startsWith('http')) {
        final response = await _dio.get(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        await file.writeAsBytes(response.data);
        _memoryCache[imageUrl] = file;
        return file;
      } else {
        final localFile = File(imageUrl);
        if (await localFile.exists()) {
          _memoryCache[imageUrl] = localFile;
          return localFile;
        }
      }
      return null;
    } catch (e) {
      print("⚠️ getCachedImage error for $imageUrl: $e");
      return null;
    }
  }

  /// 🔥 NEW: Pre-cache image (optimized for instant loading)
  static Future<File?> preCacheImage(String url) async {
    // Return immediately if already in memory cache
    if (_memoryCache.containsKey(url)) {
      return _memoryCache[url];
    }

    // Return existing completer if already loading
    if (_loadingCompleters.containsKey(url)) {
      return _loadingCompleters[url]!.future;
    }

    // Prevent duplicate loading
    if (_currentlyLoading.contains(url)) {
      final completer = Completer<File?>();
      _loadingCompleters[url] = completer;
      return completer.future;
    }

    _currentlyLoading.add(url);

    try {
      final file = await getCachedImage(url);

      // Complete any waiting completers
      if (_loadingCompleters.containsKey(url)) {
        _loadingCompleters[url]!.complete(file);
        _loadingCompleters.remove(url);
      }

      _currentlyLoading.remove(url);
      return file;
    } catch (e) {
      _currentlyLoading.remove(url);

      // Complete with error
      if (_loadingCompleters.containsKey(url)) {
        _loadingCompleters[url]!.complete(null);
        _loadingCompleters.remove(url);
      }

      print("⚠️ preCacheImage error for $url: $e");
      return null;
    }
  }

  /// 🔥 NEW: Pre-cache multiple images in parallel
  static Future<void> preCacheMultipleImages(List<String> urls, {int batchSize = 6}) async {
    if (urls.isEmpty) return;

    // Filter out already cached URLs
    final urlsToCache = urls.where((url) => !_memoryCache.containsKey(url)).toList();

    if (urlsToCache.isEmpty) {
      print("✅ All ${urls.length} images already cached in memory");
      return;
    }

    print("🔄 Pre-caching ${urlsToCache.length} images (batch size: $batchSize)...");

    // Load in batches to avoid overwhelming the network
    for (int i = 0; i < urlsToCache.length; i += batchSize) {
      final batch = urlsToCache.sublist(
          i,
          i + batchSize > urlsToCache.length ? urlsToCache.length : i + batchSize
      );

      // Load batch in parallel with error handling
      final results = await Future.wait(
        batch.map((url) => preCacheImage(url).catchError((e) {
          print("❌ Failed to pre-cache image: $url - $e");
          return null; // Continue even if some fail
        })),
        eagerError: false, // Continue even if some fail
      );

      final successful = results.where((result) => result != null).length;
      print("✅ Pre-cached batch ${(i ~/ batchSize) + 1}: $successful/${batch.length} images");

      // Small delay between batches to prevent overwhelming
      if (i + batchSize < urlsToCache.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    final totalCached = urlsToCache.where((url) => _memoryCache.containsKey(url)).length;
    print("🎉 Pre-caching completed: $totalCached/${urlsToCache.length} images cached successfully");
  }

  /// 🔥 NEW: Get pre-cached image from memory (instant access)
  static File? getPrecachedImage(String url) {
    return _memoryCache[url];
  }

  /// 🔥 NEW: Check if image is already cached
  static bool isImageCached(String url) {
    return _memoryCache.containsKey(url);
  }

  /// 🔥 NEW: Clear memory cache (useful for memory management)
  static void clearMemoryCache() {
    _memoryCache.clear();
    _loadingCompleters.clear();
    _currentlyLoading.clear();
    print("🧹 Memory cache cleared");
  }

  /// 🔥 NEW: Clear specific image from cache
  static void removeFromCache(String url) {
    _memoryCache.remove(url);
    _loadingCompleters.remove(url);
    _currentlyLoading.remove(url);
  }

  /// 🔥 NEW: Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'memoryCacheSize': _memoryCache.length,
      'currentlyLoading': _currentlyLoading.length,
      'pendingCompleters': _loadingCompleters.length,
    };
  }

  /// 🔥 NEW: Get file name from URL with proper extension
  static String _getFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        String fileName = pathSegments.last;
        // Ensure file has proper extension
        if (!fileName.contains('.') && uri.path.contains('.')) {
          final ext = uri.path.split('.').last;
          fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        }
        return fileName;
      }
    } catch (e) {
      print("⚠️ Error parsing URL for filename: $e");
    }

    // Fallback filename
    return 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  /// 🔥 NEW: Warm up cache for critical images
  static Future<void> warmUpCache(List<String> criticalUrls) async {
    if (criticalUrls.isEmpty) return;

    print("🔥 Warming up cache for ${criticalUrls.length} critical images...");

    // Start caching but don't wait for completion
    unawaited(preCacheMultipleImages(criticalUrls));
  }

  /// 🔥 NEW: Batch pre-cache with progress callback
  static Future<void> preCacheWithProgress(
      List<String> urls, {
        required void Function(int completed, int total) onProgress,
        int batchSize = 2,
      }) async {
    if (urls.isEmpty) return;

    final total = urls.length;
    int completed = 0;

    for (int i = 0; i < total; i += batchSize) {
      final batch = urls.sublist(
          i,
          i + batchSize > total ? total : i + batchSize
      );

      await Future.wait(
        batch.map((url) async {
          await preCacheImage(url);
          completed++;
          onProgress(completed, total);
        }),
        eagerError: false,
      );
    }
  }
}