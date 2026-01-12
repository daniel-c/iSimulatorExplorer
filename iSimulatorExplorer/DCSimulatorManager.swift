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
    private var developerDir : String?
    private var getSimulators : () -> [Simulator]

    
    // Get XCode simulators by browsing the file system
    private func getXcode8SimulatorsFromFileSystem() -> [Simulator] {
        
        var simulators = [Simulator]()
        
        let simBasePath = ("~/Library/Developer/CoreSimulator/Devices" as NSString).expandingTildeInPath
        if let fileList = try? FileManager.default.contentsOfDirectory(atPath: simBasePath) {
            for item in fileList
            {
                print("item is \(item)", terminator:"\n")
                
                let path = (simBasePath as NSString).appendingPathComponent(item)
                
                let sim = Simulator(path: path)
                if sim.isValid {
                    simulators.append(sim);
                }
            }
        }
        return simulators;
    }


    var simulators : [Simulator] {
        get {
            return getSimulators()
        }
    }

    
    init() {
        
        getSimulators = { () -> [Simulator] in
            return [Simulator]()
        }
        
        if let dtVersion = XCodeSupport.getDeveloperToolsVersion() {
            
            NSLog("XCode version \(dtVersion)")
            if dtVersion.compare("15.0", options: NSString.CompareOptions.numeric) == ComparisonResult.orderedAscending {
                
                NSLog("XCode version < 15.0. Not Supported")
                
            }
            else {
                NSLog("XCode version >= 15.0")

                getSimulators = getXcode8SimulatorsFromFileSystem
            }
        }
    }

    enum NotificationType {
        case deviceState
        case deviceAdded
        case deviceRemoved
        case deviceRenamed
    }
    
    func startNotificationHandler(_ handler : @escaping (NotificationType, UUID, Int) -> Void ) {

    }

}
