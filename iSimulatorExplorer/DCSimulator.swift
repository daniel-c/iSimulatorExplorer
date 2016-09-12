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
    var UDID : UUID?
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
        trustStorePath = (path as NSString?)?.appendingPathComponent("data/Library/Keychains/TrustStore.sqlite3")
    }
    
    private func initDeviceType (_ runtimeIdentifier : String?)
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
        let devicePlist = (path as NSString).appendingPathComponent("device.plist")
        let fm = FileManager.default
        if fm.fileExists(atPath: devicePlist) {
            let plistData = fm.contents(atPath: devicePlist)!
            if let plistobj : AnyObject? = try! PropertyListSerialization.propertyList(from: plistData,
                options: PropertyListSerialization.ReadOptions(rawValue: 0),
                format: nil) as AnyObject??
            {
            if let plist = plistobj as? Dictionary<String, AnyObject> {
                //let deviceType = plist["deviceType"] as? String
                let name1 = plist["name"] as? String
                if let runtime = plist["runtime"] as? String {
                    version = runtime.components(separatedBy: ".").last
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
        self.UDID = device.udid as UUID
        self.version = device.runtime?.versionString
        
        self.build = device.runtime?.buildVersionString
        initDeviceType(device.runtime?.identifier)
        initTrustStorePath()
        isValid = self.simDevice!.available;
    }
    
    func getAppDataDirMap() -> [String : String] {
        var map = [String : String]()
        let fm = FileManager.default
        let appDataContainerFolder = (self.path! as NSString).appendingPathComponent("data/Containers/Data/Application")
        if let dataFolders = try? fm.contentsOfDirectory(atPath: appDataContainerFolder) {
            for folderName in dataFolders {
                let folderPath = (appDataContainerFolder as NSString).appendingPathComponent(folderName)
                let metadataInfoFile = (folderPath as NSString).appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
                if fm.fileExists(atPath: metadataInfoFile) {
                    
                    let plistData = fm.contents(atPath: metadataInfoFile)!
                    if let plistobj : AnyObject? = try! PropertyListSerialization.propertyList(from: plistData,
                        options: PropertyListSerialization.ReadOptions(rawValue: 0),
                        format: nil) as AnyObject?? {
                        if let identifier = (plistobj as? Dictionary<String, AnyObject>)?["MCMMetadataIdentifier"] as? String {
                            map[identifier] = folderPath
                        }
                    }
                }
            }
        }
        return map
    }
    
    func getAppInfoFromFolder(_ path : String) -> SimulatorApp? {
        let fm = FileManager.default
        if let bundleFolders = try? fm.contentsOfDirectory(atPath: path) {
            for filename in bundleFolders {
                let bundleFolder = (path as NSString).appendingPathComponent(filename)
                let appInfoFile = (bundleFolder as NSString).appendingPathComponent("info.plist")
                if fm.fileExists(atPath: appInfoFile) {
                    
                    let plistData = fm.contents(atPath: appInfoFile)!
                    if let plistobj : AnyObject? = try! PropertyListSerialization.propertyList(from: plistData,
                        options: PropertyListSerialization.ReadOptions(rawValue: 0),
                        format: nil) as AnyObject?? {
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
    
    private func includeAppFilter(_ appInfo : SimulatorApp) -> Bool {
        return appInfo.identifier == nil || !appInfo.identifier!.hasPrefix("com.apple.")
    }
    
    func getAppListFromContent() -> [SimulatorApp] {
        var appList = [SimulatorApp]()
        
        let fm = FileManager.default
        // For iOS < 8.0
        let appDataContainerFolder = (self.path! as NSString).appendingPathComponent("data/Applications")
        if let dataFolders = try? fm.contentsOfDirectory(atPath: appDataContainerFolder) {
            for folderName in dataFolders {
                let folderPath = (appDataContainerFolder as NSString).appendingPathComponent(folderName)
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
            let appDataContainerFolder = (self.path! as NSString).appendingPathComponent("data/Containers/Bundle/Application")
            if let dataFolders = try? fm.contentsOfDirectory(atPath: appDataContainerFolder) {
                for folderName in dataFolders {
                    let folderPath = (appDataContainerFolder as NSString).appendingPathComponent(folderName)
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
        if self.simDevice?.state == SimDeviceState.booted {
            do {
                let appDict = try self.simDevice!.installedApps() as? [String : NSDictionary]
                //let appDict = app as? [String : NSDictionary]
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
        if XCodeSupport.getDeveloperToolsVersion()?.compare("7.0", options: NSString.CompareOptions.numeric) == ComparisonResult.orderedAscending {
            simulatorAppName = "iOS Simulator"
        }
        else
        {
            simulatorAppName = (simulatorOS == SimulatorOSType.watchOS)  ? "Simulator (Watch)" : "Simulator"
        }
        let workspace = NSWorkspace.shared()
        var appPath : String?
        if let path = workspace.fullPath(forApplication: simulatorAppName) {
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
            let fm = FileManager.default
            for testPath in possibleAppPath {
                let path = (devPath as NSString).appendingPathComponent(testPath)
                if fm.fileExists(atPath: path) {
                    appPath = path
                    break
                }
            }
        }
        if appPath != nil {
            NSLog("Found simulator app at \(appPath)")
            let appUrl = URL(fileURLWithPath: appPath!)
            let launchArg = (UDID != nil) ?
                [NSWorkspaceLaunchConfigurationArguments : ["-CurrentDeviceUDID", UDID!.uuidString]] : [String : Array<String>]()
            
            NSLog("Launching iOS Simulator with \(launchArg)")

            do {
                let runningApp = try workspace.launchApplication(at: appUrl, options: NSWorkspaceLaunchOptions.default, configuration: launchArg)
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
    
    func boot(_ completionHandler : ((_ error : Error?) -> Void)?) {
        
        if simDevice != nil {
            let options : [String : AnyObject] = [
                "env" : [String : AnyObject]() as AnyObject,
                "persist" : true as AnyObject,
                "disabled_jobs" : ["com.apple.backboardd" : true] as AnyObject]
            
            simDevice!.bootAsync(options: options, completionHandler: { (error : Error?) -> Void in
                if error != nil {
                    NSLog("boot error:\(error!)")
                }
                else {
                    NSLog("boot success")
                }
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler?(error)
                })
            })
        }
        else {
            completionHandler?(NSError(domain: "iSimulatorExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot boot device when CoreSimulator is not available"]))
        }
    }
    
    func shutdown(_ completionHandler : ((_ error : Error?) -> Void)?) {
        
        if simDevice != nil {
            simDevice!.shutdownAsync { (error : Error?) -> Void in
                if error != nil {
                    NSLog("shutdown error:\(error!)")
                }
                else {
                    NSLog("shutdown success")
                }
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler?(error)
                })
            }
        }
        else {
            completionHandler?(NSError(domain: "iSimulatorExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot shutdown device when CoreSimulator is not available"]))
        }
    }
    
    enum SimulatorActionError : Error {
        case invalidBundleIdentifier
    }
    
    private func doActionWithBootAndShutdown<T> (
        _ arg1 : T,
        action: @escaping ((_ arg1 : T, _ completionHandler : ((_ error : Error?) -> Void)?) throws -> Void),
        completionHandler : ((_ error : Error?) -> Void)?) {
            
            if simDevice!.state != SimDeviceState.booted {
                boot({ (error) -> Void in
                    if error != nil {
                        completionHandler?(error)
                    }
                    try! action(arg1, { (error) -> Void in
                        self.shutdown({ (shutdownError) -> Void in
                            completionHandler?(error)
                        })
                    })
                })
            }
            else {
                try! action(arg1, completionHandler)
            }
    }
    
    func installApp (_ appUrl : URL, completionHandler : ((_ error : Error?) -> Void)?) {
        /*
        let installAppAction = {(appUrl : URL, completionHandler : ((_ error : NSError?) -> Void)?) -> Void in
            var bundleId = Bundle(url: appUrl)?.bundleIdentifier
            if bundleId == nil {
                let plistUrl = appUrl.appendingPathComponent("Info.plist")
                if let plist = NSDictionary(contentsOf: plistUrl)  {
                    bundleId = plist["CFBundleIdentifier"] as? String
                }
            }
            
            if bundleId != nil {
                let options : [String : AnyObject] = ["CFBundleIdentifier" : bundleId! as AnyObject]

                do {
                    try self.simDevice!.installApplication(appUrl, withOptions: options)
                    completionHandler?(nil)
                }
                catch let error as NSError {
                    completionHandler?(error)
                }
            }
            else {
                completionHandler?(NSError(
                    domain: "iSimulatorExplorer",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey : "Cannot install app: bundle Identifier not found"]))
            }
        }
        
        if simDevice != nil {
            
            doActionWithBootAndShutdown(appUrl, action: installAppAction, completionHandler: completionHandler)
        }
        else {
            completionHandler?(NSError(domain: "iSimulatorExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot install app when CoreSimulator is not available"]))
        }
 */
    }
    
    func uninstallApp (_ appId : String, completionHandler : ((_ error : Error?) -> Void)?) {
        /*
        
        let uninstallAppAction = { (appId : String, completionHandler : ((_ error : Error?) -> Void)?) -> Void in
            do {
                try self.simDevice!.uninstallApplication(appId, withOptions: nil)
                completionHandler?(nil)
            }
            catch let error as NSError {
                completionHandler?(error)
            }
        }
        
        if simDevice != nil {
            doActionWithBootAndShutdown(appId, action: uninstallAppAction, completionHandler: completionHandler)
        }
        else {
            completionHandler?(NSError(domain: "iSimulatorExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot uninstall app when CoreSimulator is not available"]))
        }
 */
    }
}
