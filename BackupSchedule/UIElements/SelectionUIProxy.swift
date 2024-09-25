//
// SelectionUIProxy.swift
// BackupSchedule
//
// Created by Tohr01 on 11.08.24
// Copyright © 2024 Tohr01. All rights reserved.
//
        

import Cocoa

class SelectionUIProxy: NSObject {
    // Action
    var onClick: () -> Void
    
    // UI Elements
    var checkbox: DefaultButton // toggleButtonOnly must be set to false
    var toggleLabels: [ToggleTextField]
    var textField: NSTextField?
    
    // Current state
    var active: Bool
    
    init(onClick: @escaping () -> Void, checkbox: DefaultButton, toggleLabels: [ToggleTextField], textField: NSTextField? = nil, active: Bool = false) {
        self.onClick = onClick
        self.checkbox = checkbox
        self.toggleLabels = toggleLabels
        self.textField = textField
        self.active = active
        super.init()
        
        setUIStates()
        
        // Set selectors
        let runActionSelector = #selector(runAction(_:))
        checkbox.target = self
        checkbox.action = runActionSelector
        _ = toggleLabels.map{$0.addClickGestureRecognizer(target: self, selector: runActionSelector)}
    }
    
    func setActive() {
        active = true
        checkbox.setActive()
        setUIStates()
    }
    
    func setInactive() {
        active = false
        checkbox.setInactive()
        setUIStates()
    }
    
    @objc func runAction(_ sender: Any) {
        active.toggle()
        setUIStates()
        onClick()
    }
    
    private func setUIStates() {
        active ? checkbox.setActive() : checkbox.setInactive()
        _ = toggleLabels.map{active ? $0.setActive() : $0.setInactive()}
        textField?.alphaValue = active ? 1 : 0.5
        textField?.isEnabled = active
    }
}
