#!/usr/bin/env python3
"""Delete past / expired FreeFood listings from the CloudKit PUBLIC database.

Runs server-side (e.g. a GitHub Actions cron) using a CloudKit **server-to-server
key**, which has full access to the public database — so it can delete *anyone's*
stale records, unlike the app (which can only delete the signed-in user's own).

A record is deleted when EITHER:
  - the event has ended  (date + endTime in the past, with a 24h grace for timezone skew), or
  - the post is older than 7 days  (expiresAt < now).

Env vars:
  CKWS_KEY_ID         server-to-server Key ID from CloudKit Console
  CKWS_PRIVATE_KEY    the EC private key PEM (contents), or set CKWS_PRIVATE_KEY_PATH
  CKWS_PRIVATE_KEY_PATH  path to the .pem (alternative to CKWS_PRIVATE_KEY)
  CK_CONTAINER        iCloud container id (default iCloud.com.tertiaryinfotech.freefood)
  CK_ENVIRONMENT      production | development   (default production)
"""
import base64, datetime, hashlib, json, os, sys, urllib.request, urllib.error
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import load_pem_private_key

BASE = "https://api.apple-cloudkit.com"
CONTAINER = os.environ.get("CK_CONTAINER", "iCloud.com.tertiaryinfotech.freefood")
ENVIRONMENT = os.environ.get("CK_ENVIRONMENT", "production")
KEY_ID = os.environ["CKWS_KEY_ID"]
GRACE_MS = 24 * 60 * 60 * 1000  # absorb timezone differences before deleting a "past" event


def load_key():
    pem = os.environ.get("CKWS_PRIVATE_KEY")
    if not pem:
        with open(os.environ["CKWS_PRIVATE_KEY_PATH"], "rb") as f:
            return load_pem_private_key(f.read(), password=None)
    return load_pem_private_key(pem.encode(), password=None)


def request(path, body, key):
    body_bytes = json.dumps(body).encode()
    date = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    body_hash = base64.b64encode(hashlib.sha256(body_bytes).digest()).decode()
    message = f"{date}:{body_hash}:{path}"
    signature = base64.b64encode(key.sign(message.encode(), ec.ECDSA(hashes.SHA256()))).decode()
    req = urllib.request.Request(
        BASE + path, data=body_bytes, method="POST",
        headers={
            "Content-Type": "application/json",
            "X-Apple-CloudKit-Request-KeyID": KEY_ID,
            "X-Apple-CloudKit-Request-ISO8601Date": date,
            "X-Apple-CloudKit-Request-SignatureV1": signature,
        })
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        sys.exit(f"CKWS error {e.code} on {path}: {e.read().decode()[:500]}")


def now_ms():
    return datetime.datetime.now(datetime.timezone.utc).timestamp() * 1000


def combined_end_ms(date_ms, end_ms):
    """Event day (from `date`) at the end time-of-day (from `endTime`), in UTC."""
    d = datetime.datetime.fromtimestamp(date_ms / 1000, datetime.timezone.utc)
    e = datetime.datetime.fromtimestamp(end_ms / 1000, datetime.timezone.utc)
    combined = d.replace(hour=e.hour, minute=e.minute, second=0, microsecond=0)
    return combined.timestamp() * 1000


def is_stale(fields, now):
    expires = (fields.get("expiresAt") or {}).get("value")
    if expires is not None and expires < now:
        return True
    date_v = (fields.get("date") or {}).get("value")
    end_v = (fields.get("endTime") or {}).get("value")
    if date_v is not None and end_v is not None:
        if combined_end_ms(date_v, end_v) + GRACE_MS < now:
            return True
    return False


def main():
    key = load_key()
    db_path = f"/database/1/{CONTAINER}/{ENVIRONMENT}/public"
    now = now_ms()
    to_delete, marker, scanned = [], None, 0
    while True:
        body = {"query": {"recordType": "FoodListing"}, "resultsLimit": 200}
        if marker:
            body["continuationMarker"] = marker
        resp = request(db_path + "/records/query", body, key)
        records = resp.get("records", [])
        scanned += len(records)
        for rec in records:
            if is_stale(rec.get("fields", {}), now):
                to_delete.append(rec["recordName"])
        marker = resp.get("continuationMarker")
        if not marker:
            break

    print(f"Scanned {scanned} record(s); {len(to_delete)} past/expired to delete.")
    for i in range(0, len(to_delete), 200):
        batch = to_delete[i:i + 200]
        body = {"operations": [{"operationType": "delete", "record": {"recordName": rn}} for rn in batch]}
        resp = request(db_path + "/records/modify", body, key)
        deleted = [r for r in resp.get("records", []) if r.get("deleted")]
        print(f"Deleted {len(deleted)}/{len(batch)} in batch {i // 200 + 1}.")
    print("Cleanup complete.")


if __name__ == "__main__":
    main()
