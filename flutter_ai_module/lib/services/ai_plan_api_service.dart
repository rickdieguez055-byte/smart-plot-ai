import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plot_input.dart';
import '../models/floor_plan_result.dart';

/// Service for requesting AI plot layouts from Node.js Gateway (SP-AI-05).
class AIPlanApiService {
  final String baseUrl;
  final http.Client client;

  AIPlanApiService({
    this.baseUrl = 'http://10.0.2.2:5000', // Standard Android emulator localhost mapped to host port 5000
    http.Client? client,
  }) : client = client ?? http.Client();

  /// Generates a preliminary floor plan
  Future<FloorPlanResult> generatePlan(PlotInput input, {String? authToken}) async {
    final uri = Uri.parse('$baseUrl/api/v1/plans/generate');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await client.post(
      uri,
      headers: headers,
      body: jsonEncode(input.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return FloorPlanResult.fromJson(data);
    } else {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      final message = errorBody['message'] ?? 'Failed to generate plan';
      throw Exception('SmartPlot AI Error (${response.statusCode}): $message');
    }
  }

  void dispose() {
    client.close();
  }
}
