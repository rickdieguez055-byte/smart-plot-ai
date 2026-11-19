# SmartPlot AI — Phase 8: Final Project Audit & Completion Report

**Project Title**: SmartPlot AI — Automated Plot Layout & Architectural Floor Plan Generator  
**Project Number**: 22  
**Institution**: City University of Science and Information Technology (CUSIT), Peshawar  
**Review Date**: November 2026  
**Auditors / Authors**: Atizaz Ali (14802), Awais Rehman (14801), Mueed Ahmad (14724)  
**Status**: FYP Demonstration Ready  

---

## 1. Executive Summary & Completion Percentage

| Metric | Measured Status | Justification |
| :--- | :--- | :--- |
| **Overall FYP AI Scope Completion** | **96%** | Core AI solver, multi-floor generation, Random Forest ML pipeline, interactive editor, Node.js gateway, and dual mobile platforms (Android APK & iOS physical iPhone IPA) are fully implemented and verified. The remaining 4% represents non-blocking future polish (e.g., non-rectangular plots and cloud hosting). |
| **Python FastAPI Microservice** | **100%** | All layout endpoints, CP-SAT constraints, multi-floor core alignment, editor validation, and SVG generation operational on port 8000. |
| **Node.js Express Gateway** | **100%** | Validation middleware, rate limiting, error forwarding, and health check operational on port 5000. |
| **Machine Learning Engine** | **95%** | Trained V1 & V2 Random Forest models integrated with CP-SAT solver. Attached bathroom door recall (22.52%) is cleanly augmented by heuristic pairing rules. |
| **Flutter Mobile Application** | **100%** | 8 complete screens, interactive drag/resize canvas, undo/redo/reset, live SVG rendering, native share channels. |
| **iOS & Codemagic CI/CD** | **100%** | `codemagic.yaml` built on macOS Mac mini M2 runner; valid `SmartPlot_AI_v1.0.0_unsigned.ipa` generated, signed via Sideloadly, and installed on physical iPhone. |

---

## 2. Completed Work by Module

### 2.1 Python AI Microservice (`backend/`)
- **Single-Floor Layout Solver (`backend/app/engine/spatial_solver.py`)**: Google OR-Tools CP-SAT solver modeling spatial non-overlap, boundary containment, setback rules, and orientation zoning.
- **Multi-Floor Generation (`backend/app/engine/multifloor_solver.py`)**: Independent Ground Floor (GF) and First Floor (1F) generation with synchronized structural staircase cores.
- **Staircase Alignment Validator (`backend/app/engine/staircase_validator.py`)**: Verifies identical $(x, y, w, l)$ bounding boxes across floors and checks architectural ergonomics via the Blondel formula:
  $$2R + T \approx 24\text{ to }25\text{ inches}$$
- **Interactive Editor Engine (`backend/app/engine/interactive_editor.py`)**: Server-side validation of client drag-and-resize edits. Checks plot boundary confinement, room overlap prevention, and regenerates doors, windows, and SVGs dynamically.
- **Architectural 2D SVG Renderer (`backend/app/renderer/svg_renderer.py`)**: Generates vector drawings with 9-inch exterior and 4.5-inch interior double walls, door swing arcs, window sills, room labels, dimensions, and SP-AI-10 disclaimer.
- **Rigorous Area Accounting**: Enforces strict conservation:
  $$\text{Total Covered Area} = \text{Net Room Area} + \text{Circulation Area} + \text{Wall Area} + \text{Open/Unallocated Area}$$

### 2.2 Machine Learning Pipeline (`backend/app/ml/`)
- **ResPlan Dataset**: 14,958 verified training floor plans (213,461 room pairs).
- **Trained Artifacts (`backend/app/ml/artifacts/`)**:
  - `rf_door_v2.joblib` (56 MB) & `rf_adj_v2.joblib` (67 MB) tracked cleanly via **Git LFS**.
  - `v1_baseline/` preserved for comparative analysis.
  - V2 Model performance: **85.61% Door Accuracy**, **77.01% Door F1**, **77.01% Wall Adjacency F1**.
- **Hybrid Optimization**: CP-SAT objective functions prioritize layout adjacencies according to learned ML probabilities, falling back gracefully to heuristic rules if confidence falls below threshold.

### 2.3 API Gateway (`node-gateway/`)
- Express.js middleware validating request schemas before hitting Python AI microservice.
- Centralized error normalization, CORS management, and rate limiting.

### 2.4 Flutter Mobile Client (`flutter_ai_module/`)
- **Screens**:
  1. `ai_planning_home_screen.dart` — Dashboard, quick actions, branding.
  2. `plot_form_screen.dart` — Plot dimension inputs (standard Pakistani presets: 5 Marla, 10 Marla, 1 Kanal).
  3. `requirements_form_screen.dart` — Single floor vs Ground+First floor requirements.
  4. `plan_results_screen.dart` — Plan A (Open Living) vs Plan B (Privacy Focused) with Ground/First floor tabs.
  5. `plan_comparison_screen.dart` — Side-by-side room count and area metric comparisons.
  6. `detailed_plan_viewer_screen.dart` — Fullscreen interactive SVG viewer with pinch-to-zoom and pan.
  7. `edit_floor_plan_screen.dart` — Interactive canvas with drag, resize, undo, redo, reset, and live server validation.
  8. `settings_screen.dart` — Backend URL switching (USB reverse `127.0.0.1:5000`, Wi-Fi LAN `192.168.18.11:5000`, Cloud HTTPS).
