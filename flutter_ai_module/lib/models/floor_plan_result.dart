library floor_plan_result;

/// Floor plan result models matching SP-AI-07, SP-AI-08, SP-AI-10 and Phase 2 dual-alternative specs.

class SpatialBreakdownModel {
  final double totalPlotArea;
  final double netRoomArea;
  final double circulationArea;
  final double wallArea;
  final double openUnallocatedArea;
  final double setbackArea;
  final double totalCoveredArea;
  final double utilizationPercentage;
  final double? groundCoveredFootprint;
  final double? firstCoveredFootprint;
  final double? roomUsableArea;
  final double? staircaseArea;
  final double terraceBalconyArea;
  final double? totalConstructedFloorArea;
  final double? uncoveredArea;
  final bool conservationVerified;
  final double conservationDiscrepancy;

  const SpatialBreakdownModel({
    required this.totalPlotArea,
    required this.netRoomArea,
    required this.circulationArea,
    required this.wallArea,
    required this.openUnallocatedArea,
    required this.setbackArea,
    required this.totalCoveredArea,
    required this.utilizationPercentage,
    this.groundCoveredFootprint,
    this.firstCoveredFootprint,
    this.roomUsableArea,
    this.staircaseArea,
    this.terraceBalconyArea = 0.0,
    this.totalConstructedFloorArea,
    this.uncoveredArea,
    this.conservationVerified = true,
    this.conservationDiscrepancy = 0.0,
  });

