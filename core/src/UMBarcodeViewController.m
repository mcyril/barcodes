//
//  UMBarcodeViewController.m
//
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//  Created by Cyril Murzin
//

//  some work derived & base ideas of scan controller are borrowed from CardIO library,
//  the courtesy of eBay Software Foundation. see LICENSE & README files for more info

#import "UMBarcodeViewController.h"

#import "UMBarcodeScanViewControllerPvt.h"
#import "UMBarcodeView.h"
#import "UMBarcodeScanContext.h"
#import "UMBarcodeScanUtilities.h"

#import "PocketSVG.h"


#define kButtonSizeOutset   20.
#define kButtonMargin       8.

#define kDropShadowRadius   3.
#define kShadowInsets UIEdgeInsetsMake(-kDropShadowRadius, -kDropShadowRadius, -kDropShadowRadius, -kDropShadowRadius)

#define kButtonRotationDelay (kRotationAnimationDuration + .1)

@interface UMBarcodeViewController ()
@property (nonatomic, retain) UMBarcodeView* barcodeView;
@property (nonatomic, retain) CALayer* shadowLayer;

@property (nonatomic, assign) BOOL changeStatusBarHiddenStatus;
@property (nonatomic, assign) BOOL newStatusBarHiddenStatus;
@property (nonatomic, assign) BOOL originalStatusBarHiddenStatus;

@property (nonatomic, assign) UIDeviceOrientation deviceOrientation;

@property (nonatomic, retain) UIButton* cancelButton;
@property (nonatomic, assign) CGSize cancelButtonFrameSize;

@property (nonatomic, retain) UIButton* helpButton;
@property (nonatomic, assign) CGSize helpButtonFrameSize;

@property (nonatomic, retain) UIButton* torchButton;

@property (nonatomic, retain) UILabel* hintLabel;

- (void)_layoutButtonsForCameraPreviewFrame:(CGRect)cameraPreviewFrame;

- (UIInterfaceOrientationMask)_supportedOverlayOrientationsMask;
- (BOOL)_isSupportedOverlayOrientation:(UIInterfaceOrientation)orientation;
- (UIInterfaceOrientation)_defaultSupportedOverlayOrientation;

- (void)_didReceiveDeviceOrientationNotification:(NSNotification*)notification;

- (void)_cancel:(id)sender;
- (void)_help:(id)sender;

- (UIButton*)_makeButtonWithTitle:(NSString*)title withSelector:(SEL)selector;
- (UIButton*)_makeTorchButtonWithSelector:(SEL)selector;
- (UILabel*)_makeLabelWithTitle:(NSString*)title;

@end

@implementation UMBarcodeViewController
@synthesize barcodeView = _barcodeView;
@synthesize shadowLayer = _shadowLayer;

@synthesize changeStatusBarHiddenStatus = _changeStatusBarHiddenStatus;
@synthesize newStatusBarHiddenStatus = _newStatusBarHiddenStatus;
@synthesize originalStatusBarHiddenStatus = _originalStatusBarHiddenStatus;

@synthesize deviceOrientation = _deviceOrientation;

@synthesize cancelButton = _cancelButton;
@synthesize cancelButtonFrameSize = _cancelButtonFrameSize;
@synthesize helpButton = _helpButton;
@synthesize helpButtonFrameSize = _helpButtonFrameSize;
@synthesize torchButton = _torchButton;
@synthesize hintLabel = _hintLabel;

- (instancetype)initWithContext:(UMBarcodeScanContext*)aContext
{
    self = [super initWithNibName:nil bundle:nil];
    if (self != nil)
    {
        _context = [aContext retain];

        if (UMBarcodeScan_isOS7())
        {
            self.automaticallyAdjustsScrollViewInsets = YES;
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
        else
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            self.wantsFullScreenLayout = YES;
#pragma clang diagnostic pop
        }

        _originalStatusBarHiddenStatus = [UIApplication sharedApplication].statusBarHidden;
    }

    return self;
}

