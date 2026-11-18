# SmartPlot AI — Phase 5A: Genuine Machine Learning Development Report

**Date:** November 7, 2026  
**Role:** Senior Machine Learning Engineer, Data Engineer & Python Backend Developer  
**Status:** Successfully Implemented, Evaluated, and Verified  
**Target Module:** SmartPlot AI (`D:\smart plot_ai`)  

---

## Executive Summary

Phase 5A upgrades SmartPlot AI from a purely rule-based and constraint-optimization system into a **genuine hybrid Machine Learning + Constraint Optimization system**. 

Using the open-access, licensed **ResPlan-FP** dataset (16,998 real-world residential floor plans, CC-BY-4.0), a supervised machine learning pipeline was constructed to predict room connectivity and wall adjacency relationships from pre-layout features. Two Random Forest models were trained on 42,348 pairwise instances and evaluated on an independent, held-out test split of 14,368 pairs (997 floor plans), achieving **0.8683 accuracy, 0.9359 precision, and 0.9299 ROC-AUC** for door connectivity.

The trained ML model was integrated into the existing Google OR-Tools CP-SAT spatial solver. The hybrid architecture uses predicted connection probabilities to weight spatial proximity terms in the CP-SAT objective, producing layouts that measurably reduce circulation travel distance between key living spaces by **22% to 30%** while preserving 100% geometric feasibility and 100% BFS reachability.

Every test across Python (39/39), Node.js (5/5), and Flutter (13/13) passed cleanly.

---

## 1. Audit of the Existing AI Engine (Baseline)

An exhaustive audit of the Phase 1–4 codebase was performed prior to any ML integration:

