//
// DriveUtil.swift
// BackupSchedule
//
// Created by Tohr01 on 02.11.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Foundation

func getRootDrivePath() -> String {
    let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeIsRootFileSystemKey])

    if let volumes = volumes {
        for volume in volumes {
            do {
                let attr = try volume.resourceValues(forKeys: [.volumeIsRootFileSystemKey])

                if let rootFS = attr.volumeIsRootFileSystem, rootFS {
                    return volume.absoluteString.replacingOccurrences(of: "file://", with: "")
                }
            } catch {
                continue
            }
        }
    }

    #warning("potential remove")
    return "/"
}
