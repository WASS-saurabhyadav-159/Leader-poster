import 'dart:io';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';

class VideoProcessorService {
  static Future<File> processVideoWithOverlay({
    required File videoFile,
    required File overlayFile,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final outputPath = '${directory.path}/final_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    // iOS-optimized FFmpeg command
    final command = Platform.isIOS
        ? '-y -i "${videoFile.path}" -i "${overlayFile.path}" '
            '-filter_complex "[0:v][1:v]overlay=0:0" '
            '-c:v h264_videotoolbox -b:v 5M -profile:v high -level 4.1 '
            '-pix_fmt yuv420p -movflags +faststart -c:a aac -b:a 128k "$outputPath"'
        : '-y -i "${videoFile.path}" -i "${overlayFile.path}" '
            '-filter_complex "[0:v][1:v]overlay=0:0" '
            '-c:v libx264 -preset medium -crf 23 -profile:v high -level 4.1 '
            '-pix_fmt yuv420p -movflags +faststart -c:a copy "$outputPath"';

    print('🎬 FFmpeg command: $command');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    final logs = await session.getAllLogsAsString();

    print('📊 FFmpeg return code: $returnCode');

    if (ReturnCode.isSuccess(returnCode)) {
      final outputFile = File(outputPath);
      if (await outputFile.exists() && await outputFile.length() > 0) {
        print('✅ Video processed successfully: ${outputFile.path}');
        return outputFile;
      }
      throw Exception('Output file is empty or missing');
    }

    throw Exception('FFmpeg failed: $logs');
  }
}
