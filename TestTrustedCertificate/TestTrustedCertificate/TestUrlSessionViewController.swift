//
//  TestUrlSessionViewController.swift
//  TestTrustedCertificate
//
//  Created by Daniel Cerutti on 12/11/15.
//  Copyright © 2015 Cerutti Software Design. All rights reserved.
//

import UIKit

class TestUrlSessionViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        webView.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    @IBAction func openUrlButton(sender: AnyObject) {
        if let text = urlTextField.text {
            urlTextField.resignFirstResponder()
            if let url = NSURL(string: text){
                
                let session = NSURLSession.init(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
                
                session.dataTaskWithURL(url, completionHandler: { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
                    if error != nil {
                        let text = "<html><header></header><body><h2 style=\"color:red\">\(error!.localizedDescription)</h2</body></html>"
                        self.webView.loadHTMLString (text, baseURL:NSURL(string:"localhost"))
                    }
                    else
                    {
                        let mimeType = (response?.MIMEType != nil) ? response!.MIMEType! : "text/html"
                        let encoding = (response?.textEncodingName != nil) ? response!.textEncodingName! : "utf-8"
                        
                        self.webView.loadData(data!, MIMEType: mimeType, textEncodingName: encoding, baseURL: url)
                    }
                }).resume()
            }
        }
    }
    
}

