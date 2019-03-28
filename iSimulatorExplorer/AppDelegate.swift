//
//  AppDelegate.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 30.07.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet weak var window: NSWindow!

    
    class func showModalAlert (_ messageText : String, informativeText : String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.runModal()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        let xcodeVersion = XCodeSupport.getDeveloperToolsVersion()
        if xcodeVersion == nil || xcodeVersion!.compare("6.0", options: NSString.CompareOptions.numeric) == ComparisonResult.orderedAscending {
            
            AppDelegate.showModalAlert (
                NSLocalizedString("Error", comment: ""),
                informativeText: NSLocalizedString("Xcode 6 or above must be installed for iSimulatorExplorer to run.", comment: ""))
            NSApplication.shared.terminate(nil)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
 
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

