#!/bin/bash
# Complete Remaining Domain Provisioning & Nameserver Delegation Script
# Reads CLOUDFLARE_API_TOKEN, UD_COOKIE, and UD_CSRF from environment or ~/.config/cloudflare-admin.env

set -e

ENV_FILE="/home/frank/.config/cloudflare-admin.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "Error: CLOUDFLARE_API_TOKEN not set."
    exit 1
fi

echo "=== Processing remaining portfolio domains ==="
python3 - <<'EOF'
import os, json, time, urllib.request, urllib.error

rem_file = "/home/frank/remaining_de_domains.json"
if not os.path.exists(rem_file):
    print("No remaining domains file found.")
    exit(0)

with open(rem_file) as f:
    remaining = json.load(f)

with open("/home/frank/domains_portfolio.json") as pf:
    pf_domains = json.load(pf)

did_map = {d["domain"]: d["id"] for d in pf_domains}

cf_token = os.environ.get("CLOUDFLARE_API_TOKEN")
cf_account = "bfaa8f7dcb70a45d5af13f6c1a3843a2"
cf_headers = {"Authorization": f"Bearer {cf_token}", "Content-Type": "application/json"}
tunnel_target = "dd6f0a19-2dde-42ed-bfad-295b586b461f.cfargotunnel.com"

ud_cookie = os.environ.get("UD_COOKIE", "")
ud_csrf = os.environ.get("UD_CSRF", "")

ud_headers = {
    "accept": "application/json",
    "cookie": ud_cookie,
    "http-x-csrf-token": ud_csrf,
    "content-type": "application/json; charset=UTF-8",
    "origin": "https://www.united-domains.de",
    "user-agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36"
}

success = 0
still_remaining = []

for idx, dname in enumerate(remaining):
    did = did_map.get(dname)
    if not did:
        continue
        
    cf_url = "https://api.cloudflare.com/client/v4/zones"
    cf_payload = json.dumps({"account": {"id": cf_account}, "name": dname, "type": "full"}).encode("utf-8")
    cf_req = urllib.request.Request(cf_url, data=cf_payload, headers=cf_headers)
    
    assigned_ns = None
    zone_id = None
    try:
        with urllib.request.urlopen(cf_req) as r:
            cf_data = json.loads(r.read().decode("utf-8"))["result"]
            assigned_ns = cf_data.get("name_servers")
            zone_id = cf_data.get("id")
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8")
        if "already exists" in err:
            q_url = f"https://api.cloudflare.com/client/v4/zones?name={dname}"
            q_req = urllib.request.Request(q_url, headers=cf_headers)
            with urllib.request.urlopen(q_req) as qr:
                z_list = json.loads(qr.read().decode("utf-8"))["result"]
                if z_list:
                    assigned_ns = z_list[0].get("name_servers")
                    zone_id = z_list[0].get("id")
        else:
            still_remaining.append(dname)
            continue
            
    if not assigned_ns or not zone_id:
        still_remaining.append(dname)
        continue
        
    # Ensure DNS CNAME records point to edge tunnel
    rec_url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records"
    for sub in ("@", "www"):
        try:
            rec_payload = {"type": "CNAME", "name": sub, "content": tunnel_target, "ttl": 1, "proxied": True}
            urllib.request.urlopen(urllib.request.Request(rec_url, data=json.dumps(rec_payload).encode("utf-8"), headers=cf_headers, method="POST"))
        except Exception:
            pass

    if not ud_cookie or not ud_csrf:
        still_remaining.append(dname)
        continue

    time.sleep(1)
    
    # Update united-domains
    ud_url = f"https://www.united-domains.de/pfapi/ns/{did}"
    ud_headers["referer"] = f"https://www.united-domains.de/portfolio/a/domain-admin/ns/{did}"
    ud_payload = {
        "dkimRecord": None,
        "dkimDomain": None,
        "spfRecord": None,
        "dmarcRecord": None,
        "ignoreSoftErrors": True,
        "preConfig": False,
        "domainId": str(did),
        "hasOwn": True,
        "useUdagEmail": False,
        "nameservers": [
            {"nameserver": assigned_ns[0], "glue4": "", "glue6": ""},
            {"nameserver": assigned_ns[1], "glue4": "", "glue6": ""}
        ],
        "command": "setNs"
    }
    
    ud_req = urllib.request.Request(ud_url, data=json.dumps(ud_payload).encode("utf-8"), headers=ud_headers, method="PATCH")
    try:
        with urllib.request.urlopen(ud_req) as resp:
            success += 1
            print(f"[{idx+1}/{len(remaining)}] Updated {dname} -> {assigned_ns}")
    except Exception as e:
        still_remaining.append(dname)

with open(rem_file, "w") as fp:
    json.dump(still_remaining, fp, indent=2)

print(f"Batch finished: {success} newly processed. Remaining: {len(still_remaining)}")
EOF
