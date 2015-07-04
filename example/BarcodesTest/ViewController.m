//
//  ViewController.m
//
//  Created by Cyril Murzin on 02/07/15.
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//

#import "ViewController.h"

#import "UMBarcodeScanViewController.h"

#import <AVFoundation/AVFoundation.h>


@interface ViewController () <UMBarcodeScanDelegate>
@property (nonatomic, retain) IBOutlet UIButton* scanSystem;
@property (nonatomic, retain) IBOutlet UIButton* scanZXing;
@property (nonatomic, retain) IBOutlet UIButton* scanZBar;

- (IBAction)_scan:(id)sender;
@end

@implementation ViewController
@synthesize scanSystem = _scanSystem;
@synthesize scanZXing = _scanZXing;
@synthesize scanZBar = _scanZBar;

- (void)dealloc
{
    [_scanSystem release];
    [_scanZXing release];
    [_scanZBar release];
    
    [super dealloc];
}

#pragma mark -

- (IBAction)_scan:(id)sender
{
    NSLog(@"### SCAN");

    UMBarcodeScanViewController* scanViewController = [[[UMBarcodeScanViewController alloc] initWithScanDelegate:self] autorelease];
    
    if (sender == _scanSystem)
        scanViewController.scanMode = kUMBarcodeScanMode_System;
    else if (sender == _scanZXing)
        scanViewController.scanMode = kUMBarcodeScanMode_ZXing;
    else if (sender == _scanZBar)
        scanViewController.scanMode = kUMBarcodeScanMode_ZBar;
    // else never happens, though UMBarcodeScanViewController will choose mode based on system: iOS6 — ZXing, iOS7+ — System
    
    scanViewController.cancelButtonText = @"Cancel";
    scanViewController.helpButtonText = @"Help";
    scanViewController.hintText = [NSString stringWithFormat:@"Place barcode inside viewfinder to scan with %@", scanViewController.scanMode == kUMBarcodeScanMode_ZXing ? @"ZXing" : (scanViewController.scanMode == kUMBarcodeScanMode_ZBar ? @"ZBar" : @"Syztem")];

    // set of formats depends on scan mode
    scanViewController.barcodeTypes = [NSArray arrayWithObjects:
                                                    kUMBarcodeScanTypeUPCACode,
                                                    kUMBarcodeScanTypeUPCECode,
                                                    kUMBarcodeScanTypeCode39Code,
                                                    kUMBarcodeScanTypeCode39Mod43Code,
                                                    kUMBarcodeScanTypeEAN13Code,
                                                    kUMBarcodeScanTypeEAN8Code,
                                                    kUMBarcodeScanTypeCode93Code,
                                                    kUMBarcodeScanTypeCode128Code,
                                                    kUMBarcodeScanTypePDF417Code,
                                                    kUMBarcodeScanTypeAztecCode,
                                                    kUMBarcodeScanTypeQRCode,
                                                    kUMBarcodeScanTypeInterleaved2of5Code,
                                                    kUMBarcodeScanTypeITF14Code,
                                                    kUMBarcodeScanTypeDataMatrixCode,
                                                nil];

    UIViewController* parent = self.presentedViewController;
    if (parent == nil)
        parent = self;

    [parent presentViewController:scanViewController animated:YES completion:nil];
}

- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController didCancelWithError:(NSError*)error
{
    if (error != nil)
        NSLog(@"### SCAN ERROR: %@", error);

    [scanViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController didScanString:(NSString*)barcodeData ofBarcodeType:(NSString*)barcodeType
{
    NSLog(@"### SCAN: %@ (%@)", barcodeData, barcodeType);

#if 0
    if ([scanViewController isSuspended]) // recognized code suspends scanner
        [scanViewController resume];
#else
    [scanViewController.presentingViewController dismissViewControllerAnimated:YES
                                                                    completion:^
                                                                            {
                                                                                [[[[UIAlertView alloc] initWithTitle:barcodeType
                                                                                                             message:barcodeData
                                                                                                            delegate:nil
                                                                                                   cancelButtonTitle:@"OK"
                                                                                                   otherButtonTitles:nil] autorelease] show];
                                                                            }];
#endif
}

- (void)scanViewControllerDidPressHelpButton:(UMBarcodeScanViewController*)scanViewController
{
    NSLog(@"### SCAN WANTS HELP");
}

@end
