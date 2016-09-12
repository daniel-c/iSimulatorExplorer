//
//  DCSimulatorInfoViewController.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 12.10.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

import Cocoa

struct DCInfoViewItem {
    var name : String
    var value : String
}

class DCSimulatorInfoViewController: DCSimulatorViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var infoTableView: NSTableView!

    private var infoItems = [DCInfoViewItem]()
    override var simulator : Simulator? {
        didSet {
            infoItems = [DCInfoViewItem]()
            let empty = ""
            infoItems.append(DCInfoViewItem(name: NSLocalizedString("Name:", comment: ""), value: simulator!.name ?? empty))
            if simulator!.deviceName != nil {
                infoItems.append(DCInfoViewItem(name: NSLocalizedString("Simulated Model:", comment: ""), value: simulator!.deviceName!))
            }
            infoItems.append(DCInfoViewItem(name: NSLocalizedString("Version:", comment: ""), value: "\(simulator!.version ?? empty) - \(simulator!.build ?? empty)"))
            if simulator!.UDID != nil {
                infoItems.append(DCInfoViewItem(name: NSLocalizedString("UDID:", comment: ""), value: simulator!.UDID!.uuidString))
            }
            infoItems.append(DCInfoViewItem(name: NSLocalizedString("Path:", comment: ""), value: (simulator!.path as NSString?)?.abbreviatingWithTildeInPath ?? empty))
            if simulator!.stateString != nil {
                infoItems.append(DCInfoViewItem(name: NSLocalizedString("State:", comment: ""), value: simulator!.stateString!))
            }
            infoTableView.reloadData()
        }
    }
    
    override func viewDidAppear() {
        // ViewController lifecycle methods are only available with OS X 10.10 and above
    }
    
    override func viewDidDisappear() {
        // ViewController lifecycle methods are only available with OS X 10.10 and above
    }
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        if simulator != nil {
            return infoItems.count
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        if tableColumn?.identifier == "NameColumn" {
            return infoItems[row].name
        } else if tableColumn?.identifier == "ValueColumn" {
            return infoItems[row].value
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
    
    @IBAction func showInFinderPressed(_ sender: NSButton) {
        if simulator != nil {
            NSWorkspace.shared().selectFile(simulator!.path!, inFileViewerRootedAtPath: simulator!.path!)
        }
    }
    
    @IBAction func openSimulatorPressed(_ sender: NSButton) {
        if simulator != nil {
            simulator?.launchSimulatorApp()
        }
    }
}
