"""Idempotent RevenueCat setup: products, entitlement "pro", current offering "default".

Usage: python3 scripts/revenuecat_setup.py
Reads the v2 secret key from .secrets/revenuecat_v2.txt (git-ignored).
"""
import json
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KEY = (ROOT / ".secrets" / "revenuecat_v2.txt").read_text().strip()
PROJECT = "projd99429d7"
APP = "appf9d467733a"
BASE = f"https://api.revenuecat.com/v2/projects/{PROJECT}"
PRODUCTS = {
    "com.sahinrasit.biliteral.lifetime": ("non_consumable", "Biliteral Lifetime", "$rc_lifetime", "Lifetime"),
    "com.sahinrasit.biliteral.monthly": ("subscription", "Biliteral Monthly", "$rc_monthly", "Monthly"),
}


def call(method, path, body=None):
    request = urllib.request.Request(BASE + path, method=method, data=json.dumps(body).encode() if body else None,
                                     headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            text = response.read().decode()
            return json.loads(text) if text else {}
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"{method} {path} -> {error.code} {error.read().decode()}") from None


def listing(path):
    items, url = [], path
    while url:
        page = call("GET", url)
        items += page.get("items", [])
        nxt = page.get("next_page")
        url = nxt.split(f"/projects/{PROJECT}", 1)[1] if nxt else None
    return items


def main():
    products = {p["store_identifier"]: p for p in listing("/products?limit=100")}
    for store_id, (kind, name, _, _) in PRODUCTS.items():
        if store_id not in products:
            products[store_id] = call("POST", "/products", {"store_identifier": store_id, "app_id": APP,
                                                             "type": kind, "display_name": name})
            print("product", store_id)
    ids = [products[s]["id"] for s in PRODUCTS]

    ents = {e["lookup_key"]: e for e in listing("/entitlements?limit=100")}
    ent = ents.get("pro") or call("POST", "/entitlements", {"lookup_key": "pro", "display_name": "Biliteral Pro"})
    attached = {p["id"] for p in listing(f"/entitlements/{ent['id']}/products?limit=100")}
    missing = [i for i in ids if i not in attached]
    if missing:
        call("POST", f"/entitlements/{ent['id']}/actions/attach_products", {"product_ids": missing})
    print("entitlement pro ->", len(ids), "products")

    offerings = {o["lookup_key"]: o for o in listing("/offerings?limit=100")}
    off = offerings.get("default") or call("POST", "/offerings", {"lookup_key": "default", "display_name": "Biliteral Pro"})
    if not off.get("is_current"):
        call("POST", f"/offerings/{off['id']}", {"is_current": True})
    packages = {p["lookup_key"]: p for p in listing(f"/offerings/{off['id']}/packages?limit=100")}
    for position, (store_id, (_, _, lookup, display)) in enumerate(PRODUCTS.items(), start=1):
        pkg = packages.get(lookup) or call("POST", f"/offerings/{off['id']}/packages",
                                           {"lookup_key": lookup, "display_name": display, "position": position})
        have = {p["product"]["id"] for p in listing(f"/packages/{pkg['id']}/products?limit=100")} if lookup in packages else set()
        if products[store_id]["id"] not in have:
            call("POST", f"/packages/{pkg['id']}/actions/attach_products",
                 {"products": [{"product_id": products[store_id]["id"], "eligibility_criteria": "all"}]})
        print("package", lookup, "->", store_id)
    print("offering default is current")


if __name__ == "__main__":
    main()
