import json
import sys
from pathlib import Path

def load_leases(path):
    try:
        with open(path) as f:
            content = f.read().strip()
            if not content:
                print(f"Warning: {path} is empty, using empty leases list")
                return []
            data = json.loads(content)
        return data.get("leases", [])
    except FileNotFoundError:
        print(f"Warning: {path} not found, using empty leases list")
        return []
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON from {path}: {e}")
        print(f"File content preview: {content[:200]}...")
        return []

def save_leases(path, leases, version=1):
    with open(path, "w") as f:
        json.dump({"version": version, "leases": leases}, f, indent=2)

def main(static_path, dynamic_path):
    static_leases = load_leases(static_path)
    dynamic_leases = load_leases(dynamic_path)

    static_macs = {l["mac"].upper() for l in static_leases if l.get("static", False)}
    # Only add dynamic leases not present as static
    new_leases = static_leases[:]
    for lease in dynamic_leases:
        mac = lease.get("mac", "").upper()
        if not lease.get("static", False) and mac not in static_macs:
            # Avoid duplicate IPs
            if not any(l.get("mac", "").upper() == mac for l in new_leases):
                lease["static"] = False
                new_leases.append(lease)

    save_leases(dynamic_path, new_leases)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 merge_dynamic_leases.py <static_leases.json> <dynamic_leases.json>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])