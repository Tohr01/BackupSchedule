//
// CenterCell.swift
// BackupSchedule
//
// Created by Tohr01 on 27.05.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Cocoa

class CenterCell: NSTextFieldCell {
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        let newRect = NSRect(x: 0, y: (rect.size.height-20)/2, width: rect.size.width, height: 20)
        return super.drawingRect(forBounds: newRect)
    }
}
