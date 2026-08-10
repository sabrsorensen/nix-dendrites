#!/usr/bin/env python3
"""Build, validate, and activate local or remote Nix configurations."""

from __future__ import annotations

import argparse
import json
import shlex
import shutil
import subprocess
import sys
import termios
import time
import tty
from dataclasses import dataclass
from typing import Sequence


@dataclass(frozen=True)
class Config:
    flake: str
    domain: str
    inhibit_sleep: bool


SECURE_CONFIG = {
    "naboo": {
        "peerIp": "192.168.1.4",
        "peerName": "Nevarro",
        "peerServices": ["blocky", "coredns", "dhcp-coredns-kea"],
        "probeDomains": ["naboo.{domain}", "nevarro.{domain}", "atlasuponraiden.{domain}"],
        "targetServices": ["blocky", "coredns", "dhcp-failover.timer"],
    },
    "nevarro": {
        "peerIp": "192.168.1.3",
        "peerName": "Naboo",
        "peerServices": ["blocky", "coredns", "dhcp-failover.timer"],
        "probeDomains": ["naboo.{domain}", "nevarro.{domain}", "atlasuponraiden.{domain}"],
        "targetServices": ["blocky", "coredns", "dhcp-coredns-kea"],
    },
}

HOME_OUTPUTS = {"emeraldecho": "emeraldecho-steamos"}
HOME_USERS = {
    "atlasuponraiden": "sam",
    "emeraldecho": "sam",
    "kamino": "sam",
    "naboo": "sam",
    "nevarro": "sam",
    "zaphodbeeblebrox": "sam",
}


def run(
    command: Sequence[str],
    *,
    check: bool = False,
    capture: bool = False,
    quiet: bool = False,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        list(command),
        check=check,
        text=True,
        capture_output=capture,
        stdout=subprocess.DEVNULL if quiet and not capture else None,
        stderr=subprocess.DEVNULL if quiet else None,
    )


def run_inhibited(config: Config, command: Sequence[str]) -> subprocess.CompletedProcess[str]:
    if not config.inhibit_sleep:
        return run(command)
    print(f"🔒 Inhibiting sleep for: {' '.join(command)}")
    inhibited = [
        "systemd-inhibit",
        "--what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch",
        "--who=nix-deploy",
        "--why=Nix deployment",
        "--mode=block",
        *command,
    ]
    return run(inhibited)


def wait_for_key() -> None:
    if not sys.stdin.isatty():
        input()
        return
    settings = termios.tcgetattr(sys.stdin)
    try:
        tty.setcbreak(sys.stdin.fileno())
        sys.stdin.read(1)
    finally:
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, settings)
    print()


def target_reachable(target: str, domain: str) -> bool:
    ping_host = f"{target}.{domain}"
    return run(["ping", "-c", "1", "-W", "1", ping_host], quiet=True).returncode == 0


def wait_for_target(target: str, domain: str) -> None:
    ping_host = f"{target}.{domain}"
    print(f"{target} is not responding at {ping_host}.")
    print("Turn on the target, then press any key to begin waiting for reachability.")
    wait_for_key()
    print(f"Waiting for {target} at {ping_host} to respond to ping...")
    while not target_reachable(target, domain):
        time.sleep(5)
    print(f"{target} is reachable. Starting remote deployment...")


def notify(title: str, message: str) -> None:
    if shutil.which("notify-send"):
        run(["notify-send", title, message])


def service_command(services: Sequence[str]) -> str:
    return " && ".join(f"systemctl is-active --quiet {shlex.quote(service)}" for service in services)


def secure_config(target: str, domain: str) -> dict | None:
    template = SECURE_CONFIG.get(target.lower())
    if template is None:
        return None
    return json.loads(json.dumps(template).replace("{domain}", domain))


