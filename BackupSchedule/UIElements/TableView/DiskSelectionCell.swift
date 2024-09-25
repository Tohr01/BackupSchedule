//
// DiskSelectionCell.swift
// BackupSchedule
//
// Created by Tohr01 on 10.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Cocoa

class DiskSelectionCell: NSTableCellView {
    @IBOutlet var driveTitle: NSTextField!
    @IBOutlet var indicatorView: NSView!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        layer?.cornerRadius = 7
        layer?.masksToBounds = true

        indicatorView.layer?.cornerRadius = indicatorView.frame.size.width / 2
        indicatorView.layer?.backgroundColor = NSColor(named: "defaultColor")?.cgColor
    }

    func setIndicatorActive() {
        indicatorView.alphaValue = 1
        setNeedsDisplay(bounds)
    }

    func setIndicatorInactive() {
        indicatorView.alphaValue = 0.0
        setNeedsDisplay(bounds)
    }
}
