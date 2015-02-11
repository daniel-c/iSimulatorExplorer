//
//  DCSimulatorTrustStore.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 11.10.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

import Foundation

class DCSimulatorTruststoreItem {
    
    var sha1: NSData?, subject : NSData?, data : NSData?
    
    var tset : NSData?
    
    init() {
        
        tset = ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
            "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n" +
            "<plist version=\"1.0\">\n" +
            "<array/>\n" +
            "</plist>\n").dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
    }
    
    convenience init (sha1: NSData?, subject : NSData?, tset : NSData?, data : NSData?)
    {
        self.init()
        self.sha1 = sha1
        self.subject = subject
        self.tset = tset
        self.data = data
    }
    
    convenience init (certificate : SecCertificate) {
        self.init()
        let cdata = SecCertificateCopyData(certificate).takeRetainedValue()
        data = cdata as NSData
        sha1 = getThumbprint()
        subject = getNormalizedSubject()
    }
    
    private var _certificate : SecCertificate?
    var certificate : SecCertificate? {
        get {
            if _certificate == nil && data != nil {
                _certificate = SecCertificateCreateWithData(nil, data!)?.takeRetainedValue()
            }
            return _certificate;
        }
    }
    
    var subjectSummary : String? {
        get {
            if certificate != nil {
                return SecCertificateCopySubjectSummary(certificate).takeRetainedValue()
            }
            return nil
        }
    }
    
    
    func getNormalizedSubject() -> NSData? {
        //BUG Something to causes an exception in the swift compiler!
        //if let data = SecCertificateCopyNormalizedSubjectContent(certificate, nil)?.takeRetainedValue() as? NSData {
        
        if let cdata = SecCertificateCopyNormalizedSubjectContent(certificate, nil)?.takeRetainedValue() {
            let data = cdata as NSData
            return data
        }
        return nil
    }
    
    func calcSHA1(data : NSData) -> NSData {
        
        var digest = NSMutableData(length: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1(data.bytes, CC_LONG(data.length), UnsafeMutablePointer<UInt8>(digest!.mutableBytes))
        return digest!
    }
    
    func getThumbprint() -> NSData {
        
        return calcSHA1(data!)
    }
    
    func hexstringFromData(data : NSData) -> String {
        var dataBytes = UnsafePointer<UInt8>(data.bytes)
        var str : String = ""
        for var i = 0; i < data.length; i++ {
            dataBytes.memory
            str += NSString(format: "%02x", dataBytes.memory)
            dataBytes = dataBytes.successor()
        }
        return str
    }
    
    func getThumbprintAsHexString() -> String {
        return hexstringFromData(getThumbprint())
    }
    
    func export(url : NSURL) -> Bool {
        var result = false
        if let cert = certificate? {
            var outData : Unmanaged<CFData>?
            let status = SecItemExport(cert, SecExternalFormat(kSecFormatUnknown), SecItemImportExportFlags(kSecItemPemArmour), nil, &outData)
            if status == errSecSuccess {
                if let cdata = outData?.takeRetainedValue() {
                    let data = cdata as NSData
                    result = data.writeToURL(url, atomically: false)
                }
            }
        }
        return result
    }
}

class DCSimulatorTruststore {
    
    init (path : String) {
        self.path = path
        items = [DCSimulatorTruststoreItem]()
    }
    
    private var path : String
    
    private(set) var items : [DCSimulatorTruststoreItem]
    
    func openTrustStore() {
        
        var database : COpaquePointer = nil
        var result = sqlite3_open(path.cStringUsingEncoding(NSUTF8StringEncoding)!, &database)
        if result == SQLITE_OK {
            var sqlStatements : COpaquePointer = nil
            result = sqlite3_prepare(database, "SELECT sha1, subj, tset, data FROM tsettings", -1, &sqlStatements, nil)
            if result == SQLITE_OK {
                while (sqlite3_step(sqlStatements) == SQLITE_ROW)
                {
                    var dataLength = sqlite3_column_bytes(sqlStatements, 0);
                    if (dataLength > 0)
                    {
                        var blobData = sqlite3_column_blob(sqlStatements, 0);
                        let sha1 = NSData(bytes: blobData, length: Int(dataLength))
                        
                        var subj : NSData?;
                        var tset : NSData?;
                        var data : NSData?;
                        
                        dataLength = sqlite3_column_bytes(sqlStatements, 1);
                        if dataLength > 0 {
                            blobData = sqlite3_column_blob(sqlStatements, 1);
                            subj = NSData(bytes: blobData, length: Int(dataLength))
                        }
                        dataLength = sqlite3_column_bytes(sqlStatements, 2);
                        if dataLength > 0 {
                            blobData = sqlite3_column_blob(sqlStatements, 2);
                            tset = NSData(bytes: blobData, length: Int(dataLength))
                        }
                        dataLength = sqlite3_column_bytes(sqlStatements, 3);
                        if dataLength > 0 {
                            blobData = sqlite3_column_blob(sqlStatements, 3);
                            data = NSData(bytes: blobData, length: Int(dataLength))
                            
                            let item = DCSimulatorTruststoreItem(sha1: sha1, subject: subj, tset: tset, data: data)
                            items.append(item)
                        }
                    }
                }
            }
            if sqlStatements != nil {
                sqlite3_finalize(sqlStatements);
            }
        }
        if database != nil {
            sqlite3_close(database)
        }
    }
    
