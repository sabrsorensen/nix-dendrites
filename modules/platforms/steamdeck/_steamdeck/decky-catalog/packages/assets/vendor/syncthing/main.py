import asyncio
import json
import os
import pwd
import ssl
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

import decky


SETTINGS_PATH = Path(decky.DECKY_PLUGIN_SETTINGS_DIR) / "settings.json"
DEFAULT_SETTINGS = {
    "service_unit": "",
}

FolderSummary = dict[str, Any]
DeviceSummary = dict[str, Any]


def _display_device_name(device_id: str, device_map: dict[str, dict[str, Any]], my_id: str | None) -> str:
    if my_id and device_id == my_id:
        return "This Device"
    device = device_map.get(device_id, {})
    if isinstance(device, dict):
        return str(device.get("name") or device_id)
    return device_id


def _display_folder_name(folder_id: str, folder_map: dict[str, dict[str, Any]]) -> str:
    folder = folder_map.get(folder_id, {})
    if isinstance(folder, dict):
        return str(folder.get("label") or folder_id)
    return folder_id


def _decky_user() -> str:
    return decky.DECKY_USER or os.environ.get("UNPRIVILEGED_USER", "") or decky.USER


def _decky_uid() -> int:
    user = _decky_user()
    if user:
        try:
            return pwd.getpwnam(user).pw_uid
        except KeyError:
            pass
    return os.getuid()


def _systemd_env() -> dict[str, str]:
    env = dict(os.environ)
    uid = _decky_uid()
    runtime_dir = env.get("XDG_RUNTIME_DIR", f"/run/user/{uid}")
    if runtime_dir == "/run/user/0" and uid != 0:
        runtime_dir = f"/run/user/{uid}"
    user_home = decky.DECKY_USER_HOME or env.get("HOME", "")
    if user_home:
        env["HOME"] = user_home
    user = _decky_user()
    if user:
        env["USER"] = user
    env["XDG_RUNTIME_DIR"] = runtime_dir
    env["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={runtime_dir}/bus"
    env.setdefault("SYSTEMD_PAGER", "")
    env.setdefault("SYSTEMD_COLORS", "0")
    return env


def _normalize_unit(unit: str) -> str:
    unit = unit.strip()
    if unit and "." not in unit:
        return f"{unit}.service"
    return unit


def _dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for item in items:
        if item and item not in seen:
            seen.add(item)
            result.append(item)
    return result


def _load_settings() -> dict[str, Any]:
    if SETTINGS_PATH.exists():
        try:
            loaded = json.loads(SETTINGS_PATH.read_text())
            if isinstance(loaded, dict):
                return {**DEFAULT_SETTINGS, **loaded}
        except Exception as exc:
            decky.logger.error(f"Failed reading settings, using defaults: {exc}")
    return dict(DEFAULT_SETTINGS)


def _save_settings(settings: dict[str, Any]) -> None:
    SETTINGS_PATH.parent.mkdir(parents=True, exist_ok=True)
    SETTINGS_PATH.write_text(json.dumps(settings))


async def _run_command(*args: str) -> tuple[int, str, str]:
    proc = await asyncio.create_subprocess_exec(
        *args,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=_systemd_env(),
    )
    stdout, stderr = await proc.communicate()
    return (
        proc.returncode,
        stdout.decode("utf-8", errors="replace").strip(),
        stderr.decode("utf-8", errors="replace").strip(),
    )


async def _show_unit(unit: str) -> dict[str, str] | None:
    code, stdout, stderr = await _run_command(
        "systemctl",
        "--user",
        "show",
        unit,
        "--property",
        "Id,LoadState,ActiveState,SubState,UnitFileState,FragmentPath",
        "--no-pager",
    )
    if code != 0 and not stdout:
        decky.logger.info(f"Unit {unit} not available: {stderr}")
        return None

    props: dict[str, str] = {}
    for line in stdout.splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        props[key] = value

    if props.get("LoadState") == "not-found":
        return None
    if "Id" not in props:
        return None
    return props


def _service_candidates(settings: dict[str, Any]) -> list[str]:
    configured = _normalize_unit(str(settings.get("service_unit", "")))
    decky_user = _decky_user()
    return _dedupe(
        [
            configured,
            "syncthing.service",
            f"syncthing@{decky_user}.service" if decky_user else "",
        ]
    )


async def _discover_unit(settings: dict[str, Any]) -> dict[str, Any]:
    candidates = _service_candidates(settings)
    for candidate in candidates:
        shown = await _show_unit(candidate)
        if shown is not None:
            return {
                "service_unit": shown["Id"],
                "service_found": True,
                "load_state": shown.get("LoadState", "unknown"),
                "active_state": shown.get("ActiveState", "unknown"),
                "sub_state": shown.get("SubState", "unknown"),
                "unit_file_state": shown.get("UnitFileState", "unknown"),
                "fragment_path": shown.get("FragmentPath") or None,
            }

    fallback = candidates[0] if candidates else "syncthing.service"
    return {
        "service_unit": fallback,
        "service_found": False,
        "load_state": "not-found",
        "active_state": "inactive",
        "sub_state": "dead",
        "unit_file_state": "not-found",
        "fragment_path": None,
    }


def _config_paths() -> list[Path]:
    home = Path(decky.DECKY_USER_HOME)
    candidates: list[Path] = []

    candidates.extend(
        [
            home / ".local" / "state" / "syncthing" / "config.xml",
            home / ".config" / "syncthing" / "config.xml",
        ]
    )

    xdg_state_home = os.environ.get("XDG_STATE_HOME")
    if xdg_state_home:
        candidates.append(Path(xdg_state_home) / "syncthing" / "config.xml")

    xdg_config_home = os.environ.get("XDG_CONFIG_HOME")
    if xdg_config_home:
        candidates.append(Path(xdg_config_home) / "syncthing" / "config.xml")

    result: list[Path] = []
    seen: set[str] = set()
    for candidate in candidates:
        text = str(candidate)
        if text not in seen:
            seen.add(text)
            result.append(candidate)
    return result


def _read_syncthing_config() -> tuple[Path | None, dict[str, Any]]:
    for path in _config_paths():
        try:
            root = ET.fromstring(path.read_text())
        except Exception:
            continue

        gui = root.find("gui")
        if gui is None:
            return path, {"config_path": str(path), "config_error": "Missing <gui> section"}

        addresses = [
            item.text.strip()
            for item in gui.findall("address")
            if item.text and item.text.strip()
        ]
        address = addresses[0] if addresses else "127.0.0.1:8384"
        if "://" in address:
            parsed = urllib.parse.urlparse(address)
            scheme = parsed.scheme or "http"
            netloc = parsed.netloc
        else:
            scheme = "https" if gui.get("tls", "").lower() == "true" else "http"
            netloc = address
            if netloc.startswith("0.0.0.0:"):
                netloc = netloc.replace("0.0.0.0", "127.0.0.1", 1)
            if netloc.startswith("[::]:"):
                netloc = netloc.replace("[::]", "127.0.0.1", 1)

        api_key = gui.findtext("apikey", "").strip()
        auth_user = gui.findtext("user", "").strip()
        return path, {
            "config_path": str(path),
            "gui_url": f"{scheme}://{netloc}",
            "gui_address": netloc,
            "gui_scheme": scheme,
            "api_key": api_key,
            "api_key_present": bool(api_key),
            "basic_auth_configured": bool(auth_user),
            "basic_auth_user": auth_user or None,
        }

    return None, {
        "config_path": None,
        "gui_url": None,
        "gui_address": None,
        "gui_scheme": None,
        "api_key": "",
        "api_key_present": False,
        "basic_auth_configured": False,
        "basic_auth_user": None,
    }


def _request_json(url: str, api_key: str) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        headers={
            "X-API-Key": api_key,
            "Accept": "application/json",
            "User-Agent": "decky-syncthing-jovian",
        },
    )
    context = ssl._create_unverified_context()
    with urllib.request.urlopen(request, timeout=3, context=context) as response:
        return json.loads(response.read().decode("utf-8"))


