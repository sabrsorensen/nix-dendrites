#!/usr/bin/env python3
import argparse
import ipaddress
import json
import re
import sys
from pathlib import Path

from PyQt5.QtCore import Qt
from PyQt5.QtWidgets import (
    QApplication,
    QFileDialog,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QTableWidget,
    QTableWidgetItem,
    QVBoxLayout,
    QWidget,
)


RESERVED_NAMES = {
    "gateway", "router", "dns", "dhcp", "ns", "ns1", "ns2", "localhost", "www",
    "mail", "ftp", "pop", "imap", "smtp", "in", "a", "aaaa", "cname", "mx", "txt", "ptr", "soa",
}


def is_valid_mac(mac: str) -> bool:
    return bool(re.match(r"^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$", mac.strip()))


def normalize_mac(mac: str) -> str:
    return mac.strip().replace("-", ":").upper()


def normalize_hostname(hostname: str) -> str:
    hostname = hostname.strip().lower().replace(" ", "-").replace("_", "-")
    hostname = re.sub(r"[^a-z0-9-]", "", hostname).strip("-")
    return hostname


def load_reservations(path: Path):
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return []

    if not isinstance(data, dict):
        return []

    if isinstance(data.get("reservations"), list):
        return data["reservations"]

    legacy_leases = data.get("leases", [])
    if isinstance(legacy_leases, list):
        return [
            {
                "ip": record.get("ip", ""),
                "hostname": record.get("hostname", ""),
                "mac": record.get("mac", ""),
            }
            for record in legacy_leases
            if isinstance(record, dict) and record.get("ip") and record.get("mac") and record.get("static", True)
        ]

    return []


class ReservationsTableWidget(QTableWidget):
    def __init__(self, editor, parent=None):
        super().__init__(parent)
        self.editor = editor
        self.setDragDropMode(self.InternalMove)
        self.setSelectionBehavior(self.SelectRows)
        self.setEditTriggers(self.DoubleClicked | self.SelectedClicked)
        self.setDropIndicatorShown(True)
        self.setDragEnabled(True)
        self.setAcceptDrops(True)
        self.setDefaultDropAction(Qt.MoveAction)
        self.itemChanged.connect(self.editor.refresh_validation)

    def dropEvent(self, event):
        source_row = self.currentRow()
        dest_index = self.indexAt(event.pos())
        dest_row = dest_index.row() if dest_index.isValid() else self.rowCount() - 1

        if source_row == dest_row or source_row == -1:
            return

        row_data = [self.item(source_row, col).text() if self.item(source_row, col) else "" for col in range(self.columnCount())]
        self.removeRow(source_row)
        if source_row < dest_row:
            dest_row -= 1
        self.insertRow(dest_row)
        for col, value in enumerate(row_data):
            self.setItem(dest_row, col, QTableWidgetItem(value))

        first_host = next(self.editor.subnet.hosts(), ipaddress.IPv4Address("192.168.1.1"))
        new_ip = first_host
        if dest_row > 0:
            prev_ip_item = self.item(dest_row - 1, 0)
            try:
                new_ip = ipaddress.IPv4Address(prev_ip_item.text()) + 1 if prev_ip_item else first_host
            except Exception:
                new_ip = first_host

        self.setItem(dest_row, 0, QTableWidgetItem(str(new_ip)))

        current_ip = new_ip
        for row in range(dest_row + 1, self.rowCount()):
            item = self.item(row, 0)
            try:
                next_ip = ipaddress.IPv4Address(item.text()) if item else None
            except Exception:
                next_ip = None
            if next_ip is not None and int(next_ip) <= int(current_ip):
                current_ip = current_ip + 1
                self.setItem(row, 0, QTableWidgetItem(str(current_ip)))
            else:
                break

        event.accept()
        self.editor.refresh_validation()


