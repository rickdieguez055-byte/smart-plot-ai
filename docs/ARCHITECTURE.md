# SmartPlot AI Module Architecture

## 1. System Context & Data Flow

```
+---------------------------+
|    Flutter Mobile App     |
+---------------------------+
              |
              | HTTPS (SP-AI-05, SP-NFR-SEC-01)
              v
+---------------------------+
|    Node.js / Express      |  Port 5000
|       API Gateway         |  - Auth & RBAC (SP-AI-13, Buyer/Client)
+---------------------------+  - Request Validation (SP-AI-03, SP-AI-04)
              |                - Gateway Timeout (SP-AI-11)
              | HTTP (Internal)
              v
+---------------------------+
|   Python / FastAPI AI     |  Port 8000
|       Microservice        |  - Protected internal service (SP-NFR-SEC-05)
+---------------------------+  - OpenAPI Docs (/docs)
              |
      +-------+-------+
      |               |
      v               v
+------------+  +--------------------------------+
| Dimension  |  | Google OR-Tools CP-SAT Solver  |
| Estimator  |  |  (2D Spatial Non-Overlap &     |
+------------+  |   Zoning Constraints)          |
      |         +--------------------------------+
      v                       |
+----------------------+      v
| Recommendation Engine|  +----------------------+
| (Sun/Wind/Zoning)    |  | 2D SVG Vector        |
+----------------------+  | Renderer             |
                          +----------------------+
```

---

## 2. Directory Structure

```
SmartPlot_AI/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   └── errors.py
│   │   ├── schemas/
│   │   │   ├── plot.py
│   │   │   ├── layout.py
│   │   │   └── response.py
│   │   ├── engine/
│   │   │   ├── dimension_estimator.py
│   │   │   ├── spatial_solver.py
│   │   │   └── recommendation_engine.py
│   │   ├── renderer/
│   │   │   └── svg_renderer.py
│   │   └── services/
│   │       └── plan_service.py
│   ├── pyproject.toml
│   ├── requirements.txt
│   └── .env.example
├── node-gateway/
│   ├── src/
│   │   ├── index.js
│   │   ├── config.js
│   │   ├── routes/
│   │   │   ├── plans.js
│   │   │   └── health.js
│   │   └── middleware/
│   │       ├── auth.js
│   │       ├── validator.js
│   │       └── errorHandler.js
│   ├── package.json
│   └── .env.example
├── flutter_ai_module/
│   ├── lib/
│   │   ├── smartplot_ai.dart
│   │   ├── models/
│   │   ├── services/
│   │   └── widgets/
│   ├── pubspec.yaml
│   └── README.md
├── docs/
│   ├── Final Smart_plot_Srs .pdf
│   ├── ALGORITHM_EVALUATION.md
│   ├── ARCHITECTURE.md
│   └── DECISIONS.md
├── tests/
│   ├── test_schemas.py
│   ├── test_dimension_estimator.py
│   ├── test_spatial_solver.py
│   ├── test_svg_renderer.py
│   ├── test_api_endpoints.py
│   └── test_e2e.py
├── README.md
└── .gitignore
```
