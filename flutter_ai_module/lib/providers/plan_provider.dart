library plan_provider;

import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/floor_plan_result.dart';
import '../models/plot_input.dart';
import '../services/ai_plan_api_service.dart';
import '../services/entitlement_service.dart';
import '../services/plan_storage_service.dart';

class PlanProvider extends ChangeNotifier {
  final AiPlanApiService _apiService;
  final EntitlementService _entitlementService = EntitlementService();

  // Active form inputs (Defaulting to standard 5 Marla / 25x45 ft Pakistani plot)
  PlotInput _input = const PlotInput(
    plotLength: 45.0,
    plotWidth: 25.0,
    frontWidth: 25.0,
    entranceOrientation: 'South',
    unit: 'feet',
    bedrooms: 2,
    bathrooms: 2,
    floors: 1,
    kitchen: true,
    livingRoom: true,
    parking: true,
  );

  // Application State
  bool _isLoading = false;
  String _loadingStep = 'Initializing spatial solver...';
  FloorPlanResult? _latestResult;
  int _selectedAlternativeIndex = 0;
  String? _errorMessage;
  bool _isGatewayHealthy = false;
  String? _lastSavedFilePath;

  PlanProvider({String? initialBaseUrl})
      : _apiService = AiPlanApiService(initialBaseUrl: initialBaseUrl ?? ApiConfig.defaultBaseUrl) {
    checkHealth();
  }

  // Getters
  PlotInput get input => _input;
  bool get isLoading => _isLoading;
  String get loadingStep => _loadingStep;
  FloorPlanResult? get latestResult => _latestResult;
  int get selectedAlternativeIndex => _selectedAlternativeIndex;
  String? get errorMessage => _errorMessage;
  bool get isGatewayHealthy => _isGatewayHealthy;
  String get currentBaseUrl => _apiService.baseUrl;
  int get remainingFreeGenerations => _entitlementService.remainingFreeGenerations;
  int get usedGenerations => _entitlementService.usedGenerations;
  bool get canGenerateFree => _entitlementService.canGenerateFree;
  String? get lastSavedFilePath => _lastSavedFilePath;

  /// Returns currently selected alternative
  PlanAlternativeModel? get selectedAlternative {
    if (_latestResult == null) return null;
    if (_latestResult!.alternatives.isNotEmpty) {
      if (_selectedAlternativeIndex >= 0 &&
          _selectedAlternativeIndex < _latestResult!.alternatives.length) {
        return _latestResult!.alternatives[_selectedAlternativeIndex];
      }
      return _latestResult!.alternatives.first;
    }
    return _latestResult!.primaryPlan;
  }

  /// Sets alternative index (0 for Plan A, 1 for Plan B)
  void selectAlternative(int index) {
    if (_selectedAlternativeIndex != index) {
      _selectedAlternativeIndex = index;
      notifyListeners();
    }
  }

  /// Updates active Gateway Base URL
  void updateBaseUrl(String newUrl) {
    _apiService.baseUrl = newUrl.trim();
    checkHealth();
    notifyListeners();
  }

  /// Checks Gateway connectivity
  Future<void> checkHealth() async {
    _isGatewayHealthy = await _apiService.checkHealth();
    notifyListeners();
  }

  /// Updates Plot dimensions and orientation
  void updatePlotInput({
    double? plotLength,
    double? plotWidth,
    double? frontWidth,
    String? entranceOrientation,
    String? unit,
    SetbacksModel? setbacks,
  }) {
    _input = _input.copyWith(
      plotLength: plotLength,
      plotWidth: plotWidth,
      frontWidth: frontWidth,
      entranceOrientation: entranceOrientation,
      unit: unit,
      setbacks: setbacks,
    );
    notifyListeners();
  }

  /// Updates Room Requirements
  void updateRequirements({
    int? bedrooms,
    int? bathrooms,
    int? floors,
    bool? kitchen,
    bool? livingRoom,
    bool? parking,
    bool? diningRoom,
    bool? lawn,
  }) {
    _input = _input.copyWith(
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      floors: floors,
      kitchen: kitchen,
      livingRoom: livingRoom,
      parking: parking,
      diningRoom: diningRoom,
      lawn: lawn,
    );
    notifyListeners();
  }

  /// Triggers AI Floor Plan Generation
  Future<bool> generateFloorPlan() async {
    _errorMessage = null;
    _isLoading = true;
    _loadingStep = 'Validating dimensional feasibility...';
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _loadingStep = 'Running Google OR-Tools CP-SAT spatial solver...';
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));
      _loadingStep = 'Synthesizing Plan A (Open Living) & Plan B (Privacy Focused)...';
      notifyListeners();

      final result = await _apiService.generatePlan(_input);

      _loadingStep = 'Rendering architectural vector SVGs...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));

      _latestResult = result;
      _selectedAlternativeIndex = 0;
      _entitlementService.recordGeneration();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Saves current active SVG plan locally to disk
  Future<String?> saveCurrentPlanLocally() async {
    final alt = selectedAlternative;
    if (alt == null || _latestResult == null) return null;

    try {
      final path = await PlanStorageService.saveFloorPlanSvg(
        planId: _latestResult!.planId,
        title: alt.title,
        svgContent: alt.svgFloorPlan,
      );
      _lastSavedFilePath = path;
      notifyListeners();
      return path;
    } catch (e) {
      _errorMessage = 'Could not save plan locally: $e';
      notifyListeners();
      return null;
    }
  }

  /// Resets prototype entitlement counter for testing
  void resetPrototypeTier() {
    _entitlementService.resetPrototypeTier();
    notifyListeners();
  }

  /// Clears active error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Explicitly sets plan result for test execution and preview
  void setResultForTesting(FloorPlanResult result) {
    _latestResult = result;
    _selectedAlternativeIndex = 0;
    _isGatewayHealthy = true;
    notifyListeners();
  }
}
