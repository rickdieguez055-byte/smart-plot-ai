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

  const SpatialBreakdownModel({
    required this.totalPlotArea,
    required this.netRoomArea,
    required this.circulationArea,
    required this.wallArea,
    required this.openUnallocatedArea,
    required this.setbackArea,
    required this.totalCoveredArea,
    required this.utilizationPercentage,
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
  });

  factory PlanAlternativeModel.fromJson(Map<String, dynamic> json) {
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
  });

  factory FloorPlanResult.fromJson(Map<String, dynamic> json) {
    final altsJson = json['alternatives'] as List<dynamic>?;
    final List<PlanAlternativeModel> altsList = altsJson != null
        ? altsJson.map((a) => PlanAlternativeModel.fromJson(a as Map<String, dynamic>)).toList()
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
    );
  }
}
