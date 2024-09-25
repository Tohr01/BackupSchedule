//
// AddScheduleCellView.swift
// BackupSchedule
//
// Created by Tohr01 on 07.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Cocoa

class AddScheduleCellView: NSTableCellView, DefaultSidebarTableCellView {
    @IBOutlet var backgroundView: BackgroundView!
    @IBOutlet var activityIndicator: ScheduleSelectionIndicator!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        backgroundView.layer?.backgroundColor = .white
        backgroundView.layer?.cornerRadius = 7
        
    }
    
    func setActive() {
        activityIndicator.isHidden = false
    }
    func setInactive() {
        activityIndicator.isHidden = true
    }
    
}
