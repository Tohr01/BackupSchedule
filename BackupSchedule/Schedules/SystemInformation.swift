//
// SystemInformation.swift
// BackupSchedule
//
// Created by Tohr01 on 13.04.23
// Copyright © 2023 Tohr01. All rights reserved.
//


import Cocoa
import IOKit.ps

class SystemInformation {
    static func isInBatteryMode() -> Bool {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var deviceModel = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &deviceModel, &size, nil, 0)
        
        // Check if device is MacBook
        guard let device = String(cString: deviceModel, encoding: .utf8)?.lowercased(), device.contains("macbook") else {
           return false
        }
        
        let powerSources = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        
        let sources = IOPSCopyPowerSourcesList(powerSources).takeRetainedValue() as Array<AnyObject>
        
        for ps in sources {
            if let info = IOPSGetPowerSourceDescription(powerSources, ps).takeUnretainedValue() as? Dictionary<String, Any>, info[kIOPSIsPresentKey] as? Bool == true {
                if let powerSource = info[kIOPSPowerSourceStateKey] as? String {
                    if powerSource == kIOPSACPowerValue {
                        return false
                    }
                }
            }
        }
        return true
    }
}
