//
// DiskSelection.swift
// BackupSchedule
//
// Created by Tohr01 on 10.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//


import Cocoa

class DiskSelection: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var diskSelectionTableView: NSTableView!
    
    var tmTargets: [TMDestination] = []
    var selectedDrive: TMDestination?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = .clear
        
        tmTargets = (try? AppDelegate.tm?.getDestinations()) ?? []
    }
    override func viewWillAppear() {
        guard let frameView = view.window?.contentView?.superview else {
            return
        }
        
        let backgroundView = NSView(frame: frameView.bounds)
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = .white // colour of your choice
        backgroundView.autoresizingMask = [.maxXMargin, .maxYMargin]
        
        frameView.addSubview(backgroundView, positioned: .below, relativeTo: frameView)

    }
}

// MARK: -
// MARK: TableView
extension DiskSelection {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tmTargets.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = diskSelectionTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("diskcell"), owner: self) as? DiskSelectionCell else {
            return nil
        }
        cell.driveTitle.stringValue = tmTargets[row].name
        if let selectedDrive = selectedDrive, selectedDrive == tmTargets[row] {
            cell.checkboxButton.setActive()
        } else {
            cell.checkboxButton.setInactive()
        }
        
        return cell
    }
}
