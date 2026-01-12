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
    // Get simulators using `simctl` JSON output
    func getSimulatorsUsingSimctl() -> [Simulator] {
        // Prepare the process to call: xcrun simctl list -j devices
        let process = Process()
        process.launchPath = "/usr/bin/xcrun"
        process.arguments = ["simctl", "list", "-j", "devices"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            NSLog("Failed to run simctl: \(error)")
            return []
        }

        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard !data.isEmpty else { return [] }

        // Parse JSON: { "devices": { "iOS <version>": [ { ... device ... } ], ... } }
        struct SimctlResponse: Decodable {
            let devices: [String: [SimctlDevice]]
        }
        struct SimctlDevice: Decodable {
            let state: String?
            let isAvailable: Bool?
            let name: String?
            let udid: String?
            let availabilityError: String?
            let deviceTypeIdentifier: String?
            let lastBootedAt: String?
            let dataPath: String?
            let logPath: String?
        }

        var simulators: [Simulator] = []
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(SimctlResponse.self, from: data)

            // Flatten devices across runtimes, filter to iOS only and available
            for (runtime, devices) in response.devices {
                // Keep iOS runtimes only
                let isIOSRuntime = runtime.lowercased().contains("ios") || runtime.lowercased().contains("iphoneos") || runtime.lowercased().contains("com.apple.coreSimulator.simruntime.ios")
                guard isIOSRuntime else { continue }

                for d in devices {
                    guard let udid = d.udid, let isAvailable = d.isAvailable, isAvailable else { continue }

                    // If simctl provides a dataPath, use that; otherwise, construct default path
                    let dataPath: String
                    //if let p = d.dataPath, !p.isEmpty {
                    //    dataPath = p
                    //} else {
                        dataPath = ("~/Library/Developer/CoreSimulator/Devices" as NSString).expandingTildeInPath + "/" + udid
                    //}

                    // Initialize Simulator from path; fall back if needed
                    let sim = Simulator(path: dataPath)
                    if sim.isValid {
                        simulators.append(sim)
                    }
                }
            }
        } catch {
            // If JSON parsing fails, log and return empty
            if let s = String(data: data, encoding: .utf8) {
                NSLog("Failed to parse simctl JSON. Raw output: \(s)")
            }
            NSLog("JSON parse error: \(error)")
            return []
        }

        return simulators
    }

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

                getSimulators = getSimulatorsUsingSimctl // getXcode8SimulatorsFromFileSystem
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
