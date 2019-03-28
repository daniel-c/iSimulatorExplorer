//
//  DCAppInfoTableCellView.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 07.10.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

import Cocoa

class DCAppInfoTableCellView: NSTableCellView {
    
    @IBOutlet weak var appNameTextField: NSTextField!
    @IBOutlet weak var appDetailTextField: NSTextField!
    
    var _appInfo : SimulatorApp!
    
    var appInfo : SimulatorApp! {
        get {
            return _appInfo
        }
        set(appInfo) {
            _appInfo = appInfo
            
            if appNameTextField == nil {
                appNameTextField = viewWithTag(1) as? NSTextField
            }
            if appDetailTextField == nil {
                appDetailTextField = viewWithTag(2) as? NSTextField
            }
            
            if appNameTextField != nil {
                if appInfo!.displayName != nil {
                    appNameTextField!.stringValue = appInfo!.displayName!
                }
                else {
                    appNameTextField!.stringValue = appInfo!.bundleName!
                }
            }
            //self.textField!.stringValue = appInfo!.displayName!
            if appDetailTextField != nil {
                appDetailTextField!.stringValue = appInfo!.identifier!
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    @IBAction func openAppBundleInFinderButtonPressed(_ sender: NSButton) {
        if let path = appInfo?.path {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: path)
        }
    }
    
    @IBAction func openAppDataInFinderButtonPressed(_ sender: NSButton) {
        if let path = appInfo?.dataPath {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: path)
        }
    }
}
