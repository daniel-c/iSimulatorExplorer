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
        if let developerDir = NSProcessInfo.processInfo().environment["DEVELOPER_DIR"] as? String {
            return developerDir
        }
        var error : NSError?
        if let symDir = NSFileManager.defaultManager().destinationOfSymbolicLinkAtPath("/var/db/xcode_select_link", error: &error) {
            return symDir
        }
        let defaultDir = "/Applications/Xcode.app/Contents/Developer"
        if NSFileManager.defaultManager().fileExistsAtPath(defaultDir) {
            return defaultDir
        }
        return nil
    }
    
    class func getDeveloperToolsVersion() -> String? {
        if let developerDir = getDeveloperToolsPath() {
            let fm = NSFileManager.defaultManager()
            let versionPlist = developerDir.stringByAppendingPathComponent("../version.plist")
            if fm.fileExistsAtPath(versionPlist) {
                let versionPlistData = NSFileManager.defaultManager().contentsAtPath(versionPlist)!
                var error : NSError?
                let plistobj: AnyObject? = NSPropertyListSerialization.propertyListWithData(versionPlistData,
                    options: 0,
                    format: nil,
                    error: &error)
                if let plist = plistobj as? Dictionary<String, AnyObject> {
                    return plist["CFBundleShortVersionString"] as? String
                }
                else if error != nil {
                    NSLog("Error reading developer tools version: %@", error!)
                }
            }
        }
        return nil;
    }
}