import 'package:dartz/dartz.dart';
import 'package:manus/core/error/failure.dart';
import 'package:manus/domain/entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();
}
