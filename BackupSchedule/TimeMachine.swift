//
// TimeMachine.swift
// BackupScheduler
//
// Created by Tohr01 on 17.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Foundation

enum TimeMachineError: Error {
    case tmutilNonExistent
    case authError
    case tmutilRequestError
}

enum AppleScriptExecutionResult {
    case canceled
    case success
}

struct TMDestination: Codable, Equatable, Hashable {
    var name: String
    var id: String
    var mounted: Bool
}

class TimeMachine {
    private static var tmutilPath = "/usr/bin/tmutil"

    init() throws {
        // Check if tmutil binary exists
        let fm = FileManager()
        if !fm.fileExists(atPath: TimeMachine.tmutilPath) {
            throw TimeMachineError.tmutilNonExistent
        }
    }

    func isAutoBackupEnabled() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", "/Library/Preferences/com.apple.TimeMachine.plist", "AutoBackup"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines)

        if output == "1" {
            return true
        } else {
            return false
        }
    }

    @discardableResult
    func disableAutoBackup() throws -> AppleScriptExecutionResult {
        var err: NSDictionary?
        NSAppleScript(source: "do shell script \"/usr/bin/sudo /usr/bin/tmutil disable\" with administrator " +
            "privileges")!.executeAndReturnError(&err)
        if err == nil {
            return .success
        }
        return .canceled
    }

    func startBackup(destID: String? = nil) throws {
        do {
            if let destID = destID {
                try tmutilRequest(args: "startbackup -d \(destID)")
            } else {
                try tmutilRequest(args: "startbackup")
            }
        } catch {
            throw error
        }
        NotificationCenter.default.post(name: Notification.Name("startedbackup"), object: nil)
    }

    func stopBackup() throws {
        do {
            try tmutilRequest(args: "stopbackup")
        } catch {
            throw error
        }
    }

    func isConfigured() throws -> Bool {
        do {
            if let destinationInfo = try tmutilRequest(args: "destinationinfo", "-X"),
               let destInfoData = destinationInfo.data(using: .utf8)
            {
                let destInfoDict = try PropertyListSerialization.propertyList(from: destInfoData, format: nil)
                if let destInfoDict = destInfoDict as? [String: Any] {
                    return !destInfoDict.isEmpty
                }
            }
        } catch {
            throw error
        }
        return false
    }

    func getLatestKnownBackup() -> Date? {
        let savedDate = UserDefaults.standard.value(forKey: "latestBackup") as? Date
        if let lastBackupTM = getLatestBackup() {
            if let savedDate = savedDate, lastBackupTM < savedDate {
                return savedDate
            } else {
                UserDefaults.standard.set(lastBackupTM, forKey: "latestBackup")
                return lastBackupTM
            }
        } else if let savedDate = savedDate {
            return savedDate
        }
        
        return nil
    }
    
    func getLatestBackup() -> Date? {
    latestBackupCheck: if let latestBackupStr = (try? tmutilRequest(args: "latestbackup")), let dateArr = groups(for: latestBackupStr, pattern: #"(\d{4})-(\d{2})-(\d{2})-(\d{2})(\d{2})\d*\.backup"#, capture_group: [2, 3, 1, 4, 5]) {
            let dateArrInt = dateArr.map { Int($0) }.compactMap { $0 }
            if dateArrInt.count < 5 { break latestBackupCheck }
            var dateComp = DateComponents()
            dateComp.month = dateArrInt[0]
            dateComp.day = dateArrInt[1]
            dateComp.year = dateArrInt[2]
            dateComp.hour = dateArrInt[3]
            dateComp.minute = dateArrInt[4]
            return Calendar.current.date(from: dateComp)
        }
        return getLatestKnownBackup()
    }
    
    func getLatestBackupStr() -> String {
        if let latestBackup = getLatestBackup() {
            return "Last Backup: \(latestBackup.getLatestBackupString().capitalizeFirst)"
        }
        return "No latest Backup found"
    }

    func getPrimaryVolume() throws -> TMDestination? {
        do {
            if let destinations = try getDestinations() {
                return destinations.first
            }
        } catch {
            throw error
        }
        return nil
    }

    func isMounted(destination: TMDestination? = nil) -> Bool {
        do {
            if let destinationInfo = try tmutilRequest(args: "destinationinfo", "-X"),
               let destInfoData = destinationInfo.data(using: .utf8)
            {
                let destInfoDict = try PropertyListSerialization.propertyList(from: destInfoData, format: nil)

                if let destInfoDict = destInfoDict as? [String: Any], let destinations = destInfoDict["Destinations"] as? [[String: Any]] {
                    if let destination = destination {
                        if let destDict = destinations.filter({$0["ID"] as! String == destination.id}).first {
                            return destDict["MountPoint"] != nil
                        }
                    } else {
                        return !destinations.filter({$0["MountPoint"] != nil}).isEmpty
                    }
                }
            }
        } catch {
            return false
        }
        return false
    }
    
    func getDestinations() throws -> [TMDestination]? {
        do {
            if let destinationInfo = try tmutilRequest(args: "destinationinfo", "-X"),
               let destInfoData = destinationInfo.data(using: .utf8)
            {
                let destInfoDict = try PropertyListSerialization.propertyList(from: destInfoData, format: nil)

                if let destInfoDict = destInfoDict as? [String: Any], let destinations = destInfoDict["Destinations"] as? [[String: Any]] {
                    return destinations.map { TMDestination(name: $0["Name"] as! String, id: $0["ID"] as! String, mounted: $0["MountPoint"] != nil) }
                }
            }
        } catch {
            throw error
        }
        return nil
    }

    func isBackupRunning() throws -> Bool {
        do {
            if let statusStr = try tmutilRequest(args: "status", "-X"),
               let statusData = statusStr.data(using: .utf8)
            {
                let statusPlist = try PropertyListSerialization.propertyList(from: statusData, format: nil)
                if let statusDict = statusPlist as? [String: Any], let running = statusDict["Running"] as? Bool {
                    return running
                } else {
                    return false
                }
            }
        } catch {
            throw error
        }
        return false
    }

    func getBackupProgess() throws -> Float? {
        do {
            if let progressStr = try tmutilRequest(args: "status", "-X"), let progressData = progressStr.data(using: .utf8) {
                print(progressStr)
                let progressPlist = try PropertyListSerialization.propertyList(from: progressData, format: nil)
                if let statusDict = progressPlist as? [String: Any], let progressDict = statusDict["Progress"] as? [String: Any], let percent = progressDict["Percent"] as? Double {
                    return Float(percent)
                }
            }
            return nil
        } catch {
            throw error
        }
    }

    func getBackupVolumeCount() throws -> Int? {
        do {
            if let destinationInfo = try tmutilRequest(args: "destinationinfo", "-X"),
               let destInfoData = destinationInfo.data(using: .utf8)
            {
                let destInfoDict = try PropertyListSerialization.propertyList(from: destInfoData, format: nil)
                if let destInfoDict = destInfoDict as? [String: Any], let destinations = destInfoDict["Destinations"] as? [[String: Any]] {
                    return destinations.count
                }
            }
        } catch {
            throw error
        }
        return nil
    }

    @discardableResult
    private func tmutilRequest(args: String...) throws -> String? {
        let process = Process()
        if #available(macOS 10.13, *) {
            process.executableURL = URL(fileURLWithPath: TimeMachine.tmutilPath)
        } else {
            // Fallback on earlier versions
            process.launchPath = TimeMachine.tmutilPath
        }
        process.arguments = Array(args)

        let pipe = Pipe()
        process.standardOutput = pipe

        if #available(macOS 10.13, *) {
            do {
                try process.run()
            } catch {
                throw TimeMachineError.tmutilRequestError
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
        return output
    }
}