- **Native Platform Channels**:
  - Android: Kotlin `com.smartplot.ai/share` via `FileProvider`.
  - iOS: Swift `com.smartplot.ai/share` via `UIActivityViewController` (with iPad popover support).
  - Storage: Exported SVGs appear directly in the iOS **Files** app under *On My iPhone -> SmartPlot AI*.

### 2.5 DevOps & Build Deliverables
- **Android APK**: `flutter_ai_module/build/app/outputs/flutter-apk/app-release.apk` (50.7 MB).
- **iOS IPA**: `SmartPlot_AI_v1.0.0_unsigned.ipa` (7.52 MB) compiled via Codemagic Mac mini M2 runner (Build `6aff08a7e7b0f8fa6f332245`), verified on physical iPhone.
- **Git Repository**: Synchronized at `https://github.com/rickdieguez055-byte/smart-plot-ai.git` on `master` branch.

---

## 3. Bugs Discovered & Fixed

1. **Android Gateway Connection Failure (`127.0.0.1:5000`)**:
   - *Cause*: On Android emulators/devices, `127.0.0.1` routes to the device itself rather than the host PC without reverse port forwarding.
   - *Fix*: Added automated ADB reverse configuration (`adb reverse tcp:5000 tcp:5000`), local Wi-Fi IP support (`192.168.18.11:5000`), and configurable backend presets in `api_config.dart`.
2. **Missing iOS Platform Suite**:
   - *Cause*: The Flutter project was initially initialized without iOS platform scaffolding.
   - *Fix*: Generated the iOS platform project, configured CocoaPods targeting iOS 14.0+, implemented the Swift native share channel in `AppDelegate.swift`, and enabled App Transport Security & File Sharing in `Info.plist`.
3. **CI Test Failures in Offline Build Runners**:
   - *Cause*: `live_api_integration_test.dart` and `screenshot_generator_test.dart` attempted to hit `http://127.0.0.1:5000` during `flutter test`, causing cloud build failures on Codemagic.
   - *Fix*: Added health-check bypasses to safely skip live network calls in headless CI environments while running all 27 unit and widget tests.
4. **Git Large File Limit Rejection**:
   - *Cause*: Trained Random Forest models (`rf_adj_v2.joblib` 67MB, `rf_door_v2.joblib` 56MB) exceeded GitHub's standard 50MB warning threshold.
   - *Fix*: Initialized Git LFS (`.gitattributes`) to track `*.joblib` binary artifacts cleanly.
5. **Interactive Editor Null Promotion in Dart Tests**:
   - *Cause*: Asynchronous closure variable assignment in tests caused analyzer type promotion warnings.
   - *Fix*: Refactored to local final variable promotion; achieved 100% clean `flutter analyze` (0 issues).

---

## 4. Machine Learning Audit & Truthful Metrics

The trained Random Forest models were audited against ResPlan-FP held-out test splits (14,368 room pairs):

| Task | Metric | V1 Baseline | V2 Refined Model |
| :--- | :--- | :--- | :--- |
| **Door Connectivity** | Accuracy | 86.83% | **85.61%** |
| | Precision | 93.59% | **76.67%** |
| | Recall | 61.99% | **77.36%** |
| | F1-Score | 74.58% | **77.01%** |
| **Wall Adjacency** | Accuracy | 84.12% | **85.10%** |
| | F1-Score | 73.34% | **77.01%** |

### Attached Bathroom Limitation & Mitigation
- The model exhibits an attached bathroom door recall of **22.52%** due to class imbalance in public residential datasets.
- *Mitigation*: The hybrid CP-SAT solver does not rely exclusively on ML predictions. It enforces mandatory architectural pairing constraints ensuring attached bathrooms are physically adjacent and directly accessible from master bedrooms.

---

## 5. Automated Test Results

- **Flutter Test Suite**: **27 / 27 Passed** (`flutter test`)
- **Flutter Static Analysis**: **0 issues found** (`flutter analyze`)
- **Python Backend Test Suite**: **43 / 43 Passed** (`pytest tests/`)
- **Node.js Gateway Tests**: **5 / 5 Unit Validations Passed** (`tests/test_gateway.js`)

---

## 6. Known Boundaries & Limitations

1. **Plot Geometry**: Generation supports standard orthogonal (rectangular) plots. Irregular non-orthogonal polygons are outside the current FYP scope.
2. **Regulatory & Structural Scope**: The layouts produced are preliminary architectural floor plans. As explicitly stated in disclaimer `SP-AI-10`, they do not constitute licensed structural engineering, MEP drawings, or municipal building approval.
