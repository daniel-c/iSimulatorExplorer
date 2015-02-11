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
    var simulatorAppList : [SimulatorApp]?
    
    override var simulator : Simulator? {
        didSet {
            simulatorAppList = simulator!.getAppList()?
            appTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
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
    
    
}
