import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class BackgroundRemovalService {
  static const String _apiKey = 's4qnmX5bpYk9o6tCKnZfBcDK';
  static const String _apiUrl = 'https://api.remove.bg/v1.0/removebg';

  static Future<File?> removeBackground(File imageFile) async {
    try {
      final dio = Dio();
      
      FormData formData = FormData.fromMap({
        'image_file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'size': 'auto',
      });

      final response = await dio.post(
        _apiUrl,
        data: formData,
        options: Options(
          headers: {
            'X-Api-Key': _apiKey,
          },
          responseType: ResponseType.bytes,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final outputFile = File('${tempDir.path}/nobg_$timestamp.png');
        await outputFile.writeAsBytes(response.data);
        return outputFile;
      } else {
        print('Background removal API error: ${response.statusCode}');
        print('Response: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Error removing background: $e');
      return null;
    }
  }
}
