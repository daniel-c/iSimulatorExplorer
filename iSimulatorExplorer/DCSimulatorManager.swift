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
    private var simulatorFramework : Bundle?
    private let kDVTFoundationRelativePath = "../SharedFrameworks/DVTFoundation.framework"
    private let kDevToolsFoundationRelativePath = "../OtherFrameworks/DevToolsFoundation.framework"
    private var developerDir : String?
    private var simServiceContextClass : AnyClass?
    private var simDeviceSetClass : AnyClass?
    private var simDeviceSet : AnyObject?
    private var getSimulators : () -> [Simulator]

    // Helper to find a class by name and die if it isn't found.
    private func FindClassByName(_ nameOfClass : String) -> AnyClass! {
        if let theClass : AnyClass = NSClassFromString(nameOfClass) {
            return theClass
        }
        else
        {
            NSLog("Failed to find class %@ at runtime.", nameOfClass)
            return nil
        }
    }

    private func LoadSimulatorFramework() -> Bundle! {
        if let devDir = XCodeSupport.getDeveloperToolsPath() as NSString? {
            self.developerDir = devDir as String

            // The Simulator framework depends on some of the other Xcode private
            // frameworks; manually load them first so everything can be linked up.
            let dvtFoundationPath = devDir.appendingPathComponent(kDVTFoundationRelativePath)
            
            if let dvtFoundationBundle = Bundle(path: dvtFoundationPath) {
                if !(dvtFoundationBundle.load()) {
                    return nil
                }
            }
            
            let devToolsFoundationPath = devDir.appendingPathComponent(kDevToolsFoundationRelativePath)
            if let devToolsFoundationBundle = Bundle(path: devToolsFoundationPath) {
                if !(devToolsFoundationBundle.load()) {
                    return nil
                }
            }
            

            // Prime DVTPlatform.
            do {
                try CoreSimulatorHelper.loadAllPlatformsReturningError()
            }
            catch let error as NSError {
                NSLog("Unable to loadAllPlatformsReturningError. Error: %@", error.localizedDescription)
                return nil;
            }
            catch {
                NSLog("Unable to loadAllPlatformsReturningError. Unknown Error")
                return nil;
            }

            // The path within the developer dir of the private Simulator frameworks.
            let simulatorFrameworkRelativePath = "../SharedFrameworks/DVTiPhoneSimulatorRemoteClient.framework";
            let kCoreSimulatorRelativePath = "Library/PrivateFrameworks/CoreSimulator.framework";
            let coreSimulatorPath = devDir.appendingPathComponent(kCoreSimulatorRelativePath);
            if let coreSimulatorBundle = Bundle(path: coreSimulatorPath) {
                if !(coreSimulatorBundle.load()) {
                    return nil
                }
            }
            let simBundlePath = devDir.appendingPathComponent(simulatorFrameworkRelativePath);
            if let simBundle = Bundle(path: simBundlePath) {
                if !(simBundle.load()) {
                    return nil
                }
                return simBundle;
            }
        }
        return nil;
    }

    
    // Get XCode version 8 simulators using CoreSimulator framework
    fileprivate func getXcode8SimulatorsFromCoreSimulator() -> [Simulator] {

        var simulators = [Simulator]()
        
        //if let context = try? simServiceContextClass!.sharedServiceContext(forDeveloperDir: developerDir!) {
        if let context = try? SimServiceContextWrapper.sharedServiceContext(forDeveloperDir: developerDir!, simServiceContextClass:simServiceContextClass!) {

            simDeviceSet = try! context.defaultDeviceSet()
            
            if simDeviceSet != nil  {
                if let deviceList = simDeviceSet!.availableDevices {
                    for simDevice in deviceList! {
                        let sim = Simulator(device: simDevice as AnyObject)
                        if sim.isValid {
                            simulators.append(sim)
                        }
                    }
                }
            }

        }
 
        return simulators;
    }
    
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
            if dtVersion.compare("8.0", options: NSString.CompareOptions.numeric) == ComparisonResult.orderedAscending {
                
                NSLog("XCode version < 8.0. Not Supported")
                
            }
            else {
                NSLog("XCode version >= 8.0")

                // XCode version 8.0 simulators
                simulatorFramework = LoadSimulatorFramework()
                simDeviceSetClass = FindClassByName("SimDeviceSet")
                simServiceContextClass = FindClassByName("SimServiceContext")
                if simServiceContextClass != nil {
                    getSimulators = getXcode8SimulatorsFromCoreSimulator
                }
                else
                {
                    getSimulators = getXcode8SimulatorsFromFileSystem
                }
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
        if simDeviceSet != nil {
            
            let _ = simDeviceSet!.registerNotificationHandler({ (data : [AnyHashable: Any]?) -> Void in

                if let notificationData = data as? [String : AnyObject] {
                    if let notificationTypeString = notificationData["notification"] as? String {
                        
                        //var state : Int = 0
                        var notificationType : NotificationType?
                        //var udid : NSUUID?
                        //TODO : review if SimDevice cast work
                        let simDevice : AnyObject? = notificationData["device"] // as? SimDevice
                        
                        switch notificationTypeString {
                            case "device_state":
                                notificationType = .deviceState
                                if let state = notificationData["new_state"] as? Int {
                                    NSLog("SimDevice \(String(describing: simDevice?.udid)) new state: \(state)")
                                }
                            
                            case "device_added":
                                notificationType = .deviceAdded
                                NSLog("SimDevice \(String(describing: simDevice?.udid)) added: \(String(describing: simDevice?.stateString()))")
                                
                            case "device_removed":
                                notificationType = .deviceRemoved
                                NSLog("SimDevice \(String(describing: simDevice?.udid)) removed")
                                
                            case "device_renamed":
                                notificationType = .deviceRenamed
                                //NSLog("SimDevice \(simDevice?.udid) renamed to: \(simDevice?.name)")
                                
                            default:
                                NSLog("Notification: \(String(describing: data))")
                        }
                        if notificationType != nil && simDevice != nil {
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                handler(notificationType!, simDevice!.udid, 0)
                            })
                            
                        }
                    }
                }
            })
            NSLog("SimDeviceSet notification started")
        }
    }

}
