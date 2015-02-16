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
    private var simulatorFramework : NSBundle?
    private let kDVTFoundationRelativePath = "../SharedFrameworks/DVTFoundation.framework"
    private let kDevToolsFoundationRelativePath = "../OtherFrameworks/DevToolsFoundation.framework"
    private let kSimulatorRelativePath = "Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app"
    private let sim5BasePath = "~/Library/Application Support/iPhone Simulator".stringByExpandingTildeInPath
    private var simDeviceSetClass : AnyClass?
    private var simDeviceSet : AnyObject?
    private let getSimulators : () -> [Simulator]
    
    // Helper to find a class by name and die if it isn't found.
    private func FindClassByName(nameOfClass : String) -> AnyClass! {
        if let theClass : AnyClass = NSClassFromString(nameOfClass)? {
            return theClass
        }
        else
        {
            NSLog("Failed to find class %@ at runtime.", nameOfClass)
            return nil
        }
    }
    
    
    private func LoadSimulatorFramework() -> NSBundle! {
        if let developerDir = XCodeSupport.getDeveloperToolsPath()? {
            
            // The Simulator framework depends on some of the other Xcode private
            // frameworks; manually load them first so everything can be linked up.
            let dvtFoundationPath = developerDir.stringByAppendingPathComponent(kDVTFoundationRelativePath)
            
            if let dvtFoundationBundle = NSBundle(path: dvtFoundationPath)? {
                if !(dvtFoundationBundle.load()) {
                    return nil
                }
            }
            
            let devToolsFoundationPath = developerDir.stringByAppendingPathComponent(kDevToolsFoundationRelativePath)
            if let devToolsFoundationBundle = NSBundle(path: devToolsFoundationPath)? {
                if !(devToolsFoundationBundle.load()) {
                    return nil
                }
            }
            
            
            // Prime DVTPlatform.
            var error : NSError?
            if let DVTPlatformClass : AnyClass = FindClassByName("DVTPlatform")? {
                if !(DVTPlatformClass.loadAllPlatformsReturningError(&error)) {
                    NSLog("Unable to loadAllPlatformsReturningError. Error: %@", error!.localizedDescription)
                    return nil;
                }
            }
            
            // The path within the developer dir of the private Simulator frameworks.
            let simulatorFrameworkRelativePath = "../SharedFrameworks/DVTiPhoneSimulatorRemoteClient.framework";
            let kCoreSimulatorRelativePath = "Library/PrivateFrameworks/CoreSimulator.framework";
            let coreSimulatorPath = developerDir.stringByAppendingPathComponent(kCoreSimulatorRelativePath);
            if let coreSimulatorBundle = NSBundle(path: coreSimulatorPath)? {
                if !(coreSimulatorBundle.load()) {
                    return nil
                }
            }
            let simBundlePath = developerDir.stringByAppendingPathComponent(simulatorFrameworkRelativePath);
            if let simBundle = NSBundle(path: simBundlePath)? {
                if !(simBundle.load()) {
                    return nil
                }
                return simBundle;
            }
        }
        return nil;
    }
    
    
    // Get XCode version 6.0 simulators using CoreSimulator framework
    private func getXcode6SimulatorsFromCoreSimulator() -> [Simulator] {
        
        var simulators = [Simulator]()

        simDeviceSet = simDeviceSetClass?.defaultSet()
        if simDeviceSet != nil  {
            if let deviceList = simDeviceSet!.availableDevices? {
                for simDevice in deviceList {
                    var sim = Simulator(device: simDevice)
                    if sim.isValid {
                        simulators.append(sim)
                    }
                }
            }
        }
        return simulators;
    }
    
    // Get XCode version 6.0 simulators by browsing the file system
    private func getXcode6SimulatorsFromFileSystem() -> [Simulator] {
        
        var simulators = [Simulator]()
        
        let simBasePath = "~/Library/Developer/CoreSimulator/Devices".stringByExpandingTildeInPath
        let fileList1 = NSFileManager.defaultManager().contentsOfDirectoryAtPath(simBasePath, error: nil) as [String]?
        if let fileList = fileList1?       {
            for item in fileList
            {
                println("item is \(item)")
                
                let path = simBasePath.stringByAppendingPathComponent(item)
                
                var sim = Simulator(path: path)
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
        
        if let dtVersion = XCodeSupport.getDeveloperToolsVersion()? {
            
            NSLog("XCode version \(dtVersion)")
            if dtVersion.compare("6.0", options: NSStringCompareOptions.NumericSearch) == NSComparisonResult.OrderedAscending {
                
                NSLog("XCode version < 6.0. Not Supported")
                
            }
            else {
                NSLog("XCode version >= 6.0")

                // XCode version 6.0 simulators
                simulatorFramework = LoadSimulatorFramework()
                simDeviceSetClass = FindClassByName("SimDeviceSet")
                
                if simDeviceSetClass != nil {
                    getSimulators = getXcode6SimulatorsFromCoreSimulator
                }
                else
                {
                    getSimulators = getXcode6SimulatorsFromFileSystem
                }
            }
        }
    }
    
    func startNotificationHandler(handler : (NSUUID, Int) -> Void ) {
        if simDeviceSet != nil {
            
            simDeviceSet!.registerNotificationHandler({ (data : [NSObject : AnyObject]!) -> Void in

                // NSLog("SimDeviceSet notification: \(data.debugDescription)")
                if let notificationData = data as? [String : AnyObject] {
                    if let notificationType = notificationData["notification"] as? String {
                        if notificationType == "device_state"  {
                            let simDevice: AnyObject! = notificationData["device"] as AnyObject!
                            let state = notificationData["new_state"] as Int!
                            
                            NSLog("SimDevice \(simDevice.UDID) new state: \(state)")
                            
                            // handle notification
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                handler(simDevice.UDID, state)
                            })
                        }
                        else {
                            NSLog("Notification: %@", data)
                        }
                    }
                }
            })
            NSLog("SimDeviceSet notification started")
        }
    }
    
}