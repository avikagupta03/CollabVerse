import 'dart:convert';
import 'package:http/http.dart' as http;


class MlApiService {
  static const endpoint = "https://YOUR_CLOUD_FUNCTION_ENDPOINT/suggest_teams";


  static Future<List<dynamic>> getSuggestions(Map<String, dynamic> payload) async {
    final res = await http.post(Uri.parse(endpoint), body: jsonEncode(payload), headers: {'Content-Type': 'application/json'});
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }
}