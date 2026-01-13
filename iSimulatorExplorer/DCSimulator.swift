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

enum SimulatorDeviceState : String {
    case creating = "Creating"
    case shutDown = "ShutDown"
    case booting = "Booting"
    case booted = "Booted"
    case shuttingDown = "ShuttingDown"
}

class Simulator {
    var name : String?
    var deviceName : String?
    var version : String?
    var UDID : UUID?
    var path : String
    var trustStorePath : String?
    var isValid : Bool
    var simulatorOS : SimulatorOSType
    
    // private var appDataDirMap : [String : String]?
    
    init(udid: String?, path : String, state : SimulatorDeviceState, name : String?, runtime : String?) {
        isValid = false
        self.UDID = udid != nil ? UUID(uuidString: udid!) : nil
        self.path = path
        // self.state =
        simulatorOS = SimulatorOSType.iOS
            self.state = state
        if let runtime = runtime, let name = name {
            version = runtime.components(separatedBy: ".").last
            self.name = name
            isValid = true
            initDeviceType(runtime)
            initTrustStorePath()
        }
    }
    
    var stateString : String {
        return state.rawValue
    }
    
    var nameAndVersion : String? {
        guard let name, let version else { return nil }
        return name + " (" + version + ")"
    }
    
    var state : SimulatorDeviceState
    
    private func initTrustStorePath() {
        trustStorePath = (path as NSString?)?.appendingPathComponent("private/var/protected/trustd/private/TrustStore.sqlite3")
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
    
    func getAppDataDirMap() -> [String : String] {
        var map = [String : String]()
        let fm = FileManager.default
        let appDataContainerFolder = (self.path as NSString).appendingPathComponent("Containers/Data/Application")
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
        let map = getAppDataDirMap()
        
        let appDataContainerFolder = (self.path as NSString).appendingPathComponent("Containers/Bundle/Application")
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
        return appList
        
    }
    
    
    func getAppList() -> [SimulatorApp]?
    {
        return getAppListFromContent()
    }
    
    func launchSimulatorApp() -> Bool {
        var result = false
        let workspace = NSWorkspace.shared
        if let appUrl = workspace.urlForApplication(withBundleIdentifier: "com.apple.iphonesimulator") {
            NSLog("Found simulator app at \(String(describing: appUrl))")

            let openConfig = NSWorkspace.OpenConfiguration()
            if (UDID != nil)
            {
                openConfig.arguments = ["-CurrentDeviceUDID", UDID!.uuidString]
            }
            NSLog("Launching iOS Simulator with \(openConfig.arguments)")

            let semaphore = DispatchSemaphore(value: 0)
            workspace.openApplication(at: appUrl, configuration: openConfig) { app, error in
                if let error = error {
                    NSLog("Error launching simulator: %@", error.localizedDescription)
                    result = false
                } else if let app = app {
                    NSLog("Simulator started. PID=%u", app.processIdentifier)
                    result = true
                } else {
                    NSLog("Simulator launch returned no app and no error")
                    result = false
                }
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 30)
        }
        else {
            NSLog("Simulator App not found")
        }
        return result
    }
    
    func boot(_ completionHandler : ((_ error : Error?) -> Void)?) {
        
        let result = SimCtl.bootDevice(udid: UDID!.uuidString)

        if (!result) {
            completionHandler?(NSError(domain: "iSimulatorExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey : "Error booting device"]))
        }
        else {
            completionHandler?(nil)
        }
    }
    
    func shutdown(_ completionHandler : ((_ error : Error?) -> Void)?) {
        
        let result = SimCtl.shutDownDevice(udid: UDID!.uuidString)
        
        if (!result) {
            completionHandler?(NSError(domain: "iSimulatorExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot shutdown device"]))
        }
        else {
            completionHandler?(nil)
        }
    }

    enum SimulatorActionError : Error {
        case invalidBundleIdentifier
    }
    
    private func doActionWithBootAndShutdown<T> (
        _ arg1 : T,
        action: @escaping ((_ arg1 : T, _ completionHandler : ((_ error : Error?) -> Void)?) throws -> Void),
        completionHandler : ((_ error : Error?) -> Void)?) {
            
            if state != .booted {
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
        
        let installAppAction = {(appUrl : URL, completionHandler : ((_ error : Error?) -> Void)?) -> Void in
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
                    //try self.simDevice!.installApplication(appUrl, withOptions: options)
                    completionHandler?(nil)
                }
                catch let error {
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
        
//        if simDevice != nil {
//
//            doActionWithBootAndShutdown(appUrl, action: installAppAction, completionHandler: completionHandler)
//        }
//        else {
            completionHandler?(NSError(domain: "iSimulatorExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot install app when CoreSimulator is not available"]))
//        }
 
    }
    
    func uninstallApp (_ appId : String, completionHandler : ((_ error : Error?) -> Void)?) {
        
        
        let uninstallAppAction = { (appId : String, completionHandler : ((_ error : Error?) -> Void)?) -> Void in
            do {
                // try self.simDevice!.uninstallApplication(appId, withOptions: nil)
                completionHandler?(nil)
            }
            catch let error {
                completionHandler?(error)
            }
        }
        
//        if simDevice != nil {
//            doActionWithBootAndShutdown(appId, action: uninstallAppAction, completionHandler: completionHandler)
//        }
//        else {
            completionHandler?(NSError(domain: "iSimulatorExplorer", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot uninstall app when CoreSimulator is not available"]))
//        }
 
    }
}