- (void)dealloc
{
    [_barcodeView release];
    [_shadowLayer release];

    [_cancelButton release];
    [_helpButton release];
    [_torchButton release];
    [_hintLabel release];

    [_context release];

    [super dealloc];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.backgroundColor = [UIColor colorWithWhite:.15 alpha:1.];

    self.barcodeView = [[[UMBarcodeView alloc] initWithFrame:self.view.bounds andContext:_context] autorelease];

    [self.view addSubview:self.barcodeView];

    self.cancelButton = [self _makeButtonWithTitle:_context.cancelButtonText withSelector:@selector(_cancel:)];
    self.cancelButton.center = self.view.center;
    self.cancelButtonFrameSize = self.cancelButton.frame.size;

    [self.view addSubview:self.cancelButton];

    if ([_context.helpButtonText length] > 0)
    {
        self.helpButton = [self _makeButtonWithTitle:_context.helpButtonText withSelector:@selector(_help:)];
        self.helpButton.center = self.view.center;
        self.helpButtonFrameSize = self.helpButton.frame.size;

        [self.view addSubview:self.helpButton];
    }

    {
        self.torchButton = [self _makeTorchButtonWithSelector:@selector(_torch:)];
        self.torchButton.center = self.view.center;

        [self.view addSubview:self.torchButton];
    }

    if ([_context.hintLabelText length] > 0)
    {
        self.hintLabel = [self _makeLabelWithTitle:_context.hintLabelText];
        self.hintLabel.center = self.view.center;

        [self.view addSubview:self.hintLabel];
    }

    // Add shadow to camera preview
    self.shadowLayer = [CALayer layer];
    self.shadowLayer.shadowRadius = kDropShadowRadius;
    self.shadowLayer.shadowColor = [UIColor blackColor].CGColor;
    self.shadowLayer.shadowOffset = CGSizeMake(.0, .0);
    self.shadowLayer.shadowOpacity = .5;
    self.shadowLayer.masksToBounds = NO;

    [self.barcodeView.layer insertSublayer:self.shadowLayer atIndex:0]; // must go *behind* everything
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    self.barcodeView.frame = self.view.bounds;

    [self.barcodeView setNeedsLayout]; // nice for iOS6

    // Only muck around with the status bar at all if we're in full screen modal style
    if (self.navigationController.modalPresentationStyle == UIModalPresentationFullScreen && [UMBarcodeScanUtilities appHasViewControllerBasedStatusBar] && !self.originalStatusBarHiddenStatus)
    {
        self.changeStatusBarHiddenStatus = YES;
        self.newStatusBarHiddenStatus = YES;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self.barcodeView layoutIfNeeded];

    // Re-layout shadow
    CGRect cameraPreviewFrame = self.barcodeView.cameraPreviewFrame;
    UIBezierPath* shadowPath = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(cameraPreviewFrame, kShadowInsets)];
    self.shadowLayer.shadowPath = shadowPath.CGPath;

    [self _layoutButtonsForCameraPreviewFrame:self.barcodeView.cameraPreviewFrame];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.deviceOrientation = UIDeviceOrientationUnknown;

    self.barcodeView.hidden = NO; // also start scanning

    [self.navigationController setNavigationBarHidden:YES animated:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveDeviceOrientationNotification:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

    [self _didReceiveDeviceOrientationNotification:nil];

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.changeStatusBarHiddenStatus)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:self.newStatusBarHiddenStatus withAnimation:UIStatusBarAnimationFade];

        if (UMBarcodeScan_isOS7())
        {
            [self setNeedsStatusBarAppearanceUpdate];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.barcodeView.hidden = YES; // also stop scanning

    if (self.changeStatusBarHiddenStatus)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:self.originalStatusBarHiddenStatus withAnimation:UIStatusBarAnimationFade];

        if (UMBarcodeScan_isOS7())
        {
            [self setNeedsStatusBarAppearanceUpdate];
        }
    }

    [super viewWillDisappear:animated];

    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [self.navigationController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (BOOL)shouldAutorotate
{
    return [self.navigationController shouldAutorotate];
}

- (UMInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.navigationController supportedInterfaceOrientations];
}

