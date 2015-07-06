//
//  UMBarcodeScanViewController.m
//
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//  Created by Cyril Murzin
//

//  some work derived & base ideas of scan controller are borrowed from CardIO library,
//  the courtesy of eBay Software Foundation. see LICENSE & README files for more info

#import "UMBarcodeScanViewControllerPvt.h"

#import "UMBarcodeViewController.h"
#import "UMBarcodeScanContext.h"
#import "UMBarcodeScanUtilities.h"

#import <libkern/OSAtomic.h>


@implementation UMBarcodeScanViewController
@dynamic cancelButtonText;
@dynamic helpButtonText;
@dynamic hintText;
@dynamic scanMode;
@dynamic barcodeTypes;

@synthesize context = _context;
@synthesize shouldStoreStatusBarStyle = _shouldStoreStatusBarStyle;
@synthesize statusBarWasOriginallyHidden = _statusBarWasOriginallyHidden;
@synthesize originalStatusBarStyle = _originalStatusBarStyle;

- (instancetype)initWithScanDelegate:(id<UMBarcodeScanDelegate>)delegate
{
    UMBarcodeScanContext* context = [[[UMBarcodeScanContext alloc] init] autorelease];

    UIViewController* viewController = [[self class] _viewControllerWithContext:context];

    self = [super initWithRootViewController:viewController];
    if (self != nil)
    {
        context->_state = STOPPED;

        context.delegate = delegate;
        context.initialInterfaceOrientationForViewcontroller = [UIApplication sharedApplication].statusBarOrientation;
#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
        context.scanMode = UMBarcodeScan_isOS7() ? kUMBarcodeScanMode_System : kUMBarcodeScanMode_ZXing;
#else
        context.scanMode = kUMBarcodeScanMode_System;
#endif

        self.context = context;
        self.shouldStoreStatusBarStyle = YES;
    }

    return self;
}

