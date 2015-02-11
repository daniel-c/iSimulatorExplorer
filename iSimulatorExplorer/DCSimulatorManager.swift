//
//  DCSimulatorManager.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 25.08.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.

import Foundation
import Cocoa

class SimulatorApp {
    var identifier : String?
    var bundleName : String?
    var displayName : String?
    var path : String?
    var dataPath : String?
    
    init(appInfo : [String : AnyObject]) {
        identifier = appInfo[kCFBundleIdentifierKey] as? String
        // appInfo[kCFBundleExecutableKey]  as? String
        bundleName = appInfo[kCFBundleNameKey] as? String
        displayName = appInfo["CFBundleDisplayName"] as? String
        path = appInfo["Path"] as? String
    }
    
}


class Simulator {
    var name : String?
    var deviceName : String?
    var version : String?
    var build : String?
    var UDID : NSUUID?
    var path : String?
    var trustStorePath : String?
    var isValid : Bool
    
    private var simDevice : AnyObject?
    // private var appDataDirMap : [String : String]?
    
    init() {
        isValid = false
    }
    
    var stateString : String? {
        return self.simDevice?.stateString()
    }
    
    var state : SimDeviceState? {
        return self.simDevice?.state
    }
    
    private func initTrustStorePath() {
        trustStorePath = path?.stringByAppendingPathComponent("data/Library/Keychains/TrustStore.sqlite3")
    }
    
    convenience init(path : String) {
        self.init()
        self.path = path
        let devicePlist = path.stringByAppendingPathComponent("device.plist")
        let fm = NSFileManager.defaultManager()
        if fm.fileExistsAtPath(devicePlist) {
            let plistData = fm.contentsAtPath(devicePlist)!
            var error : NSError?
            let plistobj : AnyObject? = NSPropertyListSerialization.propertyListWithData(plistData,
                options: 0,
                format: nil,
                error: &error)
            if let plist = plistobj as? Dictionary<String, AnyObject> {
                let deviceType = plist["deviceType"] as? String
                let name1 = plist["name"] as? String
                let runtime = plist["runtime"] as String
                version = runtime.componentsSeparatedByString(".").last
                name = name1! + " v" + version!
                isValid = true
                initTrustStorePath()
            }
            
        }
    }
    
    convenience init(device : AnyObject) {
        self.init()
        self.simDevice = device
        self.name = device.name
        self.deviceName = device.deviceType?.name
        self.path = device.devicePath() as String?
        self.UDID = device.UDID as NSUUID
        self.version = device.runtime?.versionString
        self.build = device.runtime?.buildVersionString
        self.isValid = true
        initTrustStorePath()
    }
    
    func getAppDataDirMap() -> [String : String] {
        var map = [String : String]()
        let fm = NSFileManager.defaultManager()
        let appDataContainerFolder = self.path!.stringByAppendingPathComponent("data/Containers/Data/Application")
        if let dataFolders = fm.contentsOfDirectoryAtPath(appDataContainerFolder, error: nil) as? [String] {
            for folderName in dataFolders {
                let folderPath = appDataContainerFolder.stringByAppendingPathComponent(folderName)
                let metadataInfoFile = folderPath.stringByAppendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
                if fm.fileExistsAtPath(metadataInfoFile) {
                    
                    let plistData = fm.contentsAtPath(metadataInfoFile)!
                    var error : NSError?
                    let plistobj : AnyObject? = NSPropertyListSerialization.propertyListWithData(plistData,
                        options: 0,
                        format: nil,
                        error: &error)
                    if let identifier = (plistobj as? Dictionary<String, AnyObject>)?["MCMMetadataIdentifier"] as? String {
                        map[identifier] = folderPath
                    }
                }
            }
        }
        return map
    }

    func getAppInfoFromFolder(path : String) -> SimulatorApp? {
        let fm = NSFileManager.defaultManager()
        if let bundleFolders = fm.contentsOfDirectoryAtPath(path, error: nil) as? [String] {
            for filename in bundleFolders {
                let bundleFolder = path.stringByAppendingPathComponent(filename)
                let appInfoFile = bundleFolder.stringByAppendingPathComponent("info.plist")
                if fm.fileExistsAtPath(appInfoFile) {
                    
                    let plistData = fm.contentsAtPath(appInfoFile)!
                    var error : NSError?
                    let plistobj : AnyObject? = NSPropertyListSerialization.propertyListWithData(plistData,
                        options: 0,
                        format: nil,
                        error: &error)
                    if let plist = plistobj as? Dictionary<String, AnyObject> {
                        let appInfo = SimulatorApp(appInfo: plist)
                        appInfo.path = path
                        return appInfo
                    }
                }
            }
        }
        return nil
    }
    
