//
// CenterCell.swift
// BackupSchedule
//
// Created by Tohr01 on 12.08.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Cocoa

class CenterCell: NSTextFieldCell {
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        var newRect = super.drawingRect(forBounds: rect)
        let textSize = self.cellSize(forBounds: rect)
        let heightDelta = newRect.size.height - textSize.height
        if heightDelta > 0 {
            newRect.size.height -= heightDelta
            newRect.origin.y += (heightDelta / 2)
        }
        return newRect
    }
}
