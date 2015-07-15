//
//  ViewController.m
//
//  Created by Cyril Murzin on 02/07/15.
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//

#import "ViewController.h"

#import "UMBarcodeScanViewController.h"
#import "UMBarcodeGenerator.h"

#import <AVFoundation/AVFoundation.h>


@interface ViewController () <UMBarcodeScanDelegate>
@property (nonatomic, retain) IBOutlet UIImageView* barcodeImage;

@property (nonatomic, retain) IBOutlet UIButton* scanSystem;
@property (nonatomic, retain) IBOutlet UIButton* scanZXing;
@property (nonatomic, retain) IBOutlet UIButton* scanZBar;

- (IBAction)_scan:(id)sender;
@end

@implementation ViewController
@synthesize barcodeImage = _barcodeImage;
@synthesize scanSystem = _scanSystem;
@synthesize scanZXing = _scanZXing;
@synthesize scanZBar = _scanZBar;

- (void)dealloc
{
    [_barcodeImage release];

    [_scanSystem release];
    [_scanZXing release];
    [_scanZBar release];

    [super dealloc];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];

    _barcodeImage.clipsToBounds = YES;
    _barcodeImage.contentMode = UIViewContentModeScaleAspectFit;

    UMBarcodeScanMode_t* scanModes = [UMBarcodeScanViewController allowedScanModes];
    for (int index = 0; scanModes[index] != kUMBarcodeScanMode_NONE; index++)
    {
        switch (scanModes[index])
        {
        case kUMBarcodeScanMode_System:
            _scanSystem.hidden = NO;
            break;
        case kUMBarcodeScanMode_ZXing:
            _scanZXing.hidden = NO;
            break;
        case kUMBarcodeScanMode_ZBar:
            _scanZBar.hidden = NO;
            break;
        default:
            break;
        }
    }
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
    // else never happens here
    //  though in this case UMBarcodeScanViewController will choose mode based on system:
    //  iOS6    — ZXing
    //  iOS7+   — System

    scanViewController.cancelButtonText = @"Cancel";
    scanViewController.helpButtonText = @"Help";
    scanViewController.hintText = [NSString stringWithFormat:@"Place barcode inside viewfinder to scan with %@", scanViewController.scanMode == kUMBarcodeScanMode_ZXing ? @"ZXing" : (scanViewController.scanMode == kUMBarcodeScanMode_ZBar ? @"ZBar" : @"Syztem")];

    // set of formats depends on scan mode
    scanViewController.barcodeTypes = [NSArray arrayWithObjects:
                                                    kUMBarcodeTypeUPCACode,
                                                    kUMBarcodeTypeUPCECode,
                                                    kUMBarcodeTypeCode39Code,
                                                    kUMBarcodeTypeCode39Mod43Code,
                                                    kUMBarcodeTypeEAN13Code,
                                                    kUMBarcodeTypeEAN8Code,
                                                    kUMBarcodeTypeCode93Code,
                                                    kUMBarcodeTypeCode128Code,
                                                    kUMBarcodeTypePDF417Code,
                                                    kUMBarcodeTypeAztecCode,
                                                    kUMBarcodeTypeQRCode,
                                                    kUMBarcodeTypeInterleaved2of5Code,
                                                    kUMBarcodeTypeITF14Code,
                                                    kUMBarcodeTypeDataMatrixCode,
                                                nil];

    [self presentViewController:scanViewController animated:YES completion:nil];
}

- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController didCancelWithError:(NSError*)error
{
    if (error != nil)
        NSLog(@"### SCAN ERROR: %@", error);

    [scanViewController.presentingViewController dismissViewControllerAnimated:YES
                                                                    completion:^
                                                                            {
                                                                                if (error != nil)
                                                                                {
                                                                                    [[[[UIAlertView alloc] initWithTitle:@"ERROR"
                                                                                                                 message:[error localizedDescription]
                                                                                                                delegate:nil
                                                                                                       cancelButtonTitle:@"OK"
                                                                                                       otherButtonTitles:nil] autorelease] show];
                                                                                }
                                                                            }];
}

- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController didScanString:(NSString*)barcodeData ofBarcodeType:(NSString*)barcodeType
{
    NSLog(@"### SCAN: %@ (%@)", barcodeData, barcodeType);

    _barcodeImage.image = [UMBarcodeGenerator imageWithData:barcodeData encoding:kCFStringEncodingUTF8 barcodeType:barcodeType imageSize:_barcodeImage.bounds.size whiteOpaque:YES error:nil];

#if 0
    if ([scanViewController isSuspended])   // recognized code suspends scanner
        [scanViewController resume];        //  so we have to resume to continue scanning
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

    _barcodeImage.image = nil;
}

