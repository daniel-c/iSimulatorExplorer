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

    
    class func showModalAlert (messageText : String, informativeText : String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.runModal()
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        let xcodeVersion = XCodeSupport.getDeveloperToolsVersion()
        if xcodeVersion == nil || xcodeVersion!.compare("6.0", options: NSStringCompareOptions.NumericSearch) == NSComparisonResult.OrderedAscending {
            
            AppDelegate.showModalAlert (
                NSLocalizedString("Error", comment: ""),
                informativeText: NSLocalizedString("Xcode 6 or above must be installed for iSimulatorExplorer to run.", comment: ""))
            NSApplication.sharedApplication().terminate(nil)
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
 
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}

