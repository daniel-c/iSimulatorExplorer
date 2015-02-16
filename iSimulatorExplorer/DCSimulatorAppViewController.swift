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
            simulatorAppList = simulator!.getAppList()?
            appTableView.reloadData()
            enableButtons()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func loadView() {
        super.loadView()
        enableButtons()
    }
    
    func enableButtons() {
        let enableActionOnSelected = (appTableView.selectedRow >= 0 && simulatorAppList != nil && simulatorAppList!.count > 0)
        uninstallAppButton.enabled = enableActionOnSelected && !isBusy
        installAppButton.enabled = !isBusy
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        
        if simulatorAppList != nil {
            return (simulatorAppList!.count > 0) ? simulatorAppList!.count : 1
        }
        return 0
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if simulatorAppList != nil && simulatorAppList!.count == 0 {
            return tableView.makeViewWithIdentifier("NoAppCell", owner: self) as? NSTableCellView
        }
        if let result = tableView.makeViewWithIdentifier("DataCell", owner: self) as? DCAppInfoTableCellView {
            if let appInfo = simulatorAppList?[row] {
                //result.textField!.stringValue = appInfo.displayName!
                result.appInfo = appInfo
            }
            return result
        }
        return nil
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return nil
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        enableButtons()
    }

    
    @IBAction func openAppDataInFinderPressed(sender: NSButton) {
        if let appInfoCellView = sender.superview as? DCAppInfoTableCellView {
            if let path = appInfoCellView.appInfo?.dataPath? {
                NSWorkspace.sharedWorkspace().selectFile(path, inFileViewerRootedAtPath: path)
            }
        }
    }
    
    @IBAction func openAppBundleInFinderPressed(sender: NSButton) {
        if let appInfoCellView = sender.superview as? DCAppInfoTableCellView {
            if let path = appInfoCellView.appInfo?.path? {
                NSWorkspace.sharedWorkspace().selectFile(path, inFileViewerRootedAtPath: path)
            }
        }
    }
    
    @IBAction func installApp(sender: AnyObject) {
        var openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == NSFileHandlingPanelOKButton {
            if let urls = openPanel.URLs as? [NSURL] {
                for url in urls {
                    isBusy = true
                    enableButtons()
                    simulator!.installApp(url, completionHandler: { (error) -> Void in
                        self.isBusy = false
                        self.enableButtons()
                        if error != nil {
                            AppDelegate.showModalAlert(
                                NSLocalizedString("Error installing app \(url)", comment: ""),
                                informativeText: "Error details: \(error)")
                            println("Install app \(url) error: \(error!)")
                        }
                        else {
                            println("Install app \(url) successful")
                            self.simulatorAppList = self.simulator!.getAppList()?
                            self.appTableView.reloadData()
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func uninstallApp(sender: AnyObject) {
        if appTableView.selectedRow >= 0 {
            if let appId = simulatorAppList![appTableView.selectedRow].identifier? {
            
                isBusy = true
                enableButtons()
                simulator!.uninstallApp(appId, completionHandler: { (error) -> Void in
                    self.isBusy = false
                    self.enableButtons()
                    if error != nil {

                        AppDelegate.showModalAlert(
                            NSLocalizedString("Error uninstalling app \(appId)", comment: ""),
                            informativeText: "Error details: \(error)")
                    }
                    else {
                        println("Uninstall app \(appId) successful")
                        self.simulatorAppList = self.simulator!.getAppList()?
                        self.appTableView.reloadData()
                    }
                })
            }
            
        }
    }
    

}
