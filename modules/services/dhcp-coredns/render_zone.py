#!/usr/bin/env python3
import argparse
import json
import time
from pathlib import Path


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--domain", required=True)
    p.add_argument("--records", required=True)
    p.add_argument("--static-records-json", required=False, default="[]")
    p.add_argument("--zone", required=True)
    p.add_argument("--ns", required=True)
    p.add_argument("--ns2", required=False, default="")
    args = p.parse_args()

    domain = args.domain.strip().rstrip(".")
    ns = args.ns.strip().rstrip(".")
    records = json.loads(Path(args.records).read_text(encoding="utf-8"))
    static_records = json.loads(args.static_records_json)

    serial = int(time.time())
    lines = [
        f"$ORIGIN {domain}.",
        "$TTL 60",
        f"@ IN SOA {ns}.{domain}. admin.{domain}. ({serial} 60 60 1209600 60)",
        f"@ IN NS {ns}.{domain}.",
    ]
    if args.ns2.strip():
        lines.append(f"@ IN NS {args.ns2.strip().rstrip('.')}.{domain}.")

    for r in static_records:
        hostname = str(r.get("hostname", "")).strip().lower()
        ip = str(r.get("ip", "")).strip()
        if hostname and ip:
            lines.append(f"{hostname} IN A {ip}")

    for r in records:
        lines.append(f"{r['hostname']} IN A {r['ip']}")

    Path(args.zone).write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
