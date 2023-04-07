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
    @IBInspectable var hoverDarken: Bool = false
    
    var defaultBackgroundColor: NSColor!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        defaultBackgroundColor = backgroundColor.withAlphaComponent(alphaComponent)
        self.layer?.backgroundColor = defaultBackgroundColor.cgColor
        
        if hoverDarken {
            let trackingArea = NSTrackingArea(rect: self.bounds, options: [.activeInKeyWindow, .mouseEnteredAndExited], owner: self, userInfo: nil)
            self.addTrackingArea(trackingArea)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            self.animator().layer?.backgroundColor = defaultBackgroundColor.darken(by: 0.2).cgColor
        }
    }
    
    /// On mouse leaving
    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            self.animator().layer?.backgroundColor = defaultBackgroundColor.cgColor
        }
    }
    
}
