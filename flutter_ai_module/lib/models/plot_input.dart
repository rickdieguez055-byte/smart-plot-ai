library plot_input;

/// Setbacks model matching SP-AI-01 and municipal zoning requirements.
class SetbacksModel {
  final double front;
  final double rear;
  final double left;
  final double right;

  const SetbacksModel({
    this.front = 0.0,
    this.rear = 0.0,
    this.left = 0.0,
    this.right = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'front': front,
      'rear': rear,
      'left': left,
      'right': right,
    };
  }

  factory SetbacksModel.fromJson(Map<String, dynamic> json) {
    return SetbacksModel(
      front: (json['front'] as num?)?.toDouble() ?? 0.0,
      rear: (json['rear'] as num?)?.toDouble() ?? 0.0,
      left: (json['left'] as num?)?.toDouble() ?? 0.0,
      right: (json['right'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Floor-specific requirement model for Phase 6 multi-floor house planning.
class FloorRequirementModel {
  final int bedrooms;
  final int bathrooms;
  final bool kitchen;
  final bool livingRoom;
  final bool drawingRoom;
  final bool terrace;
  final bool storeRoom;

  const FloorRequirementModel({
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.kitchen = true,
    this.livingRoom = true,
    this.drawingRoom = false,
    this.terrace = false,
    this.storeRoom = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'kitchen': kitchen,
      'living_room': livingRoom,
      'drawing_room': drawingRoom,
      'terrace': terrace,
      'store_room': storeRoom,
    };
  }

  factory FloorRequirementModel.fromJson(Map<String, dynamic> json) {
    return FloorRequirementModel(
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 1,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 1,
      kitchen: json['kitchen'] as bool? ?? true,
      livingRoom: (json['living_room'] ?? json['livingRoom']) as bool? ?? true,
      drawingRoom: (json['drawing_room'] ?? json['drawingRoom']) as bool? ?? false,
      terrace: json['terrace'] as bool? ?? false,
      storeRoom: (json['store_room'] ?? json['storeRoom']) as bool? ?? false,
    );
  }

  FloorRequirementModel copyWith({
    int? bedrooms,
    int? bathrooms,
    bool? kitchen,
    bool? livingRoom,
    bool? drawingRoom,
    bool? terrace,
    bool? storeRoom,
  }) {
    return FloorRequirementModel(
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      kitchen: kitchen ?? this.kitchen,
      livingRoom: livingRoom ?? this.livingRoom,
      drawingRoom: drawingRoom ?? this.drawingRoom,
      terrace: terrace ?? this.terrace,
      storeRoom: storeRoom ?? this.storeRoom,
    );
  }
}

/// Plot input model matching SP-AI-01, SP-AI-02, SP-AI-03.
class PlotInput {
  final double plotLength;
  final double plotWidth;
  final double frontWidth;
  final String entranceOrientation;
  final String unit;
  final SetbacksModel? setbacks;

  // Layout Requirements
  final int bedrooms;
  final int bathrooms;
  final int floors;
  final bool kitchen;
  final bool livingRoom;
  final bool parking;
  final bool diningRoom;
  final bool lawn;

  // Floor-specific requirements for Phase 6 multi-floor layouts
  final FloorRequirementModel? groundFloor;
  final FloorRequirementModel? firstFloor;

  const PlotInput({
    required this.plotLength,
    required this.plotWidth,
    required this.frontWidth,
    required this.entranceOrientation,
    this.unit = 'feet',
    this.setbacks,
    this.bedrooms = 2,
    this.bathrooms = 2,
    this.floors = 1,
    this.kitchen = true,
    this.livingRoom = true,
    this.parking = true,
    this.diningRoom = false,
    this.lawn = false,
    this.groundFloor,
    this.firstFloor,
  });

  /// Copy with modifications
  PlotInput copyWith({
    double? plotLength,
    double? plotWidth,
    double? frontWidth,
    String? entranceOrientation,
    String? unit,
    SetbacksModel? setbacks,
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
    return PlotInput(
      plotLength: plotLength ?? this.plotLength,
      plotWidth: plotWidth ?? this.plotWidth,
      frontWidth: frontWidth ?? this.frontWidth,
      entranceOrientation: entranceOrientation ?? this.entranceOrientation,
      unit: unit ?? this.unit,
      setbacks: setbacks ?? this.setbacks,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      floors: floors ?? this.floors,
      kitchen: kitchen ?? this.kitchen,
      livingRoom: livingRoom ?? this.livingRoom,
      parking: parking ?? this.parking,
      diningRoom: diningRoom ?? this.diningRoom,
      lawn: lawn ?? this.lawn,
      groundFloor: groundFloor ?? this.groundFloor,
      firstFloor: firstFloor ?? this.firstFloor,
    );
  }

  /// Calculates total plot area
  double get totalArea => plotLength * plotWidth;

  /// Validates basic dimensional integrity
  String? validate() {
    if (plotLength <= 0 || plotWidth <= 0 || frontWidth <= 0) {
      return 'Plot dimensions must be strictly positive.';
    }
    if (plotLength < 15.0 || plotWidth < 10.0) {
      return 'Plot dimensions are too small for residential layout (min 15x10 ft).';
    }
    if (frontWidth > plotWidth) {
      return 'Front width ($frontWidth ft) cannot exceed total plot width ($plotWidth ft).';
    }
    if (floors < 1 || floors > 2) {
      return 'Floors must be either 1 or 2.';
    }
    if (floors == 2 && (groundFloor != null || firstFloor != null)) {
      final gBeds = groundFloor?.bedrooms ?? 1;
      final fBeds = firstFloor?.bedrooms ?? 1;
      final gBaths = groundFloor?.bathrooms ?? 1;
      final fBaths = firstFloor?.bathrooms ?? 1;
      if (gBeds + fBeds < 1 || gBeds + fBeds > 6) {
        return 'Total bedrooms across floors must be between 1 and 6.';
      }
      if (gBaths + fBaths < 1 || gBaths + fBaths > 5) {
        return 'Total bathrooms across floors must be between 1 and 5.';
      }
    } else {
      if (bedrooms < 1 || bedrooms > 6) {
        return 'Bedrooms must be between 1 and 6.';
      }
      if (bathrooms < 1 || bathrooms > 5) {
        return 'Bathrooms must be between 1 and 5.';
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> plotMap = {
      'plot_length': plotLength,
      'plot_width': plotWidth,
      'front_width': frontWidth,
      'entrance_orientation': entranceOrientation,
      'unit': unit,
    };
    if (setbacks != null) {
      plotMap['setbacks'] = setbacks!.toJson();
    }

    final Map<String, dynamic> reqMap = {
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'floors': floors,
      'kitchen': kitchen,
      'living_room': livingRoom,
      'parking': parking,
      'dining_room': diningRoom,
      'lawn': lawn,
    };

    if (floors == 2) {
      if (groundFloor != null) {
        reqMap['ground_floor'] = groundFloor!.toJson();
      }
      if (firstFloor != null) {
        reqMap['first_floor'] = firstFloor!.toJson();
      }
    }

    return {
      'plot': plotMap,
      'requirements': reqMap,
    };
  }
}