- (void)dealloc
{
    [_context release];

    [super dealloc];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Store the current state BEFORE calling super!
    if (self.shouldStoreStatusBarStyle)
    {
        self.originalStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
        self.statusBarWasOriginallyHidden = [UIApplication sharedApplication].statusBarHidden;
        self.shouldStoreStatusBarStyle = NO; // only store the very first time
    }

    self.navigationBar.barStyle = _context.navigationBarStyle;
    if (UMBarcodeScan_isOS7())
    {
        self.navigationBar.barTintColor = _context.navigationBarTintColor;
    }
    else
    {
        self.navigationBar.tintColor = _context.navigationBarTintColor;
    }

    [super viewWillAppear:animated];

    if (self.modalPresentationStyle == UIModalPresentationFullScreen && !_context.keepStatusBarStyle)
    {
        if (UMBarcodeScan_isOS7())
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
        }
        else
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.modalPresentationStyle == UIModalPresentationFullScreen)
    {
        [[UIApplication sharedApplication] setStatusBarStyle:self.originalStatusBarStyle animated:animated];
        [[UIApplication sharedApplication] setStatusBarHidden:self.statusBarWasOriginallyHidden withAnimation:UIStatusBarAnimationFade];

        if (UMBarcodeScan_isOS7())
        {
            [self setNeedsStatusBarAppearanceUpdate];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [self _isBeingPresentedModally] || (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
    return [self _isBeingPresentedModally];
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([self _isBeingPresentedModally])
    {
        return UIInterfaceOrientationMaskAll;
    }
    else
    {
        return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark -

- (UMBarcodeScanMode_t)scanMode
{
    return _context.scanMode;
}

- (void)setScanMode:(UMBarcodeScanMode_t)scanMode
{
    NSAssert(scanMode != kUMBarcodeScanMode_System || UMBarcodeScan_isOS7(), @"*** iOS 6 HAS NO SCANNING CAPABILITIES");

    UMBarcodeScanMode_t* scanModes = [UMBarcodeScanUtilities _allowedScanModes];
    for (int index = 0; scanModes[index] != kUMBarcodeScanMode_NONE; index++)
        if (scanModes[index] == scanMode)
        {
            _context.scanMode = scanMode;
            return;
        }

    NSAssert(NO, @"*** UNDEFINED SCAN MODE");
}

- (NSArray*)barcodeTypes
{
    return _context.barcodeTypes;
}

- (void)setBarcodeTypes:(NSArray*)barcodeTypes
{
    _context.barcodeTypes = barcodeTypes;
}

- (NSString*)cancelButtonText
{
    return _context.cancelButtonText;
}

- (void)setCancelButtonText:(NSString*)cancelButtonText
{
    _context.cancelButtonText = cancelButtonText;
}

- (NSString*)helpButtonText
{
    return _context.helpButtonText;
}

- (void)setHelpButtonText:(NSString*)helpButtonText
{
    _context.helpButtonText = helpButtonText;
}

- (NSString*)hintText
{
    return _context.hintLabelText;
}

- (void)setHintText:(NSString*)hintText
{
    _context.hintLabelText = hintText;
}

- (BOOL)isSuspended
{
    return (OSAtomicOr32Barrier(0, &_context->_state) & (PAUSED|RUNNING)) != RUNNING;
}

- (void)suspend
{
    if (![self isSuspended])
    {
        OSAtomicXor32Barrier(PAUSED, &_context->_state); // suspend
    }
}

- (void)resume
{
    if ([self isSuspended])
    {
        OSAtomicAnd32Barrier(~PAUSED, &_context->_state); // resume if clean
    }
}

- (BOOL)allowFreelyRotatingGuide
{
    return _context.allowFreelyRotatingGuide;
}

- (void)setAllowFreelyRotatingGuide:(BOOL)allowFreelyRotatingGuide
{
    _context.allowFreelyRotatingGuide = allowFreelyRotatingGuide;
}

- (BOOL)keepStatusBarStyle
{
    return _context.keepStatusBarStyle;
}

- (void)setKeepStatusBarStyle:(BOOL)keepStatusBarStyle
{
    _context.keepStatusBarStyle = keepStatusBarStyle;
}

- (UIBarStyle)navigationBarStyle
{
    return _context.navigationBarStyle;
}

- (void)setNavigationBarStyle:(UIBarStyle)navigationBarStyle
{
    _context.navigationBarStyle = navigationBarStyle;
}

- (UIColor*)navigationBarTintColor
{
    return _context.navigationBarTintColor;
}

- (void)setNavigationBarTintColor:(UIColor*)navigationBarTintColor
{
    _context.navigationBarTintColor = navigationBarTintColor;
}

#pragma mark -

- (BOOL)_isBeingPresentedModally
{
    UIViewController* viewController = self;
    while (viewController != nil)
    {
        if (viewController.modalPresentationStyle == UIModalPresentationFormSheet || viewController.modalPresentationStyle == UIModalPresentationPageSheet)
        {
            return YES;
        }
        else
        {
            if (viewController.presentingViewController != nil)
            {
                viewController = viewController.presentingViewController;
            }
            else
            {
                viewController = viewController.parentViewController;
            }
        }
    }

    return NO;
}

- (UIInterfaceOrientationMask)_supportedOverlayOrientationsMask
{
    if (_context.allowFreelyRotatingGuide)
    {
        return UIInterfaceOrientationMaskAll;
    }
    else
    {
        UIInterfaceOrientationMask pListMask = UIInterfaceOrientationMaskAll;

        // As far as I can determine, when we call [super supportedInterfaceOrientations],
        // iOS should already be intersecting that result either with application:supportedInterfaceOrientationsForWindow:
        // or with the plist values for UISupportedInterfaceOrientations.
        // I'm reasonably sure that I extensively tested and confirmed all that a year or two ago.
        // However, today that's definitely not happening. So let's do the work ourselves, just to be safe!
        // [- Dave Goldman, 7 Jun 2015]

        UIApplication* application = [UIApplication sharedApplication];
        if ([application.delegate respondsToSelector:@selector(application:supportedInterfaceOrientationsForWindow:)])
        {
            pListMask = [application.delegate application:application supportedInterfaceOrientationsForWindow:self.view.window];
        }
        else
        {
        static UIInterfaceOrientationMask cachedPListMask = UIInterfaceOrientationMaskAll;
        static dispatch_once_t onceToken;

            dispatch_once(&onceToken, ^
                    {
                        NSArray* supportedOrientations = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
                        if ([supportedOrientations count])
                        {
                            cachedPListMask = 0;
                            for (NSString* orientationString in supportedOrientations)
                            {
                                if ([orientationString isEqualToString:@"UIInterfaceOrientationPortrait"])
                                {
                                    cachedPListMask |= UIInterfaceOrientationMaskPortrait;
                                }
                                else if ([orientationString isEqualToString:@"UIInterfaceOrientationLandscapeLeft"])
                                {
                                    cachedPListMask |= UIInterfaceOrientationMaskLandscapeLeft;
                                }
                                else if ([orientationString isEqualToString:@"UIInterfaceOrientationLandscapeRight"])
                                {
                                    cachedPListMask |= UIInterfaceOrientationMaskLandscapeRight;
                                }
                                else if ([orientationString isEqualToString:@"UIInterfaceOrientationPortraitUpsideDown"])
                                {
                                    cachedPListMask |= UIInterfaceOrientationMaskPortraitUpsideDown;
                                }
                            }
                        }
                    });

            pListMask = cachedPListMask;
        }

        return [super supportedInterfaceOrientations] & pListMask;
    }
}

#pragma mark -

+ (UIViewController*)_viewControllerWithContext:(UMBarcodeScanContext*)aContext
{
    return [[[UMBarcodeViewController alloc] initWithContext:aContext] autorelease];
}

+ (UMBarcodeScanViewController*)_barcodeScanViewControllerForResponder:(UIResponder*)responder
{
    while (responder != nil && ![responder isKindOfClass:[UMBarcodeScanViewController class]])
        responder = responder.nextResponder;

    return (UMBarcodeScanViewController*)responder;
}

+ (BOOL)canReadBarcodeWithCamera
{
    return [UMBarcodeScanUtilities _canReadBarcodeWithCamera];
}

+ (UMBarcodeScanMode_t*)allowedScanModes
{
    return [UMBarcodeScanUtilities _allowedScanModes];
}

@end