    func removeItem(index : Int) -> Bool {
        var success = false
        if index >= 0 && index < items.count {
            let item = items[index]
            
            let certificateSha1 = item.getThumbprintAsHexString().uppercaseString.cStringUsingEncoding(NSUTF8StringEncoding)!
            
            var database : COpaquePointer = nil
            var result = sqlite3_open(path.cStringUsingEncoding(NSUTF8StringEncoding)!, &database)
            if result == SQLITE_OK {
                var sqlStatements : COpaquePointer = nil
                result = sqlite3_prepare_v2(database, "DELETE FROM tsettings WHERE hex(sha1)=?", -1, &sqlStatements, nil)
                if result == SQLITE_OK {
                    
                    result = sqlite3_bind_text(sqlStatements, 1, certificateSha1, -1, nil) // SQLITE_TRANSIENT);
                    if result == SQLITE_OK {
                        result = sqlite3_step(sqlStatements);
                        if result == SQLITE_DONE  {
                            if (sqlite3_changes(database) > 0) {
                                items.removeAtIndex(index)
                                success = true
                            }
                            else {
                                NSLog("Could not remove the certificate \(item.subjectSummary) from TrustStore.sqlite3")
                            }
                        }
                        else {
                            NSLog("Error (sqlite3 code:\(result)) removing the certificate \(item.subjectSummary) from TrustStore.sqlite3")
                        }
                    }
                }
                if sqlStatements != nil {
                    sqlite3_finalize(sqlStatements);
                }
            }
            if database != nil {
                sqlite3_close(database);
            }
        }
        return success
    }
    
    func addItem(item : DCSimulatorTruststoreItem) -> Bool {
        
        var success = false
        var database : COpaquePointer = nil
        var result = sqlite3_open(path.cStringUsingEncoding(NSUTF8StringEncoding)!, &database)
        if result == SQLITE_OK {
            var sqlStatements : COpaquePointer = nil
            result = sqlite3_prepare_v2(database, "INSERT INTO tsettings (sha1, subj, tset, data) VALUES (?, ?, ?, ?)", -1, &sqlStatements, nil)
            
            if result == SQLITE_OK {
                result = sqlite3_bind_blob(sqlStatements, 1, item.sha1!.bytes, Int32(item.sha1!.length), nil) //SQLITE_TRANSIENT);
                result = sqlite3_bind_blob(sqlStatements, 2, item.subject!.bytes, Int32(item.subject!.length), nil) // SQLITE_STATIC);
                result = sqlite3_bind_blob(sqlStatements, 3, item.tset!.bytes, Int32(item.tset!.length), nil) // SQLITE_STATIC);
                result = sqlite3_bind_blob(sqlStatements, 4, item.data!.bytes, Int32(item.data!.length), nil) //SQLITE_STATIC);
                if result == SQLITE_OK {
                    result = sqlite3_step(sqlStatements);
                    if result == SQLITE_DONE {
                        if sqlite3_changes(database) > 0 {
                            items.append(item);
                            success = true
                        }
                        else {
                            NSLog("Could not add the certificate \(item.subjectSummary) to TrustStore.sqlite3")
                        }
                    }
                    else
                    {
                        //TODO: result == SQLITE_CONSTRAINT (19) -> due to already existing item: show a message box for this
                        NSLog("Error (sqlite3 code:\(result)) adding the certificate \(item.subjectSummary) to TrustStore.sqlite3")
                    }
                }
            }
            if sqlStatements != nil {
                sqlite3_finalize(sqlStatements);
            }
        }
        if database != nil {
            sqlite3_close(database);
        }
        return success
    }
}
