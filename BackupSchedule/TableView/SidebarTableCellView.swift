//
// SidebarTableCellView.swift
// BackupSchedule
//
// Created by Tohr01 on 06.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Cocoa

class SidebarTableCellView: NSTableCellView {

    @IBOutlet var backgroundView: NSView!
    @IBOutlet var runDaysTitle: NSTextField!
    @IBOutlet var runTime: NSTextField!
    @IBOutlet var deleteButton: NSImageView!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        deleteButton.alphaValue = 0.6
        
        backgroundView.layer?.cornerRadius = 7
        backgroundView.layer?.backgroundColor = .white
    }
    
}
