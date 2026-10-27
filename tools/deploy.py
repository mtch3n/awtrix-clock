import base64
import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = {
    "blockfont": "blockfont",
    "sky": "Sky",
    "clock": "Clock",
    "timer": "Timer",
    "calm": "Calm",
    "google-calendar": "Google-Calendar",
    "gmail": "Gmail",
    "slack": "Slack",
    "network": "Network",
    "pet": "Pet",
}


def call(method, path, body=None, content_type="application/json"):
    host = os.environ["AWTRIX_HOST"]
    auth = base64.b64encode(f"{os.environ['AWTRIX_USER']}:{os.environ['AWTRIX_PASS']}".encode()).decode()
    req = urllib.request.Request(f"http://{host}/api/v1{path}", data=body, method=method,
                                 headers={"Authorization": f"Basic {auth}", "Content-Type": content_type})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def main():
    for stem, names in SCRIPTS.items():
        source = (ROOT / "scripts" / f"{stem}.be").read_bytes()
        for name in names if isinstance(names, list) else [names]:
            print(name, call("PUT", f"/apps/script/{name}", source, "text/plain"))
    display = json.loads((ROOT / "settings" / "display.json").read_text())
    print("settings", "ok" if call("PATCH", "/settings", json.dumps(display).encode()) else "failed")
    present = {a["name"] for a in call("GET", "/apps")}
    for name, values in json.loads((ROOT / "settings" / "app-config.json").read_text()).items():
        if name in present and values:
            print(name, "config", call("PATCH", f"/apps/{name}/config", json.dumps(values).encode()))
        elif name not in present:
            print(name, "not installed: send it from the AWTRIX Hub, then run again")
    print("order", call("PUT", "/apps/order", (ROOT / "settings" / "apps.json").read_bytes()))


if __name__ == "__main__":
    if not all(os.environ.get(k) for k in ("AWTRIX_HOST", "AWTRIX_USER", "AWTRIX_PASS")):
        sys.exit("Set AWTRIX_HOST, AWTRIX_USER and AWTRIX_PASS")
    main()
