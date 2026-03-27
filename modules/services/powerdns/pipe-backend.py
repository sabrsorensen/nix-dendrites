#!/usr/bin/env python3
import sys
import time
import requests
import logging
import os
import threading
from typing import Dict, Optional
from datetime import datetime

# Configuration
ZONE_NAME = "dummydomain"
CACHE_TTL = 300  # Cache DHCP data for 5 minutes

# Global in-memory cache
_dhcp_cache = {}
_cache_timestamp = 0
_cache_lock = threading.Lock()
_cache_initialized = False

# Configure logging
def setup_logging():
    """Set up logging configuration"""
    # Get log level from environment variable, default to INFO
    log_level = os.getenv('LOG_LEVEL', 'INFO').upper()

    # Create logger
    logger = logging.getLogger('powerdns-pipe-backend')
    logger.setLevel(getattr(logging, log_level, logging.INFO))

    # Create handler that writes to stderr
    handler = logging.StreamHandler(sys.stderr)
    handler.setLevel(logger.level)

    # Create formatter
    formatter = logging.Formatter('[%(asctime)s] %(levelname)s: %(message)s')
    handler.setFormatter(formatter)

    # Add handler to logger
    logger.addHandler(handler)

    return logger

# Initialize logger
logger = setup_logging()

# Static zone data
ZONE_DATA = {
    f"{ZONE_NAME}.": {
        "SOA": f"ns1.{ZONE_NAME}. admin.{ZONE_NAME}. 2025093001 3600 1800 604800 300",
        "NS": [f"ns1.{ZONE_NAME}.", f"ns2.{ZONE_NAME}."],
    },
    f"ns1.{ZONE_NAME}.": {"A": "ns1placeholder"},
    f"ns2.{ZONE_NAME}.": {"A": "ns2placeholder"},
    f"agh-naboo.{ZONE_NAME}.": {"CNAME": f"naboo.{ZONE_NAME}."},
    f"agh-nevarro.{ZONE_NAME}.": {"CNAME": f"nevarro.{ZONE_NAME}."},
    f"atlas.{ZONE_NAME}.": {"CNAME": f"atlasuponraiden.{ZONE_NAME}."},
    f"auth.{ZONE_NAME}.": {"CNAME": f"nevarro.{ZONE_NAME}."},
    f"headplane.{ZONE_NAME}.": {"CNAME": f"nevarro.{ZONE_NAME}."},
    f"headscale.{ZONE_NAME}.": {"CNAME": f"nevarro.{ZONE_NAME}."},
    f"home-gw.{ZONE_NAME}.": {"CNAME": f"gt-ax11000-pro.{ZONE_NAME}."},
    f"mealie.{ZONE_NAME}.": {"CNAME": f"atlasuponraiden.{ZONE_NAME}."},
    f"netbird.{ZONE_NAME}.": {"CNAME": f"nevarro.{ZONE_NAME}."},
    f"plex.{ZONE_NAME}.": {"CNAME": f"atlasuponraiden.{ZONE_NAME}."},
}

def read_secret(path: str, default: Optional[str] = None) -> Optional[str]:
    """Read secret from file"""
    try:
        with open(path, "r") as f:
            return f.read().strip()
    except Exception:
        return default

def should_skip_hostname(hostname: str) -> bool:
    """Determine if a hostname should be skipped"""
    static_entries = {'ns1', 'ns2', 'atlas', 'home-gw', 'agh-naboo', 'agh-nevarro', 'headplane', 'headscale', 'plex'}
    reserved_names = {
        'gateway', 'router', 'dns', 'dhcp', 'ns', 'ns1', 'ns2',
        'localhost', 'www', 'mail', 'ftp', 'pop', 'imap', 'smtp',
        'in', 'a', 'aaaa', 'cname', 'mx', 'txt', 'ptr', 'soa'
    }

    return (hostname in static_entries or
            hostname in reserved_names or
            len(hostname) > 63 or
            len(hostname) == 0)

