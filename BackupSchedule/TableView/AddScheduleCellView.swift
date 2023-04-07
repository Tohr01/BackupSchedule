//
// AddScheduleCellView.swift
// BackupSchedule
//
// Created by Tohr01 on 07.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Cocoa

class AddScheduleCellView: NSTableCellView {

    @IBOutlet var backgroundView: BackgroundView!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        backgroundView.layer?.backgroundColor = .white
        backgroundView.layer?.cornerRadius = 7
        // Drawing code here.
    }
    
}
