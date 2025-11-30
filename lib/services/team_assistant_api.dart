import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin HTTP client that calls your deployed LLM gateway (Cloud Function, FastAPI,
/// etc.) to generate team-assistant responses.
class TeamAssistantApi {
  /// Replace with your own HTTPS endpoint that proxies requests to OpenAI,
  /// Gemini, or any other model. It must accept POST body JSON and return
  /// `{ "reply": "..." }`.
  static const endpoint = 'https://YOUR_CLOUD_FUNCTION_ENDPOINT/team_assistant';

  static Future<String?> generateReply(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final reply = decoded['reply']?.toString();
      return reply?.trim().isEmpty ?? true ? null : reply;
    } catch (_) {
      return null;
    }
  }
}
