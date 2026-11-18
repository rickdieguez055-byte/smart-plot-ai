# SmartPlot AI — Machine Learning Dataset Audit

**Document:** `docs/ML_DATASET_AUDIT.md`  
**Date:** November 7, 2026  
**Auditor:** Senior ML Engineer & Python Backend Developer  
**Status:** Verified & Implemented  

---

## 1. Candidate Dataset Evaluation

To transition SmartPlot AI from a pure heuristic and constraint solver into a genuine hybrid system, two prominent residential architectural datasets were evaluated:

### 1.1 RPLAN Dataset
* **Citation:** Wu et al., *"Data-driven Interior Plan Generation for Residential Buildings"*, ACM Transactions on Graphics (SIGGRAPH 2019).
* **Scale:** 80,788 annotated residential floor plans.
* **Format:** Primarily raster image masks (`.png`) and MATLAB `.mat` layout graphs.
* **Availability & Access:** Access to the official raw dataset requires an academic request form submitted to the original authors. Third-party mirrors on GitHub (e.g. Graph2Plan) provide pre-extracted `.mat` subsets, but raw images require manual approval and are not directly streamable via automated package managers.
* **Data Representation:** Highly stylized, idealized residential plans from Asian high-rise apartments. Each plan contains outer boundary loops, sequential room ordering, room types (`rType`), and bounding boxes (`gtBox`).
* **Licensing:** Research-only, non-commercial academic license.

### 1.2 ResPlan-FP Dataset (Selected)
* **Citation:** Zhang, He, *"When Should a Network Emit Geometry, and When Should It Detect It? Readout, Reconciliation, and Representation in Floorplan Vectorization"*, arXiv:2608.25608 (2026).
* **Repository:** [Tristan12138/resplan-fp on Hugging Face](https://huggingface.co/datasets/Tristan12138/resplan-fp)
* **Scale:** 16,998 residential floor plans.
* **Format:** Wall-first vector JSON Lines (`train.jsonl`, `val.jsonl`, `test.jsonl`) with standardized 1024-pixel longer-edge coordinate frames.
* **Availability & Access:** Publicly hosted on Hugging Face with global CloudFront CDN endpoints; accessible programmatically without authentication barriers, API fees, or restrictive request forms.
* **Licensing:** **Creative Commons Attribution 4.0 International (CC-BY-4.0)**. Permits copying, redistribution, transformation, and building upon the material for academic and commercial applications with proper attribution.
* **Semantic Annotations:**
  * **Rooms:** Wall-cycle polygons with exact coordinate vertices and functional semantic labels (`LIVING`, `BEDROOM`, `BATH`, `KITCHEN`, `ROOM`, `BALCONY`).
  * **Walls:** Centerline start and end coordinates `(x, y)`, physical wall thicknesses, wall classifications (`interior` vs `exterior`), and opening arrays.
  * **Openings:** Explicit sub-element annotations for doors and windows, complete with `type` (`door`, `window`), `center` coordinates, and physical aperture `width`.

---

## 2. Selection Rationale: Why ResPlan-FP Was Chosen

| Evaluation Criteria | RPLAN | ResPlan-FP | Selection Verdict |
| :--- | :--- | :--- | :--- |
| **Licensing** | Academic request only | **CC-BY-4.0 Open Access** | **ResPlan-FP** |
| **Direct Accessibility** | Form submission required | **Direct HTTP stream via Hugging Face** | **ResPlan-FP** |
| **Openings Ground Truth** | Inferred from adjacency | **Explicit door/window coordinates on walls** | **ResPlan-FP** |
| **Vector Geometry** | Bounding box approximations | **Exact polygon loops + wall centerlines** | **ResPlan-FP** |
| **Data Integrity Splits** | Community ad-hoc splits | **Frozen splits with official SHA-256 hashes** | **ResPlan-FP** |

ResPlan-FP was selected as the verified ground truth dataset for SmartPlot Phase 5A because it provides explicit, verifiable door openings on shared walls—the exact ground truth required to train a door-connectivity and wall-adjacency predictor.

---

## 3. Data Integrity & Leakage Prevention Protocol

To strictly satisfy `ml-best-practices`:

1. **Split-by-Plan-Identity:**
   ResPlan provides three officially frozen splits defined in `splits.json`:
   * **Train Split (`train.jsonl`):** 14,998 floor plans (SHA256: `5af77996b313bba2`).
   * **Validation Split (`val.jsonl`):** 1,000 floor plans (SHA256: `efb5e82b808acec4`).
   * **Test Split (`test.jsonl`):** 1,000 floor plans (SHA256: `669656eabb515960`).
   SmartPlot streamed the first 2,992 plans from `train.jsonl`, all 998 valid plans from `val.jsonl`, and all 997 valid plans from `test.jsonl`. No plan ID exists in more than one split.

2. **Strict Featurization Ordering:**
   * Feature transformation (`ColumnTransformer`) was fit **exclusively** on the training split (`train_df`).
   * `StandardScaler` mean and variance, and `OneHotEncoder` category dictionaries were learned on the training set and applied to validation and test sets without re-fitting.
   * Zero data leakage between evaluation and training sets.

3. **No Target Leakage:**
   * During layout inference, the physical $(x, y)$ coordinates, wall positions, and door counts are outputs of the layout solver, not inputs.
   * Features are strictly limited to properties available *before* spatial layout: plot dimensions, setbacks, requested room types, target room areas, and plot aspect ratios.

---

## 4. Semantic Room Label Mapping

Raw labels in ResPlan-FP were mapped to SmartPlot's canonical architectural taxonomy via [`backend/app/ml/taxonomy.py`](file:///D:/smart%20plot_ai/backend/app/ml/taxonomy.py):

| ResPlan Raw Label | SmartPlot Canonical Category | Sample Count (Train Split) |
| :--- | :--- | :--- |
| `BEDROOM`, `ROOM` | `bedroom` | 7,047 |
| `BATH` | `bathroom` | 6,214 |
| `LIVING`, `DINING`, `HALL` | `living` | 2,931 |
| `KITCHEN` | `kitchen` | 549 |
| `BALCONY`, `TERRACE` | `parking` (outdoor buffer) | 2 |

Total room entities in training split: **16,743 rooms**.

---

## 5. Note on Pakistani Architectural Datasets

In accordance with strict academic integrity guidelines:
* **No synthetic or fabricated Pakistani architectural dataset is claimed.**
* While SmartPlot's Phase 1–4 geometric rules reflect Pakistani residential plot sizes (5 Marla, 10 Marla, 1 Kanal) and municipal setback bylaws (CDA/LDA/KDA approximations), training a supervised deep learning model on domain-specific Pakistani layouts requires a legitimate, licensed CAD repository of stamped Pakistani blueprints.
* Collecting, anonymizing, and vectorizing 500+ verified Pakistani architectural plans with formal builder consent is scheduled as a dedicated future data engineering initiative for Phase 5B. ResPlan-FP serves as the validated open benchmark for Phase 5A.
