#!/usr/bin/env python3
import argparse
import json
import re
import sys
from pathlib import Path

import requests


RESERVED_NAMES = {
    "gateway",
    "router",
    "dns",
    "dhcp",
    "ns",
    "ns1",
    "ns2",
    "localhost",
    "www",
    "mail",
    "ftp",
    "pop",
    "imap",
    "smtp",
    "in",
    "a",
    "aaaa",
    "cname",
    "mx",
    "txt",
    "ptr",
    "soa",
}


def read_text(path: str) -> str:
    return Path(path).read_text(encoding="utf-8").strip()


def normalize_hostname(hostname: str) -> str:
    hostname = hostname.strip().lower().replace(" ", "-").replace("_", "-")
    hostname = re.sub(r"[^a-z0-9-]", "", hostname).strip("-")
    return hostname


def load_leases(path: str):
    try:
        data = json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception:
        return []
    return data.get("leases", [])


def load_previous_managed(path: str):
    try:
        data = json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception:
        return set()
    domains = data.get("managed_domains", [])
    return {str(d).strip().lower() for d in domains if str(d).strip()}


def save_managed(path: str, domains):
    payload = {"managed_domains": sorted(domains)}
    Path(path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def build_desired_rewrites(domain: str, leases_path: str, static_rewrites_json: str):
    desired = {}
    static_rewrites = json.loads(static_rewrites_json)

    for rewrite in static_rewrites:
        name = rewrite["name"].strip().lower()
        answer = rewrite["answer"].strip()
        if name and answer:
            desired[f"{name}.{domain}"] = answer

    for lease in load_leases(leases_path):
        hostname = normalize_hostname(lease.get("hostname", ""))
        ip = lease.get("ip", "").strip()
        if not hostname or not ip:
            continue
        if hostname in RESERVED_NAMES:
            continue
        if len(hostname) > 63:
            continue
        fqdn = f"{hostname}.{domain}"
        if fqdn not in desired:
            desired[fqdn] = ip

    return desired


def api_get_rewrites(base_url: str, auth):
    response = requests.get(f"{base_url}/control/rewrite/list", auth=auth, timeout=10)
    response.raise_for_status()
    payload = response.json()
    if isinstance(payload, dict) and "rewrites" in payload:
        return payload["rewrites"]
    if isinstance(payload, list):
        return payload
    return []


def api_add_rewrite(base_url: str, auth, domain: str, answer: str):
    response = requests.post(
        f"{base_url}/control/rewrite/add",
        auth=auth,
        json={"domain": domain, "answer": answer},
        timeout=10,
    )
    response.raise_for_status()


def api_delete_rewrite(base_url: str, auth, domain: str, answer: str):
    response = requests.post(
        f"{base_url}/control/rewrite/delete",
        auth=auth,
        json={"domain": domain, "answer": answer},
        timeout=10,
    )
    response.raise_for_status()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--username-file", required=True)
    parser.add_argument("--password-file", required=True)
    parser.add_argument("--domain", required=True)
    parser.add_argument("--leases-path", required=True)
    parser.add_argument("--static-rewrites-json", required=True)
    parser.add_argument("--state-file", required=True)
    args = parser.parse_args()

    username = read_text(args.username_file)
    password = read_text(args.password_file)
    domain = args.domain.strip().lower()
    desired = build_desired_rewrites(domain, args.leases_path, args.static_rewrites_json)
    managed_domains = set(desired.keys())
    previous_managed = load_previous_managed(args.state_file)
    all_managed = managed_domains | previous_managed

    auth = (username, password)
    existing = {}
    for item in api_get_rewrites(args.base_url.rstrip("/"), auth):
        d = str(item.get("domain", "")).strip().lower()
        a = str(item.get("answer", "")).strip()
        if d and a:
            existing[d] = a

    for d in all_managed:
        if d in existing and (d not in desired or existing[d] != desired[d]):
            api_delete_rewrite(args.base_url.rstrip("/"), auth, d, existing[d])
            existing.pop(d, None)

    for d, answer in desired.items():
        if existing.get(d) == answer:
            continue
        api_add_rewrite(args.base_url.rstrip("/"), auth, d, answer)

    save_managed(args.state_file, managed_domains)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"failed to sync dns rewrites: {exc}", file=sys.stderr)
        sys.exit(1)
