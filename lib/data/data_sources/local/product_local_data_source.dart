import 'package:manus/core/error/exception.dart';
import 'package:manus/data/data_sources/local/hive_service.dart';
import 'package:manus/data/model/product_model.dart';

abstract class ProductLocalDataSource {
  Future<void> cacheProducts(List<ProductModel> products);
  Future<List<ProductModel>> getLastProducts();
}

const String cachedProducts = 'CACHED_PRODUCTS';

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final HiveService hiveService;

  ProductLocalDataSourceImpl({required this.hiveService});

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    // Storing as a list of maps for simplicity in this boiler plate
    // In production, register a TypeAdapter for ProductModel
    final productsJson = products.map((e) => e.toJson()).toList();
    await hiveService.save(cachedProducts, productsJson);
  }

  @override
  Future<List<ProductModel>> getLastProducts() async {
    final dynamic jsonList = hiveService.get(cachedProducts);
    if (jsonList != null) {
      // Because Hive might return List<dynamic>, we interpret it
      // Standard casting might be needed
      try {
        final List<dynamic> decoded = jsonList;
        return decoded
            .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        throw CacheException(message: 'Data corrupted');
      }
    } else {
      throw CacheException(message: 'No cached data found');
    }
  }
}
