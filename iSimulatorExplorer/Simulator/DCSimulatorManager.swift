//
//  DCSimulatorManager.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 25.08.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.

import Foundation
import Cocoa

class DCSimulatorManager {

    private var _simulators : [Simulator]?

    
    var simulators : [Simulator] {
        get {
            if _simulators == nil {
                _simulators = SimCtl.listSimulators()
            }
            return _simulators!
        }
    }

    
    init() {
    }

    
    enum NotificationType {
        case deviceState
        case deviceAdded
        case deviceRemoved
        case deviceRenamed
    }
    
    struct SimulatorNotification {
        let notificationType : NotificationType
        let udid : UUID
    }
    
    
    public func refreshSimulators() {
        
        guard _simulators != nil else {
            return
        }
        
        var notifications : [SimulatorNotification] = []
        
        let updatedSimulators = SimCtl.listSimulators()
        for sim in simulators {
            if let updatedSim = updatedSimulators.first(where: {$0.UDID == sim.UDID }) {
                if updatedSim.state != sim.state {
                    sim.state = updatedSim.state

                    NSLog("SimDevice \(String(describing: updatedSim.UDID)) new state: \(updatedSim.state)")

                    notifications.append(SimulatorNotification(
                        notificationType: NotificationType.deviceState, udid: sim.UDID!))
                }
                if updatedSim.name != sim.name {
                    sim.name = updatedSim.name
                    
                    NSLog("SimDevice \(String(describing: updatedSim.UDID)) renamed: \(String(describing: updatedSim.name))")

                    notifications.append(SimulatorNotification(
                        notificationType: NotificationType.deviceRenamed, udid: sim.UDID!))
                }
            }
            else {
                notifications.append(SimulatorNotification(
                    notificationType: NotificationType.deviceRemoved, udid: sim.UDID!))
            }
        }
        notifications.filter { $0.notificationType == .deviceRemoved }.forEach { notification in
            NSLog("SimDevice \(String(describing: notification.udid)) removed")
            _simulators!.removeAll { $0.UDID == notification.udid }
        }
        
        for updatedSim in updatedSimulators {
            if simulators.first(where: {$0.UDID == updatedSim.UDID }) == nil {
                _simulators!.append(updatedSim)
                
                NSLog("SimDevice \(String(describing: updatedSim.UDID)) added: \(String(describing: updatedSim.name))")

                notifications.append(SimulatorNotification(
                    notificationType: NotificationType.deviceAdded, udid: updatedSim.UDID!))
            }
        }
        
        guard notificationHandler != nil, !notifications.isEmpty else {
            return
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            for notification in notifications {
                self.notificationHandler?(notification.notificationType, notification.udid, 0)
            }
        })

    }

    private var notificationHandler : ((NotificationType, UUID, Int) -> Void)?
    
    private var timer : Timer?
    
    
    func startNotificationHandler(_ handler : @escaping (NotificationType, UUID, Int) -> Void ) {
        notificationHandler = handler

        guard timer == nil else {
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { (timer) in
                self.refreshSimulators()
            })
            RunLoop.current.run()
        }

        NSLog("Simulator device notification started")
    }

}

