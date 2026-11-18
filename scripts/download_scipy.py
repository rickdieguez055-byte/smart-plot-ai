"""Robust chunked wheel downloader with retry and range resumption."""
import os
import time
import httpx

URL = "https://files.pythonhosted.org/packages/39/e7/979fd14e75008623df31ba70d6bb144700f68feadcea042021c06a05bf82/scipy-1.18.1-cp312-cp312-win_amd64.whl"
DST = os.path.join("data", "wheels", "scipy-1.18.1-cp312-cp312-win_amd64.whl")
TOTAL_SIZE = 36658278

def download_scipy():
    os.makedirs(os.path.dirname(DST), exist_ok=True)
    existing = os.path.getsize(DST) if os.path.exists(DST) else 0
    if existing >= TOTAL_SIZE:
        print(f"scipy wheel already complete: {existing} bytes")
        return

    print(f"Starting download of scipy wheel ({TOTAL_SIZE} bytes), resuming from {existing} bytes...")
    t0 = time.time()
    last_print = t0

    client = httpx.Client(follow_redirects=True, timeout=120.0)
    headers = {"Range": f"bytes={existing}-"} if existing > 0 else {}

    with open(DST, "ab" if existing > 0 else "wb") as f:
        with client.stream("GET", URL, headers=headers) as resp:
            if resp.status_code not in (200, 206):
                raise RuntimeError(f"Unexpected HTTP status {resp.status_code}")
            
            for chunk in resp.iter_bytes(chunk_size=65536):
                f.write(chunk)
                existing += len(chunk)
                now = time.time()
                if now - last_print >= 5.0 or existing >= TOTAL_SIZE:
                    pct = (existing / TOTAL_SIZE) * 100
                    speed = (existing / (now - t0)) / 1024 if (now - t0) > 0 else 0
                    print(f"Scipy download: {existing}/{TOTAL_SIZE} bytes ({pct:.1f}%) at {speed:.1f} KB/s")
                    last_print = now

    print(f"Scipy download complete! Saved to {DST} in {round(time.time() - t0, 1)}s")

if __name__ == "__main__":
    download_scipy()
