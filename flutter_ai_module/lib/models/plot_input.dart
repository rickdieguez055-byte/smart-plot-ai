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
    if (bedrooms < 1 || bedrooms > 6) {
      return 'Bedrooms must be between 1 and 6.';
    }
    if (bathrooms < 1 || bathrooms > 5) {
      return 'Bathrooms must be between 1 and 5.';
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

    return {
      'plot': plotMap,
      'requirements': {
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'floors': floors,
        'kitchen': kitchen,
        'living_room': livingRoom,
        'parking': parking,
        'dining_room': diningRoom,
        'lawn': lawn,
      },
    };
  }
}
