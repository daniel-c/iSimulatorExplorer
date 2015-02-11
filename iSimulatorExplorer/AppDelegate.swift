//
//  AppDelegate.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 30.07.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
        
        if XCodeSupport.getDeveloperToolsPath() == nil {
            var alert = NSAlert()
            alert.messageText = NSLocalizedString("Error", comment: "")
            alert.informativeText = NSLocalizedString("Xcode must be installed for iSimulatorExplorer to run", comment: "")
            alert.runModal()
            NSApplication.sharedApplication().terminate(nil)
        }
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }
 
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}

