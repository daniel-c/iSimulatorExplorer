//
//  SimCtl.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 12.01.2026.
//  Copyright © 2026 Daniel Cerutti. All rights reserved.
//

import Foundation


public class SimCtl {

    private static func getProcess(arguments : [String] ) -> Process {
        let task = Process()
        task.launchPath = "/usr/bin/xcrun"
        var args = ["simctl"]
        args.append(contentsOf: arguments)
        task.arguments = args
        return task
    }
    
    
    private static func runSimCtl(arguments : [String], output : Pipe?) -> Bool {
        let process = getProcess(arguments: arguments)

        let pipe = output ?? Pipe()
        process.standardOutput = pipe
        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            NSLog("Failed to run simctl: \(error)")
            return false
        }

        process.waitUntilExit()

        if (process.terminationStatus != 0)
        {
            do {
                let errordata = try errorPipe.fileHandleForReading.readToEnd()
                NSLog("simctl error\(process.terminationStatus): \(errordata != nil ? String(describing: String(data: errordata!, encoding: .utf8)) : String())")
                
            } catch {
                NSLog("Error reading simctl output: \(error)")
            }
            return false
        }
        return true
    }
    
    static func listSimulators() -> [Simulator] {
        
        let pipe = Pipe()
        guard runSimCtl(arguments: ["list", "-j", "devices"], output: pipe) else { return [] }
        
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
                    if let p = d.dataPath, !p.isEmpty {
                        dataPath = p
                    } else {
                        dataPath = ("~/Library/Developer/CoreSimulator/Devices" as NSString).expandingTildeInPath + "/" + udid + "/data"
                    }

                    let state = (d.state == "Booted") ? SimulatorDeviceState.booted : .shutDown
                    let sim = Simulator(udid: udid, path: dataPath, state: state, name: d.name, runtime: runtime)
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
    
    static public func bootDevice(udid : String) -> Bool {

        return runSimCtl(arguments: ["boot", udid], output: nil)
    }
    
    static public func shutDownDevice(udid : String) -> Bool {
        
        return runSimCtl(arguments: ["shutdown", udid], output: nil)
    }
    
    static public func installApp(udid: String, appPath: String) -> Bool {
        
        return runSimCtl(arguments: ["install", udid, appPath], output: nil)
    }
    
    static public func uninstallApp(udid: String, appBundleIdentifier: String) -> Bool {
        
        return runSimCtl(arguments: ["uninstall", udid, appBundleIdentifier], output: nil)
    }

}
