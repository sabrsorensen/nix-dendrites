import {
  ConfirmModal,
  DialogButton,
  Field,
  Focusable,
  Navigation,
  PanelSection,
  PanelSectionRow,
  ProgressBarItem,
  Spinner,
  staticClasses,
  showModal,
  TextField,
} from "@decky/ui";
import { callable, definePlugin, toaster } from "@decky/api";
import { ComponentProps, ReactNode, useEffect, useRef, useState } from "react";
import {
  FaCheckCircle,
  FaExclamationCircle,
  FaGlobe,
  FaHourglass,
  FaHourglassHalf,
  FaPauseCircle,
  FaPlay,
  FaPowerOff,
  FaQuestionCircle,
  FaRecycle,
  FaSearch,
  FaSkull,
  FaSkullCrossbones,
  FaStop,
  FaStopCircle,
  FaSync,
  FaSyncAlt,
  FaUnlink,
  FaWrench,
} from "react-icons/fa";

type FolderSummary = {
  id: string;
  label: string;
  path: string | null;
  paused: boolean;
  type: string | null;
  state: string;
  need_bytes: number | null;
  need_items: number | null;
  global_bytes: number | null;
  local_bytes: number | null;
  errors: number | null;
  shared_devices: string[];
};

type DeviceSummary = {
  device_id: string;
  name: string;
  paused: boolean;
  connected: boolean;
  is_self: boolean;
  address: string | null;
  client_version: string | null;
  type: string | null;
  shared_folders: string[];
};

type Status = {
  service_unit: string;
  configured_service_unit: string | null;
  service_found: boolean;
  load_state: string;
  active_state: string;
  sub_state: string;
  unit_file_state: string;
  fragment_path: string | null;
  config_path: string | null;
  gui_url: string | null;
  gui_address: string | null;
  gui_scheme: string | null;
  api_key_present: boolean;
  basic_auth_configured: boolean;
  basic_auth_user: string | null;
  api_reachable: boolean;
  api_error: string | null;
  version: string | null;
  my_id: string | null;
  uptime_seconds: number | null;
  folders_total: number | null;
  devices_total: number | null;
  connected_devices: number | null;
  folders: FolderSummary[];
  devices: DeviceSummary[];
};

const getStatus = callable<[], Status>("get_status");
const setServiceUnit = callable<[serviceUnit: string], Status>("set_service_unit");
const clearServiceUnit = callable<[], Status>("clear_service_unit");
const startService = callable<[], Status>("start_service");
const stopService = callable<[], Status>("stop_service");

function ConfirmModalCompat(props: ComponentProps<typeof ConfirmModal>) {
  return window.SP_REACT.createElement(ConfirmModal as never, props);
}

function DialogButtonCompat(props: ComponentProps<typeof DialogButton>) {
  return window.SP_REACT.createElement(DialogButton as never, props);
}

function FieldCompat(props: ComponentProps<typeof Field>) {
  return window.SP_REACT.createElement(Field as never, props);
}

function FocusableCompat(props: ComponentProps<typeof Focusable>) {
  return window.SP_REACT.createElement(Focusable as never, props);
}

function PanelSectionCompat(props: ComponentProps<typeof PanelSection>) {
  return window.SP_REACT.createElement(PanelSection as never, props);
}

function PanelSectionRowCompat(props: ComponentProps<typeof PanelSectionRow>) {
  return window.SP_REACT.createElement(PanelSectionRow as never, props);
}

function ProgressBarItemCompat(props: ComponentProps<typeof ProgressBarItem>) {
  return window.SP_REACT.createElement(ProgressBarItem as never, props);
}

function SpinnerCompat(props: ComponentProps<typeof Spinner>) {
  return window.SP_REACT.createElement(Spinner as never, props);
}

function TextFieldCompat(props: ComponentProps<typeof TextField>) {
  return window.SP_REACT.createElement(TextField as never, props);
}

const syncthingCss = `
.syncthing-identicon {
  width: 1em;
  height: 1em;
  shape-rendering: crispEdges;
}

.syncthing-identicon rect {
  fill: currentColor;
}

.syncthing-entity-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.syncthing-entity-label {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  gap: 16px;
}

.syncthing-entity-label--label {
  text-align: right;
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.syncthing-entity-label--icons {
  display: inline-flex;
  padding: 0;
  gap: 8px;
}

.syncthing-details {
  font-size: 12px;
  line-height: 16px;
}
`;

