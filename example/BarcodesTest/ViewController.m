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


#define kViewFinderAimMargin    16.

@interface ViewController () <
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
                                CAAnimationDelegate,
#endif
                                UMBarcodeScanDelegate>

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

- (instancetype)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        _barcodeGenerator = [[UMBarcodeGenerator alloc] initWithGenMode:kUMBarcodeGenMode_System];
    }
    
    return self;
}

- (void)dealloc
{
    [_barcodeImage release];

    [_scanSystem release];
    [_scanZXing release];
    [_scanZBar release];

    [_barcodeGenerator release];
    
    [super dealloc];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];

    _barcodeImage.clipsToBounds = YES;
    _barcodeImage.contentMode = UIViewContentModeCenter;
//  _barcodeImage.backgroundColor = [UIColor magentaColor];

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
    scanViewController.hintText = [NSString stringWithFormat:@"Place barcode inside viewfinder to scan with %@",
                                                                            scanViewController.scanMode == kUMBarcodeScanMode_ZXing ? @"ZXing" :
                                                                                (scanViewController.scanMode == kUMBarcodeScanMode_ZBar ? @"ZBar" : @"System")];
    scanViewController.torchMode = kUMBarcodeScanTorchMode_BUTTON | kUMBarcodeScanTorchModeInit_AUTO;

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

    _barcodeImage.image = [_barcodeGenerator imageWithData:barcodeData encoding:kCFStringEncodingUTF8 barcodeType:barcodeType imageSize:_barcodeImage.bounds.size whiteOpaque:YES error:nil];

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

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    _barcodeImage.image = nil;
#else
    _barcodeImage.image = [_barcodeGenerator imageWithData:@"abcdABCD123\nЧадъ и угаръ" encoding:kCFStringEncodingUTF8 barcodeType:/*kUMBarcodeTypeQRCode*/ kUMBarcodeTypeAztecCode imageSize:_barcodeImage.bounds.size whiteOpaque:YES error:nil];

    [scanViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
#endif
}

/* example of viewfinder override with animation */
/* since UMBarcodeScanViewController has no built-in viewfinder anymore it would be wise idea to borrow the code below to own project */
- (CALayer*)scanViewController:(UMBarcodeScanViewController*)scanViewController addLayerAtIndex:(NSUInteger)index
{
    CAShapeLayer* layer = nil;

    switch (index)
    {
    case 0: // viewfinder frame
        {
            layer = [CAShapeLayer layer];
            layer.name = @"layer-0";
            layer.strokeColor = [UIColor greenColor].CGColor;
            layer.fillColor = [UIColor clearColor].CGColor;
            layer.lineWidth = 4.;
        }
        break;

    case 1: // barcode red-line "scanner"
        {
            layer = [CAShapeLayer layer];
            layer.name = @"layer-1";
            layer.strokeColor = [UIColor redColor].CGColor;
            layer.fillColor = [UIColor clearColor].CGColor;
            layer.lineWidth = 1.5;
        }
        break;

    default:
        break;
    }

    return layer;
}

- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController layoutLayer:(CALayer*)layer atIndex:(NSUInteger)index viewRect:(CGRect)r
{
    switch (index)
    {
    case 0:
        {
            // show square viewfinder in portrait orientation

            if (UIInterfaceOrientationIsPortrait(scanViewController.interfaceOrientationForScan))
            {
                CGFloat size = MIN(CGRectGetWidth(r), CGRectGetHeight(r)) - 2. * kViewFinderAimMargin;

                r = CGRectMake(CGRectGetMidX(r) - size / 2., CGRectGetMidY(r) - size / 2., size, size);
            }
            else
            {
                if (CGRectGetWidth(r) > CGRectGetHeight(r))
                    r = CGRectInset(r, kViewFinderAimMargin, 3. * kViewFinderAimMargin);
                else
                    r = CGRectInset(r, 3. * kViewFinderAimMargin, kViewFinderAimMargin);
            }

            CGMutablePathRef path = CGPathCreateMutable();

            CGPathMoveToPoint(path, NULL, CGRectGetMinX(r), CGRectGetMinY(r) + kViewFinderAimMargin);
            CGPathAddLineToPoint(path, NULL, CGRectGetMinX(r), CGRectGetMinY(r));
            CGPathAddLineToPoint(path, NULL, CGRectGetMinX(r) + kViewFinderAimMargin, CGRectGetMinY(r));

            CGPathMoveToPoint(path, NULL, CGRectGetMaxX(r), CGRectGetMinY(r) + kViewFinderAimMargin);
            CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(r), CGRectGetMinY(r));
            CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(r) - kViewFinderAimMargin, CGRectGetMinY(r));

            CGPathMoveToPoint(path, NULL, CGRectGetMaxX(r), CGRectGetMaxY(r) - kViewFinderAimMargin);
            CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(r), CGRectGetMaxY(r));
            CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(r) - kViewFinderAimMargin, CGRectGetMaxY(r));

            CGPathMoveToPoint(path, NULL, CGRectGetMinX(r), CGRectGetMaxY(r) - kViewFinderAimMargin);
            CGPathAddLineToPoint(path, NULL, CGRectGetMinX(r), CGRectGetMaxY(r));
            CGPathAddLineToPoint(path, NULL, CGRectGetMinX(r) + kViewFinderAimMargin, CGRectGetMaxY(r));

            if (((CAShapeLayer*)layer).path != NULL)
            {
                CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"path"];
                animation.toValue = (id)path;
                animation.duration = scanViewController.orientationAnimationDuration;
                animation.fillMode = kCAFillModeForwards;
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
                animation.removedOnCompletion = NO; // keep it until manual finale path set
                animation.delegate = self;

                // propagate values to delegate
                [animation setValue:layer forKey:@"layer"];
                [animation setValue:(id)path forKey:@"path"];

                [layer addAnimation:animation forKey:layer.name];
            }
            else
                ((CAShapeLayer*)layer).path = path;

            CGPathRelease(path);
        }
        break;

    case 1:
        {
            // show red-line "scanner" in landscape orientation

            float opacity = UIInterfaceOrientationIsLandscape(scanViewController.interfaceOrientationForScan) ? 1. : .0;

            CGMutablePathRef path = CGPathCreateMutable();

            CGFloat delta = kViewFinderAimMargin + (CGRectGetHeight(r) - 2. * kViewFinderAimMargin) / 2. * (1. - opacity);

            CGPathMoveToPoint(path, NULL, CGRectGetMidX(r), CGRectGetMinY(r) + delta);
            CGPathAddLineToPoint(path, NULL, CGRectGetMidX(r), CGRectGetMaxY(r) - delta);

            if (((CAShapeLayer*)layer).path != NULL)
            {
                CABasicAnimation* animation1 = [CABasicAnimation animationWithKeyPath:@"path"];
                animation1.toValue = (id)path;

                CABasicAnimation* animation2 = [CABasicAnimation animationWithKeyPath:@"opacity"];
                animation2.toValue = [NSNumber numberWithFloat:opacity];

                CAAnimationGroup* animation = [CAAnimationGroup animation];
                animation.animations = [NSArray arrayWithObjects:animation1, animation2, nil];
                animation.fillMode = kCAFillModeForwards;
                animation.duration = scanViewController.orientationAnimationDuration;
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
                animation.repeatCount = 1.;
                animation.removedOnCompletion = NO; // keep it until manual finale path set
                animation.delegate = self;

                // propagate values to delegate
                [animation setValue:layer forKey:@"layer"];
                [animation setValue:(id)path forKey:@"path"];
                [animation setValue:[NSNumber numberWithFloat:opacity] forKey:@"opacity"];

                [layer addAnimation:animation forKey:layer.name];
            }
            else
            {
                ((CAShapeLayer*)layer).path = path;

                layer.opacity = opacity;
            }

            CGPathRelease(path);
        }
        break;

    default:
        break;
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
            {
                ((CAShapeLayer*)layer).path = (CGPathRef)[animation valueForKey:@"path"];
            }
            else if ([layer.name isEqualToString:@"layer-1"])
            {
                ((CAShapeLayer*)layer).path = (CGPathRef)[animation valueForKey:@"path"];
                layer.opacity = [[animation valueForKey:@"opacity"] floatValue];
            }

            [layer removeAnimationForKey:layer.name];
        }
    }
}

@end
