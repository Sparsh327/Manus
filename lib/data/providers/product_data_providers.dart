import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:manus/core/providers/core_providers.dart';
import 'package:manus/data/data_sources/local/hive_service.dart';
import 'package:manus/data/data_sources/local/product_local_data_source.dart';
import 'package:manus/data/data_sources/remote/product_remote_data_source.dart';
import 'package:manus/data/repositories/product_repository_impl.dart';
import 'package:manus/domain/repositories/product_repository.dart';

final productHiveServiceProvider = Provider<HiveService>(
  (ref) => HiveService(Hive.box(cachedProducts)),
);

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>(
  (ref) => ProductRemoteDataSourceImpl(client: ref.watch(apiClientProvider)),
);

final productLocalDataSourceProvider = Provider<ProductLocalDataSource>(
  (ref) => ProductLocalDataSourceImpl(
    hiveService: ref.watch(productHiveServiceProvider),
  ),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
    localDataSource: ref.watch(productLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  ),
);