| Component | File Path | Existing Methodology | Status Before Phase 5A |
| :--- | :--- | :--- | :--- |
| **Spatial Solver** | [`spatial_solver.py`](file:///D:/smart%20plot_ai/backend/app/engine/spatial_solver.py) | Mathematical Optimization (Google OR-Tools CP-SAT) + Deterministic Geometric Slicing Heuristic | 0% ML. Solves non-overlap 2D integer intervals and boundary constraints. |
| **Architectural Rules** | [`architectural_rules.py`](file:///D:/smart%20plot_ai/backend/app/engine/architectural_rules.py) | Graph Algorithms (BFS Traversal) + Building Standards | 0% ML. Verifies physical reachability from entrance and validates privacy. |
| **Dimension Estimator** | [`dimension_estimator.py`](file:///D:/smart%20plot_ai/backend/app/engine/dimension_estimator.py) | Deterministic Architectural Heuristics | 0% ML. Lookup tables for room aspect ratios, minimum dimensions, and priorities. |
| **Recommendation Engine** | [`recommendation_engine.py`](file:///D:/smart%20plot_ai/backend/app/engine/recommendation_engine.py) | Rule-Based Expert System | 0% ML. Conditional logic on solar orientation and cross-ventilation. |
| **Plan Service** | [`plan_service.py`](file:///D:/smart%20plot_ai/backend/app/services/plan_service.py) | Microservice Orchestration | 0% ML. Calls estimators, solver, recommendations, and SVG renderer. |

**Audit Conclusion:** Prior to Phase 5A, the system contained **zero trained machine learning models, zero learned weights, and no statistical data pipeline**. "AI" referred exclusively to symbolic constraint satisfaction (OR-Tools CP-SAT).

---

## 2. Real Dataset Research & Preparation

*Full details documented in [`docs/ML_DATASET_AUDIT.md`](file:///D:/smart%20plot_ai/docs/ML_DATASET_AUDIT.md).*

### 2.1 Dataset Selection: ResPlan-FP
* **Source:** [Tristan12138/resplan-fp on Hugging Face](https://huggingface.co/datasets/Tristan12138/resplan-fp)
* **Citation:** Zhang, He, *"Readout, Reconciliation, and Representation in Floorplan Vectorization"*, arXiv:2608.25608 (2026).
* **License:** **Creative Commons Attribution 4.0 International (CC-BY-4.0)**.
* **Format:** Clean JSON Lines with exact room polygons, wall centerlines, and explicit door and window openings.
* **Volume Used:** 
  * Training Split: 2,992 real floor plans (`42,348` room pairs)
  * Validation Split: 998 real floor plans (`14,075` room pairs)
  * Held-Out Test Split: 997 real floor plans (`14,368` room pairs)

### 2.2 Leakage-Free Preprocessing Pipeline
Implemented in [`backend/app/ml/dataset.py`](file:///D:/smart%20plot_ai/backend/app/ml/dataset.py) and [`backend/app/ml/features.py`](file:///D:/smart%20plot_ai/backend/app/ml/features.py):
1. **Split-by-Floor-Plan-Identity:** Official frozen splits from `splits.json` were strictly preserved; no floor plan identity overlaps across train, validation, or test sets.
2. **Shoelace Polygon Area:** Room polygons converted to metric area units using the mathematical Shoelace formula.
3. **Ground Truth Graph Extraction:**
   * Adjacency ($is\_adjacent = 1$): Pairs sharing at least one wall in their wall arrays.
   * Door Connectivity ($is\_connected = 1$): Pairs sharing a wall with an opening of type `door`.
4. **Featurization Ordering:** Standard scalers and one-hot encoders fit strictly on `train_df` and applied out-of-sample to `val_df` and `test_df`.

---

## 3. Supervised ML Model Implementation

Implemented in [`backend/app/ml/train.py`](file:///D:/smart%20plot_ai/backend/app/ml/train.py):

### 3.1 Feature Vector (Pre-Layout Only)
* **Numerical Features:** `plot_width`, `plot_length`, `plot_area`, `plot_aspect_ratio`, `total_rooms`, `num_bedrooms`, `num_bathrooms`, `has_living`, `has_kitchen`, `has_parking`, `is_same_category`, `room1_area_ratio`, `room2_area_ratio`, `pair_area_ratio`.
* **Categorical Features:** `room1_category`, `room2_category`, `pair_type`.
* **Leakage Guarantee:** No room coordinates $(x, y)$, wall lengths, or door locations are used as input features.

### 3.2 Model Architectures & Configurations
1. **Dummy Majority Classifier:** Predicts the most frequent class in training data.
2. **Logistic Regression Baseline:** Linear model with L2 regularization (`C=1.0, max_iter=500`).
3. **Random Forest Classifier (Primary Model):**
   * `n_estimators`: 100
   * `max_depth`: 12
   * `min_samples_split`: 10
   * `random_state`: 42
   * `n_jobs`: -1 (multicore parallel training)

### 3.3 Model Artifacts Saved
Trained artifacts are serialized via `joblib` into [`backend/app/ml/artifacts/`](file:///D:/smart%20plot_ai/backend/app/ml/artifacts/):
* `preprocessor.joblib` (ColumnTransformer with StandardScaler + OneHotEncoder)
* `rf_door_model.joblib` (Random Forest door connectivity predictor)
* `rf_adj_model.joblib` (Random Forest wall adjacency predictor)
* `lr_door_model.joblib` & `lr_adj_model.joblib` (Logistic regression baselines)
* `feature_schema.json` (Dataset and feature column metadata)
* `evaluation_metrics.json` (Complete test set metrics, confusion matrices, and slice analysis)

---

## 4. Model Evaluation & Benchmark Metrics

*Full evaluation details documented in [`docs/ML_EXPERIMENT_RESULTS.md`](file:///D:/smart%20plot_ai/docs/ML_EXPERIMENT_RESULTS.md).*

### 4.1 Test Split Evaluation (14,368 Unseen Room Pairs)

#### Door Connectivity (`is_connected`):
* **Class Balance:** Positive = 4,478 (31.17%), Negative = 9,890 (68.83%)
* **Dummy Majority Baseline:** Accuracy 0.6883, Precision 0.0000, Recall 0.0000, F1 0.0000, ROC-AUC 0.5000
* **Logistic Regression Baseline:** Accuracy 0.8543, Precision 0.8836, Recall 0.6134, F1 0.7241, ROC-AUC 0.9160
* **Random Forest (Primary):** **Accuracy 0.8683**, **Precision 0.9359**, **Recall 0.6199**, **F1 0.7458**, **ROC-AUC 0.9299**

#### Confusion Matrix (Random Forest):
$$\begin{pmatrix} \text{TN: } 9,700 & \text{FP: } 190 \\ \text{FN: } 1,702 & \text{TP: } 2,776 \end{pmatrix}$$
*With only 190 false positives out of 9,890 negative pairs (1.9% false positive rate), the model exhibits high fidelity against creating invalid door connections.*

### 4.2 Architectural Slice Analysis
* **`kitchen_living`:** F1 = **0.9795** (Precision = 0.9598, Recall = 1.0000). The model reliably learned that kitchen and living areas must connect.
* **`bedroom_living`:** F1 = **0.9953** (Precision = 0.9933, Recall = 0.9973). Captures central living hub access.
* **`bedroom_bedroom` & `bathroom_bathroom`:** True Positive Rate < 0.1%, F1 = 0.0000. Accurately preserves inter-room privacy.

---

## 5. Hybrid ML + CP-SAT Architecture

Implemented in [`backend/app/ml/hybrid_solver.py`](file:///D:/smart%20plot_ai/backend/app/ml/hybrid_solver.py) and integrated into [`backend/app/services/plan_service.py`](file:///D:/smart%20plot_ai/backend/app/services/plan_service.py):

```
┌────────────────────────────────────────────────────────┐
│                   User Requirements                    │
│   (Plot dimensions, setbacks, requested room counts)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│        DimensionEstimator & Feature Extraction         │
│   (Computes target areas, ratios, and pair features)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│      Trained ML Model (RoomRelationshipPredictor)      │
│   - Predicts door connectivity probability P(door)     │
│   - Predicts wall adjacency probability P(adj)         │
└───────────────────────────┬────────────────────────────┘
                            │ Soft Affinity Weights w(u,v)
                            ▼
┌────────────────────────────────────────────────────────┐
│          Google OR-Tools CP-SAT Spatial Solver         │
│   - Hard Constraints: AddNoOverlap2D, Setbacks, Bounds │
│   - Soft Objective: min(dim_dev) + sum w(u,v)*dist(u,v)│
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│     Geometric & Circulation Verification (BFS Graph)   │
│   - Validates 100% reachability from entrance          │
│   - Validates zero privacy violations                  │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│      High-Fidelity SVG Floor Plan Rendering Engine     │
└────────────────────────────────────────────────────────┘
```

### 5.1 Fallback Safety Guarantee
* If the ML model artifacts cannot be loaded or throw any exception, [`RoomRelationshipPredictor`](file:///D:/smart%20plot_ai/backend/app/ml/model.py) falls back immediately to deterministic architectural priors.
* If CP-SAT encounters an infeasible configuration or times out, [`HybridSpatialSolver`](file:///D:/smart%20plot_ai/backend/app/ml/hybrid_solver.py) falls back automatically to the baseline Phase 2/3/4 solver.
* Zero unhandled exceptions reach the user or API client.

---

## 6. Comparative Experiment Results

Layouts were generated using both Baseline CP-SAT and Hybrid ML + CP-SAT across four standard plot dimensions via [`scripts/compare_phase5_ml.py`](file:///D:/smart%20plot_ai/scripts/compare_phase5_ml.py):

1. **5 Marla Standard (25 × 45 ft):**
   * Baseline Living-to-Kitchen distance: 16.05 ft
   * Hybrid ML Living-to-Kitchen distance: **12.50 ft** (**22.1% reduction**)
   * Feasibility: 100% Valid, BFS Reachability: 100% Verified
2. **5 Marla Modern (25 × 50 ft):**
   * Baseline Living-to-Kitchen distance: 16.65 ft
   * Hybrid ML Living-to-Kitchen distance: **12.50 ft** (**24.9% reduction**)
   * Feasibility: 100% Valid, BFS Reachability: 100% Verified
3. **10 Marla Luxury (35 × 65 ft):**
   * Baseline Living-to-Kitchen distance: 23.00 ft
   * Hybrid ML Living-to-Kitchen distance: **16.00 ft** (**30.4% reduction**)
   * Feasibility: 100% Valid, BFS Reachability: 100% Verified
4. **1 Kanal Estate (50 × 90 ft):**
   * Baseline Living-to-Kitchen distance: 27.00 ft
   * Hybrid ML Living-to-Kitchen distance: **20.00 ft** (**25.9% reduction**)
   * Feasibility: 100% Valid, BFS Reachability: 100% Verified

**Operational Trade-off:**
* Baseline cold execution: ~1–7 ms
* Hybrid ML + CP-SAT warm execution: **45–60 ms** (well within the 200 ms interactive mobile UI threshold).

---

## 7. Automated Test Suite Results

Every test across all three application layers passed with zero failures:

### 7.1 Python Test Suite (39 passed in 5.14s)
```
tests/test_api_endpoints.py .......                                      [ 17%]
tests/test_dimension_estimator.py ...                                    [ 25%]
tests/test_e2e.py .                                                      [ 28%]
tests/test_ml_pipeline.py ......                                         [ 43%]
tests/test_phase2_functional_layouts.py .......                          [ 61%]
tests/test_schemas.py .........                                          [ 84%]
tests/test_spatial_solver.py .....                                       [ 97%]
tests/test_svg_renderer.py .                                             [100%]
======================= 39 passed, 6 warnings in 5.14s ========================
```

### 7.2 Node.js Gateway Test Suite (5 passed in 0.5s)
```
Test 1: GET /health - 200 OK
Test 2: POST /api/v1/plans/generate (missing plot) - 400 Bad Request
Test 3: POST /api/v1/plans/generate (negative dimensions) - 400 Bad Request
Test 4: POST /api/v1/plans/generate (invalid orientation) - 400 Bad Request
Test 5: POST /api/v1/plans/generate (unsupported multi-floor request) - 400 Bad Request
All Gateway unit tests passed successfully!
```

### 7.3 Flutter Test Suite (13 passed in 5.2s)
```
Live API Test Successful:
  Plan ID: plan_1781c2cefbfa
  Plan A: Plan A: ML-Optimized Open Living Concept (Rooms: 7, Doors: 9, Windows: 10)
  Plan B: Plan B: ML-Optimized Privacy Focused (Rooms: 8, Doors: 10, Windows: 11)
  ✓ Captured: 1_ai_planning_home.png (77314 bytes)
  ✓ Captured: 2_plot_measurements_form.png (17168 bytes)
  ✓ Captured: 3_room_requirements_form.png (23611 bytes)
  ✓ Captured: 4_plan_results_plan_a.png (29133 bytes)
  ✓ Captured: 5_plan_results_plan_b.png (30055 bytes)
  ✓ Captured: 6_plan_a_vs_b_comparison.png (15943 bytes)
  ✓ Captured: 7_detailed_plan_viewer.png (37103 bytes)
All screen captures saved successfully to docs/screenshots/
All tests passed!
```

---

## 8. Exact Execution Commands

To reproduce the Phase 5A pipeline from scratch:

```powershell
# 1. Activate environment and verify dependencies
cd D:\smart plot_ai
$env:PYTHONPATH="D:\smart plot_ai"

# 2. Run ML Training Pipeline on ResPlan Dataset
& "D:\smart plot_ai\backend\.venv\Scripts\python.exe" -u backend/app/ml/train.py

# 3. Run Comparative Experiment Suite
& "D:\smart plot_ai\backend\.venv\Scripts\python.exe" -u scripts/compare_phase5_ml.py

# 4. Run Full Python Test Suite
& "D:\smart plot_ai\backend\.venv\Scripts\python.exe" -m pytest tests/

# 5. Run Node.js Gateway Tests
node tests/test_gateway.js

# 6. Run Flutter Integration and Live API Tests
cd flutter_ai_module
flutter test
```

---

## 9. Limitations & Phase 5B Roadmap

1. **Current Scope (Pairwise Topology):** Phase 5A predicts room-to-room connectivity and adjacency probabilities to parameterize CP-SAT. It does not predict freeform continuous polygon coordinates directly (which is deliberately handled by CP-SAT to guarantee zero room overlap and exact millimeter setbacks).
2. **Phase 5B Graph Neural Network (GNN):** With the pairwise baseline validated, Phase 5B will benchmark Graph Neural Networks (e.g. Graph Convolutional Networks or Edge-Conditioned Graphs) against the Random Forest baseline.
3. **Domain-Specific Pakistani Dataset:** Curating and annotating 500+ licensed CAD blueprints of Pakistani residential layouts to fine-tune regional spatial preferences (dedicated guest drawing rooms, servant quarters, and internal light wells).
