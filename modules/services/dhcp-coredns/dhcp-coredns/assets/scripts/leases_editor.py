#!/usr/bin/env python3
"""Edit and validate the encrypted DHCP reservation JSON before re-encrypting it.

The editor deliberately works on a caller-provided file.  It never reads a
decrypted service-state file or writes into the Nix store.
"""

import argparse
import ipaddress
import json
import re
import sys
from pathlib import Path

from PyQt5.QtCore import Qt
from PyQt5.QtGui import QColor
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


def normalize_hostname(value):
    return re.sub(r"[^a-z0-9-]", "", value.strip().lower().replace(" ", "-").replace("_", "-")).strip("-")


def normalize_mac(value):
    return value.strip().replace("-", ":").upper()


def valid_mac(value):
    return bool(re.fullmatch(r"([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}", value))


def load_reservations(path):
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    if not isinstance(payload, dict):
        return []
    if isinstance(payload.get("reservations"), list):
        return payload["reservations"]
    # Accept the predecessor's legacy file shape while always writing the
    # reservation form consumed by the current Kea configuration.
    return [
        {"ip": row.get("ip", ""), "hostname": row.get("hostname", ""), "mac": row.get("mac", "")}
        for row in payload.get("leases", [])
        if isinstance(row, dict) and row.get("ip") and row.get("mac") and row.get("static", True)
    ]


class ReservationTable(QTableWidget):
    """Keep the predecessor's row-reordering and contiguous-IP behavior."""

    def __init__(self, editor):
        super().__init__(0, 3)
        self.editor = editor
        self.setDragDropMode(QTableWidget.InternalMove)
        self.setDragEnabled(True)
        self.setAcceptDrops(True)
        self.setDropIndicatorShown(True)
        self.setDefaultDropAction(Qt.MoveAction)

    def dropEvent(self, event):
        source = self.currentRow()
        index = self.indexAt(event.pos())
        destination = index.row() if index.isValid() else self.rowCount() - 1
        if source < 0 or source == destination:
            event.ignore()
            return
        values = [self.item(source, column).text() if self.item(source, column) else "" for column in range(self.columnCount())]
        self.removeRow(source)
        if source < destination:
            destination -= 1
        self.insertRow(destination)
        for column, value in enumerate(values):
            self.setItem(destination, column, QTableWidgetItem(value))

        first_host = next(self.editor.subnet.hosts())
        try:
            current = ipaddress.IPv4Address(self.item(destination - 1, 0).text()) + 1 if destination else first_host
        except (AttributeError, ipaddress.AddressValueError):
            current = first_host
        self.setItem(destination, 0, QTableWidgetItem(str(current)))
        for row in range(destination + 1, self.rowCount()):
            try:
                existing = ipaddress.IPv4Address(self.item(row, 0).text())
            except (AttributeError, ipaddress.AddressValueError):
                existing = current
            if existing <= current:
                current += 1
                self.setItem(row, 0, QTableWidgetItem(str(current)))
            else:
                break
        event.accept()
        self.editor.refresh()