def _folder_summary(
    gui_url: str,
    api_key: str,
    folder: dict[str, Any],
    device_map: dict[str, dict[str, Any]],
    my_id: str | None,
) -> FolderSummary:
    folder_id = str(folder.get("id", ""))
    status = _request_json(
        f"{gui_url}/rest/db/status?folder={urllib.parse.quote(folder_id, safe='')}",
        api_key,
    )
    return {
        "id": folder_id,
        "label": folder.get("label") or folder_id,
        "path": folder.get("path"),
        "paused": bool(folder.get("paused", False)),
        "type": folder.get("type"),
        "state": status.get("state") or "unknown",
        "need_bytes": status.get("needBytes"),
        "need_items": status.get("needItems"),
        "global_bytes": status.get("globalBytes"),
        "local_bytes": status.get("localBytes"),
        "errors": status.get("errors"),
        "shared_devices": [
            _display_device_name(str(device.get("deviceID", "")), device_map, my_id)
            for device in folder.get("devices", [])
            if isinstance(device, dict) and device.get("deviceID")
        ],
    }


def _device_summary(
    device: dict[str, Any],
    connection_map: dict[str, Any],
    my_id: str | None,
    folders: list[dict[str, Any]],
    folder_map: dict[str, dict[str, Any]],
) -> DeviceSummary:
    device_id = str(device.get("deviceID", ""))
    connection = connection_map.get(device_id, {})
    return {
        "device_id": device_id,
        "name": device.get("name") or device_id,
        "paused": bool(device.get("paused", False)),
        "connected": bool(isinstance(connection, dict) and connection.get("connected", False)),
        "is_self": bool(my_id and device_id == my_id),
        "address": connection.get("address") if isinstance(connection, dict) else None,
        "client_version": connection.get("clientVersion") if isinstance(connection, dict) else None,
        "type": connection.get("type") if isinstance(connection, dict) else None,
        "shared_folders": [
            _display_folder_name(str(folder.get("id", "")), folder_map)
            for folder in folders
            if isinstance(folder, dict)
            and any(
                isinstance(shared_device, dict) and str(shared_device.get("deviceID", "")) == device_id
                for shared_device in folder.get("devices", [])
            )
        ],
    }


