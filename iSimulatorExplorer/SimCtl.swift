//
//  SimCtl.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 12.01.2026.
//  Copyright © 2026 Daniel Cerutti. All rights reserved.
//

import Foundation


public class SimCtl {

    static func getProcess(arguments : [String] ) -> Process {
        let task = Process()
        task.launchPath = "/usr/bin/xcrun"
        var args = ["simctl"]
        args.append(contentsOf: arguments)
        task.arguments = args
        return task
    }
    
    
    static func listSimulators() -> [Simulator] {
        let process = getProcess(arguments: ["list", "-j", "devices"])

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
        
        let process = getProcess(arguments: ["boot", udid])

        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
        } catch {
            NSLog("Failed to run simctl: \(error)")
            return false
        }

        process.waitUntilExit()
        
        return process.terminationStatus == 0
    }
    
    static public func shutDownDevice(udid : String) -> Bool {
        
        let process = getProcess(arguments: ["shutdown", udid])

        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
        } catch {
            NSLog("Failed to run simctl: \(error)")
            return false
        }

        process.waitUntilExit()
        
        return process.terminationStatus == 0

    }

}
