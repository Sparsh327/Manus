import 'package:manus/core/error/exception.dart';
import 'package:manus/data/data_sources/remote/api_client.dart';
import 'package:manus/data/model/product_model.dart';
import 'package:manus/values/network_constants.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient client;

  ProductRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await client.get(ApiEndPoints.getProducts);
    if (response.statusCode == 200) {
      final List<dynamic> productsJson = response.data['products'];
      return productsJson.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw ServerException(message: 'Failed to fetch products');
    }
  }
}
