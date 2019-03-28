//
//  DCSimulatorTrustStoreViewController.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 10.10.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

import Cocoa
import SecurityInterface

class DCSimulatorTrustStoreViewController: DCSimulatorViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var notavailableInfoTextField: NSTextField!
    @IBOutlet weak var tableScrollView: NSScrollView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var importServerButton: NSButton!
    @IBOutlet weak var importFileButton: NSButton!
    @IBOutlet weak var removeButton: NSButton!
    @IBOutlet weak var exportButton: NSButton!
    
    var truststore : DCSimulatorTruststore?
    
    override var simulator : Simulator? {
        didSet {
            truststore = nil
            if let truststorePath = simulator?.trustStorePath {
                if FileManager.default.fileExists(atPath: truststorePath) {
                    truststore = DCSimulatorTruststore(path : truststorePath)
                    truststore!.openTrustStore()
                    NSLog("Trustore has \(truststore!.items.count) items")
                }
            }
            tableView.reloadData()
            enableButtons()
            if simulator != nil && truststore == nil {
                // If we do not find the truststore.sqlite3 file it is usually because the simulator has not yet been run
                // indicate it with an appropriate message and hide the tableview
                notavailableInfoTextField.isHidden = false
                tableScrollView!.isHidden = true
            }
            else {
                notavailableInfoTextField.isHidden = true
                tableScrollView!.isHidden = false
            }
        }
    }
    
    
    override func loadView() {
        super.loadView()
        enableButtons()
    }
    
    func enableButtons() {
        let enableActionOnSelected = (tableView.selectedRow >= 0)
        let enableActionOnTrustStore = (truststore != nil)
        removeButton.isEnabled = enableActionOnSelected
        exportButton.isEnabled = enableActionOnSelected
        importServerButton.isEnabled = enableActionOnTrustStore
        importFileButton.isEnabled = enableActionOnTrustStore
    }
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return truststore?.items.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let result = tableView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier("DataCell"), owner: self) as? NSTableCellView {
            if truststore != nil {
                if let text = truststore?.items[row].subjectSummary {
                    result.textField!.stringValue = text
                }
            }
            return result
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return nil;
    }
    
    @IBAction func viewCertificateButtonPressed(_ sender: NSButton) {
        if let cellView = sender.superview as? NSTableCellView {
            let row = tableView.row(for: cellView)
            if row >= 0 {
                tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                if let cert = truststore?.items[row].certificate {
                    showCertificate(cert)
                }
            }
        }
        return;
    }
    
    func showCertificate(_ cert : SecCertificate) {
        SFCertificatePanel.shared().runModal(forCertificates: [cert], showGroup: false)
    }
    
    @IBAction func importCertificateFromServerButtonPressed(_ sender: AnyObject) {
        
        let importPanel = DCImportCertificateWindowController(windowNibName: "DCImportCertificateWindowController")
        let result =  NSApplication.shared.runModal(for: importPanel.window!)
        if result.rawValue == 0 {
            if importPanel.certificate != nil {
                let item = DCSimulatorTruststoreItem(certificate: importPanel.certificate!)
                if truststore!.addItem(item) {
                    tableView.reloadData()
                    enableButtons()
                }
            }
        }
        NSLog("Modal close: \(result)")
        return;
        
    }
    
    @IBAction func importCertificateFromFile(_ sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal().rawValue == NSFileHandlingPanelOKButton {
            for url in openPanel.urls {
                if let data = try? Data(contentsOf: url) {
                    
                    var format : SecExternalFormat = SecExternalFormat.formatUnknown
                    var itemType : SecExternalItemType = SecExternalItemType.itemTypeCertificate
                    //var outItems : Unmanaged<CFArray>?
                    var outItems : CFArray?
                    //var outItems : UnsafeMutablePointer<CFArray?>
                    
                    SecItemImport(data as CFData, nil, &format, &itemType, SecItemImportExportFlags(rawValue: 0), nil, nil, &outItems)
                    //if let itemCFArray = outItems?.takeRetainedValue() {
                    if let itemCFArray = outItems {
                        let itemArray = itemCFArray as NSArray
                        if itemArray.count > 0 && itemType == SecExternalItemType.itemTypeCertificate {
                            
                            // Here we must use an unconditional downcast (conditional downcast does not work here).
                            let item = DCSimulatorTruststoreItem(certificate: itemArray[0] as! SecCertificate)
                            
                            if truststore!.addItem(item) {
                                tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func removeCertificateButtonPressed(_ sender: AnyObject) {
        if tableView.selectedRow >= 0 {
            if truststore != nil {
                if truststore!.removeItem(tableView.selectedRow) {
                    tableView.reloadData()
                    enableButtons()
                }
            }
        }
    }
    
    @IBAction func exportButtonPressed(_ sender: AnyObject) {
        if tableView.selectedRow >= 0 {
            if truststore != nil {
                let item = truststore!.items[tableView.selectedRow]
                let savePanel = NSSavePanel()
                if let text = item.subjectSummary {
                    savePanel.nameFieldStringValue = text
                }
                if savePanel.runModal().rawValue == NSFileHandlingPanelOKButton {
                    if let url = savePanel.url {
                        _ = item.export(url)
                    }
                }
            }
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        enableButtons()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSUserInterfaceItemIdentifier(_ input: String) -> NSUserInterfaceItemIdentifier {
	return NSUserInterfaceItemIdentifier(rawValue: input)
}