def _query_syncthing_api(gui_url: str | None, api_key: str) -> dict[str, Any]:
    if not gui_url or not api_key:
        return {
            "api_reachable": False,
            "api_error": "Missing Syncthing GUI URL or API key",
            "version": None,
            "my_id": None,
            "uptime_seconds": None,
            "folders_total": None,
            "devices_total": None,
            "connected_devices": None,
            "folders": [],
            "devices": [],
        }

    try:
        version = _request_json(f"{gui_url}/rest/system/version", api_key)
        status = _request_json(f"{gui_url}/rest/system/status", api_key)
        config = _request_json(f"{gui_url}/rest/config", api_key)
        connections = _request_json(f"{gui_url}/rest/system/connections", api_key)
        connection_map = connections.get("connections", {})
        my_id = status.get("myID")
        config_folders = [folder for folder in config.get("folders", []) if isinstance(folder, dict)]
        config_devices = [device for device in config.get("devices", []) if isinstance(device, dict)]
        folder_map = {str(folder.get("id", "")): folder for folder in config_folders}
        device_map = {str(device.get("deviceID", "")): device for device in config_devices}
        connected_devices = sum(
            1
            for conn in connection_map.values()
            if isinstance(conn, dict) and conn.get("connected")
        )
        folders = [
            _folder_summary(gui_url, api_key, folder, device_map, my_id)
            for folder in config_folders
        ]
        devices = [
            _device_summary(device, connection_map, my_id, config_folders, folder_map)
            for device in config_devices
        ]
        return {
            "api_reachable": True,
            "api_error": None,
            "version": version.get("version"),
            "my_id": my_id,
            "uptime_seconds": status.get("uptime"),
            "folders_total": len(config_folders),
            "devices_total": len(config_devices),
            "connected_devices": connected_devices,
            "folders": folders,
            "devices": devices,
        }
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, ValueError) as exc:
        return {
            "api_reachable": False,
            "api_error": str(exc),
            "version": None,
            "my_id": None,
            "uptime_seconds": None,
            "folders_total": None,
            "devices_total": None,
            "connected_devices": None,
            "folders": [],
            "devices": [],
        }


async def _build_status(settings: dict[str, Any]) -> dict[str, Any]:
    unit_info = await _discover_unit(settings)
    _, config_info = _read_syncthing_config()
    api_info = _query_syncthing_api(
        config_info.get("gui_url"),
        str(config_info.get("api_key", "")),
    )
    return {
        **unit_info,
        **config_info,
        **api_info,
        "configured_service_unit": _normalize_unit(str(settings.get("service_unit", ""))) or None,
    }


class Plugin:
    async def _main(self):
        self.settings = _load_settings()
        decky.logger.info("Decky Syncthing Jovian plugin loaded")

    async def _unload(self):
        decky.logger.info("Decky Syncthing Jovian plugin unloaded")

    async def get_status(self) -> dict[str, Any]:
        self.settings = _load_settings()
        return await _build_status(self.settings)

    async def set_service_unit(self, service_unit: str) -> dict[str, Any]:
        self.settings = _load_settings()
        self.settings["service_unit"] = _normalize_unit(service_unit)
        _save_settings(self.settings)
        return await _build_status(self.settings)

    async def clear_service_unit(self) -> dict[str, Any]:
        self.settings = _load_settings()
        self.settings["service_unit"] = ""
        _save_settings(self.settings)
        return await _build_status(self.settings)

    async def _run_systemctl_action(self, action: str) -> dict[str, Any]:
        self.settings = _load_settings()
        unit_info = await _discover_unit(self.settings)
        if not unit_info["service_found"]:
            raise RuntimeError(
                f"Syncthing user service not found. Tried {_service_candidates(self.settings)}"
            )

        code, stdout, stderr = await _run_command(
            "systemctl",
            "--user",
            action,
            unit_info["service_unit"],
            "--no-pager",
        )
        if code != 0:
            raise RuntimeError(stderr or stdout or f"systemctl {action} failed")
        return await _build_status(self.settings)

    async def start_service(self) -> dict[str, Any]:
        return await self._run_systemctl_action("start")

    async def stop_service(self) -> dict[str, Any]:
        return await self._run_systemctl_action("stop")

    async def restart_service(self) -> dict[str, Any]:
        return await self._run_systemctl_action("restart")