def fetch_dhcp_leases() -> Dict[str, Dict]:
    """Fetch DHCP leases from AdGuard Home instances"""
    try:
        # Get credentials
        username = read_secret("/run/secrets/adguardhome_user")
        password = read_secret("/run/secrets/adguardhome_password")

        if not username or not password:
            logger.error("AdGuard Home credentials not found")
            return {}

        dynamic_records = {}
        seen_ips = set()

        sources = [
            {"url": "http://127.0.0.1:3003", "name": "Local AdGuard Home", "verify_ssl": False},
            {"url": "https://ns1placeholder", "name": "Nevarro AdGuard Home", "verify_ssl": False},
            {"url": "https://ns2placeholder", "name": "Naboo AdGuard Home", "verify_ssl": False},
        ]

        for source in sources:
            try:
                logger.debug(f"Attempting to connect to {source['name']} at {source['url']}")

                # Configure requests with shorter timeout for non-blocking operation
                session = requests.Session()

                response = session.get(
                    f"{source['url']}/control/dhcp/status",
                    auth=(username, password),
                    timeout=5,  # Reduced timeout
                    verify=source.get('verify_ssl', True),
                    headers={
                        'User-Agent': 'PowerDNS-Pipe-Backend/1.0',
                        'Accept': 'application/json',
                        'Connection': 'close'
                    }
                )

                logger.debug(f"Response from {source['name']}: {response.status_code}")
                response.raise_for_status()

                data = response.json()
                static_leases = data.get('static_leases', [])

                logger.info(f"Successfully fetched {len(static_leases)} leases from {source['name']}")

                for lease in static_leases:
                    hostname = lease.get('hostname', '').strip()
                    ip = lease.get('ip', '').strip()

                    if hostname and ip and ip not in seen_ips:
                        # Normalize hostname
                        hostname = hostname.lower().replace(' ', '-').replace('_', '-')
                        hostname = ''.join(c for c in hostname if c.isalnum() or c == '-').strip('-')

                        if hostname and not should_skip_hostname(hostname):
                            fqdn = f"{hostname}.{ZONE_NAME}."
                            dynamic_records[fqdn] = {"A": ip}
                            seen_ips.add(ip)

                            # Debug logging for deskdockingstation
                            if "deskdockingstation" in hostname:
                                logger.debug(f"Found deskdockingstation record: {fqdn} -> {ip}")

                # Close the session to clean up connections
                session.close()

            except requests.exceptions.SSLError as e:
                logger.warning(f"SSL certificate error for {source['name']} ({source['url']}): {e}")
            except requests.exceptions.ConnectionError as e:
                logger.warning(f"Connection error to {source['name']} ({source['url']}): {e}")
            except requests.exceptions.Timeout as e:
                logger.warning(f"Timeout connecting to {source['name']} ({source['url']}): {e}")
            except requests.exceptions.HTTPError as e:
                logger.warning(f"HTTP {e.response.status_code} error from {source['name']} ({source['url']}): {e}")
            except Exception as e:
                logger.warning(f"Unexpected error from {source['name']} ({source['url']}): {type(e).__name__}: {e}")

        # Debug: Log if deskdockingstation was found in final records
        deskdockingstation_found = any("deskdockingstation" in fqdn for fqdn in dynamic_records.keys())
        logger.debug(f"deskdockingstation in final dynamic_records: {deskdockingstation_found}")

        logger.info(f"Collected {len(dynamic_records)} unique dynamic records from {len(sources)} sources")
        return dynamic_records

    except Exception as e:
        logger.error(f"Error getting DHCP leases: {e}")
        return {}

def get_dynamic_records() -> Dict[str, Dict]:
    """Get dynamic records with in-memory caching"""
    global _dhcp_cache, _cache_timestamp, _cache_initialized

    with _cache_lock:
        current_time = time.time()

        # Check if cache is still valid
        if _dhcp_cache and (current_time - _cache_timestamp) < CACHE_TTL:
            return _dhcp_cache

        # Cache miss or expired - fetch new data
        try:
            fresh_records = fetch_dhcp_leases()
            _dhcp_cache = fresh_records
            _cache_timestamp = current_time
            _cache_initialized = True
            logger.info(f"Refreshed DHCP cache: {len(fresh_records)} records")
            return fresh_records
        except Exception as e:
            logger.error(f"Failed to refresh DHCP cache: {e}")
            # Return stale cache if available
            return _dhcp_cache if _dhcp_cache else {}

def initialize_cache_async():
    """Initialize the cache asynchronously in a background thread"""
    def init_worker():
        global _dhcp_cache, _cache_timestamp, _cache_initialized

        logger.info("Pre-populating DHCP cache at startup...")
        try:
            initial_records = fetch_dhcp_leases()
            with _cache_lock:
                _dhcp_cache = initial_records
                _cache_timestamp = time.time()
                _cache_initialized = True
            logger.info(f"Initial DHCP cache populated with {len(initial_records)} records")

            # Log some examples of what was loaded
            if initial_records:
                logger.debug("Existing lease records loaded:")
                for i, (fqdn, record) in enumerate(initial_records.items()):
                    if i < 5:  # Show first 5 records
                        logger.debug(f"  {fqdn} -> {record}")
                    else:
                        break
                if len(initial_records) > 5:
                    logger.debug(f"  ... and {len(initial_records) - 5} more records")

        except Exception as e:
            logger.error(f"Failed to pre-populate DHCP cache: {e}")
            with _cache_lock:
                _dhcp_cache = {}
                _cache_timestamp = 0
                _cache_initialized = True

    # Start the initialization in a background thread
    init_thread = threading.Thread(target=init_worker, daemon=True)
    init_thread.start()

