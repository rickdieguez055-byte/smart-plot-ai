# SmartPlot AI — Architectural Layout Quality Benchmark Suite

**Phase:** 5B Validation & Quality Verification  
**Date:** November 8, 2026  
**Evaluation Suite:** 64 Exhaustive Residential Layout Scenarios  

---

## 1. Executive Summary & Verification Metrics

| Evaluation Metric | Target Threshold | Actual Result | Status |
| :--- | :--- | :--- | :--- |
| **Geometric Feasibility Rate** | 100% | **100.0%** | PASS |
| **Boundary Containment** | 100% | **100.0%** | PASS |
| **Zero Room Overlap Guarantee** | 100% | **100.0%** | PASS |
| **Circulation Reachability (BFS)** | 100% | **100.0%** | PASS |
| **ML Hybrid Engine Utilization** | > 95% | **100.0%** | PASS |
| **Average Solver Execution Latency** | < 200 ms | **113.4 ms** | PASS |
| **Average Foyer-to-Room Walk Distance** | Feasible Path | **34.29 ft** | PASS |

---

## 2. Benchmark Scenario Matrix (Sample of 64 Scenarios)

| Case ID | Plot Size & Orientation | Room Template | Mode | Feasible | Overlap | Reachable | Avg Walk Dist | Solve Latency |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `CASE_01` | 40x25 ft (North) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 25.9 ft | 2237.3 ms |
| `CASE_02` | 40x25 ft (North) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 26.5 ft | 86.4 ms |
| `CASE_03` | 40x25 ft (South) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 25.9 ft | 80.0 ms |
| `CASE_04` | 40x25 ft (South) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 26.5 ft | 86.9 ms |
| `CASE_05` | 40x25 ft (East) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 25.9 ft | 74.4 ms |
| `CASE_06` | 40x25 ft (East) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 26.5 ft | 76.5 ms |
| `CASE_07` | 40x25 ft (West) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 25.9 ft | 73.4 ms |
| `CASE_08` | 40x25 ft (West) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 26.5 ft | 73.7 ms |
| `CASE_09` | 45x25 ft (North) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 28.2 ft | 73.7 ms |
| `CASE_10` | 45x25 ft (North) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 28.8 ft | 101.1 ms |
| `CASE_11` | 45x25 ft (South) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 28.2 ft | 88.5 ms |
| `CASE_12` | 45x25 ft (South) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 28.8 ft | 79.4 ms |
| `CASE_13` | 45x25 ft (East) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 28.2 ft | 73.9 ms |
| `CASE_14` | 45x25 ft (East) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 28.8 ft | 74.2 ms |
| `CASE_15` | 45x25 ft (West) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 28.2 ft | 76.0 ms |
| `CASE_16` | 45x25 ft (West) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 28.8 ft | 74.1 ms |
| `CASE_17` | 50x25 ft (North) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 30.0 ft | 89.9 ms |
| `CASE_18` | 50x25 ft (North) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 30.7 ft | 102.7 ms |
| `CASE_19` | 50x25 ft (South) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 30.0 ft | 72.9 ms |
| `CASE_20` | 50x25 ft (South) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 30.7 ft | 73.1 ms |
| `CASE_21` | 50x25 ft (East) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 30.0 ft | 74.8 ms |
| `CASE_22` | 50x25 ft (East) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 30.7 ft | 73.7 ms |
| `CASE_23` | 50x25 ft (West) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 30.0 ft | 71.9 ms |
| `CASE_24` | 50x25 ft (West) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 30.7 ft | 109.3 ms |
| `CASE_25` | 50x30 ft (North) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 32.2 ft | 84.0 ms |
| `CASE_26` | 50x30 ft (North) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 32.8 ft | 89.8 ms |
| `CASE_27` | 50x30 ft (South) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 32.2 ft | 80.4 ms |
| `CASE_28` | 50x30 ft (South) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 32.8 ft | 98.5 ms |
| `CASE_29` | 50x30 ft (East) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 32.2 ft | 81.2 ms |
| `CASE_30` | 50x30 ft (East) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 32.8 ft | 97.8 ms |
| `CASE_31` | 50x30 ft (West) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 32.2 ft | 74.2 ms |
| `CASE_32` | 50x30 ft (West) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 32.8 ft | 90.5 ms |
| `CASE_33` | 60x30 ft (North) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 34.1 ft | 91.1 ms |
| `CASE_34` | 60x30 ft (North) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 34.9 ft | 75.3 ms |
| `CASE_35` | 60x30 ft (South) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 34.1 ft | 73.0 ms |
| `CASE_36` | 60x30 ft (South) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 34.9 ft | 72.8 ms |
| `CASE_37` | 60x30 ft (East) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 34.1 ft | 85.9 ms |
| `CASE_38` | 60x30 ft (East) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 34.9 ft | 99.8 ms |
| `CASE_39` | 60x30 ft (West) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 34.1 ft | 76.3 ms |
| `CASE_40` | 60x30 ft (West) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 34.9 ft | 74.9 ms |
| `CASE_41` | 65x35 ft (North) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 37.2 ft | 72.8 ms |
| `CASE_42` | 65x35 ft (North) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 38.0 ft | 72.4 ms |
| `CASE_43` | 65x35 ft (South) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 37.2 ft | 74.8 ms |
| `CASE_44` | 65x35 ft (South) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 38.0 ft | 87.0 ms |
| `CASE_45` | 65x35 ft (East) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 37.2 ft | 72.3 ms |
| `CASE_46` | 65x35 ft (East) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 38.0 ft | 73.7 ms |
| `CASE_47` | 65x35 ft (West) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 37.2 ft | 73.2 ms |
| `CASE_48` | 65x35 ft (West) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 38.0 ft | 73.1 ms |
| `CASE_49` | 70x40 ft (North) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 40.1 ft | 75.8 ms |
| `CASE_50` | 70x40 ft (North) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 41.1 ft | 75.7 ms |
| `CASE_51` | 70x40 ft (South) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 40.1 ft | 73.2 ms |
| `CASE_52` | 70x40 ft (South) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 41.1 ft | 75.0 ms |
| `CASE_53` | 70x40 ft (East) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 40.1 ft | 73.8 ms |
| `CASE_54` | 70x40 ft (East) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 41.1 ft | 76.4 ms |
| `CASE_55` | 70x40 ft (West) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 40.1 ft | 72.7 ms |
| `CASE_56` | 70x40 ft (West) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 41.1 ft | 73.2 ms |
| `CASE_57` | 90x50 ft (North) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 43.1 ft | 73.4 ms |
| `CASE_58` | 90x50 ft (North) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 45.0 ft | 73.9 ms |
| `CASE_59` | 90x50 ft (South) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 43.1 ft | 88.6 ms |
| `CASE_60` | 90x50 ft (South) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 45.0 ft | 78.5 ms |
| `CASE_61` | 90x50 ft (East) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 43.1 ft | 76.4 ms |
| `CASE_62` | 90x50 ft (East) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 45.0 ft | 76.7 ms |
| `CASE_63` | 90x50 ft (West) | 2-Bed Standard (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 43.1 ft | 75.7 ms |
| `CASE_64` | 90x50 ft (West) | 3-Bed Family (with Porch) | `ml_hybrid` | YES | 0.0 sqft | 100% | 45.0 ft | 76.1 ms |

---

## 3. Methodology & Mathematical Guarantees

1. **Boundary Containment:** Verified via 2D bounding rectangle intersection tests against buildable plot envelope.
2. **Zero Overlap:** Pairwise rectangle intersection area checked for every pair of rooms; guaranteed 0.0 sqft overlap.
3. **Graph Walking Distance:** Computed along the explicit door and corridor topology using Dijkstra's shortest path algorithm.
4. **Reachability:** Full BFS traversal confirms every room is directly connected to a corridor or social space.
