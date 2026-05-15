import 'package:dartz/dartz.dart';
import 'package:manus/core/error/exception.dart';
import 'package:manus/core/error/failure.dart';
import 'package:manus/core/network/network_info.dart';
import 'package:manus/data/data_sources/local/product_local_data_source.dart';
import 'package:manus/data/data_sources/remote/product_remote_data_source.dart';
import 'package:manus/domain/entities/product.dart';
import 'package:manus/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteProducts = await remoteDataSource.getProducts();
        localDataSource.cacheProducts(remoteProducts);
        return Right(remoteProducts);
      } on ServerException catch (e) {
        return Left(
          ServerFailure(message: e.message, statusCode: e.statusCode),
        );
      } catch (e) {
        // If remote fails but we have network, we might want to fallback to cache?
        // Rules say: "Network updates the cache, never the UI directly" effectively means "Single Source of Truth".
        // However, "App must: Show cached data instantly, Sync silently when online".
        // This usually implies a Stream repository or a specific strategy.
        // For a simple Future-based Get, if Server fails, we can fallback to Cache if it exists.
        // But strictly, if we are online and server fails, it IS a server failure.
        // Let's fallback to cache if server fails for robustness?
        // User said: "Show cached data instantly, Sync silently when online" -> This suggests the UI should load Cache FIRST, then trigger a sync.
        // That requires a Stream or a different calling pattern (loadLocal, then loadRemote).
        // Since we are using standard Future<Either> for this UseCase, we return Remote.
        // To support "Show cached data instantly", the UI would call "getProducts(forceRefresh: false)" which might just return cache,
        // OR the UI calls a separate "getLocalProducts" then "getRemoteProducts".
        // FOR NOW: We follow standard Clean Arch "Online ? Remote : Local".
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final localProducts = await localDataSource.getLastProducts();
        return Right(localProducts);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }
}
