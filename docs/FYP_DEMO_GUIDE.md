# SmartPlot AI — FYP Demonstration & Defense Guide

**Project Title**: SmartPlot AI — Automated Plot Layout & Architectural Floor Plan Generator  
**Project Number**: 22  
**Final Year Project (FYP)** • City University of Science and Information Technology (CUSIT), Peshawar  

---

## 1. Quick Startup Playbook (Demo Day Setup)

Run the backend services on your Windows laptop before demonstrating on your phone.

### Step 1: Start Python AI Microservice (Port 8000)
Open PowerShell Window 1:
```powershell
cd "C:\Users\Mueed\Desktop\smart plot_ai"
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
```
*Verify at: `http://127.0.0.1:8000/docs` (Swagger UI displays green 200 OK).*

### Step 2: Start Node.js API Gateway (Port 5000)
Open PowerShell Window 2:
```powershell
cd "C:\Users\Mueed\Desktop\smart plot_ai\node-gateway"
node src/index.js
```
*Verify at: `http://127.0.0.1:5000/health` (Returns `{"status": "ok", "service": "smartplot-gateway"}`).*

### Step 3: Connect Your Mobile Phone

#### For Android (e.g. Google Pixel 7 via USB):
```powershell
adb reverse tcp:5000 tcp:5000
```
In the SmartPlot Android app: Settings -> Select **Physical Device USB Reverse (127.0.0.1:5000)**.

#### For iPhone (Physical Device via Wi-Fi):
Ensure your iPhone and Windows laptop are connected to the same Wi-Fi router.
In the SmartPlot iOS app: Settings -> Select **Local Wi-Fi Host (192.168.18.11:5000)**.

---

## 2. Step-by-Step Demonstration Walkthrough

### Scenario 1: Standard 5 Marla Single-Floor Layout (Plan A vs Plan B)
1. **Launch App**: Open SmartPlot AI on your phone. Point out the professional branding and clean UI.
2. **Plot Inputs**:
   - Tap **Generate New Floor Plan**.
   - Select preset **5 Marla (25 × 45 ft)**.
   - Road Entrance Orientation: **South**.
   - Tap **Next: Living Requirements**.
3. **Room Requirements**:
   - Number of Floors: **1 Floor (Single Story)**.
   - Bedrooms: **2**, Bathrooms: **2**, Car Porch: **Yes**, Kitchen: **Yes**, Living Room: **Yes**.
   - Tap **Generate Architectural Plans**.
4. **Show Dual Design Alternatives**:
   - Explain **Plan A (Open Living Concept)**: Emphasizes open spatial flow, central family living, and direct kitchen connection.
   - Explain **Plan B (Privacy-Segregated Concept)**: Features a dedicated formal drawing room near the entrance for guests, keeping family bedrooms and kitchen private.
   - Tap **Compare Plans**: Show the side-by-side room count and spatial utilization breakdown.

### Scenario 2: Multi-Floor Generation (Ground Floor + First Floor)
1. In the input form, select **2 Floors (G+1)** for a **10 Marla (35 × 65 ft)** plot.
2. Ground Floor: Drawing room, Porch, Kitchen, Living room, Master bedroom with attached bath.
3. First Floor: 2 Family bedrooms, Upper lounge, Front open terrace.
4. Tap **Generate**.
5. Switch between the **Ground Floor** and **First Floor** tabs on the Results Screen.
6. **Key Defense Point**: Highlight the **Staircase Core Alignment**. The staircase has the exact same coordinate bounding box $(x, y, w, l)$ on both the ground and first floor, satisfying the Blondel architectural formula ($2R + T \approx 24.5''$).

### Scenario 3: Interactive Floor Plan Editor
1. From any generated layout, tap the **Edit Plan** button.
2. Select a room (e.g., *Master Bedroom*).
3. Use the interactive controls to **nudge/move** or **resize** the room.
4. Demonstrate **Constraint Enforcement**:
   - Try to drag the room outside the plot boundary -> The editor flags invalid coordinates.
5. Tap **Apply & Recalculate**:
   - The backend validates geometry, regenerates physical wall cutouts, recalculates doors/windows, and returns a freshly rendered SVG.
6. Demonstrate **Undo**, **Redo**, and **Reset to AI Layout**.

### Scenario 4: Exporting & Native Sharing
1. Tap the **Export Plan** icon in the viewer.
2. Save the layout to persistent storage.
3. On iOS, open the native **Files** app -> go to *On My iPhone -> SmartPlot AI* to show the exported vector `.svg` file.
4. Tap **Share** to demonstrate opening the iOS Native Share Sheet (AirDrop / Mail / Messages).

---

## 3. Defense Questions & Strong Architectural Answers

| Likely Question from Jury | Recommended Answer |
| :--- | :--- |
| **"Why did you use CP-SAT instead of training an End-to-End Deep Learning model to draw houses?"** | *"Pure generative ML (like GANs or diffusion) often produces hallucinated, non-square rooms with overlapping walls and impossible geometries. We implemented a **Hybrid AI Architecture**: Random Forest models predict probabilistic room adjacencies and door connectivity from 14,000+ real floor plans, while Google OR-Tools CP-SAT enforces mathematical non-overlap, boundary containment, and circulation clearance."* |
| **"Why is the attached bathroom door recall 22.52% in your ML model?"** | *"In real-world residential datasets, attached bathrooms represent an imbalanced minority class compared to common hallway doors. Instead of fabricating fake metrics, we truthfully audited this limitation and designed an architectural pairing rule in the CP-SAT engine that guarantees attached bathrooms always share a wall and direct doorway with their master bedroom."* |
| **"Can these plans be directly submitted for city municipal approval?"** | *"No. As printed directly on every generated drawing under requirement **SP-AI-10**, SmartPlot AI generates preliminary architectural spatial layouts. Structural load calculations, column placement, plumbing risers, and electrical drawings require review by a licensed structural engineer."* |
| **"How does the interactive editor prevent the user from making an invalid house?"** | *"When a user resizes or drags a room, the client submits the updated bounding box coordinates to `/api/v1/plans/edit/validate`. The backend verifies non-overlap and setback containment before committing the changes and dynamically recalculates doors and circulation."* |
