//
//  DCSimulator.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 16/02/15.
//  Copyright (c) 2015 Daniel Cerutti. All rights reserved.
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
        identifier = appInfo[kCFBundleIdentifierKey as String] as? String
        // appInfo[kCFBundleExecutableKey]  as? String
        bundleName = appInfo[kCFBundleNameKey as String] as? String
        displayName = appInfo["CFBundleDisplayName"] as? String
        path = appInfo["Path"] as? String
    }
    
}

enum SimulatorOSType {
    case iOS
    case tvOS
    case watchOS
}

class Simulator {
    var _name : String?
    var deviceName : String?
    var version : String?
    var build : String?
    var UDID : NSUUID?
    var path : String?
    var trustStorePath : String?
    var isValid : Bool
    var simulatorOS : SimulatorOSType
    
    private var simDevice : SimDeviceWrapper?
    // private var appDataDirMap : [String : String]?
    
    init() {
        isValid = false
        simulatorOS = SimulatorOSType.iOS
    }
    
    var stateString : String? {
        return self.simDevice?.stateString()
    }
    
    var state : SimDeviceState? {
        return self.simDevice?.state
    }
    
    var name : String? {
        if simDevice != nil {
            return simDevice!.name
        }
        else {
            return _name
        }
    }
    
    private func initTrustStorePath() {
        trustStorePath = (path as NSString?)?.stringByAppendingPathComponent("data/Library/Keychains/TrustStore.sqlite3")
    }
    
    private func initDeviceType (runtimeIdentifier : String?)
    {
        if runtimeIdentifier != nil {
            if runtimeIdentifier!.hasPrefix("com.apple.CoreSimulator.SimRuntime.watchOS") {
                simulatorOS = SimulatorOSType.watchOS
            }
            else if runtimeIdentifier!.hasPrefix("com.apple.CoreSimulator.SimRuntime.tvOS") {
                simulatorOS = SimulatorOSType.tvOS
            }
        }
    }
    
    convenience init(path : String) {
        self.init()
        self.path = path
        let devicePlist = (path as NSString).stringByAppendingPathComponent("device.plist")
        let fm = NSFileManager.defaultManager()
        if fm.fileExistsAtPath(devicePlist) {
            let plistData = fm.contentsAtPath(devicePlist)!
            if let plistobj : AnyObject? = try? NSPropertyListSerialization.propertyListWithData(plistData,
                options: NSPropertyListReadOptions(rawValue: 0),
                format: nil)
            {
            if let plist = plistobj as? Dictionary<String, AnyObject> {
                //let deviceType = plist["deviceType"] as? String
                let name1 = plist["name"] as? String
                if let runtime = plist["runtime"] as? String {
                    version = runtime.componentsSeparatedByString(".").last
                    _name = name1! + " v" + version!
                    isValid = true
                    initDeviceType(runtime)
                    initTrustStorePath()
                }
            }
            }
            
        }
    }
    
    convenience init(device : AnyObject) {
        self.init()
        self.simDevice = SimDeviceWrapper(device)
        self.deviceName = device.deviceType?.name
        self.path = device.devicePath() as String?
        self.UDID = device.UDID as NSUUID
        self.version = device.runtime?.versionString
        
        self.build = device.runtime?.buildVersionString
        initDeviceType(device.runtime?.identifier)
        initTrustStorePath()
        isValid = self.simDevice!.available;
    }
    
    func getAppDataDirMap() -> [String : String] {
        var map = [String : String]()
        let fm = NSFileManager.defaultManager()
        let appDataContainerFolder = (self.path! as NSString).stringByAppendingPathComponent("data/Containers/Data/Application")
        if let dataFolders = try? fm.contentsOfDirectoryAtPath(appDataContainerFolder) {
            for folderName in dataFolders {
                let folderPath = (appDataContainerFolder as NSString).stringByAppendingPathComponent(folderName)
                let metadataInfoFile = (folderPath as NSString).stringByAppendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
                if fm.fileExistsAtPath(metadataInfoFile) {
                    
                    let plistData = fm.contentsAtPath(metadataInfoFile)!
                    if let plistobj : AnyObject? = try? NSPropertyListSerialization.propertyListWithData(plistData,
                        options: NSPropertyListReadOptions(rawValue: 0),
                        format: nil) {
                        if let identifier = (plistobj as? Dictionary<String, AnyObject>)?["MCMMetadataIdentifier"] as? String {
                            map[identifier] = folderPath
                        }
                    }
                }
            }
        }
        return map
    }
    
