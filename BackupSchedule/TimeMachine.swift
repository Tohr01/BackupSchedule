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

struct TMDestination: Equatable, Hashable {
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
    }
    
    func isConfigured() throws -> Bool {
        do {
            if let destinationInfo = try tmutilRequest(args: "destinationinfo", "-X"),
               let destInfoData = destinationInfo.data(using: .utf8) {
                
                let destInfoDict = try PropertyListSerialization.propertyList(from: destInfoData, format: nil)
                if let destInfoDict = destInfoDict as? [String : Any] {
                    return !destInfoDict.isEmpty
                }
            }
        } catch {
            throw error
        }
        return false
    }
    
    func getLatestBackup() -> Date? {
        if let latestBackupStr = (try? tmutilRequest(args: "latestbackup")), let dateArr = groups(for: latestBackupStr, pattern: #"(\d{4})-(\d{2})-(\d{2})-\d*\.backup"#, capture_group: [2,3,1]) {
            let dateArrInt = dateArr.map({Int($0)}).compactMap({$0})
            if dateArrInt.count != 3 { return nil }
            var dateComp = DateComponents()
            dateComp.month = dateArrInt[0]
            dateComp.day = dateArrInt[1]
            dateComp.year = dateArrInt[2]
            return Calendar.current.date(from: dateComp)
        }
        return nil
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
    
    func getDestinations() throws -> [TMDestination]? {
        do {
            if let destinationInfo = try tmutilRequest(args: "destinationinfo", "-X"),
               let destInfoData = destinationInfo.data(using: .utf8) {
                
                let destInfoDict = try PropertyListSerialization.propertyList(from: destInfoData, format: nil)
                
                if let destInfoDict = destInfoDict as? [String : Any], let destinations = destInfoDict["Destinations"] as? [[String: Any]] {
                    return destinations.map{TMDestination(name: $0["Name"] as! String, id: $0["ID"] as! String, mounted: $0["MountPoint"] != nil)}
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
               let statusData = statusStr.data(using: .utf8) {
                
                let statusPlist = try PropertyListSerialization.propertyList(from: statusData, format: nil)
                if let statusDict = statusPlist as? [String : Any], let running = statusDict["Running"] as? Bool {
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
    
    func getBackupVolumeCount() throws -> Int? {
        do {
            if let destinationInfo = try tmutilRequest(args: "destinationinfo", "-X"),
               let destInfoData = destinationInfo.data(using: .utf8) {
                
                let destInfoDict = try PropertyListSerialization.propertyList(from: destInfoData, format: nil)
                if let destInfoDict = destInfoDict as? [String : Any], let destinations = destInfoDict["Destinations"] as? [[String: Any]] {
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
            if (data.count == 0) {
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