#if 1 /* example of viewfinder override with animation */
- (CALayer*)scanViewController:(UMBarcodeScanViewController*)scanViewController addLayerAtIndex:(NSUInteger)index
{
    CAShapeLayer* layer = nil;

    switch (index)
    {
    case 0:
        {
            layer = [CAShapeLayer layer];
            layer.name = @"layer-0";
            layer.strokeColor = [UIColor greenColor].CGColor;
            layer.fillColor = [UIColor clearColor].CGColor;
            layer.lineWidth = 4.;

            layer.lineJoin = kCALineJoinMiter;
            layer.lineCap = kCALineCapSquare;
        }
        break;

    case 1:
        {
            layer = [CAShapeLayer layer];
            layer.name = @"layer-1";
            layer.strokeColor = [UIColor redColor].CGColor;
            layer.fillColor = [UIColor clearColor].CGColor;
            layer.lineWidth = 1.;

            layer.lineCap = kCALineCapSquare;
        }
        break;

    default:
        break;
    }

    return layer;
}

- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController layoutLayer:(CALayer*)layer viewRect:(CGRect)r
{
    if ([layer.name isEqualToString:@"layer-0"])
    {
        // show square viewfinder in portrait orientation
        if (UIInterfaceOrientationIsPortrait(scanViewController.interfaceOrientationForScan))
        {
            CGFloat size = MIN(CGRectGetWidth(r), CGRectGetHeight(r));

            r = CGRectMake(CGRectGetMidX(r) - size / 2., CGRectGetMidY(r) - size / 2., size, size);
        }
        else
        {
            if (CGRectGetWidth(r) > CGRectGetHeight(r))
                r = CGRectInset(r, 16., 48.);
            else
                r = CGRectInset(r, 48., 16.);
        }

        CGMutablePathRef path = CGPathCreateMutable();

        CGPathMoveToPoint(path, NULL, CGRectGetMinX(r), CGRectGetMinY(r) + 16.);
        CGPathAddLineToPoint(path, NULL, CGRectGetMinX(r), CGRectGetMinY(r));
        CGPathAddLineToPoint(path, NULL, CGRectGetMinX(r) + 16., CGRectGetMinY(r));

        CGPathMoveToPoint(path, NULL, CGRectGetMaxX(r), CGRectGetMinY(r) + 16.);
        CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(r), CGRectGetMinY(r));
        CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(r) - 16., CGRectGetMinY(r));

        CGPathMoveToPoint(path, NULL, CGRectGetMaxX(r), CGRectGetMaxY(r) - 16.);
        CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(r), CGRectGetMaxY(r));
        CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(r) - 16., CGRectGetMaxY(r));

        CGPathMoveToPoint(path, NULL, CGRectGetMinX(r), CGRectGetMaxY(r) - 16.);
        CGPathAddLineToPoint(path, NULL, CGRectGetMinX(r), CGRectGetMaxY(r));
        CGPathAddLineToPoint(path, NULL, CGRectGetMinX(r) + 16., CGRectGetMaxY(r));

        if (((CAShapeLayer*)layer).path != NULL)
        {
            CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"path"];
            animation.toValue = (id)path;
            animation.duration = .2;
            animation.fillMode = kCAFillModeForwards;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            animation.removedOnCompletion = NO; // keep it until manual finale path set
            animation.delegate = self;

            [animation setValue:layer forKey:@"layer"]; // propagate owner layer to delegate

            [layer addAnimation:animation forKey:animation.keyPath];
        }
        else
            ((CAShapeLayer*)layer).path = path;

        CGPathRelease(path);
    }
    else if ([layer.name isEqualToString:@"layer-1"])
    {
        // show red line "scanner" in landscape orientation
        if (UIInterfaceOrientationIsLandscape(scanViewController.interfaceOrientationForScan))
        {
            CGMutablePathRef path = CGPathCreateMutable();

            CGPathMoveToPoint(path, NULL, CGRectGetMidX(r), CGRectGetMinY(r) + 16.);
            CGPathAddLineToPoint(path, NULL, CGRectGetMidX(r), CGRectGetMaxY(r) - 16.);

            ((CAShapeLayer*)layer).path = path;

            CGPathRelease(path);
        }
        else
            ((CAShapeLayer*)layer).path = NULL;
    }
}

- (void)animationDidStop:(CAAnimation*)animation finished:(BOOL)flag
{
    if (flag)
    {
        CALayer* layer = [animation valueForKey:@"layer"];
        if (layer != nil)
        {
            if ([layer.name isEqualToString:@"layer-0"])
                ((CAShapeLayer*)layer).path = (CGPathRef)((CABasicAnimation*)animation).toValue;

            [layer removeAnimationForKey:((CABasicAnimation*)animation).keyPath];
        }
    }
}

#endif

@end
