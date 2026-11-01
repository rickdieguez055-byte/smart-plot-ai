/// Plot input model matching SP-AI-01, SP-AI-02, SP-AI-03.
class PlotInput {
  final double plotLength;
  final double plotWidth;
  final double frontWidth;
  final String entranceOrientation;
  final String unit;

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
    this.bedrooms = 2,
    this.bathrooms = 2,
    this.floors = 1,
    this.kitchen = true,
    this.livingRoom = true,
    this.parking = true,
    this.diningRoom = false,
    this.lawn = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'plot': {
        'plot_length': plotLength,
        'plot_width': plotWidth,
        'front_width': frontWidth,
        'entrance_orientation': entranceOrientation,
        'unit': unit,
      },
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