function formatBytes(value: number | null | undefined): string {
  if (value == null || Number.isNaN(value)) {
    return "Unavailable";
  }
  if (value < 1024) {
    return `${value} B`;
  }
  const units = ["KiB", "MiB", "GiB", "TiB"];
  let next = value;
  let unit = units[0];
  for (const candidate of units) {
    unit = candidate;
    next /= 1024;
    if (next < 1024) {
      break;
    }
  }
  return `${next.toFixed(next >= 10 ? 0 : 1)} ${unit}`;
}

function formatUptime(seconds: number | null): string {
  if (seconds == null || Number.isNaN(seconds)) {
    return "Unavailable";
  }
  const total = Math.max(0, Math.floor(seconds));
  const days = Math.floor(total / 86400);
  const hours = Math.floor((total % 86400) / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  if (days > 0) {
    return `${days}d ${hours}h`;
  }
  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  }
  return `${minutes}m`;
}

function formatDeviceId(deviceId: string | null | undefined): string {
  if (!deviceId) {
    return "Unavailable";
  }
  const parts = deviceId.split("-");
  if (parts.length < 2) {
    return deviceId;
  }
  return `${parts[0]}...${parts[parts.length - 1]}`;
}

function serviceState(status: Status | null): "running" | "starting" | "stopped" | "failed" | "unknown" {
  if (!status) {
    return "unknown";
  }
  if (status.active_state === "active") {
    return "running";
  }
  if (status.active_state === "activating" || status.active_state === "deactivating") {
    return "starting";
  }
  if (status.active_state === "failed") {
    return "failed";
  }
  if (!status.service_found) {
    return "unknown";
  }
  return "stopped";
}

function folderState(folder: FolderSummary):
  | "clean-waiting"
  | "cleaning"
  | "failed"
  | "idle"
  | "paused"
  | "scanning"
  | "stopped"
  | "sync-waiting"
  | "syncing"
  | "unshared"
  | "unknown" {
  if (folder.paused) {
    return "paused";
  }
  if (folder.errors && folder.errors > 0) {
    return "failed";
  }
  switch (folder.state) {
    case "clean-wait":
    case "scan-wait":
      return "clean-waiting";
    case "cleaning":
      return "cleaning";
    case "idle":
      return folder.need_items && folder.need_items > 0 ? "unshared" : "idle";
    case "scanning":
      return "scanning";
    case "stopped":
      return "stopped";
    case "sync-wait":
      return "sync-waiting";
    case "syncing":
      return "syncing";
    case "unshared":
      return "unshared";
    default:
      return folder.need_items && folder.need_items > 0 ? "failed" : "unknown";
  }
}

function makeFolderDetails(folder: FolderSummary): string {
  const parts: string[] = [`State: ${folder.state}`];
  if (folder.need_items != null) {
    parts.push(`Need items: ${folder.need_items}`);
  }
  if (folder.need_bytes != null) {
    parts.push(`Need bytes: ${formatBytes(folder.need_bytes)}`);
  }
  if (folder.path) {
    parts.push(`Path: ${folder.path}`);
  }
  if (folder.shared_devices.length > 0) {
    parts.push(`Shared with: ${folder.shared_devices.join(", ")}`);
  }
  return parts.join("\n");
}

function makeDeviceDetails(device: DeviceSummary, status: Status): string {
  const parts: string[] = [];
  if (device.is_self) {
    parts.push(`Device ID: ${formatDeviceId(status.my_id)}`);
    parts.push(`Version: ${status.version ?? "Unavailable"}`);
    parts.push(`Uptime: ${formatUptime(status.uptime_seconds)}`);
  } else {
    parts.push(`Device ID: ${formatDeviceId(device.device_id)}`);
    parts.push(`Connection: ${device.connected ? "Connected" : "Disconnected"}`);
    if (device.address) {
      parts.push(`Address: ${device.address}`);
    }
    if (device.client_version) {
      parts.push(`Client: ${device.client_version}`);
    }
  }
  if (device.shared_folders.length > 0) {
    parts.push(`Folders: ${device.shared_folders.join(", ")}`);
  }
  return parts.join("\n");
}

