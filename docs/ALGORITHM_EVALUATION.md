# Spatial Constraint-Solving Algorithm Evaluation

## 1. Problem Definition
The SmartPlot AI planning engine must solve the problem of arranging a user-specified set of functional rooms (bedrooms, bathrooms, kitchen, living room, car porch, circulation) inside a 2D rectangular parcel of land subject to:
1. Strict boundary containment ($x \ge 0, y \ge 0, x+w \le W, y+h \le L$).
2. Strict non-overlapping invariant between all pairs of rooms.
3. Realistic architectural dimensions and aspect ratios (e.g. rooms cannot be 1-foot thin strips).
4. Orientation and zoning constraints (e.g., entrance and parking on the road side, kitchen on external perimeter for natural ventilation, private bedrooms at rear).
5. Computational efficiency: Response within < 3 seconds on standard CPU hardware.

---

## 2. Candidate Approaches Evaluated

### Approach A: Deep Learning / Generative Floor Plan Models (e.g., HouseGAN++, Graph-to-Plan, Diffusion)
- **Strengths:** Can learn nuanced human architectural styles from large CAD/BIM floor plan datasets.
- **Critical Limitations for Phase 1:**
  - Requires large-scale labelled residential architectural datasets (e.g., R-PLAN, LIFULL) mapped to local Pakistani plot sizes (e.g., 5 Marla, 10 Marla, 1 Kanal) and building bylaws.
  - Generative neural networks (GANs/Diffusion) frequently generate invalid geometry: walls that do not close, floating ungrounded doors, overlapping rooms, or structurally unfeasible dimensions.
  - Per project instructions: *"The ML model must be introduced through a genuine, explainable training or inference pipeline. If an appropriate model or dataset has not been established, do not fabricate one or falsely label a rule-based solver as machine learning."*
- **Verdict:** Deferred to later phases when clean training data and fine-tuning pipelines are established.

### Approach B: Pure Heuristic / Force-Directed / Genetic Algorithms
- **Strengths:** Easy to write initial prototype; handles continuous placements.
- **Critical Limitations:**
  - Non-deterministic: the same inputs can produce wildly different layouts.
  - Prone to local minima where rooms slightly overlap or boundaries get violated.
  - Hard to guarantee 100% overlap-free solutions without high computational cost.
- **Verdict:** Inadequate for a reliable, testable engineering core.

### Approach C: Binary Space Partitioning (BSP) / Recursive Slicing Floorplans
- **Strengths:** Very fast ($O(n \log n)$), mathematically guarantees zero room overlaps.
- **Limitations:** Only generates guillotine partitions (slicing tree structures); cannot easily enforce complex cross-room adjacency or custom boundary alignments (e.g. aligning a car porch precisely to the entrance edge).
- **Verdict:** Selected as a robust secondary/fallback mechanism for fast initial approximations.

### Approach D: Constraint Programming with Google OR-Tools CP-SAT (Selected Approach)
- **Strengths:**
  - **Exactness:** Uses SAT-based constraint programming with integer interval variables (`NewIntervalVar`) and the native 2D non-overlapping global constraint (`AddNoOverlap2D`).
  - **Guaranteed non-overlap:** Proven mathematical guarantee that no two rectangles intersect.
  - **Flexible constraints:** Enables explicit expression of setbacks, zoning (front vs. rear vs. side), aspect ratios, and adjacency objectives.
  - **High Performance:** Google OR-Tools CP-SAT solver is implemented in optimized C++ with Python bindings; solves residential room layout problems with 5-15 rooms in tens to hundreds of milliseconds.
  - **Explainability:** 100% explainable, deterministic when seeded, and provably verifiable by unit tests.
- **Verdict:** **Selected as the primary spatial layout engine for SmartPlot Phase 1.**

---

## 3. Mathematical Formulation (CP-SAT)

Let the plot bounding box have buildable width $W_{net}$ and length $L_{net}$.
For each room $i \in \{1, \dots, N\}$:
- Width $w_i \in [w_{min, i}, w_{max, i}]$
- Length $h_i \in [h_{min, i}, h_{max, i}]$
- Origin position $(X_i, Y_i)$ where $X_i \in [0, W_{net} - w_i]$ and $Y_i \in [0, L_{net} - h_i]$
- Intervals: $I_{x, i} = \text{Interval}(X_i, w_i, X_i + w_i)$, $I_{y, i} = \text{Interval}(Y_i, h_i, Y_i + h_i)$

Global 2D non-overlapping constraint:
$$\text{NoOverlap2D}(\{ (I_{x, i}, I_{y, i}) \mid i = 1, \dots, N \})$$

Zoning Constraints:
- **Entrance Zone:** For entrance orientation (e.g., South road at $Y=0$), Porch and Main Foyer/Living Room are constrained to $Y_i = 0$ or within the front $30\%$ of plot depth.
- **Private Zone:** Bedrooms constrained to the rear $60\%$ of plot depth ($Y_i \ge 0.4 \times L_{net}$).
- **Ventilation:** Kitchen constrained to border an outer wall ($X_i = 0 \lor X_i + w_i = W_{net} \lor Y_i + h_i = L_{net}$).

Objective:
Minimize circulation waste and distance between functionally coupled rooms (e.g. Kitchen $\leftrightarrow$ Living/Dining, Bedroom $\leftrightarrow$ Attached Bath).