- (BOOL)prefersStatusBarHidden
{
    if (self.changeStatusBarHiddenStatus)
    {
        return self.newStatusBarHiddenStatus;
    }
    else
    {
        return YES;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark -

- (void)_layoutButtonsForCameraPreviewFrame:(CGRect)cameraPreviewFrame
{
    if (cameraPreviewFrame.size.width == 0 || cameraPreviewFrame.size.height == 0)
    {
        return;
    }

    // - When setting each button's frame, it's simplest to do that without any rotational transform applied to the button.
    //   So immediately prior to setting the frame, we set `button.transform = CGAffineTransformIdentity`.
    // - Later in this method we set a new transform for each button.
    // - We call [CATransaction setDisableActions:YES] to suppress the visible animation to the
    //   CGAffineTransformIdentity position; for reasons we haven't explored, this is only desirable for the
    //   InterfaceToDeviceOrientationRotatedClockwise and InterfaceToDeviceOrientationRotatedCounterclockwise rotations.
    //   (Thanks to https://github.com/card-io/card.io-iOS-source/issues/30 for the [CATransaction setDisableActions:YES] suggestion.)

    InterfaceToDeviceOrientationDelta delta = orientationDelta([UIApplication sharedApplication].statusBarOrientation, self.deviceOrientation);
    BOOL disableTransactionActions = (delta == InterfaceToDeviceOrientationRotatedClockwise || delta == InterfaceToDeviceOrientationRotatedCounterclockwise);

    if (disableTransactionActions)
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }

    self.cancelButton.transform = CGAffineTransformIdentity;
    self.cancelButton.frame = CGRectWithXYAndSize(cameraPreviewFrame.origin.x + kButtonMargin, CGRectGetMaxY(cameraPreviewFrame) - self.cancelButtonFrameSize.height - kButtonMargin, self.cancelButtonFrameSize);

    if (self.helpButton != nil)
    {
        self.helpButton.transform = CGAffineTransformIdentity;
        self.helpButton.frame = CGRectWithXYAndSize(CGRectGetMaxX(cameraPreviewFrame) - self.helpButtonFrameSize.width - kButtonMargin, CGRectGetMaxY(cameraPreviewFrame) - self.helpButtonFrameSize.height - kButtonMargin, self.helpButtonFrameSize);
    }

    {
        self.torchButton.transform = CGAffineTransformIdentity;
        self.torchButton.frame = CGRectWithXYAndSize(CGRectGetMaxX(cameraPreviewFrame) - self.torchButton.bounds.size.width - kButtonMargin, CGRectGetMinY(cameraPreviewFrame) + kButtonMargin, self.torchButton.bounds.size);
    }

    CGSize hintLabelSize = CGSizeZero;

    if (self.hintLabel != nil)
    {
        hintLabelSize = [self.hintLabel.attributedText boundingRectWithSize:CGSizeMake(MIN(cameraPreviewFrame.size.width, cameraPreviewFrame.size.height) - 2. * kButtonSizeOutset, 32000.) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;

        self.hintLabel.transform = CGAffineTransformIdentity;
        self.hintLabel.frame = CGRectWithXYAndSize(CGRectGetMidX(cameraPreviewFrame) - hintLabelSize.width / 2., CGRectGetMidY(cameraPreviewFrame) - hintLabelSize.height / 2., hintLabelSize);
    }

    if (disableTransactionActions)
        [CATransaction commit];

    CGFloat rotation = -rotationForOrientationDelta(delta); // undo the orientation delta
    CGAffineTransform r = CGAffineTransformMakeRotation(rotation);

    switch (delta)
    {
    case InterfaceToDeviceOrientationSame:
    case InterfaceToDeviceOrientationUpsideDown:
        {
            self.cancelButton.transform = r;
            self.helpButton.transform = r;
            self.torchButton.transform = r;
            self.hintLabel.transform = r;
        }
        break;
    case InterfaceToDeviceOrientationRotatedClockwise:
    case InterfaceToDeviceOrientationRotatedCounterclockwise:
        {
            CGFloat cancelDelta = (self.cancelButtonFrameSize.width - self.cancelButtonFrameSize.height) / 2.;
            CGFloat helpDelta = (self.helpButtonFrameSize.width - self.helpButtonFrameSize.height) / 2.;
            if (delta == InterfaceToDeviceOrientationRotatedClockwise)
            {
                cancelDelta = -cancelDelta;
                helpDelta = -helpDelta;
            }

            self.cancelButton.transform = CGAffineTransformTranslate(r, cancelDelta, -cancelDelta);
            self.helpButton.transform = CGAffineTransformTranslate(r, helpDelta, helpDelta);
            self.torchButton.transform = r;
            self.hintLabel.transform = r;
        }
        break;
    default:
        break;
    }

    // show controls for the rest (they created hidden)
    self.cancelButton.hidden = NO;
    self.helpButton.hidden = NO;
    self.torchButton.hidden = NO;
    self.hintLabel.hidden = NO;
}

// Overlay orientation has the same constraints as the view controller,
// unless self.config.allowFreelyRotatingCardGuide == YES.

- (UIInterfaceOrientationMask)_supportedOverlayOrientationsMask
{
    UIInterfaceOrientationMask supportedOverlayOrientationsMask = UIInterfaceOrientationMaskAll;

    UMBarcodeScanViewController* vc = [UMBarcodeScanViewController _barcodeScanViewControllerForResponder:self];
    if (vc != nil)
    {
        supportedOverlayOrientationsMask = [vc _supportedOverlayOrientationsMask];
    }

    return supportedOverlayOrientationsMask;
}

- (BOOL)_isSupportedOverlayOrientation:(UIInterfaceOrientation)orientation
{
    return (([self _supportedOverlayOrientationsMask] & (1 << orientation)) != 0);
}

- (UIInterfaceOrientation)_defaultSupportedOverlayOrientation
{
    if (_context.allowFreelyRotatingGuide)
    {
        return UIInterfaceOrientationPortrait;
    }
    else
    {
        UIInterfaceOrientation defaultOrientation = (UIInterfaceOrientation)UIDeviceOrientationUnknown;
        UIInterfaceOrientationMask supportedOverlayOrientationsMask = [self _supportedOverlayOrientationsMask];

        for (UIInterfaceOrientationMask orientation = (UIInterfaceOrientationMask)UIInterfaceOrientationPortrait; orientation <= UIInterfaceOrientationLandscapeRight; orientation++)
        {
            if ((supportedOverlayOrientationsMask & (1 << orientation)) != 0)
            {
                defaultOrientation = (UIInterfaceOrientation)orientation;
                break;
            }
        }

        return defaultOrientation;
    }
}

- (void)_didReceiveDeviceOrientationNotification:(NSNotification*)notification
{
    UIDeviceOrientation newDeviceOrientation;

    CGRect cameraPreviewFrame = self.barcodeView.cameraPreviewFrame;
    switch ([UIDevice currentDevice].orientation)
    {
    case UIDeviceOrientationPortrait:
        newDeviceOrientation = UIDeviceOrientationPortrait;
        break;
    case UIDeviceOrientationPortraitUpsideDown:
        newDeviceOrientation = UIDeviceOrientationPortraitUpsideDown;
        break;
    case UIDeviceOrientationLandscapeLeft:
        newDeviceOrientation = UIDeviceOrientationLandscapeLeft;
        cameraPreviewFrame = CGRectWithRotatedRect(cameraPreviewFrame);
        break;
    case UIDeviceOrientationLandscapeRight:
        newDeviceOrientation = UIDeviceOrientationLandscapeRight;
        cameraPreviewFrame = CGRectWithRotatedRect(cameraPreviewFrame);
        break;
    default:
        if (self.deviceOrientation == UIDeviceOrientationUnknown)
        {
            newDeviceOrientation = (UIDeviceOrientation)_context.initialInterfaceOrientationForViewcontroller;
        }
        else
        {
            newDeviceOrientation = self.deviceOrientation;
        }
        break;
    }

    if (![self _isSupportedOverlayOrientation:(UIInterfaceOrientation)newDeviceOrientation])
    {
        if ([self _isSupportedOverlayOrientation:(UIInterfaceOrientation)self.deviceOrientation])
        {
            newDeviceOrientation = self.deviceOrientation;
        }
        else
        {
            UIInterfaceOrientation orientation = [self _defaultSupportedOverlayOrientation];
            if (orientation != UIDeviceOrientationUnknown)
            {
                newDeviceOrientation = (UIDeviceOrientation)orientation;
            }
        }
    }

    if (newDeviceOrientation != self.deviceOrientation)
    {
        self.deviceOrientation = newDeviceOrientation;

        // Also update initialInterfaceOrientationForViewcontroller, so that CardIOView will present its transition view in the correct orientation
        _context.initialInterfaceOrientationForViewcontroller = (UIInterfaceOrientation)newDeviceOrientation;

        if (cameraPreviewFrame.size.width == 0 || cameraPreviewFrame.size.height == 0)
        {
            [self.view setNeedsLayout];
        }
        else
        {
            [UIView animateWithDuration:_context.orientationAnimationDuration
                             animations:^
                                    {
                                        [self _layoutButtonsForCameraPreviewFrame:cameraPreviewFrame];
                                    }];
        }
    }
}

#pragma mark -

- (void)_cancel:(id)sender
{
    [_context.delegate scanViewController:[UMBarcodeScanViewController _barcodeScanViewControllerForResponder:self] didCancelWithError:nil];
}

- (void)_help:(id)sender
{
    if ([_context.delegate respondsToSelector:@selector(scanViewControllerDidPressHelpButton:)])
        [_context.delegate scanViewControllerDidPressHelpButton:[UMBarcodeScanViewController _barcodeScanViewControllerForResponder:self]];
}

- (void)_torch:(id)sender
{
}

#pragma mark -

- (UIButton*)_makeButtonWithTitle:(NSString*)title withSelector:(SEL)selector
{
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.hidden = YES;

    NSMutableDictionary* attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                        [NSNumber numberWithFloat:-1.], NSStrokeWidthAttributeName,
                                                                        [UIFont boldSystemFontOfSize:18.], NSFontAttributeName,
                                                                    nil];

    [attributes setObject:[UIColor colorWithWhite:1. alpha:.8] forKey:NSForegroundColorAttributeName];
    [button setAttributedTitle:[[[NSAttributedString alloc] initWithString:title attributes:attributes] autorelease] forState:UIControlStateNormal];

    [attributes setObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    [button setAttributedTitle:[[[NSAttributedString alloc] initWithString:title attributes:attributes] autorelease] forState:UIControlStateHighlighted];

    CGSize buttonTitleSize = [button.titleLabel.attributedText size];
    buttonTitleSize.height = ceilf(buttonTitleSize.height);
    buttonTitleSize.width = ceilf(buttonTitleSize.width);

    button.frame = CGRectMake(.0, .0, buttonTitleSize.width + kButtonSizeOutset, buttonTitleSize.height + kButtonSizeOutset);

    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (UIButton*)_makeTorchButtonWithSelector:(SEL)selector
{
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.hidden = YES;

    CGRect rect = CGRectMake(.0, .0, 32., 32.);

    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);

    CGPathRef path1 = [PocketSVG pathFromDAttribute:@"M16.367,5.137h-1.141c-4.852,0.307-8.721,4.364-8.721,9.322c0,3.408,1.504,6.131,4.102,7.74v2.683 c0,0.783,0.291,1.086,0.745,1.388c0.113,0.073,0.185,0.198,0.193,0.336c0.008,0.135,0.021,0.312-0.151,0.354 c-0.703,0-0.701,0.771-0.701,0.771c0,0.312,0,1.729,0,1.729c0,0.387,0.313,0.699,0.701,0.699h0.469 c0.375,0,0.648,0.311,0.648,0.311s1.649,1.348,3.286,1.348c1.66,0,3.285-1.348,3.285-1.348s0.273-0.311,0.648-0.311h0.469 c0.39,0,0.701-0.312,0.701-0.699c0,0,0-1.416,0-1.729c0,0,0.002-0.771-0.701-0.771c-0.172-0.041-0.158-0.221-0.149-0.354 c0.01-0.138,0.08-0.263,0.192-0.336c0.453-0.302,0.744-0.604,0.744-1.388v-2.683c2.598-1.608,4.103-4.332,4.103-7.74 C25.089,9.501,21.222,5.443,16.367,5.137z M19.037,20.171l-0.522,0.271v2.49c0,0.426-0.295,0.788-0.709,0.879l-1.103,0.231 c-0.186,0.041-1.074,0.188-1.812,0l-1.102-0.231c-0.414-0.091-0.709-0.453-0.709-0.879v-2.49l-0.523-0.271 c-2.626-1.35-3.177-3.762-3.177-5.542c0-3.571,2.875-6.476,6.417-6.488c3.542,0.012,6.417,2.917,6.417,6.488 C22.214,16.41,21.662,18.82,19.037,20.171z"];
    CGPathRef path2 = [PocketSVG pathFromDAttribute:@"M27.568,6.199c0.035-0.229-0.029-0.462-0.176-0.645c-0.086-0.108-0.174-0.214-0.262-0.321 c-0.15-0.177-0.365-0.285-0.6-0.298c-0.229-0.013-0.458,0.071-0.626,0.23L24.4,6.596c-0.316,0.305-0.345,0.804-0.067,1.143 c0.02,0.02,0.033,0.04,0.053,0.061c0.275,0.342,0.771,0.412,1.133,0.158l1.699-1.192C27.406,6.633,27.533,6.428,27.568,6.199z"];
    CGPathRef path3 = [PocketSVG pathFromDAttribute:@"M15.71,3.753c0.025-0.001,0.051-0.001,0.076-0.001c0.44-0.003,0.805-0.346,0.832-0.786l0.133-2.072 c0.016-0.231-0.064-0.458-0.226-0.627C16.369,0.097,16.146,0.001,15.916,0c-0.14,0-0.278,0.001-0.417,0.004 c-0.231,0.006-0.451,0.107-0.605,0.28c-0.154,0.173-0.231,0.403-0.211,0.633l0.179,2.069C14.9,3.424,15.27,3.759,15.71,3.753z"];
    CGPathRef path4 = [PocketSVG pathFromDAttribute:@"M5.223,17.219c-0.101-0.43-0.516-0.703-0.951-0.635l-2.051,0.337c-0.229,0.037-0.432,0.166-0.562,0.358 c-0.129,0.189-0.175,0.429-0.125,0.654c0.03,0.135,0.063,0.27,0.098,0.402c0.057,0.227,0.204,0.416,0.407,0.525 c0.203,0.11,0.443,0.139,0.664,0.062l1.978-0.635c0.418-0.136,0.664-0.57,0.56-0.998C5.235,17.271,5.229,17.244,5.223,17.219z"];
    CGPathRef path5 = [PocketSVG pathFromDAttribute:@"M7.215,8.008c0.017-0.021,0.032-0.042,0.049-0.062c0.272-0.348,0.229-0.845-0.097-1.141L5.63,5.41 c-0.172-0.156-0.4-0.234-0.631-0.216C4.769,5.213,4.555,5.325,4.41,5.505C4.322,5.614,4.237,5.723,4.153,5.834 C4.013,6.02,3.956,6.253,3.995,6.482c0.039,0.228,0.17,0.429,0.362,0.559l1.729,1.151C6.452,8.436,6.946,8.355,7.215,8.008z"];
    CGPathRef path6 = [PocketSVG pathFromDAttribute:@"M30.15,16.986c-0.135-0.188-0.34-0.313-0.569-0.346l-2.054-0.291c-0.436-0.062-0.846,0.225-0.938,0.654 c-0.011,0.021-0.016,0.055-0.021,0.078c-0.101,0.43,0.155,0.855,0.579,0.982l1.988,0.59c0.226,0.065,0.463,0.037,0.662-0.074 c0.198-0.117,0.344-0.312,0.396-0.537c0.031-0.139,0.062-0.271,0.088-0.404C30.333,17.41,30.283,17.176,30.15,16.986z"];

    CGContextClearRect(UIGraphicsGetCurrentContext(), rect);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path1);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path2);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path3);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path4);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path5);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path6);

    [[UIColor colorWithWhite:1. alpha:.8] set];
    CGContextDrawPath(UIGraphicsGetCurrentContext(), kCGPathFill);

    [button setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];

    CGContextClearRect(UIGraphicsGetCurrentContext(), rect);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path1);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path2);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path3);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path4);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path5);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path6);

    [[UIColor whiteColor] set];
    CGContextDrawPath(UIGraphicsGetCurrentContext(), kCGPathEOFill);

    [button setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateHighlighted];

    UIGraphicsEndImageContext();

    button.frame = rect;

    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (UILabel*)_makeLabelWithTitle:(NSString*)title
{
    UILabel* label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    label.hidden = YES;
    label.opaque = NO;
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;

    NSMutableDictionary* attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                        [UIFont systemFontOfSize:18.], NSFontAttributeName,
                                                                        [UIColor colorWithWhite:1. alpha:.8], NSForegroundColorAttributeName,
                                                                        [UIColor clearColor], NSBackgroundColorAttributeName,
                                                                    nil];

    label.attributedText = [[[NSAttributedString alloc] initWithString:title attributes:attributes] autorelease];

    CGSize labelTitleSize = [label.attributedText boundingRectWithSize:CGSizeMake(MIN(self.view.bounds.size.width, self.view.bounds.size.height) - 2. * kButtonSizeOutset, 32000.) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    labelTitleSize.height = ceilf(labelTitleSize.height);
    labelTitleSize.width = ceilf(labelTitleSize.width);

    label.frame = CGRectMake(.0, .0, labelTitleSize.width + kButtonSizeOutset, labelTitleSize.height + kButtonSizeOutset);

    return label;
}

@end
