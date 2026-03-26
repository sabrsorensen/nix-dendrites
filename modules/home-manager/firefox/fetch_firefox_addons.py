#!/usr/bin/env python3

import sys
import json
import requests
import hashlib
import argparse
import os

extensions = [
    "bitwarden-password-manager",
    "cloud-2-butt-plus",
    "dark-mode-webextension",
    "decentraleyes",
    "fast-tab-switcher",
    "herp-derp-for-youtube",
    "multi-account-containers",
    "old-reddit-redirect",
    "pixel-punk-dynamic-theme",
    "plasma-integration",
    "privacy-badger17",
    "privacy-possum",
    "recipe-filter",
    "refined-github-",
    "reddit-enhancement-suite",
    "return-youtube-dislikes",
    "sidebery",
    "sticky-window-containers",
    "ublock-origin",
]

# Base URL for the Mozilla Add-ons API
AMO_API_BASE = "https://addons.mozilla.org/api/v5/addons/addon/"

def main():
    parser = argparse.ArgumentParser(description="Fetch Firefox addon metadata and save to JSON")
    parser.add_argument("output", nargs="?", default="firefox_addons.json", 
                       help="Output file path (default: firefox_addons.json)")
    
    args = parser.parse_args()
    
    # Create output directory if it doesn't exist
    output_dir = os.path.dirname(args.output)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Fetch metadata for each extension
    extension_metadata = []
    for extension in extensions:
        response = requests.get(f"{AMO_API_BASE}{extension}/")
        if response.status_code == 200:
            data = response.json()
            #print(data["slug"])
            xpi_url = data["current_version"]["file"]["url"]
            xpi_data = requests.get(xpi_url).content
            sha256 = hashlib.sha256(xpi_data).hexdigest()
            version = data["current_version"]["version"] if "current_version" in data else "<none>"
            extension_metadata.append({
                "pname": data["slug"],
                "addonId": data["guid"],
                "version": version,
                "url": xpi_url,
                "sha256": sha256,
                "description": data["summary"],
                "homepage": data["url"],
                "license": "unknown",  # AMO API does not provide license info
            })
        else:
            print(f"Failed to fetch metadata for {extension}: {response.status_code}", file=sys.stderr)

    # Save metadata to the specified output file
    with open(args.output, "w") as f:
        json.dump(extension_metadata, f, indent=2)

    print(f"Metadata saved to {args.output}")

if __name__ == "__main__":
    main()