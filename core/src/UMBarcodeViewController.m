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
- (UIButton*)_makeImageButtonWithSelector:(SEL)selector;
- (UILabel*)_makeLabelWithTitle:(NSString*)title;

- (UIImage*)_imageWithSVG:(NSString*)data size:(CGSize)size color:(UIColor*)color;
- (void)_createTorchImages;
- (void)_updateTorchButton;

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

    [_torchIconOn release];
    [_torchIconOnPressed release];
    [_torchIconOff release];
    [_torchIconOffPressed release];

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

    if ((_context.torchMode & kUMBarcodeScanTorchMode_BUTTON) != 0)
    {
        [self _createTorchImages];

        self.torchButton = [self _makeImageButtonWithSelector:@selector(_torch:)];
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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    dispatch_async(dispatch_get_main_queue(), ^
                {
                    [self _updateTorchButton];
                });

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
    self.torchButton.hidden = !self.barcodeView.hasTorch;
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
    [self.barcodeView setTorch:!self.barcodeView.isTorchOn];

    dispatch_async(dispatch_get_main_queue(), ^
                {
                    [self _updateTorchButton];
                });
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

- (UIButton*)_makeImageButtonWithSelector:(SEL)selector
{
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.hidden = YES;
    button.frame = CGRectMake(.0, .0, 32., 32.);;

    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (UIImage*)_imageWithSVG:(NSString*)data size:(CGSize)size color:(UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);

    CGPathRef path = [PocketSVG pathFromDAttribute:data];

    CGContextClearRect(UIGraphicsGetCurrentContext(), CGRectMake(.0, .0, size.width, size.height));

    CGRect boundingBox = CGPathGetBoundingBox(path);
    CGFloat boundingBoxAspectRatio = CGRectGetWidth(boundingBox) / CGRectGetHeight(boundingBox);

    CGFloat viewAspectRatio = size.width / size.height;

    CGFloat scaleFactor;
    if (boundingBoxAspectRatio > viewAspectRatio)
        scaleFactor = size.width / CGRectGetWidth(boundingBox);
    else
        scaleFactor = size.height / CGRectGetHeight(boundingBox);

    CGAffineTransform scaleTransform = CGAffineTransformIdentity;
    scaleTransform = CGAffineTransformScale(scaleTransform, scaleFactor, scaleFactor);
    scaleTransform = CGAffineTransformTranslate(scaleTransform, -CGRectGetMinX(boundingBox), -CGRectGetMinY(boundingBox));

    CGSize scaledSize = CGSizeApplyAffineTransform(boundingBox.size, CGAffineTransformMakeScale(scaleFactor, scaleFactor));
    CGSize centerOffset = CGSizeMake((size.width - scaledSize.width) / (scaleFactor * 2.), (size.height - scaledSize.height) / (scaleFactor * 2.));
    scaleTransform = CGAffineTransformTranslate(scaleTransform, centerOffset.width, centerOffset.height);

    path = CGPathCreateCopyByTransformingPath(path, &scaleTransform);
    CGContextAddPath(UIGraphicsGetCurrentContext(), path);
    CGPathRelease(path);

    [color set];
    CGContextDrawPath(UIGraphicsGetCurrentContext(), kCGPathFill);

    UIImage* image = [UIGraphicsGetImageFromCurrentImageContext() copy];

    UIGraphicsEndImageContext();

    return [image autorelease];
}

- (void)_createTorchImages
{
    CGSize size = CGSizeMake(32., 32.);

    [_torchIconOn release];
    _torchIconOn = [[self _imageWithSVG:@"M14,0L0,18h7L6,30l14-18h-7L14,0L14,0z" size:size color:[UIColor colorWithWhite:1. alpha:.8]] retain];

    [_torchIconOnPressed release];
    _torchIconOnPressed = [[self _imageWithSVG:@"M14,0L0,18h7L6,30l14-18h-7L14,0L14,0z" size:size color:[UIColor whiteColor]] retain];

    [_torchIconOff release];
    _torchIconOff = [[self _imageWithSVG:@"M12.724,3.269L11.913,13h6.042L7.276,26.73L8.087,17H2.044L12.724,3.269 M14,0L0,18h7L6,30l14-18h-7L14,0L14,0z" size:size color:[UIColor colorWithWhite:1. alpha:.8]] retain];

    [_torchIconOffPressed release];
    _torchIconOffPressed = [[self _imageWithSVG:@"M12.724,3.269L11.913,13h6.042L7.276,26.73L8.087,17H2.044L12.724,3.269 M14,0L0,18h7L6,30l14-18h-7L14,0L14,0z" size:size color:[UIColor whiteColor]] retain];
}

- (void)_updateTorchButton
{
    BOOL onOff = self.barcodeView.isTorchOn;

    [_torchButton setImage:onOff ? _torchIconOn : _torchIconOff forState:UIControlStateNormal];
    [_torchButton setImage:onOff ? _torchIconOnPressed : _torchIconOffPressed forState:UIControlStateHighlighted];
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
