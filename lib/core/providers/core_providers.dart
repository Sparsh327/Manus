import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manus/core/network/network_info.dart';
import 'package:manus/data/data_sources/remote/api_client.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(dio: ref.watch(dioProvider)),
);

final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(ref.watch(connectivityProvider)),
);
