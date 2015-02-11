//
//  DCCertificateViewer.m
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 10.10.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

#import "DCCertificateViewer.h"
#import <SecurityInterface/SFCertificatePanel.h>

@implementation DCCertificateViewer

+(void)showCertificate:(SecCertificateRef)certificate
{
    SFCertificatePanel* panel = [SFCertificatePanel sharedCertificatePanel];
    [panel runModalForCertificates:@[(__bridge id)(certificate)] showGroup:NO];
}

@end
