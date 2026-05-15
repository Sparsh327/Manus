import 'package:dartz/dartz.dart';
import 'package:manus/core/error/failure.dart';
import 'package:manus/core/usecase/usecase.dart';
import 'package:manus/domain/entities/product.dart';
import 'package:manus/domain/repositories/product_repository.dart';

class GetProducts implements UseCase<List<Product>, NoParams> {
  final ProductRepository repository;

  GetProducts(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) async {
    return await repository.getProducts();
  }
}
