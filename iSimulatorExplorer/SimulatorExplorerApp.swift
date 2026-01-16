//
//  SimulatorExplorerApp.swift
//  SimulatorExplorer
//
//  Created by Daniel Cerutti on 14.01.2026.
//

import SwiftUI

@main
struct SimulatorExplorerApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    var body: some Scene {
        Window("Simulator Explorer", id: "main") {
            SimulatorExplorerMainView()
            //SimulatorExplorerView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    class func showModalAlert (_ messageText : String, informativeText : String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.runModal()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