function Loader(props: { fullScreen?: boolean }) {
  if (props.fullScreen) {
    return (
      <FocusableCompat
        style={{
          overflowY: "scroll",
          backgroundColor: "transparent",
          marginTop: "40px",
          height: "calc(100% - 40px)",
        }}
      >
        <div style={{ width: 36, margin: "auto" }}>
          <SpinnerCompat />
        </div>
      </FocusableCompat>
    );
  }

  return <ProgressBarItemCompat indeterminate nProgress={0} focusable />;
}

function PanelErrorContent(props: { error: unknown }) {
  if (typeof props.error === "string") {
    return <span>Error: {props.error}</span>;
  }
  if (props.error instanceof Error) {
    return <span>Error: {props.error.message}</span>;
  }
  return <span>Error: {String(props.error)}</span>;
}

function SyncthingState(props: { status: Status | null; hasError: boolean }) {
  if (props.hasError) {
    return (
      <span>
        <FaSkullCrossbones /> Error
      </span>
    );
  }
  switch (serviceState(props.status)) {
    case "failed":
      return (
        <span>
          <FaSkull /> Failed
        </span>
      );
    case "stopped":
      return (
        <span>
          <FaStop /> Stopped
        </span>
      );
    case "running":
      return (
        <span>
          <FaPlay /> Running
        </span>
      );
    case "starting":
      return (
        <span>
          <FaHourglass /> Starting
        </span>
      );
    default:
      return (
        <span>
          <FaQuestionCircle /> Unknown
        </span>
      );
  }
}

function FolderStatusIcon(props: { folder: FolderSummary }) {
  switch (folderState(props.folder)) {
    case "clean-waiting":
    case "sync-waiting":
      return <FaHourglassHalf />;
    case "cleaning":
      return <FaRecycle />;
    case "failed":
      return <FaExclamationCircle />;
    case "idle":
      return <FaCheckCircle />;
    case "paused":
      return <FaPauseCircle />;
    case "scanning":
      return <FaSearch />;
    case "stopped":
      return <FaStopCircle />;
    case "syncing":
      return <FaSync />;
    case "unshared":
      return <FaUnlink />;
    default:
      return <FaQuestionCircle />;
  }
}

function DeviceStatusIcon(props: { device: DeviceSummary }) {
  if (props.device.paused) {
    return <FaPauseCircle />;
  }
  if (props.device.connected) {
    return <FaCheckCircle />;
  }
  return <FaPowerOff />;
}

function Identicon(props: { ident: string }) {
  const ref = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    const value = props.ident?.toString().replace(/[\W_]/g, "") ?? "";
    const svgNS = "http://www.w3.org/2000/svg";
    const size = 5;
    const rectSize = 100 / size;
    const middleCol = Math.ceil(size / 2) - 1;
    const svg = document.createElementNS(svgNS, "svg");
    svg.setAttribute("class", "syncthing-identicon");

    for (let row = 0; row < size; row += 1) {
      for (let col = middleCol; col > -1; col -= 1) {
        const shouldFill = value && !(parseInt(String(value.charCodeAt(row + col * size)), 10) % 2);
        if (!shouldFill) {
          continue;
        }
        const cols = size % 2 && col === middleCol ? [col] : [col, size - col - 1];
        for (const fillCol of cols) {
          const rect = document.createElementNS(svgNS, "rect");
          rect.setAttribute("x", `${fillCol * rectSize}%`);
          rect.setAttribute("y", `${row * rectSize}%`);
          rect.setAttribute("width", `${rectSize}%`);
          rect.setAttribute("height", `${rectSize}%`);
          svg.appendChild(rect);
        }
      }
    }

    ref.current?.replaceChildren(svg);
  }, [props.ident]);

  return <span ref={ref} />;
}

function SyncthingEntity(props: {
  label: string | ReactNode;
  primaryIcon?: ReactNode;
  secondaryIcon?: ReactNode;
  onClick?: () => void;
  expanded?: boolean;
  children?: ReactNode;
}) {
  return (
    <div>
      <DialogButtonCompat focusable onClick={props.onClick}>
        <div className="syncthing-entity-label">
          <span className="syncthing-entity-label--icons">
            {props.primaryIcon}
            {props.secondaryIcon}
          </span>
          <span className="syncthing-entity-label--label">{props.label}</span>
        </div>
      </DialogButtonCompat>
      {props.expanded ? (
        <div
          className="syncthing-details"
          style={{
            whiteSpace: "pre-wrap",
            padding: "8px 12px 4px 12px",
            opacity: 0.9,
          }}
        >
          {props.children}
        </div>
      ) : null}
    </div>
  );
}