def secure_preflight(target: str, config: dict, tail: bool) -> tuple[str, bool]:
    peer_name = config["peerName"]
    peer_ip = config["peerIp"]
    peer_ssh = f"nix-{peer_name.lower()}"
    target_ssh = f"nix-{target.lower()}"
    lock_host = target_ssh
    if tail:
        target_ssh = f"{target_ssh}-tail"

    print(f"🔍 Checking health of {peer_name} ({peer_ip}) before deploying to {target}...")
    if run(["timeout", "10", "dig", f"@{peer_ip}", "-p", "53", "google.com", "+short"], quiet=True).returncode != 0:
        print(f"❌ ERROR: {peer_name} DNS on :53 is not responding!", file=sys.stderr)
        return target_ssh, False
    for domain in config["probeDomains"]:
        if run(["timeout", "10", "dig", f"@{peer_ip}", "-p", "53", domain, "+short"], quiet=True).returncode != 0:
            print(f"❌ ERROR: {peer_name} cannot resolve {domain} through Blocky/CoreDNS!", file=sys.stderr)
            return target_ssh, False
    if run(["ssh", peer_ssh, service_command(config["peerServices"])], quiet=True).returncode != 0:
        print(f"❌ ERROR: {peer_name} is not healthy for safe deployment!", file=sys.stderr)
        print(f"   Expected active services: {', '.join(config['peerServices'])}", file=sys.stderr)
        return target_ssh, False
    if run(["ssh", peer_ssh, "test -f /tmp/.deploy-lock"], quiet=True).returncode == 0:
        print(f"❌ ERROR: Deployment already in progress on {peer_name}!", file=sys.stderr)
        return target_ssh, False
    lock_command = 'printf "%s: Deploying from %s\\n" "$(date)" "$(hostname)" > /tmp/.deploy-lock'
    if run(["ssh", lock_host, lock_command], quiet=True).returncode != 0:
        print("Refusing deployment: target deployment lock is present or inaccessible", file=sys.stderr)
        return target_ssh, False
    return target_ssh, True


def cleanup_lock(lock_host: str, locked: bool) -> None:
    if locked:
        run(["ssh", lock_host, "rm -f /tmp/.deploy-lock"])


def postflight(target: str, target_ssh: str, config: dict) -> bool:
    print(f"🔍 Running post-deployment validation on {target}...")
    time.sleep(10)
    dns = run(
        ["ssh", target_ssh, "timeout 10 dig @127.0.0.1 -p 53 google.com +short"],
        capture=True,
    )
    if dns.returncode != 0:
        if dns.stdout:
            print(dns.stdout, end="")
        print(f"❌ CRITICAL: Post-deployment DNS check failed on {target}!", file=sys.stderr)
        return False
    target_command = service_command(config["targetServices"])
    if target_command and run(["ssh", target_ssh, target_command], quiet=True).returncode != 0:
        print(f"❌ CRITICAL: Post-deployment service health check failed on {target}!", file=sys.stderr)
        print(f"   Expected active services: {', '.join(config['targetServices'])}", file=sys.stderr)
        return False
    for domain in config["probeDomains"]:
        if run(["ssh", target_ssh, f"timeout 10 dig @127.0.0.1 -p 53 {shlex.quote(domain)} +short"], quiet=True).returncode != 0:
            print(f"❌ CRITICAL: Post-deployment local DNS integration check failed for {domain}!", file=sys.stderr)
            return False
    print(f"✅ Deployment to {target} completed successfully")
    return True