class ReservationsEditor(QMainWindow):
    def __init__(self, leases_json_path: str, subnet: str):
        super().__init__()
        self.leases_json_path = Path(leases_json_path)
        self.subnet = ipaddress.IPv4Network(subnet, strict=False)
        self.setWindowTitle(f"Kea/CoreDNS Reservations Editor - {self.leases_json_path}")
        self.resize(1000, 800)
        self.init_ui()
        self.load_reservations(self.leases_json_path)

    def init_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)

        search_layout = QHBoxLayout()
        self.search_box = QLineEdit()
        self.search_box.setPlaceholderText("Search IP, MAC, or Hostname...")
        self.search_box.textChanged.connect(self.apply_filter)
        search_layout.addWidget(QLabel("Filter:"))
        search_layout.addWidget(self.search_box)
        layout.addLayout(search_layout)

        self.table = ReservationsTableWidget(self)
        self.table.setColumnCount(3)
        self.table.setHorizontalHeaderLabels(["IP", "Hostname", "MAC"])
        layout.addWidget(self.table)

        for label, handler in [
            ("Add Row", self.add_row),
            ("Remove Selected Row", self.remove_selected_row),
            ("Save", self.save_reservations),
            ("Load", self.load_dialog),
        ]:
            button = QPushButton(label)
            button.clicked.connect(handler)
            layout.addWidget(button)

        self.subnet_label = QLabel()
        layout.addWidget(self.subnet_label)

        self.validation_label = QLabel()
        layout.addWidget(self.validation_label)

    def load_reservations(self, path: Path):
        reservations = load_reservations(path)
        self.table.setRowCount(0)
        for reservation in reservations:
            row = self.table.rowCount()
            self.table.insertRow(row)
            self.table.setItem(row, 0, QTableWidgetItem(str(reservation.get("ip", "")).strip()))
            self.table.setItem(row, 1, QTableWidgetItem(str(reservation.get("hostname", "")).strip()))
            self.table.setItem(row, 2, QTableWidgetItem(normalize_mac(str(reservation.get("mac", "")))))
        self.sort_by_ip()
        self.refresh_validation()
        self.table.resizeColumnsToContents()
        self.apply_filter()

    def load_dialog(self):
        path, _ = QFileDialog.getOpenFileName(self, "Open leases.json", "", "JSON Files (*.json)")
        if path:
            self.leases_json_path = Path(path)
            self.load_reservations(self.leases_json_path)

    def save_reservations(self):
        errors = self.validate_table(show=True)
        if errors:
            QMessageBox.critical(self, "Validation Error", "Cannot save due to errors:\n" + "\n".join(errors))
            return

        self.sort_by_ip()

        reservations = []
        for row in range(self.table.rowCount()):
            reservations.append(
                {
                    "ip": self.table.item(row, 0).text().strip(),
                    "hostname": normalize_hostname(self.table.item(row, 1).text()),
                    "mac": normalize_mac(self.table.item(row, 2).text()),
                }
            )

        payload = {"version": 1, "reservations": reservations}
        try:
            self.leases_json_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        except Exception as exc:
            QMessageBox.critical(self, "Error", f"Failed to save reservations: {exc}")
            return

        self.sort_by_ip()
        self.refresh_validation()
        QMessageBox.information(self, "Saved", "Reservations saved successfully.")

    def sort_by_ip(self):
        rows = []
        for row in range(self.table.rowCount()):
            row_data = [self.table.item(row, col).text() if self.table.item(row, col) else "" for col in range(self.table.columnCount())]
            try:
                ip_sort = int(ipaddress.IPv4Address(row_data[0]))
            except Exception:
                ip_sort = 0
            rows.append((ip_sort, row_data))

        rows.sort(key=lambda item: item[0])
        self.table.setRowCount(0)
        for _, row_data in rows:
            row = self.table.rowCount()
            self.table.insertRow(row)
            for col, value in enumerate(row_data):
                self.table.setItem(row, col, QTableWidgetItem(value))

    def refresh_validation(self):
        ip_count = {}
        mac_count = {}
        hostname_count = {}

        for row in range(self.table.rowCount()):
            ip = self._cell(row, 0)
            hostname = self._cell(row, 1)
            mac = normalize_mac(self._cell(row, 2)).lower()
            ip_count[ip] = ip_count.get(ip, 0) + 1
            hostname_count[hostname] = hostname_count.get(hostname, 0) + 1
            mac_count[mac] = mac_count.get(mac, 0) + 1

        for row in range(self.table.rowCount()):
            ip = self._cell(row, 0)
            hostname = self._cell(row, 1)
            mac = normalize_mac(self._cell(row, 2)).lower()
            is_duplicate = (
                (ip and ip_count.get(ip, 0) > 1)
                or (hostname and hostname_count.get(hostname, 0) > 1)
                or (mac and mac_count.get(mac, 0) > 1)
            )
            for col in range(self.table.columnCount()):
                item = self.table.item(row, col)
                if item is not None:
                    item.setBackground(Qt.red if is_duplicate else Qt.white)

        self.validate_table(show=True)
        self.visualize_subnet()

    def visualize_subnet(self):
        used_ips = set()
        for row in range(self.table.rowCount()):
            try:
                ip_obj = ipaddress.IPv4Address(self._cell(row, 0))
            except Exception:
                continue
            if ip_obj in self.subnet:
                used_ips.add(ip_obj)

        total_ips = len(list(self.subnet.hosts()))
        used_count = len(used_ips)
        free_count = total_ips - used_count
        percent_used = (used_count / total_ips) * 100 if total_ips else 0
        self.subnet_label.setText(
            f"Subnet {self.subnet} usage:\n"
            f"Total IPs: {total_ips}\n"
            f"Used: {used_count}\n"
            f"Free: {free_count}\n"
            f"Percent used: {percent_used:.1f}%"
        )

    def validate_table(self, show=False):
        errors = []
        ip_set = set()
        mac_set = set()
        hostname_set = set()

        for row in range(self.table.rowCount()):
            ip = self._cell(row, 0)
            hostname_raw = self._cell(row, 1)
            hostname = normalize_hostname(hostname_raw)
            mac = normalize_mac(self._cell(row, 2))

            try:
                ip_obj = ipaddress.IPv4Address(ip)
                if ip_obj not in self.subnet:
                    errors.append(f"Row {row + 1}: IP '{ip}' is outside subnet {self.subnet}")
            except Exception:
                errors.append(f"Row {row + 1}: Invalid IP '{ip}'")

            if not is_valid_mac(mac):
                errors.append(f"Row {row + 1}: Invalid MAC '{mac}'")

            if not hostname:
                errors.append(f"Row {row + 1}: Hostname '{hostname_raw}' normalizes to empty")
            elif hostname in RESERVED_NAMES:
                errors.append(f"Row {row + 1}: Hostname '{hostname}' is reserved")
            elif len(hostname) > 63:
                errors.append(f"Row {row + 1}: Hostname '{hostname}' exceeds 63 characters")

            if ip in ip_set:
                errors.append(f"Row {row + 1}: Duplicate IP '{ip}'")
            else:
                ip_set.add(ip)

            if mac in mac_set:
                errors.append(f"Row {row + 1}: Duplicate MAC '{mac}'")
            else:
                mac_set.add(mac)

            if hostname:
                if hostname in hostname_set:
                    errors.append(f"Row {row + 1}: Duplicate hostname '{hostname}'")
                else:
                    hostname_set.add(hostname)

        if show:
            if errors:
                self.validation_label.setText("Validation errors:\n" + "\n".join(errors))
                self.validation_label.setStyleSheet("color: red;")
            else:
                self.validation_label.setText("No validation errors.")
                self.validation_label.setStyleSheet("color: green;")

        return errors

    def apply_filter(self):
        filter_text = self.search_box.text().lower().strip()
        for row in range(self.table.rowCount()):
            visible = True
            if filter_text:
                visible = False
                for col in range(self.table.columnCount()):
                    item = self.table.item(row, col)
                    if item and filter_text in item.text().lower():
                        visible = True
                        break
            self.table.setRowHidden(row, not visible)

    def add_row(self):
        row = self.table.rowCount()
        self.table.insertRow(row)
        self.table.setItem(row, 0, QTableWidgetItem(""))
        self.table.setItem(row, 1, QTableWidgetItem(""))
        self.table.setItem(row, 2, QTableWidgetItem(""))
        self.refresh_validation()

    def remove_selected_row(self):
        selected = self.table.selectionModel().selectedRows()
        for index in sorted(selected, reverse=True):
            self.table.removeRow(index.row())
        self.refresh_validation()

    def _cell(self, row: int, col: int) -> str:
        item = self.table.item(row, col)
        return item.text().strip() if item else ""


def parse_args():
    parser = argparse.ArgumentParser(description="Kea/CoreDNS reservations editor")
    parser.add_argument(
        "leases_json_path",
        nargs="?",
        default="./leases.json",
        help="Path to leases.json file (default: ./leases.json)",
    )
    parser.add_argument(
        "--subnet",
        default="192.168.1.0/24",
        help="IPv4 subnet used for validation and usage display (default: 192.168.1.0/24)",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    app = QApplication(sys.argv)
    editor = ReservationsEditor(args.leases_json_path, args.subnet)
    editor.show()
    sys.exit(app.exec_())