function DetailsModal(props: {
  title: string;
  body: string;
  initialValue: string;
  onSave: (value: string) => Promise<void>;
  onClear: () => Promise<void>;
  closeModal?: () => void;
}) {
  const [value, setValue] = useState(props.initialValue);
  return (
    <ConfirmModalCompat
      strTitle={props.title}
      strOKButtonText="Save"
      strCancelButtonText="Close"
      onOK={async () => {
        await props.onSave(value);
        props.closeModal?.();
      }}
      closeModal={props.closeModal}
    >
      <div className="syncthing-details" style={{ whiteSpace: "pre-wrap" }}>
        {props.body}
      </div>
      <div style={{ marginTop: 16 }}>
        <FieldCompat
          label="Service unit"
          description="Leave empty to auto-detect the usual Syncthing user unit names."
        >
          <TextFieldCompat value={value} onChange={(e) => setValue(e?.target.value ?? "")} />
        </FieldCompat>
      </div>
      <DialogButtonCompat
        style={{ marginTop: 16 }}
        onClick={async () => {
          await props.onClear();
          props.closeModal?.();
        }}
      >
        Clear Override
      </DialogButtonCompat>
    </ConfirmModalCompat>
  );
}

function Content() {
  const [status, setStatus] = useState<Status | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [expandedFolderId, setExpandedFolderId] = useState<string | null>(null);
  const [expandedDeviceId, setExpandedDeviceId] = useState<string | null>(null);

  const reloadState = async (updateLoading = true) => {
    if (updateLoading) {
      setLoading(true);
    }
    setError(null);
    try {
      const next = await getStatus();
      setStatus(next);
      setError(next.api_error ?? null);
    } catch (err) {
      setError(`${err}`);
    } finally {
      if (updateLoading) {
        setLoading(false);
      }
    }
  };

  useEffect(() => {
    reloadState();
  }, []);

  const toggleSyncthing = async () => {
    if (busy) {
      return;
    }
    setBusy(true);
    try {
      const next =
        status?.active_state === "active" || status?.active_state === "activating"
          ? await stopService()
          : await startService();
      setStatus(next);
      setError(next.api_error ?? null);
    } catch (err) {
      toaster.toast({
        title: "Syncthing",
        body: `${err}`,
      });
      setError(`${err}`);
    } finally {
      setBusy(false);
    }
  };

  const openSettingsModal = () => {
    showModal(
      <DetailsModal
        title="Syncthing"
        body={[
          `Unit: ${status?.service_unit ?? "Unavailable"}`,
          `State: ${status ? `${status.active_state} (${status.sub_state})` : "Unavailable"}`,
          `Unit file: ${status?.unit_file_state ?? "Unavailable"}`,
          `Fragment: ${status?.fragment_path ?? "Unavailable"}`,
          `Config: ${status?.config_path ?? "Unavailable"}`,
          `GUI: ${status?.gui_url ?? "Unavailable"}`,
          `Version: ${status?.version ?? "Unavailable"}`,
          `Device ID: ${status?.my_id ?? "Unavailable"}`,
        ].join("\n")}
        initialValue={status?.configured_service_unit ?? ""}
        onSave={async (value) => {
          const next = await setServiceUnit(value);
          setStatus(next);
          setError(next.api_error ?? null);
          toaster.toast({
            title: "Syncthing",
            body: `Saved service unit override${value ? `: ${value}` : ""}`,
          });
        }}
        onClear={async () => {
          const next = await clearServiceUnit();
          setStatus(next);
          setError(next.api_error ?? null);
          toaster.toast({
            title: "Syncthing",
            body: "Cleared service unit override",
          });
        }}
      />,
      window,
    );
  };

  if (loading && !status) {
    return (
      <>
        <style>{syncthingCss}</style>
        <Loader fullScreen />
      </>
    );
  }

  const remoteDevices = status?.devices.filter((device) => !device.is_self) ?? [];
  const selfDevice = status?.devices.find((device) => device.is_self) ?? null;
  const hasError = error != null;

  return (
    <>
      <style>{syncthingCss}</style>
      <PanelSectionCompat>
        <PanelSectionRowCompat>
          <FocusableCompat flow-children="horizontal" style={{ display: "flex", padding: 0, gap: "8px" }}>
            <DialogButtonCompat
              style={{ minWidth: 0, width: "15%", height: "28px", padding: "6px" }}
              disabled={loading || busy}
              onClick={() => reloadState()}
            >
              <FaSyncAlt />
            </DialogButtonCompat>
            <DialogButtonCompat
              style={{ minWidth: 0, width: "15%", height: "28px", padding: "6px" }}
              disabled={busy}
              onClick={openSettingsModal}
            >
              <FaWrench />
            </DialogButtonCompat>
            <DialogButtonCompat
              style={{ minWidth: 0, width: "15%", height: "28px", padding: "6px" }}
              disabled={!status?.gui_url}
              onClick={() => status?.gui_url && Navigation.NavigateToExternalWeb(status.gui_url)}
            >
              <FaGlobe />
            </DialogButtonCompat>
            <DialogButtonCompat
              style={{ minWidth: 0, width: "15%", height: "28px", padding: "6px" }}
              disabled={busy || !status?.service_found}
              onClick={toggleSyncthing}
            >
              <FaPowerOff />
            </DialogButtonCompat>
          </FocusableCompat>
        </PanelSectionRowCompat>
        <PanelSectionRowCompat>
          <FieldCompat label={<SyncthingState status={status} hasError={hasError} />} />
        </PanelSectionRowCompat>
      </PanelSectionCompat>

      {hasError ? (
        <PanelSectionCompat title="Error">
          <PanelSectionRowCompat>
            <PanelErrorContent error={error} />
          </PanelSectionRowCompat>
        </PanelSectionCompat>
      ) : null}

      {status?.active_state === "active" && status.api_reachable ? (
        <>
          <PanelSectionCompat title="Folders">
            <PanelSectionRowCompat>
              <div className="syncthing-entity-list">
                {status.folders.map((folder) => (
                  <SyncthingEntity
                    key={folder.id}
                    primaryIcon={<FolderStatusIcon folder={folder} />}
                    label={<span>{folder.label || folder.id}</span>}
                    expanded={expandedFolderId === folder.id}
                    onClick={() =>
                      setExpandedFolderId((current) => (current === folder.id ? null : folder.id))
                    }
                  >
                    {makeFolderDetails(folder)}
                  </SyncthingEntity>
                ))}
              </div>
            </PanelSectionRowCompat>
          </PanelSectionCompat>
          <PanelSectionCompat title="Devices">
            <PanelSectionRowCompat>
              <div className="syncthing-entity-list">
                {selfDevice ? (
                  <SyncthingEntity
                    primaryIcon={<Identicon ident={selfDevice.device_id} />}
                    secondaryIcon={<DeviceStatusIcon device={selfDevice} />}
                    label={selfDevice.name || selfDevice.device_id}
                    expanded={expandedDeviceId === selfDevice.device_id}
                    onClick={() =>
                      setExpandedDeviceId((current) =>
                        current === selfDevice.device_id ? null : selfDevice.device_id,
                      )
                    }
                  >
                    {makeDeviceDetails(selfDevice, status)}
                  </SyncthingEntity>
                ) : null}
                {remoteDevices.map((device) => (
                  <SyncthingEntity
                    key={device.device_id}
                    primaryIcon={<Identicon ident={device.device_id} />}
                    secondaryIcon={<DeviceStatusIcon device={device} />}
                    label={device.name || device.device_id}
                    expanded={expandedDeviceId === device.device_id}
                    onClick={() =>
                      setExpandedDeviceId((current) =>
                        current === device.device_id ? null : device.device_id,
                      )
                    }
                  >
                    {makeDeviceDetails(device, status)}
                  </SyncthingEntity>
                ))}
              </div>
            </PanelSectionRowCompat>
          </PanelSectionCompat>
        </>
      ) : null}
    </>
  );
}

function SyncthingIcon() {
  return (
    <svg viewBox="0 0 24 24" width="1em" height="1em" aria-hidden="true">
      <circle cx="12" cy="12" r="10" fill="currentColor" opacity="0.18" />
      <path
        d="M12 4.75a7.25 7.25 0 1 1-7.19 8.18h2.06a5.25 5.25 0 1 0 1.49-4.52l2.39 2.39H5.25V5.3l1.73 1.73A7.2 7.2 0 0 1 12 4.75Z"
        fill="currentColor"
      />
    </svg>
  );
}

export default definePlugin(() => {
  return {
    name: "Syncthing",
    titleView: <div className={staticClasses.Title}>Syncthing</div>,
    content: <Content />,
    icon: <SyncthingIcon />,
  };
});
