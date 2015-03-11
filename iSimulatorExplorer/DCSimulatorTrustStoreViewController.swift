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
                if NSFileManager.defaultManager().fileExistsAtPath(truststorePath) {
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
                notavailableInfoTextField.hidden = false
                tableScrollView!.hidden = true
            }
            else {
                notavailableInfoTextField.hidden = true
                tableScrollView!.hidden = false
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func loadView() {
        super.loadView()
        enableButtons()
    }
    
    func enableButtons() {
        let enableActionOnSelected = (tableView.selectedRow >= 0)
        let enableActionOnTrustStore = (truststore != nil)
        removeButton.enabled = enableActionOnSelected
        exportButton.enabled = enableActionOnSelected
        importServerButton.enabled = enableActionOnTrustStore
        importFileButton.enabled = enableActionOnTrustStore
    }
    
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        
        return truststore?.items.count ?? 0
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let result = tableView.makeViewWithIdentifier("DataCell", owner: self) as? NSTableCellView {
            if truststore != nil {
                if let text = truststore?.items[row].subjectSummary {
                    result.textField!.stringValue = text
                }
            }
            return result
        }
        return nil
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return nil;
    }
    
    @IBAction func viewCertificateButtonPressed(sender: NSButton) {
        if let cellView = sender.superview as? NSTableCellView {
            let row = tableView.rowForView(cellView)
            if row >= 0 {
                tableView.selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
                if let cert = truststore?.items[row].certificate {
                    showCertificate(cert)
                }
            }
        }
        return;
    }
    
    func showCertificate(cert : SecCertificateRef) {
        SFCertificatePanel.sharedCertificatePanel().runModalForCertificates([cert], showGroup: false)
    }
    
    @IBAction func importCertificateFromServerButtonPressed(sender: AnyObject) {
        
        var importPanel = DCImportCertificateWindowController(windowNibName: "DCImportCertificateWindowController")
        let result =  NSApplication.sharedApplication().runModalForWindow(importPanel.window!)
        if result == 0 {
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
    
    @IBAction func importCertificateFromFile(sender: AnyObject) {
        var openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == NSFileHandlingPanelOKButton {
            if let urls = openPanel.URLs as? [NSURL] {
                for url in urls {
                    if let data = NSData(contentsOfURL: url) {
                        
                        var format : SecExternalFormat = SecExternalFormat(kSecFormatUnknown)
                        var itemType : SecExternalItemType = SecExternalItemType(kSecItemTypeCertificate)
                        var outItems : Unmanaged<CFArray>?
                        
                        let status = SecItemImport(data, nil, &format, &itemType, 0, nil, nil, &outItems)
                        if let itemCFArray = outItems?.takeRetainedValue() {
                            let itemArray = itemCFArray as NSArray
                            if itemArray.count > 0 && itemType == SecExternalItemType(kSecItemTypeCertificate) {
                                
                                // Here we must use an unconditional downcast (conditional downcast does not work here).
                                // In Swift 1.2 it is 'as!' while in Swift < 1.2 there is only the unconditional cast 'as'
                                
                                //For Swift 1.2:
                                // let item = DCSimulatorTruststoreItem(certificate: itemArray[0] as! SecCertificateRef)
                                //For Swift < 1.2:
                                let item = DCSimulatorTruststoreItem(certificate: itemArray[0] as SecCertificateRef)
                                
                                if truststore!.addItem(item) {
                                    tableView.reloadData()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func removeCertificateButtonPressed(sender: AnyObject) {
        if tableView.selectedRow >= 0 {
            if truststore != nil {
                if truststore!.removeItem(tableView.selectedRow) {
                    tableView.reloadData()
                    enableButtons()
                }
            }
        }
    }
    
    @IBAction func exportButtonPressed(sender: AnyObject) {
        if tableView.selectedRow >= 0 {
            if truststore != nil {
                let item = truststore!.items[tableView.selectedRow]
                var savePanel = NSSavePanel()
                if let text = item.subjectSummary {
                    savePanel.nameFieldStringValue = text
                }
                if savePanel.runModal() == NSFileHandlingPanelOKButton {
                    if let url = savePanel.URL {
                        item.export(url)
                    }
                }
            }
        }
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        enableButtons()
    }
}