    func getAppInfoFromFolder(path : String) -> SimulatorApp? {
        let fm = NSFileManager.defaultManager()
        if let bundleFolders = try? fm.contentsOfDirectoryAtPath(path) {
            for filename in bundleFolders {
                let bundleFolder = (path as NSString).stringByAppendingPathComponent(filename)
                let appInfoFile = (bundleFolder as NSString).stringByAppendingPathComponent("info.plist")
                if fm.fileExistsAtPath(appInfoFile) {
                    
                    let plistData = fm.contentsAtPath(appInfoFile)!
                    if let plistobj : AnyObject? = try? NSPropertyListSerialization.propertyListWithData(plistData,
                        options: NSPropertyListReadOptions(rawValue: 0),
                        format: nil) {
                        if let plist = plistobj as? Dictionary<String, AnyObject> {
                            let appInfo = SimulatorApp(appInfo: plist)
                            appInfo.path = path
                            return appInfo
                        }
                    }
                }
            }
        }
        return nil
    }
    
    private func includeAppFilter(appInfo : SimulatorApp) -> Bool {
        return appInfo.identifier == nil || !appInfo.identifier!.hasPrefix("com.apple.")
    }
    
    func getAppListFromContent() -> [SimulatorApp] {
        var appList = [SimulatorApp]()
        
        let fm = NSFileManager.defaultManager()
        // For iOS < 8.0
        let appDataContainerFolder = (self.path! as NSString).stringByAppendingPathComponent("data/Applications")
        if let dataFolders = try? fm.contentsOfDirectoryAtPath(appDataContainerFolder) {
            for folderName in dataFolders {
                let folderPath = (appDataContainerFolder as NSString).stringByAppendingPathComponent(folderName)
                if let appInfo = getAppInfoFromFolder(folderPath) {
                    if includeAppFilter(appInfo) {
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
            let appDataContainerFolder = (self.path! as NSString).stringByAppendingPathComponent("data/Containers/Bundle/Application")
            if let dataFolders = try? fm.contentsOfDirectoryAtPath(appDataContainerFolder) {
                for folderName in dataFolders {
                    let folderPath = (appDataContainerFolder as NSString).stringByAppendingPathComponent(folderName)
                    if let appInfo = getAppInfoFromFolder(folderPath) {
                        if includeAppFilter(appInfo) {
                            appInfo.dataPath = map[appInfo.identifier!]
                            appList.append(appInfo)
                        }
                    }
                }
            }
        }
        return appList
        
    }
    
    
    func getAppList() -> [SimulatorApp]?
    {
        if self.simDevice?.state == SimDeviceState.Booted {
            do {
                let app: AnyObject = try self.simDevice!.installedApps()
                let appDict = app as? [String : NSDictionary]
                NSLog("apps: %@", appDict!)
                
                let map = getAppDataDirMap()
                
                var appList = [SimulatorApp]()
                for appItem in appDict! {
                    let appItemInfo = appItem.1 as? [String : AnyObject]
                    let appInfo = SimulatorApp(appInfo : appItemInfo!)
                    if includeAppFilter(appInfo) {
                        appInfo.dataPath = map[appInfo.identifier!]
                        appList.append(appInfo)
                    }
                }
                
                return appList
            }
            catch let error as NSError
            {
                NSLog("Cannot get app list from coresimulator: %@", error.localizedDescription)
            }
            catch
            {
                NSLog("Cannot get app list from coresimulator: Unknown error")
            }
        }
        return getAppListFromContent()
    }
    
    func launchSimulatorApp() -> Bool {
        var result = false
        let simulatorAppName : String
        if XCodeSupport.getDeveloperToolsVersion()?.compare("7.0", options: NSStringCompareOptions.NumericSearch) == NSComparisonResult.OrderedAscending {
            simulatorAppName = "iOS Simulator"
        }
        else
        {
            simulatorAppName = (simulatorOS == SimulatorOSType.watchOS)  ? "Simulator (Watch)" : "Simulator"
        }
        let workspace = NSWorkspace.sharedWorkspace()
        var appPath : String?
        if let path = workspace.fullPathForApplication(simulatorAppName) {
            appPath = path
        }
        else if let devPath = XCodeSupport.getDeveloperToolsPath() {
            NSLog("Try to find simulator app at \(devPath)")
            let possibleAppPath : [String]
            if simulatorOS == SimulatorOSType.watchOS {
                possibleAppPath = ["Applications/Simulator (Watch).app"]
            }
            else {
                possibleAppPath = ["Applications/iOS Simulator.app", "Applications/Simulator.app", "../Applications/iOS Simulator.app", "../Applications/iPhone Simulator.app"]
            }
            let fm = NSFileManager.defaultManager()
            for testPath in possibleAppPath {
                let path = (devPath as NSString).stringByAppendingPathComponent(testPath)
                if fm.fileExistsAtPath(path) {
                    appPath = path
                    break
                }
            }
        }
        if appPath != nil {
            NSLog("Found simulator app at \(appPath)")
            let appUrl = NSURL.fileURLWithPath(appPath!)
            let launchArg : [String : AnyObject] = (UDID != nil) ?
                [NSWorkspaceLaunchConfigurationArguments : ["-CurrentDeviceUDID", UDID!.UUIDString]] : [String : AnyObject]()
            
            NSLog("Launching iOS Simulator with \(launchArg)")

            do {
                let runningApp = try workspace.launchApplicationAtURL(appUrl, options: NSWorkspaceLaunchOptions.Default, configuration: launchArg)
                NSLog("Simulator started. PID=%u", runningApp.processIdentifier)
                result = true
            }
            catch let error as NSError {
                NSLog("Error launching simulator: %@", error)
            }
            catch{
                NSLog("Error launching simulator: Unknown error")
            }
            
        }
        else {
            NSLog("Simulator App not found")
        }
        return result
    }
    
    func boot(completionHandler : ((error : NSError?) -> Void)?) {
        
        if simDevice != nil {
            let options : [String : AnyObject] = [
                "env" : [String : AnyObject](),
                "persist" : true,
                "disabled_jobs" : ["com.apple.backboardd" : true]]
            
            simDevice!.bootAsyncWithOptions(options, completionHandler: { (error : NSError?) -> Void in
                if error != nil {
                    NSLog("boot error:%@", error!)
                }
                else {
                    NSLog("boot success")
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler?(error: error)
                })
            })
        }
        else {
            completionHandler?(error: NSError(domain: "iSimulatorExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot boot device when CoreSimulator is not available"]))
        }
    }
    
    func shutdown(completionHandler : ((error : NSError?) -> Void)?) {
        
        if simDevice != nil {
            simDevice!.shutdownAsyncWithCompletionHandler { (error : NSError?) -> Void in
                if error != nil {
                    NSLog("shutdown error:%@", error!)
                }
                else {
                    NSLog("shutdown success")
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler?(error: error)
                })
            }
        }
        else {
            completionHandler?(error: NSError(domain: "iSimulatorExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot shutdown device when CoreSimulator is not available"]))
        }
    }
    
    enum SimulatorActionError : ErrorType {
        case InvalidBundleIdentifier
    }
    
    private func doActionWithBootAndShutdown<T> (
        arg1 : T,
        action: ((arg1 : T, completionHandler : ((error : NSError?) -> Void)?) throws -> Void),
        completionHandler : ((error : NSError?) -> Void)?) {
            
            if simDevice!.state != SimDeviceState.Booted {
                boot({ (error) -> Void in
                    if error != nil {
                        completionHandler?(error: error)
                    }
                    try! action(arg1: arg1, completionHandler : { (error) -> Void in
                        self.shutdown({ (shutdownError) -> Void in
                            completionHandler?(error: error)
                        })
                    })
                })
            }
            else {
                try! action(arg1 : arg1, completionHandler : completionHandler)
            }
    }
    
    func installApp (appUrl : NSURL, completionHandler : ((error : NSError?) -> Void)?) {
        
        let installAppAction = {(appUrl : NSURL, completionHandler : ((error : NSError?) -> Void)?) -> Void in
            var bundleId = NSBundle(URL: appUrl)?.bundleIdentifier
            if bundleId == nil {
                let plistUrl = appUrl.URLByAppendingPathComponent("Info.plist")
                if let plist = NSDictionary(contentsOfURL: plistUrl)  {
                    bundleId = plist["CFBundleIdentifier"] as? String
                }
            }
            
            if bundleId != nil {
                let options : [String : AnyObject] = ["CFBundleIdentifier" : bundleId!]

                do {
                    try self.simDevice!.installApplication(appUrl, withOptions: options)
                    completionHandler?(error: nil)
                }
                catch let error as NSError {
                    completionHandler?(error: error)
                }
            }
            else {
                completionHandler?(error: NSError(
                    domain: "iSimulatorExplorer",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey : "Cannot install app: bundle Identifier not found"]))
            }
        }
        
        if simDevice != nil {
            
            doActionWithBootAndShutdown(appUrl, action: installAppAction, completionHandler: completionHandler)
        }
        else {
            completionHandler?(error: NSError(domain: "iSimulatorExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot install app when CoreSimulator is not available"]))
        }
    }
    
    func uninstallApp (appId : String, completionHandler : ((error : NSError?) -> Void)?) {
        
        let uninstallAppAction = { (appId : String, completionHandler : ((error : NSError?) -> Void)?) -> Void in
            do {
                try self.simDevice!.uninstallApplication(appId, withOptions: nil)
                completionHandler?(error: nil)
            }
            catch let error as NSError {
                completionHandler?(error: error)
            }
        }
        
        if simDevice != nil {
            doActionWithBootAndShutdown(appId, action: uninstallAppAction, completionHandler: completionHandler)
        }
        else {
            completionHandler?(error: NSError(domain: "iSimulatorExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot uninstall app when CoreSimulator is not available"]))
        }
    }
}
