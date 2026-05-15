class GeminiConstants {
  GeminiConstants._();

  static const String model = 'gemini-2.5-flash';
  static const String _base =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String streamEndpoint = '$_base/$model:streamGenerateContent';

  static const String systemPrompt =
      'You are Manus, a helpful and capable AI agent. '
      'You can assist with a wide range of tasks including writing, analysis, '
      'coding, research, and more. Be concise, accurate, and helpful.';
}
