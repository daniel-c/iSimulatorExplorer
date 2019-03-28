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
    
    var sha1: Data?, subject : Data?, data : Data?
    
    var tset : Data?
    
    init() {
        
        tset = ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
            "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n" +
            "<plist version=\"1.0\">\n" +
            "<array/>\n" +
            "</plist>\n").data(using: String.Encoding.utf8, allowLossyConversion: false)
        
    }
    
    convenience init (sha1: Data?, subject : Data?, tset : Data?, data : Data?)
    {
        self.init()
        self.sha1 = sha1
        self.subject = subject
        self.tset = tset
        self.data = data
    }
    
    convenience init (certificate : SecCertificate) {
        self.init()
        let cdata = SecCertificateCopyData(certificate)
        data = cdata as Data
        sha1 = getThumbprint()
        subject = getNormalizedSubject()
    }
    
    private var _certificate : SecCertificate?
    var certificate : SecCertificate? {
        get {
            if _certificate == nil && data != nil {
                _certificate = SecCertificateCreateWithData(nil, data! as CFData)
            }
            return _certificate;
        }
    }
    
    var subjectSummary : String? {
        get {
            if certificate != nil {
                return SecCertificateCopySubjectSummary(certificate!) as String?
            }
            return nil
        }
    }
    
    
    func getNormalizedSubject() -> Data? {
        //BUG Something to causes an exception in the swift compiler!
        //if let data = SecCertificateCopyNormalizedSubjectContent(certificate, nil)?.takeRetainedValue() as? NSData {
        
        if certificate != nil {
            if let cdata = SecCertificateCopyNormalizedSubjectContent(certificate!, nil) {
                let data = cdata as Data
                return data
            }
        }
        return nil
    }
    
    func calcSHA1(_ data : Data) -> Data {
        
        let digest = NSMutableData(length: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1((data as NSData).bytes, CC_LONG(data.count), digest!.mutableBytes.assumingMemoryBound(to: UInt8.self))
        return digest! as Data
    }
    
    func getThumbprint() -> Data {
        
        return calcSHA1(data!)
    }
    
    func hexstringFromData(_ data : Data) -> String {
        
        return data.withUnsafeBytes { (bytes : UnsafePointer<UInt8>) -> String in
            var str : String = ""
            var dataBytes = bytes
            for _ in 0 ..< data.count {
                str += NSString(format: "%02x", dataBytes.pointee) as String
                dataBytes = dataBytes.successor()
            }
            return str
        }
    }
    
    func getThumbprintAsHexString() -> String {
        return hexstringFromData(getThumbprint())
    }
    
    func export(_ url : URL) -> Bool {
        var result = false
        if let cert = certificate {
            var outData : CFData?
            let status = SecItemExport(cert, SecExternalFormat.formatUnknown, SecItemImportExportFlags.pemArmour, nil, &outData)
            if status == errSecSuccess {
                if let cdata = outData {
                    let data = cdata as Data
                    result = (try? data.write(to: url, options: [])) != nil
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
        
        var database : OpaquePointer? = nil
        var result = sqlite3_open(path.cString(using: String.Encoding.utf8)!, &database)
        if result == SQLITE_OK {
            var sqlStatements : OpaquePointer? = nil
            result = sqlite3_prepare(database, "SELECT sha1, subj, tset, data FROM tsettings", -1, &sqlStatements, nil)
            if result == SQLITE_OK {
                while (sqlite3_step(sqlStatements) == SQLITE_ROW)
                {
                    var dataLength = sqlite3_column_bytes(sqlStatements, 0);
                    if (dataLength > 0)
                    {
                        let blobData = sqlite3_column_blob(sqlStatements, 0)
                        let sha1 = Data(bytes: blobData!, count: Int(dataLength))
                        
                        var subj : Data?;
                        var tset : Data?;
                        var data : Data?;
                        
                        dataLength = sqlite3_column_bytes(sqlStatements, 1);
                        if dataLength > 0 {
                            if let blobData = sqlite3_column_blob(sqlStatements, 1) {
                                subj = Data(bytes: blobData, count: Int(dataLength))
                            }
                        }
                        dataLength = sqlite3_column_bytes(sqlStatements, 2);
                        if dataLength > 0 {
                            if let blobData = sqlite3_column_blob(sqlStatements, 2) {
                                tset = Data(bytes: blobData, count: Int(dataLength))
                            }
                        }
                        dataLength = sqlite3_column_bytes(sqlStatements, 3);
                        if dataLength > 0 {
                            if let blobData = sqlite3_column_blob(sqlStatements, 3) {
                                data = Data(bytes: blobData, count: Int(dataLength))
                            }

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
    
    func removeItem(_ index : Int) -> Bool {
        var success = false
        if index >= 0 && index < items.count {
            let item = items[index]
            
            let certificateSha1 = item.getThumbprintAsHexString().uppercased().cString(using: String.Encoding.utf8)!
            
            var database : OpaquePointer? = nil
            var result = sqlite3_open(path.cString(using: String.Encoding.utf8)!, &database)
            if result == SQLITE_OK {
                var sqlStatements : OpaquePointer? = nil
                result = sqlite3_prepare_v2(database, "DELETE FROM tsettings WHERE hex(sha1)=?", -1, &sqlStatements, nil)
                if result == SQLITE_OK {
                    
                    result = sqlite3_bind_text(sqlStatements, 1, certificateSha1, -1, nil) // SQLITE_TRANSIENT);
                    if result == SQLITE_OK {
                        result = sqlite3_step(sqlStatements);
                        if result == SQLITE_DONE  {
                            if (sqlite3_changes(database) > 0) {
                                items.remove(at: index)
                                success = true
                            }
                            else {
                                NSLog("Could not remove the certificate \(String(describing: item.subjectSummary)) from TrustStore.sqlite3")
                            }
                        }
                        else {
                            NSLog("Error (sqlite3 code:\(result)) removing the certificate \(String(describing: item.subjectSummary)) from TrustStore.sqlite3")
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
    
    func addItem(_ item : DCSimulatorTruststoreItem) -> Bool {
        
        var success = false
        var database : OpaquePointer? = nil
        var result = sqlite3_open(path.cString(using: String.Encoding.utf8)!, &database)
        if result == SQLITE_OK {
            var sqlStatements : OpaquePointer? = nil
            result = sqlite3_prepare_v2(database, "INSERT INTO tsettings (sha1, subj, tset, data) VALUES (?, ?, ?, ?)", -1, &sqlStatements, nil)
            
            if result == SQLITE_OK {
                result = sqlite3_bind_blob(sqlStatements, 1, (item.sha1! as NSData).bytes, Int32(item.sha1!.count), nil) //SQLITE_TRANSIENT);
                result = sqlite3_bind_blob(sqlStatements, 2, (item.subject! as NSData).bytes, Int32(item.subject!.count), nil) // SQLITE_STATIC);
                result = sqlite3_bind_blob(sqlStatements, 3, (item.tset! as NSData).bytes, Int32(item.tset!.count), nil) // SQLITE_STATIC);
                result = sqlite3_bind_blob(sqlStatements, 4, (item.data! as NSData).bytes, Int32(item.data!.count), nil) //SQLITE_STATIC);
                if result == SQLITE_OK {
                    result = sqlite3_step(sqlStatements);
                    if result == SQLITE_DONE {
                        if sqlite3_changes(database) > 0 {
                            items.append(item);
                            success = true
                        }
                        else {
                            NSLog("Could not add the certificate \(String(describing: item.subjectSummary)) to TrustStore.sqlite3")
                        }
                    }
                    else
                    {
                        //TODO: result == SQLITE_CONSTRAINT (19) -> due to already existing item: show a message box for this
                        NSLog("Error (sqlite3 code:\(result)) adding the certificate \(String(describing: item.subjectSummary)) to TrustStore.sqlite3")
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
