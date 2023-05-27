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
    @IBInspectable var cornerRadius: CGFloat = 0.0
    @IBInspectable var onlyVisibleOnHover: Bool = false

    @IBInspectable var dropShadow: Bool = false
    @IBInspectable var shadowOffset: CGSize = .init(width: 0, height: 0)
    @IBInspectable var shadowOpacity: Float = 0.1

    @IBInspectable var darkenModifier: CGFloat = 0.2
    @IBInspectable var alphaAddDarkenModifier: CGFloat = 0.1

    var defaultBackgroundColor: NSColor!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        wantsLayer = true

        if dropShadow {
            layer?.masksToBounds = false
            layer?.shadowColor = .black
            layer?.shadowOffset = shadowOffset
            layer?.shadowRadius = 5
            layer?.shadowOpacity = shadowOpacity
        }

        defaultBackgroundColor = backgroundColor.withAlphaComponent(alphaComponent)

        layer?.backgroundColor = onlyVisibleOnHover ? .clear : defaultBackgroundColor.cgColor
        layer?.cornerRadius = cornerRadius

        if hoverDarken {
            let trackingArea = NSTrackingArea(rect: bounds, options: [.activeInKeyWindow, .mouseEnteredAndExited], owner: self, userInfo: nil)
            addTrackingArea(trackingArea)
        }
    }

    /// On mouse Enter
    override func mouseEntered(with _: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            self.animator().layer?.backgroundColor = defaultBackgroundColor.darken(by: darkenModifier, addAlphaWhenZero: alphaAddDarkenModifier).cgColor
        }
    }

    /// On mouse leaving
    override func mouseExited(with _: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            self.animator().layer?.backgroundColor = onlyVisibleOnHover ? .clear : defaultBackgroundColor.cgColor
        }
    }
}
