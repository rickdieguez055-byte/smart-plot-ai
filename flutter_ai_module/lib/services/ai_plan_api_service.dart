library ai_plan_api_service;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/floor_plan_result.dart';
import '../models/plot_input.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.code, this.details});

  @override
  String toString() => message;
}

class AiPlanApiService {
  String baseUrl;

  AiPlanApiService({String? initialBaseUrl})
      : baseUrl = initialBaseUrl ?? ApiConfig.defaultBaseUrl;

  /// Checks Gateway and Microservice connectivity
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final res = await http.get(uri).timeout(
            const Duration(seconds: 4),
          );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sends plot measurements and requirements to the AI gateway
  Future<FloorPlanResult> generatePlan(PlotInput input) async {
    final validationError = input.validate();
    if (validationError != null) {
      throw ApiException(validationError, statusCode: 400, code: 'CLIENT_VALIDATION');
    }

    final uri = Uri.parse('$baseUrl/api/v1/plans/generate');
    final payload = input.toJson();

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: ApiConfig.requestTimeoutSeconds),
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return FloorPlanResult.fromJson(data);
      }

      // Handle specific HTTP error payloads
      String errorMsg = 'Failed to generate floor plan (HTTP ${response.statusCode}).';
      String? errorCode;
      dynamic errorDetails;

      try {
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        errorCode = errorBody['code'] as String?;
        errorDetails = errorBody['detail'] ?? errorBody['error'];

        if (errorBody['message'] != null) {
          errorMsg = errorBody['message'] as String;
        } else if (errorBody['detail'] != null) {
          if (errorBody['detail'] is String) {
            errorMsg = errorBody['detail'] as String;
          } else if (errorBody['detail'] is List) {
            final list = errorBody['detail'] as List;
            if (list.isNotEmpty && list.first is Map) {
              errorMsg = list.first['msg'] ?? errorMsg;
            }
          }
        }
      } catch (_) {}

      if (response.statusCode == 422) {
        errorMsg = 'Dimensional Infeasibility: $errorMsg';
      }

      throw ApiException(
        errorMsg,
        statusCode: response.statusCode,
        code: errorCode,
        details: errorDetails,
      );
    } on SocketException {
      throw ApiException(
        'Cannot connect to SmartPlot Gateway at $baseUrl.\n'
        '• If using Android Emulator, verify baseUrl is set to http://10.0.2.2:5000\n'
        '• If using a physical device, verify computer and phone share the same Wi-Fi.\n'
        '• Ensure Node.js Gateway & FastAPI backend are currently running.',
        code: 'NETWORK_UNREACHABLE',
      );
    } on TimeoutException {
      throw ApiException(
        'Request timed out after ${ApiConfig.requestTimeoutSeconds}s while calculating spatial layouts.\n'
        'Please try again or simplify plot constraints.',
        code: 'GATEWAY_TIMEOUT',
      );
    } on FormatException {
      throw ApiException(
        'Invalid response received from Gateway.',
        code: 'INVALID_JSON',
      );
    }
  }

  /// Sends edited room geometry to backend for architectural validation and live layout recalculation
  Future<PlanEditValidationResultModel> validatePlanEdit({
    required PlotInput plot,
    required int floor,
    required int floorsCount,
    required List<RoomModel> rooms,
    List<RoomModel>? otherFloorRooms,
    List<Map<String, dynamic>>? circulationPaths,
    String? alternativeType,
    String? originalPlanId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/plans/validate-edit');
    final payload = {
      'plot': plot.toJson()['plot'],
      'floor': floor,
      'floors_count': floorsCount,
      'rooms': rooms.map((r) => r.toJson()).toList(),
      if (otherFloorRooms != null && otherFloorRooms.isNotEmpty)
        'other_floor_rooms': otherFloorRooms.map((r) => r.toJson()).toList(),
      if (circulationPaths != null && circulationPaths.isNotEmpty)
        'circulation_paths': circulationPaths,
      'alternative_type': alternativeType ?? 'open_living',
      'original_plan_id': originalPlanId,
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PlanEditValidationResultModel.fromJson(data);
      } else {
        return PlanEditValidationResultModel(
          isValid: false,
          errorCode: 'HTTP_${response.statusCode}',
          rejectionReason: 'Validation request failed with status ${response.statusCode}.',
        );
      }
    } catch (e) {
      return PlanEditValidationResultModel(
        isValid: false,
        errorCode: 'NETWORK_ERROR',
        rejectionReason: 'Could not connect to validation server: $e',
      );
    }
  }

  /// Applies verified edit, updating doors, windows, walls, and receiving new SVG drawing
  Future<PlanEditValidationResultModel> applyPlanEdit({
    required PlotInput plot,
    required int floor,
    required int floorsCount,
    required List<RoomModel> rooms,
    List<RoomModel>? otherFloorRooms,
    List<Map<String, dynamic>>? circulationPaths,
    String? alternativeType,
    String? originalPlanId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/plans/apply-edit');
    final payload = {
      'plot': plot.toJson()['plot'],
      'floor': floor,
      'floors_count': floorsCount,
      'rooms': rooms.map((r) => r.toJson()).toList(),
      if (otherFloorRooms != null && otherFloorRooms.isNotEmpty)
        'other_floor_rooms': otherFloorRooms.map((r) => r.toJson()).toList(),
      if (circulationPaths != null && circulationPaths.isNotEmpty)
        'circulation_paths': circulationPaths,
      'alternative_type': alternativeType ?? 'open_living',
      'original_plan_id': originalPlanId,
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PlanEditValidationResultModel.fromJson(data);
      } else {
        return PlanEditValidationResultModel(
          isValid: false,
          errorCode: 'HTTP_${response.statusCode}',
          rejectionReason: 'Apply edit request failed with status ${response.statusCode}.',
        );
      }
    } catch (e) {
      return PlanEditValidationResultModel(
        isValid: false,
        errorCode: 'NETWORK_ERROR',
        rejectionReason: 'Could not connect to validation server: $e',
      );
    }
  }
}
