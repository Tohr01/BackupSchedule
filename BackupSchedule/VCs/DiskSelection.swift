//
// DiskSelection.swift
// BackupSchedule
//
// Created by Tohr01 on 10.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Cocoa

class DiskSelection: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet var diskSelectionTableView: NSTableView!

    var tmTargets: [TMDestination] = []
    var selectedDrive: TMDestination?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = .clear
        print(selectedDrive)
        configureTableView()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "selectedDestDrive"), object: selectedDrive)
    }
}

// MARK: -

// MARK: TableView

extension DiskSelection {
    func configureTableView() {
        diskSelectionTableView.allowsMultipleSelection = false
        diskSelectionTableView.selectionHighlightStyle = .none
    }

    func numberOfRows(in _: NSTableView) -> Int {
        tmTargets.count
    }

    func tableView(_: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = diskSelectionTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("diskcell"), owner: self) as? DiskSelectionCell else {
            return nil
        }
        cell.driveTitle.stringValue = tmTargets[row].name
        if selectedDrive == tmTargets[row] {
            cell.setIndicatorActive()
        } else {
            cell.setIndicatorInactive()
        }
        return cell
    }

    func tableViewSelectionDidChange(_: Notification) {
        let selectedRow = diskSelectionTableView.selectedRow
        guard selectedRow >= 0 else { return }
        selectedDrive = tmTargets[selectedRow]
        for row in 0 ..< diskSelectionTableView.numberOfRows {
            if row == selectedRow, let cell = diskSelectionTableView.view(atColumn: 0, row: selectedRow, makeIfNecessary: false) as? DiskSelectionCell {
                print(row)
                cell.setIndicatorActive()
            } else {
                if let cell = diskSelectionTableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? DiskSelectionCell {
                    cell.setIndicatorInactive()
                }
            }
        }
    }
}
