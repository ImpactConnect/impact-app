import 'dart:io';
import 'dart:math' show log, pow;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class StorageManager {
  static Future<Map<String, int>> getStorageInfo() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = await getTemporaryDirectory();

    return {
      'appSize': await _calculateDirSize(appDir),
      'cacheSize': await _calculateDirSize(cacheDir),
    };
  }

  static Future<int> _calculateDirSize(Directory dir) async {
    if (!dir.existsSync()) return 0;
    int size = 0;
    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      print('Error calculating directory size: $e');
    }
    return size;
  }

  static String formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  static Future<void> clearCache() async {
    final cacheDir = await getTemporaryDirectory();
    if (cacheDir.existsSync()) {
      await cacheDir.delete(recursive: true);
    }
    await DefaultCacheManager().emptyCache();
  }

  static Future<void> clearAppData() async {
    final appDir = await getApplicationDocumentsDirectory();
    if (appDir.existsSync()) {
      await appDir.delete(recursive: true);
    }
  }
}
