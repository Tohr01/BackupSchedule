//
// BackgroundView.swift
// BackupSchedule
//
// Created by Tohr01 on 19.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Cocoa

class BackgroundView: NSView {
    @IBInspectable var alphaComponent: CGFloat = 0.07
    @IBInspectable var backgroundColor: NSColor = .quaternaryLabelColor
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        self.layer?.backgroundColor = backgroundColor.withAlphaComponent(alphaComponent).cgColor
    }
    
}
