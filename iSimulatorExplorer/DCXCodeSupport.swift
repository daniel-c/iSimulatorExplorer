//
//  DCXCodeSupport.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 06.10.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.

import Foundation

class XCodeSupport {
    class func getDeveloperToolsPath() -> String? {
        if let developerDir = ProcessInfo.processInfo.environment["DEVELOPER_DIR"] {
            return developerDir
        }
        if let symDir = try? FileManager.default.destinationOfSymbolicLink(atPath: "/var/db/xcode_select_link") {
            return symDir
        }
        let defaultDir = "/Applications/Xcode.app/Contents/Developer"
        if FileManager.default.fileExists(atPath: defaultDir) {
            return defaultDir
        }
        return nil
    }
    
    class func getDeveloperToolsVersion() -> String? {
        if let developerDir = getDeveloperToolsPath() {
            let fm = FileManager.default
            let versionPlist = (developerDir as NSString).appendingPathComponent("../version.plist")
            if fm.fileExists(atPath: versionPlist) {
                let versionPlistData = FileManager.default.contents(atPath: versionPlist)!
                do {
                    let plistobj: AnyObject? = try PropertyListSerialization.propertyList(from: versionPlistData,
                        options: PropertyListSerialization.ReadOptions(rawValue: 0),
                        format: nil) as AnyObject?
                    if let plist = plistobj as? Dictionary<String, AnyObject> {
                        return plist["CFBundleShortVersionString"] as? String
                    }
                }
                catch let error as NSError {
                    NSLog("Error reading developer tools version: %@", error)
                }
            }
        }
        return nil;
    }
}