    func getAppListFromContent() -> [SimulatorApp] {
        var appList = [SimulatorApp]()
        
        let fm = NSFileManager.defaultManager()
        // For iOS < 8.0
        let appDataContainerFolder = self.path!.stringByAppendingPathComponent("data/Applications")
        if let dataFolders = fm.contentsOfDirectoryAtPath(appDataContainerFolder, error: nil) as? [String] {
            for folderName in dataFolders {
                let folderPath = appDataContainerFolder.stringByAppendingPathComponent(folderName)
                if let appInfo = getAppInfoFromFolder(folderPath)? {
                    if appInfo.identifier == nil || !appInfo.identifier!.hasPrefix("com.apple.") {
                        appInfo.dataPath = appInfo.path
                        appList.append(appInfo)
                    }
                }
            }
        }
        else
        {
            let map = getAppDataDirMap()
            
            // For iOS >= 8.0
            let appDataContainerFolder = self.path!.stringByAppendingPathComponent("data/Containers/Bundle/Application")
            if let dataFolders = fm.contentsOfDirectoryAtPath(appDataContainerFolder, error: nil) as? [String] {
                for folderName in dataFolders {
                    let folderPath = appDataContainerFolder.stringByAppendingPathComponent(folderName)
                    if let appInfo = getAppInfoFromFolder(folderPath)? {
                        appInfo.dataPath = map[appInfo.identifier!]
                        appList.append(appInfo)
                    }
                }
            }
        }
        return appList
        
    }

    
    func getAppList() -> [SimulatorApp]?
    {
        if self.simDevice?.state? == SimDeviceState.Booted {
            var error : NSError?
            if let app: AnyObject = self.simDevice?.installedAppsWithError(&error) {
                let appDict = app as? [String : NSDictionary]
                NSLog("apps: %@", appDict!)
                
                let map = getAppDataDirMap()
                
                var appList = [SimulatorApp]()
                for appItem in appDict! {
                    let appItemInfo = appItem.1 as? [String : AnyObject]
                    let appInfo = SimulatorApp(appInfo : appItemInfo!)
                    appInfo.dataPath = map[appInfo.identifier!]
                    appList.append(appInfo)
                }
                
                return appList
            }
            else
            {
                if let err = error? {
                    NSLog("Cannot get app list from coresimulator: %@", err.localizedDescription)
                }
            }
        }
        return getAppListFromContent()
    }
    
    func launchSimulatorApp() -> Bool {
        var result = false
        let workspace = NSWorkspace.sharedWorkspace()
        var appPath : String?
        if let path = workspace.fullPathForApplication("iOS Simulator")? {
            appPath = path
        }
        else if let devPath = XCodeSupport.getDeveloperToolsPath()? {
            NSLog("Try to find simulator app at \(devPath)")
            let possibleAppPath = ["Applications/iOS Simulator.app", "../Applications/iOS Simulator.app", "../Applications/iPhone Simulator.app"]
            let fm = NSFileManager.defaultManager()
            for testPath in possibleAppPath {
                var path = devPath.stringByAppendingPathComponent(testPath)
                if fm.fileExistsAtPath(path) {
                    appPath = path
                    break
                }
            }
        }
        if appPath != nil {
            if let appUrl = NSURL.fileURLWithPath(appPath!)? {
                var error : NSError?
                let launchArg : [String : AnyObject] = (UDID != nil) ?
                    [NSWorkspaceLaunchConfigurationArguments : ["-CurrentDeviceUDID", UDID!.UUIDString]] : [String : AnyObject]()
                
                NSLog("Launching iOS Simulator with \(launchArg)")
                if let runningApp = workspace.launchApplicationAtURL(appUrl, options: NSWorkspaceLaunchOptions.Default, configuration: launchArg, error: &error) {
                    NSLog("Simulator started. PID=%u", runningApp.processIdentifier)
                    result = true
                }
                else {
                    NSLog("Error launching simulator: %@", error!)
                }
                
            }
        }
        else {
            NSLog("Simulator App not found")
        }
        return result
    }
}


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
                    }
                }
            })
            NSLog("SimDeviceSet notification started")
        }
    }
    
}