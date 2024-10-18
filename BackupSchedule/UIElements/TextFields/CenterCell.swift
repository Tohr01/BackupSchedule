//
// CenterCell.swift
// BackupSchedule
//
// See https://stackoverflow.com/a/45492039
//

import Cocoa

class CenterCell: NSTextFieldCell {
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        var newRect = super.drawingRect(forBounds: rect)
        let textSize = cellSize(forBounds: rect)
        let heightDelta = newRect.size.height - textSize.height
        if heightDelta > 0 {
            newRect.size.height -= heightDelta
            newRect.origin.y += (heightDelta / 2)
        }
        return newRect
    }
}