def main():
    """Main pipe backend loop"""
    logger.info("PowerDNS pipe backend starting with in-memory DHCP caching")

    # Start cache initialization in background - don't block startup
    initialize_cache_async()

    try:
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue

            parts = line.split('\t')
            if not parts:
                continue

            command = parts[0]

            if command == "HELO":
                print("OK\tPipe backend ready")
                sys.stdout.flush()

            elif command == "Q":
                if len(parts) < 6:
                    print("END")
                    sys.stdout.flush()
                    continue

                qname, qclass, qtype, query_id, remote_ip = parts[1:6]

                # Debug logging for deskdockingstation queries
                if "deskdockingstation" in qname.lower():
                    logger.debug(f"Query for deskdockingstation - qname: {qname}, qtype: {qtype}")

                # Normalize qname - convert to lowercase and ensure trailing dot
                qname = qname.lower()
                if not qname.endswith('.'):
                    qname += '.'

                # Get all records (static + cached dynamic)
                # If cache isn't initialized yet, just use static records
                if _cache_initialized:
                    dynamic_records = get_dynamic_records()
                else:
                    dynamic_records = {}
                    logger.debug("Cache not yet initialized, using static records only")

                all_records = {**ZONE_DATA, **dynamic_records}

                # Debug logging for deskdockingstation
                if "deskdockingstation" in qname:
                    logger.debug(f"Normalized qname: {qname}")
                    logger.debug(f"Available dynamic records: {list(dynamic_records.keys())}")
                    logger.debug(f"Record exists in cache: {qname in dynamic_records}")
                    if qname in dynamic_records:
                        logger.debug(f"Record data: {dynamic_records[qname]}")

                # Handle query
                if qtype == "ANY":
                    if qname in all_records:
                        for record_type, record_data in all_records[qname].items():
                            if isinstance(record_data, list):
                                for value in record_data:
                                    print(f"DATA\t{qname}\t{qclass}\t{record_type}\t300\t{query_id}\t{value}")
                            else:
                                print(f"DATA\t{qname}\t{qclass}\t{record_type}\t300\t{query_id}\t{record_data}")
                else:
                    if qname in all_records and qtype in all_records[qname]:
                        record_data = all_records[qname][qtype]
                        if isinstance(record_data, list):
                            for value in record_data:
                                print(f"DATA\t{qname}\t{qclass}\t{qtype}\t300\t{query_id}\t{value}")
                                # Debug for deskdockingstation
                                if "deskdockingstation" in qname:
                                    logger.debug(f"Returning record: {qname} {qtype} {value}")
                        else:
                            print(f"DATA\t{qname}\t{qclass}\t{qtype}\t300\t{query_id}\t{record_data}")
                            # Debug for deskdockingstation
                            if "deskdockingstation" in qname:
                                logger.debug(f"Returning record: {qname} {qtype} {record_data}")
                    else:
                        # Debug for failed lookups
                        if "deskdockingstation" in qname:
                            logger.debug(f"No record found for {qname} type {qtype}")
                            logger.debug(f"qname in all_records: {qname in all_records}")
                            if qname in all_records:
                                logger.debug(f"Available types for {qname}: {list(all_records[qname].keys())}")

                print("END")
                sys.stdout.flush()

            elif command == "AXFR":
                # Zone transfer
                if len(parts) < 2:
                    print("END")
                    sys.stdout.flush()
                    continue

                zone = parts[1].lower()  # Normalize zone name to lowercase too
                if not zone.endswith('.'):
                    zone += '.'

                # For zone transfers, wait for cache if it's still initializing
                if _cache_initialized:
                    dynamic_records = get_dynamic_records()
                else:
                    dynamic_records = {}

                all_records = {**ZONE_DATA, **dynamic_records}

                for name, records in all_records.items():
                    if name == zone or name.endswith('.' + zone):
                        for record_type, value in records.items():
                            if isinstance(value, list):
                                for v in value:
                                    print(f"DATA\t{name}\tIN\t{record_type}\t300\t-1\t{v}")
                            else:
                                print(f"DATA\t{name}\tIN\t{record_type}\t300\t-1\t{value}")

                print("END")
                sys.stdout.flush()

            elif command == "PING":
                print("PONG")
                sys.stdout.flush()

            else:
                print("END")
                sys.stdout.flush()

    except Exception as e:
        logger.critical(f"FATAL pipe backend error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()