import 'package:hive/hive.dart';
import 'package:manus/core/error/exception.dart';
import 'package:manus/data/data_sources/local/product_local_data_source.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  final Box box;

  HiveService(this.box);

  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    // Open Boxes
    await Hive.openBox(cachedProducts);
  }

  Future<void> save(String key, dynamic value) async {
    try {
      await box.put(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to save data: $e');
    }
  }

  dynamic get(String key) {
    try {
      return box.get(key);
    } catch (e) {
      throw CacheException(message: 'Failed to fetch data: $e');
    }
  }

  Future<void> delete(String key) async {
    try {
      await box.delete(key);
    } catch (e) {
      throw CacheException(message: 'Failed to delete data: $e');
    }
  }

  Future<void> clear() async {
    try {
      await box.clear();
    } catch (e) {
      throw CacheException(message: 'Failed to clear cache: $e');
    }
  }

  bool has(String key) {
    return box.containsKey(key);
  }
}
