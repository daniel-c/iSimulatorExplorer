//
//  DCSimulatorExplorerController.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 15.08.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

import Cocoa

class SimulatorVersion {
    var version : String
    var simulators : [Simulator]
    
    init(version : String, simulators : [Simulator]) {
        self.version = version
        self.simulators = simulators
    }
    
}

// Cannot use protocol because to support downcasting it must be marked as @objc which limits the types we can use.
//protocol SimulatorController {
//    var simulator : Simulator? { get set }
//}
    
class DCSimulatorViewController: NSViewController {
    var simulator : Simulator? // {
}

class DCSimulatorExplorerController: NSObject, NSWindowDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource, NSTabViewDelegate {

    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var tabView: NSTabView!
    
    var simulatorManager : DCSimulatorManager?
    
    
    var _simulators : [SimulatorVersion]?
    var simulatorVersions : [SimulatorVersion]  {
        get {
            if _simulators == nil {
                _simulators = [SimulatorVersion]()
                
                var firstInit = (simulatorManager == nil)
                if firstInit {
                    simulatorManager = DCSimulatorManager()
                }
                
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), { () -> Void in
                    
                    var simulatorsByVersion = [String : [Simulator]]()
                    for sim in self.simulatorManager!.simulators {
                        if simulatorsByVersion[sim.version!] == nil {
                            var simulators = [Simulator]()
                            simulatorsByVersion[sim.version!] = simulators
                        }
                        simulatorsByVersion[sim.version!]?.append(sim)
                        
                    }
                    var sortedKeys = simulatorsByVersion.keys.array
                    sortedKeys.sort({ (s1, s2) -> Bool in
                        return s2 > s1
                    })
                    var simulatorVersions = [SimulatorVersion]()
                    for key in sortedKeys {
                        let sims = simulatorsByVersion[key]!
                        simulatorVersions.append(SimulatorVersion(version: key, simulators: sims))
                        
                    }
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self._simulators = simulatorVersions
                        self.outlineView.reloadData()
                        self.initView(firstInit)
                    })
                })
                
            }
            return _simulators!
        }
    }

    
    func initView(firstInit : Bool) {
        initTabViewItem(tabView.selectedTabViewItem)
        outlineView.expandItem(nil, expandChildren: true)
        if (_simulators != nil) {
            if let sim = simulatorVersions.first?.simulators.first? {
                let row = outlineView.rowForItem(sim)
                if row >= 0 {
                    outlineView.selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
                }
            }
        }
        if firstInit {
            simulatorManager!.startNotificationHandler(simDeviceChanged)
        }
    }
    
    func simDeviceChanged (notificationType :  DCSimulatorManager.NotificationType, deviceUDID : NSUUID, newState : Int) -> Void {
        
        switch notificationType {
        case .DeviceState:
            if let sim = outlineView.itemAtRow(outlineView.selectedRow) as? Simulator {
                if sim.UDID == deviceUDID {
                    for tabViewItem in (tabView.tabViewItems as [NSTabViewItem]) {
                        if let item = tabViewItem.identifier as? DCSimulatorViewController {
                            item.simulator = sim
                        }
                    }
                }
            }

        case .DeviceAdded, .DeviceRemoved, .DeviceRenamed:
            // Simplified handling of other cases: just reloading the complete list
            _simulators = nil
            self.outlineView.reloadData()
            
        }
        
    }
    

    func outlineView(outlineView: NSOutlineView!, child index: Int, ofItem item: AnyObject!) -> AnyObject! {
        if (item == nil) {
            return simulatorVersions[index]
        }
        else if let simulatorsForVersion = item as? SimulatorVersion {
            return simulatorsForVersion.simulators[index];
        }
        else {
            return nil;
        }
    }

    func outlineView(outlineView: NSOutlineView!, numberOfChildrenOfItem item: AnyObject!) -> Int {
        if (item == nil) {
            return simulatorVersions.count
        }
        else if let simulatorsForVersion = item as? SimulatorVersion {
            return simulatorsForVersion.simulators.count
        }
        else {
            return 0;
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        return item is SimulatorVersion
    }
    
    func outlineView(outlineView: NSOutlineView!, isItemExpandable item: AnyObject!) -> Bool {
        return item is SimulatorVersion
    }

    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        if let simulatorsForVersion = item as? SimulatorVersion {
            if let result = outlineView.makeViewWithIdentifier("HeaderCell", owner: self) as? NSTableCellView {
                result.textField!.stringValue = "Simulator v\(simulatorsForVersion.version)"
                return result
            }
        }
        else if let sim = item as? Simulator {
            if let result = outlineView.makeViewWithIdentifier("DataCell", owner: self) as? NSTableCellView {
                result.textField!.stringValue = sim.name!
                return result
            }
        }
        return nil
    }
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        if let sim = outlineView.itemAtRow(outlineView.selectedRow) as? Simulator {
            NSLog("selected: %@", sim.name!)
            for tabViewItem in (tabView.tabViewItems as [NSTabViewItem]) {
                if let item = tabViewItem.identifier as? DCSimulatorViewController {
                    item.simulator = sim
                }
            }
        }
    }
    
    func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        return item is Simulator
    }
    
    func initTabViewItem(tabViewItem: NSTabViewItem?) {
        if let identifier = tabViewItem?.identifier as? String {
            var viewController : NSViewController?
            switch identifier {
            case "Info":
                viewController = DCSimulatorInfoViewController(nibName: "DCSimulatorInfoViewController", bundle: nil)
            case "Apps":
                viewController = DCSimulatorAppViewController(nibName: "DCSimulatorAppViewController", bundle: nil)
            case "Truststore":
                viewController = DCSimulatorTrustStoreViewController(nibName: "DCSimulatorTrustStoreViewController", bundle: nil)
            default:
                viewController = nil
            }
            if viewController != nil {
                tabViewItem?.view = viewController!.view;
                tabViewItem?.identifier = viewController!
                if outlineView.selectedRow >= 0 {
                    if let item = viewController as? DCSimulatorViewController {
                        item.simulator = outlineView.itemAtRow(outlineView.selectedRow) as? Simulator
                    }
                }
            }
        }
    }
    
    func tabView(tabView: NSTabView, shouldSelectTabViewItem tabViewItem: NSTabViewItem?) -> Bool {
        initTabViewItem(tabViewItem)
        return true;
    }
}
