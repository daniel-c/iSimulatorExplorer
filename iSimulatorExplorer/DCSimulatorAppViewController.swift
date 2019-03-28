//
//  DCSimulatorAppViewController.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 10.10.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

import Cocoa

class DCSimulatorAppViewController: DCSimulatorViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var appTableView: NSTableView!
    @IBOutlet weak var installAppButton: NSButton!
    @IBOutlet weak var uninstallAppButton: NSButton!
    var isBusy : Bool = false
    
    var simulatorAppList : [SimulatorApp]?
    
    override var simulator : Simulator? {
        didSet {
            simulatorAppList = simulator!.getAppList()
            appTableView.reloadData()
            enableButtons()
        }
    }
    
    override func loadView() {
        super.loadView()
        enableButtons()
    }
    
    func enableButtons() {
        let enableActionOnSelected = (appTableView.selectedRow >= 0 && simulatorAppList != nil && simulatorAppList!.count > 0)
        uninstallAppButton.isEnabled = enableActionOnSelected && !isBusy
        installAppButton.isEnabled = !isBusy
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        if simulatorAppList != nil {
            return (simulatorAppList!.count > 0) ? simulatorAppList!.count : 1
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if simulatorAppList != nil && simulatorAppList!.count == 0 {
            return tableView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier("NoAppCell"), owner: self) as? NSTableCellView
        }
        if let result = tableView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier("DataCell"), owner: self) as? DCAppInfoTableCellView {
            if let appInfo = simulatorAppList?[row] {
                //result.textField!.stringValue = appInfo.displayName!
                result.appInfo = appInfo
            }
            return result
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        enableButtons()
    }

    
    @IBAction func openAppDataInFinderPressed(_ sender: NSButton) {
        if let appInfoCellView = sender.superview as? DCAppInfoTableCellView {
            if let path = appInfoCellView.appInfo?.dataPath {
                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: path)
            }
        }
    }
    
    @IBAction func openAppBundleInFinderPressed(_ sender: NSButton) {
        if let appInfoCellView = sender.superview as? DCAppInfoTableCellView {
            if let path = appInfoCellView.appInfo?.path {
                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: path)
            }
        }
    }
    
    @IBAction func installApp(_ sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal().rawValue == NSFileHandlingPanelOKButton {
            for url in openPanel.urls {
                isBusy = true
                enableButtons()
                simulator!.installApp(url, completionHandler: { (error) -> Void in
                    self.isBusy = false
                    self.enableButtons()
                    if error != nil {
                        AppDelegate.showModalAlert(
                            NSLocalizedString("Error installing app \(url)", comment: ""),
                            informativeText: "Error details: \(error!)")
                        print("Install app \(url) error: \(error!)", terminator:"\n")
                    }
                    else {
                        print("Install app \(url) successful", terminator:"\n")
                        self.simulatorAppList = self.simulator!.getAppList()
                        self.appTableView.reloadData()
                    }
                })
            }
        }
    }
    
    @IBAction func uninstallApp(_ sender: AnyObject) {
        if appTableView.selectedRow >= 0 {
            if let appId = simulatorAppList![appTableView.selectedRow].identifier {
            
                isBusy = true
                enableButtons()
                simulator!.uninstallApp(appId, completionHandler: { (error) -> Void in
                    self.isBusy = false
                    self.enableButtons()
                    if error != nil {

                        AppDelegate.showModalAlert(
                            NSLocalizedString("Error uninstalling app \(appId)", comment: ""),
                            informativeText: "Error details: \(error!)")
                    }
                    else {
                        print("Uninstall app \(appId) successful", terminator:"\n")
                        self.simulatorAppList = self.simulator!.getAppList()
                        self.appTableView.reloadData()
                    }
                })
            }
            
        }
    }
    

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSUserInterfaceItemIdentifier(_ input: String) -> NSUserInterfaceItemIdentifier {
	return NSUserInterfaceItemIdentifier(rawValue: input)
}
