//
//  UMBarcodeScanContext.m
//
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//  Created by Cyril Murzin
//

//  some work derived & base ideas of scan controller are borrowed from CardIO library,
//  the courtesy of eBay Software Foundation. see LICENSE & README files for more info

#import "UMBarcodeScanContext.h"

#import "UMBarcodeScanUtilities.h"


#define kRotationAnimationDuration .2

NSString* const kUMBarcodeTypeUPCACode              = @"UPCA";
NSString* const kUMBarcodeTypeUPCECode              = @"UPCE";
NSString* const kUMBarcodeTypeCode39Code            = @"Code39";
NSString* const kUMBarcodeTypeCode39Mod43Code       = @"Code39Mod43";
NSString* const kUMBarcodeTypeEAN13Code             = @"EAN13";
NSString* const kUMBarcodeTypeEAN8Code              = @"EAN8";
NSString* const kUMBarcodeTypeCode93Code            = @"Code93";
NSString* const kUMBarcodeTypeCode128Code           = @"Code128";
NSString* const kUMBarcodeTypePDF417Code            = @"PDF417";
NSString* const kUMBarcodeTypeAztecCode             = @"Aztec";
NSString* const kUMBarcodeTypeQRCode                = @"QR";
NSString* const kUMBarcodeTypeInterleaved2of5Code   = @"Interleaved2of5";
NSString* const kUMBarcodeTypeITF14Code             = @"ITF14";
NSString* const kUMBarcodeTypeDataMatrixCode        = @"DataMatrix";

NSString* const kUMBarcodeScanContextChangedOrientation = @"kUMBarcodeScanContextChangedOrientation";

@implementation UMBarcodeScanContext
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
@dynamic orientationAnimationDuration;
@synthesize allowFreelyRotatingGuide = _allowFreelyRotatingGuide;

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _cancelButtonText = [@"Cancel" retain];

        _initialInterfaceOrientationForViewcontroller = UIInterfaceOrientationUnknown;
        _allowFreelyRotatingGuide = YES;
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

- (NSTimeInterval)orientationAnimationDuration
{
    return kRotationAnimationDuration;
}

@end
