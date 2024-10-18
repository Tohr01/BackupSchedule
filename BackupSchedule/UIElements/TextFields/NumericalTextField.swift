//
// NumericalTextField.swift
// BackupSchedule
//
// Created by Tohr01 on 07.08.24
// Copyright © 2024 Tohr01. All rights reserved.
//

import Cocoa

class NumericalTextField: NSTextField {
    @IBInspectable var enableLower: Bool = true
    @IBInspectable var lowerBound: Int = 0
    @IBInspectable var enableUpper: Bool = true
    @IBInspectable var upperBound: Int = 60
    @IBInspectable var defaultString: String = "00"
    @IBInspectable var shouldDisplayAlert: Bool = true
    @IBInspectable var shouldResetContents: Bool = true

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        if !isValid() {
            if shouldDisplayAlert {
                displayAlert()
            }
            if shouldResetContents {
                resetToDefault()
            }
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == .keyDown, event.keyCode == 48 { // 48 is the key code for Tab
            window?.selectNextKeyView(self)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    func displayAlert() {
        var alertMessage: String
        if !(enableLower || enableUpper) {
            alertMessage = "Please input a valid number."
        } else if enableLower, !enableUpper {
            alertMessage = "The number has to be bigger or equal than \(lowerBound)"
        } else if !enableLower, enableUpper {
            alertMessage = "The number has to be lower or equal than \(upperBound)"
        } else {
            alertMessage = "The number has to be between \(lowerBound) and \(upperBound)"
        }
        window?.defaultAlert(message: alertMessage)
    }

    func resetToDefault() {
        stringValue = defaultString
    }

    func isValid() -> Bool {
        let num = Int(stringValue)
        if num == nil || (enableLower && num! < lowerBound) || (enableUpper && upperBound < num!) {
            return false
        }
        return true
    }

    func getInt() -> Int {
        if !isValid() { return lowerBound }
        return Int(stringValue)!
    }
}

private class OnlyIntegerValFormatter: NumberFormatter {
    override func isPartialStringValid(_ partialString: String, newEditingString _: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if partialString.isEmpty { return true }
        return Int(partialString) != nil
    }
}