class Editor(QMainWindow):
    def __init__(self, path, subnet):
        super().__init__()
        self.path = Path(path)
        self.subnet = ipaddress.IPv4Network(subnet, strict=False)
        self.setWindowTitle(f"Kea/CoreDNS Reservations Editor - {self.path}")
        self.resize(1000, 800)

        root = QWidget()
        layout = QVBoxLayout(root)
        filter_layout = QHBoxLayout()
        self.filter = QLineEdit(placeholderText="Search IP, MAC, or hostname...")
        self.filter.textChanged.connect(self.apply_filter)
        filter_layout.addWidget(QLabel("Filter:"))
        filter_layout.addWidget(self.filter)
        layout.addLayout(filter_layout)

        self.table = ReservationTable(self)
        self.table.setHorizontalHeaderLabels(["IP", "Hostname", "MAC"])
        self.table.setSelectionBehavior(QTableWidget.SelectRows)
        self.table.setEditTriggers(QTableWidget.DoubleClicked | QTableWidget.SelectedClicked)
        self.table.itemChanged.connect(self.refresh)
        layout.addWidget(self.table)

        controls = QHBoxLayout()
        for title, action in [("Add row", self.add_row), ("Remove selected", self.remove_rows), ("Load", self.choose_file), ("Save", self.save)]:
            button = QPushButton(title)
            button.clicked.connect(action)
            controls.addWidget(button)
        layout.addLayout(controls)
        self.usage = QLabel()
        self.validation = QLabel()
        layout.addWidget(self.usage)
        layout.addWidget(self.validation)
        self.setCentralWidget(root)
        self.load(self.path)

    def cell(self, row, column):
        item = self.table.item(row, column)
        return item.text().strip() if item else ""

    def load(self, path):
        self.path = Path(path)
        self.table.blockSignals(True)
        self.table.setRowCount(0)
        for reservation in load_reservations(self.path):
            row = self.table.rowCount()
            self.table.insertRow(row)
            for column, key in enumerate(("ip", "hostname", "mac")):
                value = reservation.get(key, "")
                self.table.setItem(row, column, QTableWidgetItem(normalize_mac(value) if key == "mac" else str(value).strip()))
        self.table.blockSignals(False)
        self.sort_rows()
        self.refresh()

    def choose_file(self):
        path, _ = QFileDialog.getOpenFileName(self, "Open reservations JSON", str(self.path), "JSON files (*.json)")
        if path:
            self.load(path)

    def rows(self):
        return [[self.cell(row, column) for column in range(3)] for row in range(self.table.rowCount())]

    def sort_rows(self):
        rows = self.rows()
        def order(row):
            try:
                return int(ipaddress.IPv4Address(row[0]))
            except ipaddress.AddressValueError:
                return -1
        self.table.blockSignals(True)
        self.table.setRowCount(0)
        for values in sorted(rows, key=order):
            row = self.table.rowCount()
            self.table.insertRow(row)
            for column, value in enumerate(values):
                self.table.setItem(row, column, QTableWidgetItem(value))
        self.table.blockSignals(False)
        self.table.resizeColumnsToContents()

    def errors(self):
        errors, ips, hosts, macs = [], set(), set(), set()
        for row, (ip, raw_host, raw_mac) in enumerate(self.rows(), start=1):
            host, mac = normalize_hostname(raw_host), normalize_mac(raw_mac)
            try:
                if ipaddress.IPv4Address(ip) not in self.subnet:
                    errors.append(f"Row {row}: IP '{ip}' is outside {self.subnet}")
            except ipaddress.AddressValueError:
                errors.append(f"Row {row}: invalid IP '{ip}'")
            if not valid_mac(mac):
                errors.append(f"Row {row}: invalid MAC '{mac}'")
            if not host:
                errors.append(f"Row {row}: hostname '{raw_host}' normalizes to empty")
            elif host in RESERVED_NAMES:
                errors.append(f"Row {row}: hostname '{host}' is reserved")
            elif len(host) > 63:
                errors.append(f"Row {row}: hostname '{host}' exceeds 63 characters")
            for label, value, seen in (("IP", ip, ips), ("hostname", host, hosts), ("MAC", mac, macs)):
                if value and value in seen:
                    errors.append(f"Row {row}: duplicate {label} '{value}'")
                seen.add(value)
        return errors

    def refresh(self):
        errors = self.errors()
        duplicates = set()
        for column, normalizer in ((0, lambda value: value), (1, normalize_hostname), (2, normalize_mac)):
            values = [normalizer(self.cell(row, column)) for row in range(self.table.rowCount())]
            duplicates.update((column, value) for value in values if value and values.count(value) > 1)
        for row in range(self.table.rowCount()):
            for column in range(3):
                item = self.table.item(row, column)
                if item:
                    duplicate = (column, (normalize_hostname if column == 1 else normalize_mac if column == 2 else lambda value: value)(item.text())) in duplicates
                    item.setBackground(QColor(255, 199, 206) if duplicate else QColor(255, 255, 255))
                    item.setForeground(QColor(156, 0, 6) if duplicate else QColor(0, 0, 0))
        used = {ipaddress.IPv4Address(ip) for ip, _, _ in self.rows() if self.is_subnet_ip(ip)}
        total = self.subnet.num_addresses - 2
        self.usage.setText(f"Subnet {self.subnet} usage: total {total}; used {len(used)}; free {total - len(used)}; {len(used) / total * 100 if total else 0:.1f}% used")
        self.validation.setText("Validation errors:\n" + "\n".join(errors) if errors else "No validation errors.")
        self.validation.setStyleSheet("color: red;" if errors else "color: green;")
        self.apply_filter()

    def is_subnet_ip(self, value):
        try:
            return ipaddress.IPv4Address(value) in self.subnet
        except ipaddress.AddressValueError:
            return False

    def apply_filter(self):
        needle = self.filter.text().lower().strip()
        for row in range(self.table.rowCount()):
            self.table.setRowHidden(row, bool(needle) and not any(needle in self.cell(row, column).lower() for column in range(3)))

    def add_row(self):
        row = self.table.rowCount()
        self.table.insertRow(row)
        for column in range(3):
            self.table.setItem(row, column, QTableWidgetItem(""))
        self.refresh()

    def remove_rows(self):
        for row in sorted((index.row() for index in self.table.selectionModel().selectedRows()), reverse=True):
            self.table.removeRow(row)
        self.refresh()

    def save(self):
        errors = self.errors()
        if errors:
            QMessageBox.critical(self, "Validation error", "Cannot save:\n" + "\n".join(errors))
            return
        self.sort_rows()
        payload = {"version": 1, "reservations": [{"ip": ip, "hostname": normalize_hostname(host), "mac": normalize_mac(mac)} for ip, host, mac in self.rows()]}
        try:
            self.path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        except OSError as error:
            QMessageBox.critical(self, "Save error", str(error))
            return
        self.refresh()
        QMessageBox.information(self, "Saved", "Reservations saved successfully.")


def main():
    parser = argparse.ArgumentParser(description="Kea/CoreDNS reservations editor")
    parser.add_argument("leases_json_path", nargs="?", default="./leases.json")
    parser.add_argument("--subnet", default="192.168.1.0/24")
    args = parser.parse_args()
    application = QApplication(sys.argv)
    window = Editor(args.leases_json_path, args.subnet)
    window.show()
    return application.exec_()


if __name__ == "__main__":
    raise SystemExit(main())