def deploy_nixos(config: Config, mode: str, target: str, extra: list[str], unsafe: bool) -> int:
    target_lower = target.lower()
    tail = "--tail" in extra
    extra = [arg for arg in extra if arg != "--tail"]
    update = ["--update"] if mode == "upgrade" else []
    target_ssh = f"nix-{target_lower}{'-tail' if tail else ''}"
    lock_host = f"nix-{target_lower}"
    secure = None if unsafe else secure_config(target, config.domain)
    reachable = target_reachable(target, config.domain)
    locked = False
    try:
        if reachable:
            print(f"{target} is reachable. Starting remote deployment...")
        else:
            build = ["nh", "os", "build", config.flake, "-H", target_lower, *update, "--keep-going", "--", *extra]
            print(f"{target} is offline. Building locally before waiting for it to come online...")
            result = run_inhibited(config, build)
            if result.returncode != 0:
                return result.returncode
            notify("NixOS build complete", f"Turn on {target}. Deployment will continue after it responds to ping.")
            print(f"Build completed for {target}.")
            wait_for_target(target, config.domain)
        if secure is not None:
            target_ssh, locked = secure_preflight(target, secure, tail)
            if not locked:
                return 1
        switch = [
            "nh", "os", "switch", config.flake, "-H", target_lower,
            "--target-host", target_ssh, *update, "--keep-going", "--", *extra,
        ]
        result = run_inhibited(config, switch)
        if result.returncode != 0:
            return result.returncode
        if secure is not None and not postflight(target, target_ssh, secure):
            return 1
        return 0
    finally:
        cleanup_lock(lock_host, locked)


def deploy_home(config: Config, mode: str, target_spec: str, extra: list[str]) -> int:
    supplied_user, separator, target = target_spec.partition("@")
    remote_user = supplied_user if separator else HOME_USERS.get(target.lower(), "")
    home_output = HOME_OUTPUTS.get(target.lower(), "")
    if not home_output:
        print(f"No remote Home Manager output is defined for {target}", file=sys.stderr)
        return 1
    if not remote_user:
        print(f"No remote SSH user is defined for {target}", file=sys.stderr)
        return 1
    configured_user = HOME_USERS.get(target.lower(), remote_user)
    remote_target = target if remote_user == configured_user else f"{remote_user}@{target}"
    remote_store = f"ssh://{remote_target}?remote-program=/home/{remote_user}/.nix-profile/bin/nix-store"
    update = ["--update"] if mode == "upgrade" else []
    build = ["nh", "home", "build", f"{config.flake}#{home_output}", *update, "--", *extra]
    print(f"🔨 Building {home_output} locally before waiting for it to come online...")
    result = run_inhibited(config, build)
    if result.returncode != 0:
        return result.returncode
    path = run(["nix", "path-info", f"{config.flake}#{home_output}"], capture=True)
    if path.returncode != 0:
        return path.returncode
    store_path = path.stdout.strip().splitlines()[-1]
    notify("Home Manager build complete", f"Turn on {target}. Activation will continue after it responds to ping.")
    print(f"Build completed for {target}.")
    wait_for_target(target, config.domain)
    print(f"📦 Copying {home_output} to {remote_target}...")
    result = run_inhibited(config, ["nix", "copy", "--to", remote_store, f"{config.flake}#{home_output}"])
    if result.returncode != 0:
        return result.returncode
    activation = f"{store_path}/activate"
    remote_command = (
        f"HOME={shlex.quote(f'/home/{remote_user}')} "
        f"PATH={shlex.quote(f'/home/{remote_user}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/bin:/bin')}:$PATH "
        f"bash -lc {shlex.quote(activation)}"
    )
    print(f"🚀 Activating Home Manager on {remote_target}...")
    return run(["ssh", remote_target, remote_command]).returncode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--flake", required=True)
    parser.add_argument("--domain", required=True)
    parser.add_argument("--inhibit-sleep", action="store_true")
    parser.add_argument("mode", choices=["switch", "upgrade", "unsafe"])
    parser.add_argument("target")
    parser.add_argument("extra", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    config = Config(args.flake, args.domain, args.inhibit_sleep)
    if "@" in args.target:
        return deploy_home(config, args.mode, args.target, args.extra)
    return deploy_nixos(config, args.mode, args.target, args.extra, args.mode == "unsafe")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\nDeployment interrupted.", file=sys.stderr)
        raise SystemExit(130)
