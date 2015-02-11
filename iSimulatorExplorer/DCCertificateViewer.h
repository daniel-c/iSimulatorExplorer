//
//  DCCertificateViewer.h
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 10.10.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

#import <Foundation/Foundation.h>

@interface DCCertificateViewer : NSObject

+(void)showCertificate:(SecCertificateRef)certificate;

@end
