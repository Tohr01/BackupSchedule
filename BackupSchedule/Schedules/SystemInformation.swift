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
    static func isUnderHighLoad() -> Bool {
        let process = Process()
        let topBinaryUrl = "/usr/bin/top"
        if #available(macOS 10.13, *) {
            process.executableURL = URL(fileURLWithPath: topBinaryUrl)
        } else {
            // Fallback on earlier versions
            process.launchPath = topBinaryUrl
        }
        process.arguments = ["-l", "1", "-s", "0"]

        let pipe = Pipe()
        process.standardOutput = pipe

        if #available(macOS 10.13, *) {
            do {
                try process.run()
            } catch {
                return false
            }
        } else {
            process.launch()
        }

        var output: String?

        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if data.count == 0 {
                return
            }

            if let str = String(bytes: data, encoding: .utf8) {
                if output == nil {
                    output = ""
                }
                output?.append(str)
            }
        }
        process.waitUntilExit()
        guard let output = output else {
            return false
        }
        if let cpuUsage = groups(for: output, pattern: #"CPU usage: (\d+(\.\d+)?)%"#, capture_group: [1])?.first, let cpuUsageFloat = Float(cpuUsage) {
            return cpuUsageFloat >= 80
        }
        return false
    }

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

        let sources = IOPSCopyPowerSourcesList(powerSources).takeRetainedValue() as [AnyObject]

        for ps in sources {
            if let info = IOPSGetPowerSourceDescription(powerSources, ps).takeUnretainedValue() as? [String: Any], info[kIOPSIsPresentKey] as? Bool == true {
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
