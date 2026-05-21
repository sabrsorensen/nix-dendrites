#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path


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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--domain", required=True)
    parser.add_argument("--leases-path", required=True)
    parser.add_argument("--static-rewrites-json", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    domain = args.domain.strip().lower()
    static_rewrites = json.loads(args.static_rewrites_json)

    rewrites = []
    seen_domains = set()

    for rewrite in static_rewrites:
        name = rewrite["name"].strip().lower()
        answer = rewrite["answer"].strip()
        if not name or not answer:
            continue
        fqdn = name if "." in name else f"{name}.{domain}"
        if fqdn in seen_domains:
            continue
        rewrites.append({"domain": fqdn, "answer": answer, "enabled": True})
        seen_domains.add(fqdn)

    for lease in load_leases(args.leases_path):
        hostname = normalize_hostname(lease.get("hostname", ""))
        ip = lease.get("ip", "").strip()
        if not hostname or not ip:
            continue
        if hostname in RESERVED_NAMES:
            continue
        if len(hostname) > 63:
            continue
        fqdn = f"{hostname}.{domain}"
        if fqdn in seen_domains:
            continue
        rewrites.append({"domain": fqdn, "answer": ip})
        seen_domains.add(fqdn)

    Path(args.output).write_text(json.dumps(rewrites, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
