import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manus/core/network/network_info.dart';
import 'package:manus/data/data_sources/remote/api_client.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

// ── Logger ───────────────────────────────────────────────────
// Single Talker instance shared across the app.
// Use: ref.read(loggerProvider).info('message')
//      ref.read(loggerProvider).error('msg', error, stackTrace)
final loggerProvider = Provider<Talker>((ref) {
  return TalkerFlutter.init(
    settings: TalkerSettings(
      enabled: true,
      useConsoleLogs: true,
    ),
  );
});

// ── HTTP ─────────────────────────────────────────────────────
final dioProvider = Provider<Dio>((ref) {
  final talker = ref.watch(loggerProvider);
  final dio = Dio();
  dio.interceptors.add(
    TalkerDioLogger(
      talker: talker,
      settings: const TalkerDioLoggerSettings(
        printRequestData: true,
        printResponseData: false, // avoid flooding logs with large responses
        printRequestHeaders: false,
      ),
    ),
  );
  return dio;
});

// ── Connectivity ─────────────────────────────────────────────
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

// ── API client (REST — boilerplate product feature) ──────────
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(dio: ref.watch(dioProvider)),
);

// ── Network info ─────────────────────────────────────────────
final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(ref.watch(connectivityProvider)),
);
