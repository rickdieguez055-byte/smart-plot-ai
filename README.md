# SmartPlot AI — Plot Analysis & Layout Generation Module

**University Final Year Project (FYP)**  
**City University of Science and Information Technology (CUSIT), Pakistan**

SmartPlot AI is an automated architectural layout generation engine and microservice. It transforms raw plot boundary measurements, road entrance orientations, and residential living requirements into mathematically validated, non-overlapping 2D architectural floor plans, environmental recommendations, and vector SVG visualizations.

---

## 1. Architecture Overview

Per SRS Section 2.1, 2.5, 3.3, and Requirements SP-AI-01 to SP-AI-14:

```
Flutter Mobile App 
       │ (HTTPS)
       ▼
Node.js / Express API Gateway (Port 5000)
       │ (Internal HTTP)
       ▼
Python / FastAPI AI Microservice (Port 8000)
       │
       ├─► Dimension Estimator (Standard architectural zoning & bounds)
       ├─► Google OR-Tools CP-SAT Solver (2D spatial non-overlap & containment)
       ├─► Recommendation Engine (Orientation, solar path, ventilation, bylaws)
       └─► 2D SVG Vector Renderer (Walls, doors, labels, dimensions, disclaimer)
```

---

## 2. Directory Structure

```
SmartPlot_AI/
├── backend/                    # Python / FastAPI AI Microservice
│   ├── app/
│   │   ├── core/               # Configuration & custom exceptions
│   │   ├── schemas/            # Pydantic input/output schemas
│   │   ├── engine/             # OR-Tools CP-SAT solver, dimension estimator, recommendations
│   │   ├── renderer/           # 2D SVG floor plan generator
│   │   ├── services/           # Generation orchestration service
│   │   └── main.py             # FastAPI entrypoint
│   ├── requirements.txt
│   ├── pyproject.toml
│   └── .env.example
├── node-gateway/               # Node.js Express API Gateway
│   ├── src/
│   │   ├── config.js
│   │   ├── index.js
│   │   ├── middleware/         # Auth RBAC, validation, error handling
│   │   └── routes/             # Gateway proxy endpoints
│   ├── package.json
│   └── .env.example
├── flutter_ai_module/          # Flutter Integration Package
│   ├── lib/                    # Dart models, HTTP API client, disclaimer widgets
│   ├── pubspec.yaml
│   └── README.md
├── docs/                       # Engineering Documentation & SRS
│   ├── Final Smart_plot_Srs .pdf
│   ├── ALGORITHM_EVALUATION.md
│   ├── ARCHITECTURE.md
│   └── DECISIONS.md
├── tests/                      # Pytest suite & Gateway tests
│   ├── test_schemas.py
│   ├── test_dimension_estimator.py
│   ├── test_spatial_solver.py
│   ├── test_svg_renderer.py
│   ├── test_api_endpoints.py
│   ├── test_gateway.js
│   └── test_e2e.py
├── README.md
└── .gitignore
```

---

## 3. Quick Start & Execution

### Prerequisites
- Python 3.11+ (or `uv`)
- Node.js v18+ and npm
- Flutter 3+ (for mobile client integration)

### Step 1: Start Python FastAPI Microservice
```powershell
# Navigate to workspace root
cd "d:\smart plot_ai"

# Run with virtual environment
.\backend\.venv\Scripts\python.exe -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 --reload
```
API Documentation available at: `http://127.0.0.1:8000/docs`

### Step 2: Start Node.js API Gateway
```powershell
cd "d:\smart plot_ai\node-gateway"
node src/index.js
```
Gateway running at: `http://127.0.0.1:5000`

---

## 4. API Endpoints

### 1. Gateway Health Check
- **Endpoint:** `GET /health`
- **Response:**
```json
{
  "status": "ok",
  "gateway": {
    "name": "smartplot-gateway",
    "version": "1.0.0"
  },
  "ai_microservice": {
    "url": "http://127.0.0.1:8000",
    "status": "healthy",
    "latency_ms": 12
  }
}
```

### 2. Layout Generation
- **Endpoint:** `POST /api/v1/plans/generate`
- **Headers:** `Content-Type: application/json`
- **Sample Request:**
```json
{
  "plot": {
    "plot_length": 45.0,
    "plot_width": 25.0,
    "front_width": 25.0,
    "entrance_orientation": "South",
    "unit": "feet"
  },
  "requirements": {
    "bedrooms": 2,
    "bathrooms": 2,
    "floors": 1,
    "kitchen": true,
    "living_room": true,
    "parking": true
  }
}
```
- **Response:**
  - `status`: `"success"`
  - `plan_id`: `"plan_abc123"`
  - `rooms`: Array of room rectangles `(x, y, width, length, area, name, category)`
  - `total_built_area`: `785.5`
  - `utilization_percentage`: `69.8%`
  - `svg_floor_plan`: Proportionally scaled SVG markup string
  - `recommendations`: Location-specific architectural advice (sun path, ventilation, bylaws)
  - `disclaimer`: Mandatory preliminary design notice (SP-AI-10)

---

## 5. Running Tests

### Pytest Backend Test Suite
```powershell
.\backend\.venv\Scripts\python.exe -m pytest tests/ -v
```

### Node.js Gateway Test Suite
```powershell
node tests/test_gateway.js
```

---

## 6. SP-AI Requirements Compliance

| SRS Requirement | Description | Compliance Status |
|---|---|---|
| **SP-AI-01** | Plot input parameters (length, width, front width, entrance orientation) | **Fully Implemented** |
| **SP-AI-02** | User-specified layout requirements | **Fully Implemented** |
| **SP-AI-03** | Positive numeric validation & permitted orientations | **Fully Implemented** |
| **SP-AI-04** | Plain-language error messages on invalid input | **Fully Implemented** |
| **SP-AI-05** | Flutter → Node Gateway → FastAPI AI Microservice pipeline | **Fully Implemented** |
| **SP-AI-06** | Solver & recommendation engine execution | **Fully Implemented** |
| **SP-AI-07** | Generate preliminary 2D floor plan (SVG + coordinates) | **Fully Implemented** |
| **SP-AI-08** | Location-specific recommendations (sun path, wind, zoning) | **Fully Implemented** |
| **SP-AI-09** | Layout display to Buyer/Client | **Fully Implemented** |
| **SP-AI-10** | Mandatory preliminary design notice | **Fully Implemented** |
| **SP-AI-11** | Processing indicator & timeout handling | **Fully Implemented** |
| **SP-AI-12** | Input modification & regeneration | **Fully Implemented** |
| **SP-AI-13** | RBAC check: Buyer/Client only | **Fully Implemented** |
| **SP-AI-14** | Navigation hook to construction companies | **Prepared in metadata** |

---

## 7. Mandatory Legal Disclaimer (SP-AI-10 / SP-BR-05)
> **NOTICE:** This layout is a preliminary, AI-assisted conceptual design and does not constitute a certified architectural or structural engineering drawing. It must be reviewed and certified by a licensed architect or structural engineer prior to construction or municipal submission.
