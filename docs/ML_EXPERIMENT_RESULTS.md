# SmartPlot AI — Machine Learning Experiment Results

**Document:** `docs/ML_EXPERIMENT_RESULTS.md`  
**Date:** November 7, 2026  
**Auditor:** Senior ML Engineer & Floor-Plan Generation Specialist  
**Evaluation Set:** Held-out Test Split (`data/resplan/test.jsonl`: 997 floor plans, 14,368 pairwise relations)  

---

## 1. Machine Learning Benchmark Results

Two distinct spatial prediction tasks were evaluated on held-out test data:
1. **Task 1: Door Connectivity Prediction (`is_connected`):** Binary classification predicting whether two room entities should share a direct doorway connection.
2. **Task 2: Wall Adjacency Prediction (`is_adjacent`):** Binary classification predicting whether two room entities should share a common partition wall.

### 1.1 Task 1: Door Connectivity Evaluation (`is_connected`)

* **Test Samples:** 14,368 pairs (Positive: 4,478 [31.17%], Negative: 9,890 [68.83%])

| Model Architecture | Accuracy | Precision | Recall | F1-Score | ROC-AUC |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Dummy Majority Baseline** | 0.6883 | 0.0000 | 0.0000 | 0.0000 | 0.5000 |
| **Logistic Regression Baseline** | 0.8543 | 0.8836 | 0.6134 | 0.7241 | 0.9160 |
| **Random Forest (SmartPlot Primary)** | **0.8683** | **0.9359** | **0.6199** | **0.7458** | **0.9299** |

#### Confusion Matrix (Random Forest Door Model):
* **True Negatives (TN):** 9,700 (correctly predicted no door connection)
* **False Positives (FP):** 190 (incorrectly predicted a door connection)
* **False Negatives (FN):** 1,702 (missed a door connection)
* **True Positives (TP):** 2,776 (correctly predicted a door connection)
* **Key Finding:** Random Forest achieved **93.59% Precision**, minimizing spurious door openings between private or incompatible rooms.

---

### 1.2 Task 2: Wall Adjacency Evaluation (`is_adjacent`)

* **Test Samples:** 14,368 pairs (Positive: 7,572 [52.70%], Negative: 6,796 [47.30%])

| Model Architecture | Accuracy | Precision | Recall | F1-Score | ROC-AUC |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Dummy Majority Baseline** | 0.5270 | 0.5270 | 1.0000 | 0.6902 | 0.5000 |
| **Logistic Regression Baseline** | 0.7365 | 0.8233 | 0.6367 | 0.7181 | 0.8155 |
| **Random Forest (SmartPlot Primary)** | **0.7488** | **0.8323** | **0.6554** | **0.7334** | **0.8363** |

#### Confusion Matrix (Random Forest Adjacency Model):
* **True Negatives (TN):** 5,796
* **False Positives (FP):** 1,000
* **False Negatives (FN):** 2,609
* **True Positives (TP):** 4,963

---

## 2. Slice-Based Error Analysis (Door Connectivity)

Model performance was analyzed across individual functional room pairs to verify that the model captures genuine architectural logic rather than statistical artifacts:

| Room Pair Slice | Test Pairs | True Positive Rate | Precision | Recall | F1-Score | Architectural Meaning |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **kitchen_living** | 200 | 95.5% | **0.9598** | **1.0000** | **0.9795** | Kitchens almost universally connect to living/dining halls. |
| **bedroom_living** | 2,307 | 97.0% | **0.9933** | **0.9973** | **0.9953** | Bedrooms almost always access the central living circulation. |
| **bedroom_bedroom** | 2,027 | 0.05% | **0.0000** | **0.0000** | **0.0000** | Model correctly learned that bedrooms do NOT interconnect. |
| **bathroom_bathroom**| 1,485 | 0.07% | **0.0000** | **0.0000** | **0.0000** | Model correctly learned that bathrooms never connect. |
| **bedroom_kitchen** | 516 | 0.78% | **0.0000** | **0.0000** | **0.0000** | Acoustic/odor separation strictly preserved. |
| **bathroom_living** | 2,043 | 43.8% | **0.6776** | **0.3926** | **0.4972** | Distinguishes common powder baths from private attached baths. |

---

## 3. Top Feature Importances (Random Forest)

Gini importance ranking from the trained Random Forest door connectivity model:

1. `room2_category_living` (**21.91%**) — Strongest indicator for access connectivity.
2. `pair_type_bedroom_living` (**17.57%**) — Primary circulation pathway in residential layouts.
3. `room2_area_ratio` (**12.71%**) — Relative room scale determines hub vs terminal nodes.
4. `room1_area_ratio` (**7.23%**) — Subordinate room area.
5. `pair_area_ratio` (**5.78%**) — Ratio of room sizes indicates hierarchy.
6. `room1_category_bathroom` (**5.31%**) — Bathroom terminal classification.
7. `room2_category_bedroom` (**4.94%**) — Bedroom node classification.
8. `is_same_category` (**3.44%**) — Strong negative prior against connecting identical room types.
9. `pair_type_bedroom_bedroom` (**2.98%**) — Privacy barrier indicator.
10. `pair_type_bathroom_living` (**2.08%**) — Common bath connection prior.

---

## 4. End-to-End Comparative Layout Experiments

Test layouts were generated across four standard Pakistani plot sizes using both:
* **System A:** Baseline Phase 4 Rule-Based CP-SAT Partitioner
* **System B:** Phase 5 Hybrid ML + CP-SAT Optimization

| Metric | 5 Marla Standard (25×45 ft) | 5 Marla Modern (25×50 ft) | 10 Marla Luxury (35×65 ft) | 1 Kanal Estate (50×90 ft) |
| :--- | :--- | :--- | :--- | :--- |
| **Geometric Feasibility** | **100% Feasible** (Both) | **100% Feasible** (Both) | **100% Feasible** (Both) | **100% Feasible** (Both) |
| **BFS Reachability** | **100% Valid** (Both) | **100% Valid** (Both) | **100% Valid** (Both) | **100% Valid** (Both) |
| **Baseline LK Travel Dist** | 16.05 ft | 16.65 ft | 23.00 ft | 27.00 ft |
| **Hybrid ML LK Travel Dist** | **12.50 ft** | **12.50 ft** | **16.00 ft** | **20.00 ft** |
| **Travel Distance Reduction**| **-22.1%** | **-24.9%** | **-30.4%** | **-25.9%** |
| **Baseline Bed-Bath Dist** | 14.32 ft | 15.88 ft | 18.89 ft | 31.11 ft |
| **Hybrid Bed-Bath Dist** | 14.44 ft | 15.88 ft | **18.75 ft** | **30.93 ft** |
| **Baseline Runtime** | 7.1 ms | 0.5 ms | 0.5 ms | 1.0 ms |
| **Hybrid Runtime (Warm)** | 59.4 ms | 45.1 ms | 58.1 ms | 60.7 ms |

### Key Takeaway
The Hybrid ML + CP-SAT system achieved a **22% to 30% reduction in circulation travel distance** between frequently paired living and kitchen spaces, while strictly maintaining 100% mathematical non-overlap and 100% BFS reachability with sub-65ms warm inference latency.
