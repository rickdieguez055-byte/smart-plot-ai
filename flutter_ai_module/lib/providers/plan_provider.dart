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

  // Phase 7 Interactive Editing State
  PlanAlternativeModel? _activeEditingAlternative;
  PlanAlternativeModel? _originalGeneratedAlternative;
  final List<PlanAlternativeModel> _undoStack = [];
  final List<PlanAlternativeModel> _redoStack = [];
  String? _selectedRoomId;
  bool _isValidatingEdit = false;
  PlanEditValidationResultModel? _lastValidationResult;

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

  // Phase 7 Editing Getters
  PlanAlternativeModel? get activeEditingAlternative => _activeEditingAlternative;
  PlanAlternativeModel? get originalGeneratedAlternative => _originalGeneratedAlternative;
  String? get selectedRoomId => _selectedRoomId;
  bool get isValidatingEdit => _isValidatingEdit;
  PlanEditValidationResultModel? get lastValidationResult => _lastValidationResult;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

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
    FloorRequirementModel? groundFloor,
    FloorRequirementModel? firstFloor,
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
      groundFloor: groundFloor,
      firstFloor: firstFloor,
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

  /// Saves current active SVG plan locally to disk (with optional floor selection)
  Future<String?> saveCurrentPlanLocally({int? floor}) async {
    final alt = selectedAlternative;
    if (alt == null || _latestResult == null) return null;

    try {
      String svgContent = alt.svgFloorPlan;
      String floorSuffix = '';
      if (alt.floorsCount == 2) {
        if (floor == 1 && alt.svgGroundFloor != null) {
          svgContent = alt.svgGroundFloor!;
          floorSuffix = '_ground_floor';
        } else if (floor == 2 && alt.svgFirstFloor != null) {
          svgContent = alt.svgFirstFloor!;
          floorSuffix = '_first_floor';
        }
      }

      final path = await PlanStorageService.saveFloorPlanSvg(
        planId: _latestResult!.planId,
        title: '${alt.title}$floorSuffix',
        svgContent: svgContent,
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

  /// Saves both ground floor and first floor SVGs for a 2-floor plan
  Future<List<String>?> saveBothFloorsLocally() async {
    final alt = selectedAlternative;
    if (alt == null || _latestResult == null || alt.floorsCount != 2) {
      return null;
    }

    final gfSvg = alt.svgGroundFloor ?? alt.svgFloorPlan;
    final f1Svg = alt.svgFirstFloor ?? alt.svgFloorPlan;

    try {
      final paths = await PlanStorageService.saveBothFloorsSvgs(
        planId: _latestResult!.planId,
        title: alt.title,
        groundFloorSvg: gfSvg,
        firstFloorSvg: f1Svg,
      );
      if (paths.isNotEmpty) {
        _lastSavedFilePath = paths.first;
      }
      notifyListeners();
      return paths;
    } catch (e) {
      _errorMessage = 'Could not save both floors locally: $e';
      notifyListeners();
      return null;
    }
  }

  /// Shares current active plan SVG using native share sheet
  Future<void> shareCurrentPlan({int? floor}) async {
    final alt = selectedAlternative;
    if (alt == null || _latestResult == null) return;

    try {
      final path = await saveCurrentPlanLocally(floor: floor);
      if (path != null) {
        final floorLabel = (floor == 2) ? ' (First Floor)' : (floor == 1 && alt.floorsCount == 2 ? ' (Ground Floor)' : '');
        await PlanStorageService.shareFloorPlan(
          filePath: path,
          title: '${alt.title}$floorLabel',
        );
      }
    } catch (e) {
      _errorMessage = 'Could not share plan: $e';
      notifyListeners();
    }
  }

  /// Lists saved plans on device
  Future<List<SavedPlanItem>> getSavedPlans() async {
    return await PlanStorageService.listSavedPlans();
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

  // ==========================================
  // PHASE 7: INTERACTIVE EDITING METHODS
  // ==========================================

  /// Initializes an editing session from a generated alternative
  void initEditingSession(PlanAlternativeModel plan) {
    _activeEditingAlternative = plan;
    _originalGeneratedAlternative = plan;
    _undoStack.clear();
    _redoStack.clear();
    _selectedRoomId = plan.rooms.isNotEmpty ? plan.rooms.first.id : null;
    _lastValidationResult = null;
    notifyListeners();
  }

  /// Sets the currently selected room for highlighting and editing
  void selectRoom(String? roomId) {
    if (_selectedRoomId != roomId) {
      _selectedRoomId = roomId;
      notifyListeners();
    }
  }

  /// Updates room coordinates or dimensions, pushing previous state to undo stack
  void updateRoomGeometry(
    String roomId, {
    double? x,
    double? y,
    double? width,
    double? length,
    int? floor,
    bool recordUndo = true,
  }) {
    if (_activeEditingAlternative == null) return;

    if (recordUndo) {
      _undoStack.add(_activeEditingAlternative!);
      _redoStack.clear();
    }

    final currentFloor = floor ?? 1;
    final updatedRooms = _activeEditingAlternative!.rooms.map((r) {
      if (r.id == roomId) {
        return r.copyWith(
          x: x,
          y: y,
          width: width,
          length: length,
          floor: floor,
        );
      }
      return r;
    }).toList();

    // Also update segregated floorLayouts if present
    final updatedLayouts = _activeEditingAlternative!.floorLayouts.map((fl) {
      if (fl.floor == currentFloor) {
        final floorRooms = fl.rooms.map((r) {
          if (r.id == roomId) {
            return r.copyWith(
              x: x,
              y: y,
              width: width,
              length: length,
            );
          }
          return r;
        }).toList();
        return fl.copyWith(rooms: floorRooms);
      }
      return fl;
    }).toList();

    _activeEditingAlternative = _activeEditingAlternative!.copyWith(
      rooms: updatedRooms,
      floorLayouts: updatedLayouts,
    );

    notifyListeners();
  }

  /// Undo last room modification
  void undo() {
    if (_undoStack.isEmpty || _activeEditingAlternative == null) return;
    _redoStack.add(_activeEditingAlternative!);
    _activeEditingAlternative = _undoStack.removeLast();
    _lastValidationResult = null;
    notifyListeners();
  }

  /// Redo previously undone room modification
  void redo() {
    if (_redoStack.isEmpty || _activeEditingAlternative == null) return;
    _undoStack.add(_activeEditingAlternative!);
    _activeEditingAlternative = _redoStack.removeLast();
    _lastValidationResult = null;
    notifyListeners();
  }

  /// Resets editing session to the original AI generated layout
  void resetToOriginal() {
    if (_originalGeneratedAlternative == null || _activeEditingAlternative == null) return;
    _undoStack.add(_activeEditingAlternative!);
    _redoStack.clear();
    _activeEditingAlternative = _originalGeneratedAlternative;
    _lastValidationResult = null;
    notifyListeners();
  }

  /// Triggers live backend validation without committing changes
  Future<PlanEditValidationResultModel> validateCurrentEdit({required int floor}) async {
    if (_activeEditingAlternative == null) {
      return const PlanEditValidationResultModel(
        isValid: false,
        rejectionReason: 'No active plan being edited.',
      );
    }

    _isValidatingEdit = true;
    notifyListeners();

    try {
      final isMultiFloor = _activeEditingAlternative!.floorsCount == 2;
      final currentFloorRooms = isMultiFloor
          ? _activeEditingAlternative!.rooms.where((r) => r.floor == floor).toList()
          : _activeEditingAlternative!.rooms;
      final otherFloorRooms = isMultiFloor
          ? _activeEditingAlternative!.rooms.where((r) => r.floor != floor).toList()
          : null;
      final currentLayout = _activeEditingAlternative!.floorLayouts
          .firstWhere((fl) => fl.floor == floor, orElse: () => _activeEditingAlternative!.floorLayouts.first);

      final result = await _apiService.validatePlanEdit(
        plot: _input,
        floor: floor,
        floorsCount: _activeEditingAlternative!.floorsCount,
        rooms: currentFloorRooms,
        otherFloorRooms: otherFloorRooms,
        circulationPaths: currentLayout.circulationPaths.map((cp) => cp.toJson()).toList(),
        alternativeType: _activeEditingAlternative!.layoutType,
        originalPlanId: _latestResult?.planId,
      );

      _lastValidationResult = result;
      _isValidatingEdit = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isValidatingEdit = false;
      final errResult = PlanEditValidationResultModel(
        isValid: false,
        errorCode: 'VALIDATION_EXCEPTION',
        rejectionReason: 'Validation error: $e',
      );
      _lastValidationResult = errResult;
      notifyListeners();
      return errResult;
    }
  }

  /// Applies verified edit, updating doors, windows, walls, and receiving fresh SVG
  Future<bool> applyCurrentEdit({required int floor}) async {
    if (_activeEditingAlternative == null) return false;

    _isValidatingEdit = true;
    notifyListeners();

    try {
      final isMultiFloor = _activeEditingAlternative!.floorsCount == 2;
      final currentFloorRooms = isMultiFloor
          ? _activeEditingAlternative!.rooms.where((r) => r.floor == floor).toList()
          : _activeEditingAlternative!.rooms;
      final otherFloorRooms = isMultiFloor
          ? _activeEditingAlternative!.rooms.where((r) => r.floor != floor).toList()
          : null;
      final currentLayout = _activeEditingAlternative!.floorLayouts
          .firstWhere((fl) => fl.floor == floor, orElse: () => _activeEditingAlternative!.floorLayouts.first);

      final result = await _apiService.applyPlanEdit(
        plot: _input,
        floor: floor,
        floorsCount: _activeEditingAlternative!.floorsCount,
        rooms: currentFloorRooms,
        otherFloorRooms: otherFloorRooms,
        circulationPaths: currentLayout.circulationPaths.map((cp) => cp.toJson()).toList(),
        alternativeType: _activeEditingAlternative!.layoutType,
        originalPlanId: _latestResult?.planId,
      );

      _lastValidationResult = result;
      _isValidatingEdit = false;

      if (result.isValid && result.recalculatedLayout != null) {
        final recalc = result.recalculatedLayout!;

        // Update floor layouts
        final updatedLayouts = _activeEditingAlternative!.floorLayouts.map((fl) {
          if (fl.floor == floor) {
            return recalc;
          }
          return fl;
        }).toList();

        // Update alternative SVG
        final newGfSvg = (floor == 1) ? recalc.svgFloorPlan : _activeEditingAlternative!.svgGroundFloor;
        final newF1Svg = (floor == 2) ? recalc.svgFloorPlan : _activeEditingAlternative!.svgFirstFloor;

        _activeEditingAlternative = _activeEditingAlternative!.copyWith(
          floorLayouts: updatedLayouts,
          svgFloorPlan: recalc.svgFloorPlan,
          svgGroundFloor: newGfSvg,
          svgFirstFloor: newF1Svg,
          spatialBreakdown: recalc.spatialBreakdown,
          doors: recalc.doors,
          windows: recalc.windows,
          circulationPaths: recalc.circulationPaths,
        );

        notifyListeners();
        return true;
      }

      notifyListeners();
      return false;
    } catch (e) {
      _isValidatingEdit = false;
      _lastValidationResult = PlanEditValidationResultModel(
        isValid: false,
        errorCode: 'APPLY_EXCEPTION',
        rejectionReason: 'Failed to apply edit: $e',
      );
      notifyListeners();
      return false;
    }
  }

  /// Saves the active edited plan as a persistent named package
  Future<String?> saveNamedEditedPlan(String customName, {required int floor}) async {
    if (_activeEditingAlternative == null || _latestResult == null) return null;

    try {
      final svgToSave = (floor == 2)
          ? (_activeEditingAlternative!.svgFirstFloor ?? _activeEditingAlternative!.svgFloorPlan)
          : (_activeEditingAlternative!.svgGroundFloor ?? _activeEditingAlternative!.svgFloorPlan);

      final planData = {
        'title': _activeEditingAlternative!.title,
        'layout_type': _activeEditingAlternative!.layoutType,
        'floors_count': _activeEditingAlternative!.floorsCount,
        'floor': floor,
        'rooms': _activeEditingAlternative!.rooms.map((r) => r.toJson()).toList(),
        'doors': _activeEditingAlternative!.doors.map((d) => {
          'id': d.id, 'from_room': d.fromRoom, 'to_room': d.toRoom,
          'x': d.x, 'y': d.y, 'width': d.width, 'wall': d.wall,
        }).toList(),
        'windows': _activeEditingAlternative!.windows.map((w) => {
          'id': w.id, 'room': w.room, 'x': w.x, 'y': w.y, 'width': w.width, 'wall': w.wall,
        }).toList(),
        'spatial_breakdown': {
          'total_plot_area': _activeEditingAlternative!.spatialBreakdown.totalPlotArea,
          'total_covered_area': _activeEditingAlternative!.spatialBreakdown.totalCoveredArea,
          'net_room_area': _activeEditingAlternative!.spatialBreakdown.netRoomArea,
          'circulation_area': _activeEditingAlternative!.spatialBreakdown.circulationArea,
        },
      };

      final path = await PlanStorageService.saveEditedPlanPackage(
        planId: _latestResult!.planId,
        customName: customName,
        planDataJson: planData,
        svgContent: svgToSave,
      );

      _lastSavedFilePath = path;
      notifyListeners();
      return path;
    } catch (e) {
      _errorMessage = 'Could not save named plan: $e';
      notifyListeners();
      return null;
    }
  }
}
