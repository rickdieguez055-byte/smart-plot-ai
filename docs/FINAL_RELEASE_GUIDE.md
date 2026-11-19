# SmartPlot AI — Final Release & Installation Guide (Phase 9)

**Project Number:** 22  
**Institution:** City University of Science and Information Technology (CUSIT), Peshawar  
**Author:** Mueed Ahmad (14724)  
**Release Version:** v1.0.0 Final  
**Artifact Outputs:**  
- `SmartPlot_AI_Final.apk` (50.7 MB) — Android Release  
- `SmartPlot_AI_Final.ipa` (7.53 MB) — iOS Release  

---

## 1. Android Installation Guide

### Option A: Direct Sideloading (Recommended)
1. Copy `SmartPlot_AI_Final.apk` to Android device storage via USB or Google Drive.
2. Open Files app, tap `SmartPlot_AI_Final.apk`.
3. If prompted, allow "Install from Unknown Sources".
4. Tap **Install** and open SmartPlot AI.

### Option B: USB ADB Installation
With Android device connected in Developer Mode (USB debugging enabled):
```bash
adb install -r SmartPlot_AI_Final.apk
adb reverse tcp:5000 tcp:5000
```

---

## 2. iOS Installation Guide (Physical iPhone)

### 2.1 Sideloading via Sideloadly (Free Apple ID)
1. Open Sideloadly on Windows.
2. Connect iPhone via USB and tap "Trust This Computer" on the iPhone screen.
3. Drag and drop `SmartPlot_AI_Final.ipa` (or `SmartPlot_AI_v1.0.0_unsigned.ipa`) into Sideloadly.
4. Enter your Apple ID (e.g., `mueed.ahmad@outlook.com`).
5. Click **Start** and enter Apple ID password / 2FA code when prompted.
6. Once Sideloadly reaches 100%, the SmartPlot AI app appears on your iPhone home screen.

### 2.2 Critical Step: Trusting the Developer Certificate
When tapping the app for the first time, iOS shows:
> *"Untrusted Developer: Your device management settings do not allow using apps from developer iPhone Developer..."*

**To Trust the Developer Certificate:**
1. Open **Settings** on your iPhone.
2. Navigate to **General** ➔ **VPN & Device Management** (or **Device Management**).
3. Under **Developer App**, tap your Apple ID (`mueed.ahmad@outlook.com`).
4. Tap **Trust "iPhone Developer: mueed.ahmad@outlook.com (...)"** and confirm by tapping **Trust**.
5. *(iOS 16+ Requirement)* Ensure Developer Mode is enabled:  
   Go to **Settings** ➔ **Privacy & Security** ➔ scroll to bottom ➔ **Developer Mode** ➔ Toggle **ON** (reboot iPhone if prompted).
6. Return to your Home Screen and launch **SmartPlot AI**!

---

## 3. Connecting to the Backend Services

Ensure the host computer is running the backend services on the same Wi-Fi network:
- **FastAPI Microservice (:8000):** `python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000`
- **Node.js Gateway (:5000):** `node node-gateway/src/index.js`

### Network Presets in Mobile App:
- **Default for iPhone on Wi-Fi:** `http://192.168.18.11:5000` (auto-selected).
- **Default for Android on USB:** `http://127.0.0.1:5000` (with `adb reverse tcp:5000 tcp:5000`).
- **Cloud HTTPS:** `https://api.smartplot.ai` (when hosted on remote server).

---

## 4. Final Quality & Feasibility Verification

| Feature | Android | iOS | Validation Status |
|:---|:---:|:---:|:---:|
| **Plot Geometry Input (25×45 to 50×90)** | Supported | Supported | Verified |
| **Dual Plans (Plan A Open vs Plan B Privacy)** | Supported | Supported | Verified |
| **Multi-Floor G+1 with 3D Aligned Staircase** | Supported | Supported | Verified |
| **Interactive Plan Editing (Move/Resize)** | Supported | Supported | Verified |
| **Undo / Redo / Reset to AI Original** | Supported | Supported | Verified |
| **Save & Reopen Saved Plans** | Supported | Supported | Verified |
| **High-Res Scalable SVG Export & Share** | Supported | Supported | Verified |
| **SP-AI-10 Preliminary Design Notice** | Rendered | Rendered | Verified |
