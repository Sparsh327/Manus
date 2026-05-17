import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manus/core/providers/core_providers.dart';
import 'package:manus/values/gemini_constants.dart';
import 'package:talker_flutter/talker_flutter.dart';

// ─────────────────────────────────────────────────────────────
// GeminiService — raw Dio SSE streaming to Gemini API.
//
// Why raw Dio instead of google_generative_ai SDK:
//   The SDK wraps its own HTTP client, making it impossible to
//   pass a Dio CancelToken. The spec explicitly requires that
//   tapping Stop actually cancels the HTTP request at the
//   network layer — not just ignores future tokens.
//   Raw Dio + CancelToken is the only way to meet that spec.
//
// SSE format from Gemini:
//   data: {"candidates":[{"content":{"parts":[{"text":"token"}]}}]}
//   <blank line>
//   data: {"candidates":[...]}
// ─────────────────────────────────────────────────────────────

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(
    dio: ref.watch(dioProvider),
    talker: ref.watch(loggerProvider),
  );
});

class GeminiService {
  final Dio _dio;
  final Talker _talker;

  // API key is injected via --dart-define-from-file=.env
  // Never hardcoded, never committed.
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  GeminiService({required Dio dio, required Talker talker})
    : _dio = dio,
      _talker = talker;

  /// Streams response tokens from Gemini.
  ///
  /// [history] is a list of previous messages in Gemini content format:
  ///   [{"role": "user", "parts": [{"text": "..."}]}, ...]
  ///
  /// Caller must pass a [CancelToken] and call [CancelToken.cancel()]
  /// to abort the HTTP request (not just the Dart stream).
  Stream<String> streamResponse({
    required String prompt,
    required List<Map<String, dynamic>> history,
    required CancelToken cancelToken,
  }) async* {
    if (_apiKey.isEmpty) {
      _talker.error(
        'GEMINI_API_KEY is not set. Run with --dart-define-from-file=.env',
      );
      throw Exception('GEMINI_API_KEY not configured');
    }

    final body = _buildBody(prompt: prompt, history: history);

    try {
      final response = await _dio.post<ResponseBody>(
        GeminiConstants.streamEndpoint,
        queryParameters: {'alt': 'sse', 'key': _apiKey},
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Content-Type': 'application/json'},
        ),
        cancelToken: cancelToken,
      );

      yield* _parseSSE(response.data!.stream, cancelToken);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return; // user cancelled — not an error
      _talker.error('Gemini stream error', e, e.stackTrace);
      rethrow;
    } catch (e, st) {
      _talker.error('Gemini unexpected error', e, st);
      rethrow;
    }
  }

  Stream<String> _parseSSE(
    Stream<List<int>> byteStream,
    CancelToken cancelToken,
  ) async* {
    final buffer = StringBuffer();

    await for (final chunk in byteStream) {
      if (cancelToken.isCancelled) return;

      buffer.write(utf8.decode(chunk, allowMalformed: true));
      final raw = buffer.toString();
      buffer.clear();

      // Split on newlines; keep the last (potentially incomplete) line
      final lines = raw.split('\n');
      buffer.write(lines.removeLast()); // put incomplete line back

      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;

        final jsonStr = trimmed.substring(5).trim();
        if (jsonStr == '[DONE]') return;
        if (jsonStr.isEmpty) continue;

        final token = _extractToken(jsonStr);
        if (token != null && token.isNotEmpty) yield token;
      }
    }

    // Flush any remaining buffered data
    final remaining = buffer.toString().trim();
    if (remaining.startsWith('data:')) {
      final jsonStr = remaining.substring(5).trim();
      if (jsonStr.isNotEmpty && jsonStr != '[DONE]') {
        final token = _extractToken(jsonStr);
        if (token != null && token.isNotEmpty) yield token;
      }
    }
  }

  String? _extractToken(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;
      final content =
          (candidates.first as Map<String, dynamic>)['content']
              as Map<String, dynamic>?;
      if (content == null) return null;
      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;
      return (parts.first as Map<String, dynamic>)['text'] as String?;
    } catch (e) {
      _talker.warning('SSE parse warning: $e | raw: $jsonStr');
      return null;
    }
  }

  Map<String, dynamic> _buildBody({
    required String prompt,
    required List<Map<String, dynamic>> history,
  }) {
    return {
      'systemInstruction': {
        'parts': [
          {'text': GeminiConstants.systemPrompt},
        ],
      },
      'contents': [
        ...history,
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 8192,
      },
    };
  }
}
