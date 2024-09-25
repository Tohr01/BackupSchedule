//
// SidebarTableCellView.swift
// BackupSchedule
//
// Created by Tohr01 on 06.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Cocoa

class SidebarTableCellView: NSTableCellView, DefaultSidebarTableCellView {
    @IBOutlet var backgroundView: BackgroundView!
    @IBOutlet var runDaysTitle: NSTextField!
    @IBOutlet var runTime: NSTextField!
    @IBOutlet var deleteButton: DefaultButton!
    @IBOutlet var activityIndicator: NSImageView!
    

    var scheduleID: UUID?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        deleteButton.alphaValue = 0.6
    }
    
    func setActive() {
        activityIndicator.isHidden = false
    }
    func setInactive() {
        activityIndicator.isHidden = true
    }
    
}
