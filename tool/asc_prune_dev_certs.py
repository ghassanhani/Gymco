"""Revokes the development certificates that earlier release runs made.

Each run signs on a fresh Mac, so Xcode makes a new "Apple Development"
certificate every time and Apple's limit fills up after a dozen builds.
Only certificates made with the API key ("Created via API") are revoked;
ones made in Xcode on a real Mac are left alone. Distribution signing is
cloud-managed and not touched.

env: KEY_ID, ISSUER, KEY_PATH (the App Store Connect .p8)
"""

import json
import os
import time
import urllib.request

import jwt

API = "https://api.appstoreconnect.apple.com/v1"

token = jwt.encode(
    {"iss": os.environ["ISSUER"], "iat": int(time.time()), "exp": int(time.time()) + 600, "aud": "appstoreconnect-v1"},
    open(os.environ["KEY_PATH"]).read(),
    algorithm="ES256",
    headers={"kid": os.environ["KEY_ID"], "typ": "JWT"},
)


def call(method, path):
    req = urllib.request.Request(API + path, method=method, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req) as r:
        body = r.read()
        return json.loads(body) if body else None


certs = call("GET", "/certificates?filter[certificateType]=DEVELOPMENT,IOS_DEVELOPMENT&limit=200")["data"]
for c in certs:
    a = c["attributes"]
    label = f"{a.get('name')} / {a.get('displayName')} (expires {a.get('expirationDate', '')[:10]})"
    if "Created via API" in f"{a.get('name')} {a.get('displayName')}":
        call("DELETE", f"/certificates/{c['id']}")
        print("revoked", label)
    else:
        print("kept   ", label)
