# SmartPlot Technical Decisions & Assumptions Log

## 1. Architectural & Design Decisions

### AD-01: Microservice Decoupling
- **Decision:** Separate the Node.js Express Gateway (port 5000) from the Python FastAPI AI microservice (port 8000).
- **Rationale:** Aligns strictly with SRS Section 2.1, 2.5, 3.3, and SP-AI-05 / SP-NFR-SEC-05. The Flutter mobile app communicates exclusively with Node.js; the Python AI service remains internal and protected.

### AD-02: Spatial Engine Selection (OR-Tools CP-SAT)
- **Decision:** Employ Google OR-Tools CP-SAT as the primary constraint solver with an architectural topological slicing fallback.
- **Rationale:** Provides mathematically guaranteed non-overlapping 2D layout generation without inventing a fake ML model.

### AD-03: Vector 2D SVG Rendering
- **Decision:** Generate clean, proportionally scaled SVG vector markup directly in Python.
- **Rationale:** Resolution-independent, easily rendered in Flutter via `flutter_svg`, embeddable in web/mobile views without heavy binary rasterization dependencies.

---

## 2. Unresolved SRS Items & Phase 1 MVP Assumptions

| SRS TBD ID | Item | Phase 1 Engineering Assumption & Resolution |
|---|---|---|
| **TBD-06** | Plot input units, permitted ranges, allowed orientation values | **Units:** Feet (default for residential plots in Pakistan) and Meters. <br>**Ranges:** Length: 20 to 300 ft; Width: 15 to 200 ft; Front Width: $\le \max(\text{Length}, \text{Width})$. <br>**Orientations:** `North`, `South`, `East`, `West`, `NE`, `NW`, `SE`, `SW` (case-insensitive). |
| **TBD-07** | AI model type, training data, layout output format, layout requirements structure | **Layout Requirements:** Supported fields: `bedrooms` (1–5), `bathrooms` (1–4), `floors` (1–2), `kitchen` (bool), `living_room` (bool), `parking` (bool), `dining_room` (bool), `lawn` (bool). <br>**Output:** Structured JSON with room coordinates $(x, y, w, h)$, area, utilization percentage, location-specific orientation recommendations, and SVG vector markup. <br>**ML Model:** Explainable constraint-solving pipeline now; dedicated `MLAdvisor` interface prepared for trained model weights in future phases. |
| **TBD-08** | AI processing time target and timeout | **Timeout:** 10.0 seconds internal FastAPI solver limit; 15.0 seconds Node.js gateway upstream timeout. <br>**Processing Target:** < 2.0 seconds for standard residential layouts. |
| **TBD-30** | API protocols and message formats | REST over JSON (`POST /api/v1/plans/generate`, `GET /health`), error responses adhering to RFC 7807 problem details with `status`, `code`, `message`, and `details`. |

---

## 3. Disclaimers and Non-Certification Rule
In strict compliance with **SP-AI-10**, **SP-BR-05**, and **SP-NFR-SAF-01**, every response from the AI planning engine includes the required disclaimer:
> *"NOTICE: This layout is a preliminary, AI-assisted conceptual design and does not constitute a certified architectural or structural engineering drawing. It must be reviewed and certified by a licensed architect or structural engineer prior to construction or municipal submission."*
