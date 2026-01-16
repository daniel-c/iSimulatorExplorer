//
//  DCSimulatorExplorerController.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 15.08.14.
//  Copyright (c) 2014-2026 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

import Cocoa
import SwiftUI

class SimulatorVersion {
    var version : String
    var simulators : [Simulator]
    
    init(version : String, simulators : [Simulator]) {
        self.version = version
        self.simulators = simulators
    }
    
}

protocol SimulatorController {
    func updateSimulator(simulator : Simulator)
}
    
class SimulatorHostingViewController<SimulatorView : View> : NSHostingController<SimulatorView>, SimulatorController
    where SimulatorView: SimulatorController
{
    func updateSimulator(simulator: Simulator) {
        rootView.updateSimulator(simulator: simulator)
    }
}


class DCSimulatorExplorerController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource, NSTabViewDelegate {

//class DCSimulatorExplorerController: NSObject, NSWindowDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource, NSTabViewDelegate {

    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var tabView: NSTabView!
    
    var simulatorManager : DCSimulatorManager?
    
    
    var _simulators : [SimulatorVersion]?
    var simulatorVersions : [SimulatorVersion]  {
        get {
            if _simulators == nil {
                _simulators = [SimulatorVersion]()
                
                let firstInit = (simulatorManager == nil)
                if firstInit {
                    simulatorManager = DCSimulatorManager()
                }
                
                DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: { () -> Void in
                    
                    var simulatorsByVersion = [String : [Simulator]]()
                    for sim in self.simulatorManager!.simulators {
                        let typeAndVersion : String
                        switch sim.simulatorOS {
                        case SimulatorOSType.tvOS:
                            typeAndVersion = "tvOS Simulator \(sim.version!)"
                        case SimulatorOSType.watchOS:
                            typeAndVersion = "watchOS Simulator \(sim.version!)"
                        default:
                            typeAndVersion = "Simulator \(sim.version!)"
                            
                        }
                        
                        if simulatorsByVersion[typeAndVersion] == nil {
                            let simulators = [Simulator]()
                            simulatorsByVersion[typeAndVersion] = simulators
                        }
                        simulatorsByVersion[typeAndVersion]?.append(sim)
                        
                    }
                    let sortedKeys = simulatorsByVersion.keys.sorted()
                    //sortedKeys.sort({ (s1, s2) -> Bool in
                    //    return s2 > s1
                    //})
                    var simulatorVersions = [SimulatorVersion]()
                    for key in sortedKeys {
                        let sims = simulatorsByVersion[key]!
                        simulatorVersions.append(SimulatorVersion(version: key, simulators: sims))
                        
                    }
                    DispatchQueue.main.async(execute: { () -> Void in
                        self._simulators = simulatorVersions
                        self.outlineView.reloadData()
                        self.initView(firstInit)
                    })
                })
                
            }
            return _simulators!
        }
    }

    
    func initView(_ firstInit : Bool) {
        initTabViewItem(tabView.selectedTabViewItem)
        outlineView.expandItem(nil, expandChildren: true)
        if (_simulators != nil) {
            if let sim = simulatorVersions.first?.simulators.first {
                let row = outlineView.row(forItem: sim)
                if row >= 0 {
                    outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                }
            }
        }
        if firstInit {
            simulatorManager!.startNotificationHandler(simDeviceChanged)
        }
    }
    
    func simDeviceChanged (_ notificationType :  DCSimulatorManager.NotificationType, deviceUDID : UUID, newState : Int) -> Void {
        
        switch notificationType {
        case .deviceState:
            if let sim = outlineView.item(atRow: outlineView.selectedRow) as? Simulator {
                if sim.UDID == deviceUDID {
                    for tabViewItem in tabView.tabViewItems {
                        if let item = tabViewItem.identifier as? SimulatorController {
                            item.updateSimulator(simulator: sim)
                        }
                    }
                }
            }

        case .deviceAdded, .deviceRemoved, .deviceRenamed:
            // Simplified handling of other cases: just reloading the complete list
            _simulators = nil
            self.outlineView.reloadData()
            
        }
        
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if (item == nil) {
            return simulatorVersions[index]
        }
        else if let simulatorsForVersion = item as? SimulatorVersion {
            return simulatorsForVersion.simulators[index];
        }
        else {
            return "";
        }
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
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
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return item is SimulatorVersion
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is SimulatorVersion
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let simulatorsForVersion = item as? SimulatorVersion {
            if let result = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("HeaderCell"), owner: self) as? NSTableCellView {
                result.textField!.stringValue = simulatorsForVersion.version
                return result
            }
        }
        else if let sim = item as? Simulator {
            if let result = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: self) as? NSTableCellView {
                result.textField!.stringValue = sim.name!
                return result
            }
        }
        return nil
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let sim = outlineView.item(atRow: outlineView.selectedRow) as? Simulator {
            NSLog("selected: %@", sim.name!)
            for tabViewItem in tabView.tabViewItems {
                if let item = tabViewItem.identifier as? SimulatorController {
                    item.updateSimulator(simulator: sim)
                }
            }
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return item is Simulator
    }
    
    func initTabViewItem(_ tabViewItem: NSTabViewItem?) {
        if let identifier = tabViewItem?.identifier as? String {
            var viewController : NSViewController?
            switch identifier {
            case "Info":
                viewController = SimulatorHostingViewController(rootView: SimulatorInfoView())
            case "Apps":
                viewController = SimulatorHostingViewController(rootView: SimulatorAppView())
            case "Truststore":
                viewController = SimulatorHostingViewController(rootView: SimulatorTrustStoreView())
            default:
                viewController = nil
            }
            if viewController != nil {
                tabViewItem?.view = viewController!.view;
                tabViewItem?.identifier = viewController!
                if outlineView.selectedRow >= 0 {
                    if let item = viewController as? SimulatorController,
                       let sim = outlineView.item(atRow: outlineView.selectedRow) as? Simulator {
                        item.updateSimulator(simulator: sim)
                    }
                }
            }
        }
    }
    
    func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        initTabViewItem(tabViewItem)
        return true;
    }
}