  factory SpatialBreakdownModel.fromJson(Map<String, dynamic> json) {
    return SpatialBreakdownModel(
      totalPlotArea: (json['total_plot_area'] as num?)?.toDouble() ?? 0.0,
      netRoomArea: (json['net_room_area'] as num?)?.toDouble() ?? 0.0,
      circulationArea: (json['circulation_area'] as num?)?.toDouble() ?? 0.0,
      wallArea: (json['wall_area'] as num?)?.toDouble() ?? 0.0,
      openUnallocatedArea: (json['open_unallocated_area'] as num?)?.toDouble() ?? 0.0,
      setbackArea: (json['setback_area'] as num?)?.toDouble() ?? 0.0,
      totalCoveredArea: (json['total_covered_area'] as num?)?.toDouble() ?? 0.0,
      utilizationPercentage: (json['utilization_percentage'] as num?)?.toDouble() ?? 0.0,
      groundCoveredFootprint: (json['ground_covered_footprint'] as num?)?.toDouble(),
      firstCoveredFootprint: (json['first_covered_footprint'] as num?)?.toDouble(),
      roomUsableArea: (json['room_usable_area'] as num?)?.toDouble(),
      staircaseArea: (json['staircase_area'] as num?)?.toDouble(),
      terraceBalconyArea: (json['terrace_balcony_area'] as num?)?.toDouble() ?? 0.0,
      totalConstructedFloorArea: (json['total_constructed_floor_area'] as num?)?.toDouble(),
      uncoveredArea: (json['uncovered_area'] as num?)?.toDouble(),
      conservationVerified: json['conservation_verified'] as bool? ?? true,
      conservationDiscrepancy: (json['conservation_discrepancy'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DoorModel {
  final String id;
  final String fromRoom;
  final String toRoom;
  final double x;
  final double y;
  final double width;
  final String wall;
  final bool isExterior;
  final String swing;

  const DoorModel({
    required this.id,
    required this.fromRoom,
    required this.toRoom,
    required this.x,
    required this.y,
    required this.width,
    required this.wall,
    this.isExterior = false,
    this.swing = 'inward',
  });

  factory DoorModel.fromJson(Map<String, dynamic> json) {
    return DoorModel(
      id: json['id'] as String? ?? '',
      fromRoom: json['from_room'] as String? ?? '',
      toRoom: json['to_room'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 3.0,
      wall: json['wall'] as String? ?? 'south',
      isExterior: json['is_exterior'] as bool? ?? false,
      swing: json['swing'] as String? ?? 'inward',
    );
  }
}

class WindowModel {
  final String id;
  final String room;
  final double x;
  final double y;
  final double width;
  final String wall;
  final bool isExterior;

  const WindowModel({
    required this.id,
    required this.room,
    required this.x,
    required this.y,
    required this.width,
    required this.wall,
    this.isExterior = true,
  });

  factory WindowModel.fromJson(Map<String, dynamic> json) {
    return WindowModel(
      id: json['id'] as String? ?? '',
      room: json['room'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 4.0,
      wall: json['wall'] as String? ?? 'north',
      isExterior: json['is_exterior'] as bool? ?? true,
    );
  }
}

class CirculationPathModel {
  final String id;
  final String name;
  final double x;
  final double y;
  final double width;
  final double length;
  final double area;

  const CirculationPathModel({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.length,
    required this.area,
  });

  factory CirculationPathModel.fromJson(Map<String, dynamic> json) {
    return CirculationPathModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Corridor',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 3.5,
      length: (json['length'] as num?)?.toDouble() ?? 3.5,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'x': x,
    'y': y,
    'width': width,
    'length': length,
    'area': area,
  };
}

class RoomModel {
  final String id;
  final String name;
  final String category;
  final double x;
  final double y;
  final double width;
  final double length;
  final double area;
  final int floor;

  const RoomModel({
    required this.id,
    required this.name,
    required this.category,
    required this.x,
    required this.y,
    required this.width,
    required this.length,
    required this.area,
    this.floor = 1,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      floor: json['floor'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'x': x,
      'y': y,
      'width': width,
      'length': length,
      'area': area,
      'floor': floor,
    };
  }

  RoomModel copyWith({
    String? id,
    String? name,
    String? category,
    double? x,
    double? y,
    double? width,
    double? length,
    double? area,
    int? floor,
  }) {
    final newW = width ?? this.width;
    final newL = length ?? this.length;
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      x: x ?? this.x,
      y: y ?? this.y,
      width: newW,
      length: newL,
      area: area ?? (newW * newL),
      floor: floor ?? this.floor,
    );
  }
}

class RecommendationModel {
  final String category;
  final String title;
  final String description;
  final double? score;

  const RecommendationModel({
    required this.category,
    required this.title,
    required this.description,
    this.score,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      category: json['category'] as String? ?? 'General',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
    );
  }
}

class FloorLayoutModel {
  final int floor;
  final String name;
  final List<RoomModel> rooms;
  final List<CirculationPathModel> circulationPaths;
  final List<DoorModel> doors;
  final List<WindowModel> windows;
  final SpatialBreakdownModel spatialBreakdown;
  final String svgFloorPlan;
  final Map<String, dynamic>? staircaseBoundingBox;

  const FloorLayoutModel({
    required this.floor,
    required this.name,
    required this.rooms,
    required this.circulationPaths,
    required this.doors,
    required this.windows,
    required this.spatialBreakdown,
    required this.svgFloorPlan,
    this.staircaseBoundingBox,
  });

  factory FloorLayoutModel.fromJson(Map<String, dynamic> json) {
    return FloorLayoutModel(
      floor: json['floor'] as int? ?? 1,
      name: json['name'] as String? ?? 'Floor Plan',
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((r) => RoomModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      circulationPaths: (json['circulation_paths'] as List<dynamic>?)
              ?.map((cp) => CirculationPathModel.fromJson(cp as Map<String, dynamic>))
              .toList() ??
          [],
      doors: (json['doors'] as List<dynamic>?)
              ?.map((d) => DoorModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      windows: (json['windows'] as List<dynamic>?)
              ?.map((w) => WindowModel.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      spatialBreakdown: json['spatial_breakdown'] != null
          ? SpatialBreakdownModel.fromJson(json['spatial_breakdown'] as Map<String, dynamic>)
          : const SpatialBreakdownModel(
              totalPlotArea: 0.0,
              netRoomArea: 0.0,
              circulationArea: 0.0,
              wallArea: 0.0,
              openUnallocatedArea: 0.0,
              setbackArea: 0.0,
              totalCoveredArea: 0.0,
              utilizationPercentage: 0.0,
            ),
      svgFloorPlan: json['svg_floor_plan'] as String? ?? '',
      staircaseBoundingBox: json['staircase_bounding_box'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'floor': floor,
      'name': name,
      'rooms': rooms.map((r) => r.toJson()).toList(),
      'circulation_paths': circulationPaths.map((cp) => {
        'id': cp.id,
        'name': cp.name,
        'x': cp.x,
        'y': cp.y,
        'width': cp.width,
        'length': cp.length,
        'area': cp.area,
      }).toList(),
      'doors': doors.map((d) => {
        'id': d.id,
        'from_room': d.fromRoom,
        'to_room': d.toRoom,
        'x': d.x,
        'y': d.y,
        'width': d.width,
        'wall': d.wall,
        'is_exterior': d.isExterior,
        'swing': d.swing,
      }).toList(),
      'windows': windows.map((w) => {
        'id': w.id,
        'room': w.room,
        'x': w.x,
        'y': w.y,
        'width': w.width,
        'wall': w.wall,
        'is_exterior': w.isExterior,
      }).toList(),
      'svg_floor_plan': svgFloorPlan,
      'staircase_bounding_box': staircaseBoundingBox,
    };
  }

  FloorLayoutModel copyWith({
    int? floor,
    String? name,
    List<RoomModel>? rooms,
    List<CirculationPathModel>? circulationPaths,
    List<DoorModel>? doors,
    List<WindowModel>? windows,
    SpatialBreakdownModel? spatialBreakdown,
    String? svgFloorPlan,
    Map<String, dynamic>? staircaseBoundingBox,
  }) {
    return FloorLayoutModel(
      floor: floor ?? this.floor,
      name: name ?? this.name,
      rooms: rooms ?? this.rooms,
      circulationPaths: circulationPaths ?? this.circulationPaths,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      spatialBreakdown: spatialBreakdown ?? this.spatialBreakdown,
      svgFloorPlan: svgFloorPlan ?? this.svgFloorPlan,
      staircaseBoundingBox: staircaseBoundingBox ?? this.staircaseBoundingBox,
    );
  }
}

class StaircaseValidationModel {
  final bool isValid;
  final bool aligned;
  final double dxAlignment;
  final double dyAlignment;
  final double dwAlignment;
  final double dlAlignment;
  final Map<String, dynamic> dimensions;
  final String blondelComfortFormula;
  final bool headroomCleared;
  final bool overlapDetected;
  final bool connectivityVerified;
  final String groundFloorIndicator;
  final String firstFloorIndicator;
  final String structuralDisclaimer;

  const StaircaseValidationModel({
    this.isValid = true,
    this.aligned = true,
    this.dxAlignment = 0.0,
    this.dyAlignment = 0.0,
    this.dwAlignment = 0.0,
    this.dlAlignment = 0.0,
    this.dimensions = const {},
    this.blondelComfortFormula = '',
    this.headroomCleared = true,
    this.overlapDetected = false,
    this.connectivityVerified = true,
    this.groundFloorIndicator = 'UP ↑',
    this.firstFloorIndicator = 'DN ↓',
    this.structuralDisclaimer = '',
  });

  factory StaircaseValidationModel.fromJson(Map<String, dynamic> json) {
    return StaircaseValidationModel(
      isValid: json['is_valid'] as bool? ?? true,
      aligned: json['aligned'] as bool? ?? true,
      dxAlignment: (json['dx_alignment'] as num?)?.toDouble() ?? 0.0,
      dyAlignment: (json['dy_alignment'] as num?)?.toDouble() ?? 0.0,
      dwAlignment: (json['dw_alignment'] as num?)?.toDouble() ?? 0.0,
      dlAlignment: (json['dl_alignment'] as num?)?.toDouble() ?? 0.0,
      dimensions: json['dimensions'] as Map<String, dynamic>? ?? const {},
      blondelComfortFormula: json['blondel_comfort_formula'] as String? ?? '',
      headroomCleared: json['headroom_cleared'] as bool? ?? true,
      overlapDetected: json['overlap_detected'] as bool? ?? false,
      connectivityVerified: json['connectivity_verified'] as bool? ?? true,
      groundFloorIndicator: json['ground_floor_indicator'] as String? ?? 'UP ↑',
      firstFloorIndicator: json['first_floor_indicator'] as String? ?? 'DN ↓',
      structuralDisclaimer: json['structural_disclaimer'] as String? ?? '',
    );
  }
}

class PlanAlternativeModel {
  final String layoutType;
  final String title;
  final String description;
  final List<RoomModel> rooms;
  final List<CirculationPathModel> circulationPaths;
  final List<DoorModel> doors;
  final List<WindowModel> windows;
  final SpatialBreakdownModel spatialBreakdown;
  final List<RecommendationModel> recommendations;
  final String svgFloorPlan;
  final bool isFeasible;
  final bool connectivityVerified;
  final int floorsCount;
  final List<FloorLayoutModel> floorLayouts;
  final String? svgGroundFloor;
  final String? svgFirstFloor;
  final bool staircaseAligned;
  final StaircaseValidationModel? staircaseValidation;

  const PlanAlternativeModel({
    required this.layoutType,
    required this.title,
    required this.description,
    required this.rooms,
    required this.circulationPaths,
    required this.doors,
    required this.windows,
    required this.spatialBreakdown,
    required this.recommendations,
    required this.svgFloorPlan,
    this.isFeasible = true,
    this.connectivityVerified = true,
    this.floorsCount = 1,
    this.floorLayouts = const [],
    this.svgGroundFloor,
    this.svgFirstFloor,
    this.staircaseAligned = false,
    this.staircaseValidation,
  });

  factory PlanAlternativeModel.fromJson(Map<String, dynamic> json) {
    final layoutsJson = json['floor_layouts'] as List<dynamic>?;
    final List<FloorLayoutModel> layoutsList = layoutsJson != null
        ? layoutsJson.map((fl) => FloorLayoutModel.fromJson(fl as Map<String, dynamic>)).toList()
        : [];

    return PlanAlternativeModel(
      layoutType: json['layout_type'] as String? ?? 'open_living',
      title: json['title'] as String? ?? 'Plan Alternative',
      description: json['description'] as String? ?? '',
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((r) => RoomModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      circulationPaths: (json['circulation_paths'] as List<dynamic>?)
              ?.map((cp) => CirculationPathModel.fromJson(cp as Map<String, dynamic>))
              .toList() ??
          [],
      doors: (json['doors'] as List<dynamic>?)
              ?.map((d) => DoorModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      windows: (json['windows'] as List<dynamic>?)
              ?.map((w) => WindowModel.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      spatialBreakdown: json['spatial_breakdown'] != null
          ? SpatialBreakdownModel.fromJson(json['spatial_breakdown'] as Map<String, dynamic>)
          : const SpatialBreakdownModel(
              totalPlotArea: 0.0,
              netRoomArea: 0.0,
              circulationArea: 0.0,
              wallArea: 0.0,
              openUnallocatedArea: 0.0,
              setbackArea: 0.0,
              totalCoveredArea: 0.0,
              utilizationPercentage: 0.0,
            ),
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((rec) => RecommendationModel.fromJson(rec as Map<String, dynamic>))
              .toList() ??
          [],
      svgFloorPlan: json['svg_floor_plan'] as String? ?? '',
      isFeasible: json['is_feasible'] as bool? ?? true,
      connectivityVerified: json['connectivity_verified'] as bool? ?? true,
      floorsCount: json['floors_count'] as int? ?? 1,
      floorLayouts: layoutsList,
      svgGroundFloor: json['svg_ground_floor'] as String?,
      svgFirstFloor: json['svg_first_floor'] as String?,
      staircaseAligned: json['staircase_aligned'] as bool? ?? false,
      staircaseValidation: json['staircase_validation'] != null
          ? StaircaseValidationModel.fromJson(json['staircase_validation'] as Map<String, dynamic>)
          : null,
    );
  }

  PlanAlternativeModel copyWith({
    String? layoutType,
    String? title,
    String? description,
    List<RoomModel>? rooms,
    List<CirculationPathModel>? circulationPaths,
    List<DoorModel>? doors,
    List<WindowModel>? windows,
    SpatialBreakdownModel? spatialBreakdown,
    List<RecommendationModel>? recommendations,
    String? svgFloorPlan,
    bool? isFeasible,
    bool? connectivityVerified,
    int? floorsCount,
    List<FloorLayoutModel>? floorLayouts,
    String? svgGroundFloor,
    String? svgFirstFloor,
    bool? staircaseAligned,
    StaircaseValidationModel? staircaseValidation,
  }) {
    return PlanAlternativeModel(
      layoutType: layoutType ?? this.layoutType,
      title: title ?? this.title,
      description: description ?? this.description,
      rooms: rooms ?? this.rooms,
      circulationPaths: circulationPaths ?? this.circulationPaths,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      spatialBreakdown: spatialBreakdown ?? this.spatialBreakdown,
      recommendations: recommendations ?? this.recommendations,
      svgFloorPlan: svgFloorPlan ?? this.svgFloorPlan,
      isFeasible: isFeasible ?? this.isFeasible,
      connectivityVerified: connectivityVerified ?? this.connectivityVerified,
      floorsCount: floorsCount ?? this.floorsCount,
      floorLayouts: floorLayouts ?? this.floorLayouts,
      svgGroundFloor: svgGroundFloor ?? this.svgGroundFloor,
      svgFirstFloor: svgFirstFloor ?? this.svgFirstFloor,
      staircaseAligned: staircaseAligned ?? this.staircaseAligned,
      staircaseValidation: staircaseValidation ?? this.staircaseValidation,
    );
  }
}

class PlanEditValidationResultModel {
  final bool isValid;
  final String? errorCode;
  final String? rejectionReason;
  final List<String> conflictingRoomIds;
  final FloorLayoutModel? recalculatedLayout;
  final Map<String, dynamic>? multiFloorValidation;
  final bool isMlRecommended;
  final List<String> recommendations;

  const PlanEditValidationResultModel({
    required this.isValid,
    this.errorCode,
    this.rejectionReason,
    this.conflictingRoomIds = const [],
    this.recalculatedLayout,
    this.multiFloorValidation,
    this.isMlRecommended = false,
    this.recommendations = const [],
  });

  factory PlanEditValidationResultModel.fromJson(Map<String, dynamic> json) {
    return PlanEditValidationResultModel(
      isValid: json['is_valid'] as bool? ?? false,
      errorCode: json['error_code'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      conflictingRoomIds: (json['conflicting_room_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          [],
      recalculatedLayout: json['recalculated_layout'] != null
          ? FloorLayoutModel.fromJson(json['recalculated_layout'] as Map<String, dynamic>)
          : null,
      multiFloorValidation: json['multi_floor_validation'] as Map<String, dynamic>?,
      isMlRecommended: json['is_ml_recommended'] as bool? ?? false,
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((r) => r.toString())
              .toList() ??
          [],
    );
  }
}

class FloorPlanResult {
  final String planId;
  final double totalBuiltArea;
  final double circulationArea;
  final double utilizationPercentage;
  final SpatialBreakdownModel? spatialBreakdown;
  final String svgFloorPlan;
  final String disclaimer;
  final List<RoomModel> rooms;
  final List<RecommendationModel> recommendations;
  final List<PlanAlternativeModel> alternatives;
  final int floorsCount;
  final List<FloorLayoutModel> floorLayouts;
  final String? svgGroundFloor;
  final String? svgFirstFloor;

  const FloorPlanResult({
    required this.planId,
    required this.totalBuiltArea,
    required this.circulationArea,
    required this.utilizationPercentage,
    this.spatialBreakdown,
    required this.svgFloorPlan,
    required this.disclaimer,
    required this.rooms,
    required this.recommendations,
    required this.alternatives,
    this.floorsCount = 1,
    this.floorLayouts = const [],
    this.svgGroundFloor,
    this.svgFirstFloor,
  });

  factory FloorPlanResult.fromJson(Map<String, dynamic> json) {
    final altsJson = json['alternatives'] as List<dynamic>?;
    final List<PlanAlternativeModel> altsList = altsJson != null
        ? altsJson.map((a) => PlanAlternativeModel.fromJson(a as Map<String, dynamic>)).toList()
        : [];

    final layoutsJson = json['floor_layouts'] as List<dynamic>?;
    final List<FloorLayoutModel> layoutsList = layoutsJson != null
        ? layoutsJson.map((fl) => FloorLayoutModel.fromJson(fl as Map<String, dynamic>)).toList()
        : [];

    return FloorPlanResult(
      planId: json['plan_id'] as String? ?? '',
      totalBuiltArea: (json['total_built_area'] as num?)?.toDouble() ?? 0.0,
      circulationArea: (json['circulation_area'] as num?)?.toDouble() ?? 0.0,
      utilizationPercentage: (json['utilization_percentage'] as num?)?.toDouble() ?? 0.0,
      spatialBreakdown: json['spatial_breakdown'] != null
          ? SpatialBreakdownModel.fromJson(json['spatial_breakdown'] as Map<String, dynamic>)
          : null,
      svgFloorPlan: json['svg_floor_plan'] as String? ?? '',
      disclaimer: json['disclaimer'] as String? ?? '',
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((r) => RoomModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((rec) => RecommendationModel.fromJson(rec as Map<String, dynamic>))
              .toList() ??
          [],
      alternatives: altsList,
      floorsCount: json['floors_count'] as int? ?? 1,
      floorLayouts: layoutsList,
      svgGroundFloor: json['svg_ground_floor'] as String?,
      svgFirstFloor: json['svg_first_floor'] as String?,
    );
  }

  /// Helper to get the primary Plan A (or fallback)
  PlanAlternativeModel get primaryPlan {
    if (alternatives.isNotEmpty) {
      return alternatives.first;
    }
    return PlanAlternativeModel(
      layoutType: 'default',
      title: 'Generated Plan',
      description: 'AI Generated Floor Plan',
      rooms: rooms,
      circulationPaths: [],
      doors: [],
      windows: [],
      spatialBreakdown: spatialBreakdown ??
          SpatialBreakdownModel(
            totalPlotArea: 0.0,
            netRoomArea: totalBuiltArea,
            circulationArea: circulationArea,
            wallArea: 0.0,
            openUnallocatedArea: 0.0,
            setbackArea: 0.0,
            totalCoveredArea: totalBuiltArea + circulationArea,
            utilizationPercentage: utilizationPercentage,
          ),
      recommendations: recommendations,
      svgFloorPlan: svgFloorPlan,
      floorsCount: floorsCount,
      floorLayouts: floorLayouts,
      svgGroundFloor: svgGroundFloor,
      svgFirstFloor: svgFirstFloor,
    );
  }
}
