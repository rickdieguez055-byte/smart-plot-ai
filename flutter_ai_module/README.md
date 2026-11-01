# SmartPlot Flutter AI Integration Module

This Flutter package contains the client-side integration models, API service, and UI components for the **SmartPlot AI Plot Analysis and Layout Generation Module** (SP-AI-01 to SP-AI-14).

## Architecture
- Communicates directly with the **Node.js API Gateway** (`/api/v1/plans/generate`), never directly with the Python microservice (SP-AI-05, SP-NFR-SEC-05).
- Displays the generated SVG floor plans via `flutter_svg`.
- Implements mandatory preliminary design notices (SP-AI-10, SP-BR-05).

## Usage
```dart
import 'package:smartplot_ai_module/smartplot_ai.dart';

final service = AIPlanApiService(baseUrl: 'http://<GATEWAY_HOST>:5000');

final input = PlotInput(
  plotLength: 45.0,
  plotWidth: 25.0,
  frontWidth: 25.0,
  entranceOrientation: 'North',
  bedrooms: 2,
  bathrooms: 2,
);

final result = await service.generatePlan(input);
print('Generated Plan: ${result.planId}, Built Area: ${result.totalBuiltArea}');
```
