#!/usr/bin/env python3
import argparse
import csv
import json
import re
from pathlib import Path


RESERVED_NAMES = {
    "gateway", "router", "dns", "dhcp", "ns", "ns1", "ns2", "localhost", "www",
    "mail", "ftp", "pop", "imap", "smtp", "in", "a", "aaaa", "cname", "mx", "txt", "ptr", "soa",
}


def normalize_hostname(hostname: str) -> str:
    hostname = hostname.strip().lower().replace(" ", "-").replace("_", "-")
    hostname = re.sub(r"[^a-z0-9-]", "", hostname).strip("-")
    return hostname


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def load_static_leases(path: Path):
    data = load_json(path)
    return data.get("leases", []) if isinstance(data, dict) else []


def parse_dhcpd_leases(path: Path):
    if not path.exists():
        return []
    text = path.read_text(encoding="utf-8", errors="ignore")
    leases = []
    blocks = re.findall(r"lease\s+([0-9.]+)\s*\{(.*?)\}", text, flags=re.S)
    for ip, body in blocks:
        host_match = re.search(r"client-hostname\s+\"([^\"]+)\";", body)
        mac_match = re.search(r"hardware\s+ethernet\s+([0-9a-f:]+);", body, flags=re.I)
        if host_match:
            leases.append({
                "ip": ip.strip(),
                "hostname": host_match.group(1).strip(),
                "mac": (mac_match.group(1).upper() if mac_match else ""),
                "static": False,
            })
    return leases


def parse_kea_leases(path: Path):
    leases = []
    if not path.exists():
        return leases

    text = path.read_text(encoding="utf-8", errors="ignore").strip()
    if not text:
        return leases

    try:
        rows = list(csv.DictReader(text.splitlines()))
    except Exception:
        return leases

    for row in rows:
        if not isinstance(row, dict):
            continue
        if str(row.get("state", "")).strip() not in {"", "0"}:
            continue
        ip = (row.get("address") or "").strip()
        hostname = (row.get("hostname") or "").strip()
        mac = (row.get("hwaddr") or "").strip().upper()
        if ip and hostname:
            leases.append({"ip": ip, "hostname": hostname, "mac": mac, "static": False})
    return leases


def dedupe(records):
    out = []
    seen_host = set()
    seen_ip = set()
    for r in records:
        hostname = normalize_hostname(r.get("hostname", ""))
        ip = r.get("ip", "").strip()
        if not hostname or not ip:
            continue
        if hostname in RESERVED_NAMES or len(hostname) > 63:
            continue
        key_host = hostname
        if key_host in seen_host or ip in seen_ip:
            continue
        seen_host.add(key_host)
        seen_ip.add(ip)
        out.append({"hostname": hostname, "ip": ip})
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--static-leases", required=True)
    p.add_argument("--backend", required=True, choices=["isc-dhcpd", "kea-dhcp4"])
    p.add_argument("--dynamic-leases", required=True)
    p.add_argument("--output", required=True)
    args = p.parse_args()

    static_records = load_static_leases(Path(args.static_leases))
    dynamic_records = parse_dhcpd_leases(Path(args.dynamic_leases)) if args.backend == "isc-dhcpd" else parse_kea_leases(Path(args.dynamic_leases))

    static_macs = {str(l.get("mac", "")).upper() for l in static_records if l.get("static", False)}
    merged = []
    for s in static_records:
        merged.append({
            "hostname": s.get("hostname", ""),
            "ip": s.get("ip", ""),
            "mac": str(s.get("mac", "")).upper(),
            "static": True,
        })

    for d in dynamic_records:
        if d.get("mac", "") and d["mac"] in static_macs:
            continue
        merged.append(d)

    Path(args.output).write_text(json.dumps(dedupe(merged), indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
