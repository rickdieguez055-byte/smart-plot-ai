/// Floor plan result models matching SP-AI-07, SP-AI-08, SP-AI-10.

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
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      length: (json['length'] as num).toDouble(),
      area: (json['area'] as num).toDouble(),
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
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
    );
  }
}

class FloorPlanResult {
  final String planId;
  final double totalBuiltArea;
  final double circulationArea;
  final double utilizationPercentage;
  final String svgFloorPlan;
  final String disclaimer;
  final List<RoomModel> rooms;
  final List<RecommendationModel> recommendations;

  const FloorPlanResult({
    required this.planId,
    required this.totalBuiltArea,
    required this.circulationArea,
    required this.utilizationPercentage,
    required this.svgFloorPlan,
    required this.disclaimer,
    required this.rooms,
    required this.recommendations,
  });

  factory FloorPlanResult.fromJson(Map<String, dynamic> json) {
    return FloorPlanResult(
      planId: json['plan_id'] as String,
      totalBuiltArea: (json['total_built_area'] as num).toDouble(),
      circulationArea: (json['circulation_area'] as num).toDouble(),
      utilizationPercentage: (json['utilization_percentage'] as num).toDouble(),
      svgFloorPlan: json['svg_floor_plan'] as String,
      disclaimer: json['disclaimer'] as String,
      rooms: (json['rooms'] as List<dynamic>)
          .map((r) => RoomModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((rec) => RecommendationModel.fromJson(rec as Map<String, dynamic>))
          .toList(),
    );
  }
}
