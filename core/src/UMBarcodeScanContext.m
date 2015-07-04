//
//  UMBarcodeScanContext.m
//
//  Created by Cyril Murzin on 02/07/15.
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//

#import "UMBarcodeScanContext.h"

#import "UMBarcodeScanUtilities.h"


NSString* const kUMBarcodeScanTypeUPCACode = @"kUMBarcodeScanTypeUPCACode";
NSString* const kUMBarcodeScanTypeUPCECode = @"kUMBarcodeScanTypeUPCECode";
NSString* const kUMBarcodeScanTypeCode39Code = @"kUMBarcodeScanTypeCode39Code";
NSString* const kUMBarcodeScanTypeCode39Mod43Code = @"kUMBarcodeScanTypeCode39Mod43Code";
NSString* const kUMBarcodeScanTypeEAN13Code = @"kUMBarcodeScanTypeEAN13Code";
NSString* const kUMBarcodeScanTypeEAN8Code = @"kUMBarcodeScanTypeEAN8Code";
NSString* const kUMBarcodeScanTypeCode93Code = @"kUMBarcodeScanTypeCode93Code";
NSString* const kUMBarcodeScanTypeCode128Code = @"kUMBarcodeScanTypeCode128Code";
NSString* const kUMBarcodeScanTypePDF417Code = @"kUMBarcodeScanTypePDF417Code";
NSString* const kUMBarcodeScanTypeAztecCode = @"kUMBarcodeScanTypeAztecCode";
NSString* const kUMBarcodeScanTypeQRCode = @"kUMBarcodeScanTypeQRCode";
NSString* const kUMBarcodeScanTypeInterleaved2of5Code = @"kUMBarcodeScanTypeInterleaved2of5Code";
NSString* const kUMBarcodeScanTypeITF14Code = @"kUMBarcodeScanTypeITF14Code";
NSString* const kUMBarcodeScanTypeDataMatrixCode = @"kUMBarcodeScanTypeDataMatrixCode";

NSString* const kUMBarcodeScanContextChangedOrientation = @"kUMBarcodeScanContextChangedOrientation";

@implementation UMBarcodeScanContext
@dynamic allowedScanModes;
@synthesize delegate = _delegate;

@synthesize cancelButtonText = _cancelButtonText;
@synthesize helpButtonText = _helpButtonText;
@synthesize hintLabelText = _hintLabelText;
@synthesize scanMode = _scanMode;
@synthesize barcodeTypes = _barcodeTypes;

@synthesize keepStatusBarStyle = _keepStatusBarStyle;
@synthesize navigationBarStyle = _navigationBarStyle;
@synthesize navigationBarTintColor = _navigationBarTintColor;

@dynamic initialInterfaceOrientationForViewcontroller;
@synthesize allowFreelyRotatingGuide = _allowFreelyRotatingGuide;
@synthesize showFoundCodePoints = _showFoundCodePoints;

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _cancelButtonText = [@"Cancel" retain];

        _initialInterfaceOrientationForViewcontroller = UIInterfaceOrientationUnknown;
        _allowFreelyRotatingGuide = YES;
        _showFoundCodePoints = NO;

        int index = 0;
        if (UMBarcodeScan_isOS7())
            _allowedScanModes[index++] = kUMBarcodeScanMode_System;
#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
        _allowedScanModes[index++] = kUMBarcodeScanMode_ZXing;
#endif
#if defined(UMBARCODE_SCAN_ZBAR) && UMBARCODE_SCAN_ZBAR
        _allowedScanModes[index++] = kUMBarcodeScanMode_ZBar;
#endif
        _allowedScanModes[index++] = kUMBarcodeScanMode_NONE;
    }

    return self;
}

- (void)dealloc
{
    [_navigationBarTintColor release];

    [_cancelButtonText release];
    [_helpButtonText release];
    [_hintLabelText release];

    [_barcodeTypes release];

    [super dealloc];
}

#pragma mark -

- (UMBarcodeScanMode_t*)allowedScanModes
{
    return _allowedScanModes;
}

- (UIInterfaceOrientation)initialInterfaceOrientationForViewcontroller
{
    return _initialInterfaceOrientationForViewcontroller;
}

- (void)setInitialInterfaceOrientationForViewcontroller:(UIInterfaceOrientation)initialInterfaceOrientationForViewcontroller
{
    if (initialInterfaceOrientationForViewcontroller != _initialInterfaceOrientationForViewcontroller)
    {
        _initialInterfaceOrientationForViewcontroller = initialInterfaceOrientationForViewcontroller;

        [[NSNotificationCenter defaultCenter] postNotificationName:kUMBarcodeScanContextChangedOrientation object:self];
    }
}

@end
