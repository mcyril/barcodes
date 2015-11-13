//
//  UMBarcodeView.m
//
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//  Created by Cyril Murzin
//

//  some work derived & base ideas of scan controller are borrowed from CardIO library,
//  the courtesy of eBay Software Foundation. see LICENSE & README files for more info

#import "UMBarcodeView.h"

#import "UMBarcodeScanViewControllerPvt.h"
#import "UMBarcodeScanContext.h"
#import "UMBarcodeScanUtilities.h"

#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
#import "ZXCGImageLuminanceSource.h"
#import "ZXHybridBinarizer.h"
#import "ZXBinaryBitmap.h"
#import "ZXResult.h"
#import "ZXDecodeHints.h"
#import "ZXMultiFormatReader.h"
#import "ZXResultPoint.h"
#endif

#if defined(UMBARCODE_SCAN_ZBAR) && UMBARCODE_SCAN_ZBAR
#import "ZBarImage.h"
#import "ZBarImageScanner.h"
#endif

#import <AVFoundation/AVFoundation.h>

#import <libkern/OSAtomic.h>


#define kMinimalTorchLevel      .05

#define kViewFinderMargin       20.
#define kViewFinderFrameMargin  8.

@interface UMBarcodeView ()
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
                            <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
#endif

@property (nonatomic, readwrite) BOOL enableCapture;
@property (nonatomic, retain) NSError* error;

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
- (void)_initializeAVBowels;
#endif
- (BOOL)_initializeViewFinder;
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
- (BOOL)_initializeSystemOutput;
#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
- (BOOL)_initializeSystemZXingOutput;
#endif
#if defined(UMBARCODE_SCAN_ZBAR) && UMBARCODE_SCAN_ZBAR
- (BOOL)_initializeSystemZBar;
#endif
#endif

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
- (BOOL)_changeCameraConfiguration:(BOOL(^)(NSError** error))changeBlock error:(NSError**)outError;
- (void)_refocus;
- (void)_autofocusOnce;
- (void)_resumeContinuousAutofocusing;
#endif

- (void)_didReceiveDeviceOrientationNotification:(NSNotification*)notification;

- (void)_didReadNewCode:(id)code;
@end

@implementation UMBarcodeView
@dynamic cameraPreviewFrame;
@dynamic hasTorch;
@dynamic isTorchOn;

@dynamic enableCapture;
@synthesize error = _error;

- (instancetype)initWithFrame:(CGRect)frame andContext:(UMBarcodeScanContext*)context
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _context = [context retain];

        [super setHidden:YES]; // initially hidden and suspended

        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor clearColor];
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
        [self _initializeAVBowels];
#else
        [self _initializeViewFinder];
#endif
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveDeviceOrientationNotification:) name:kUMBarcodeScanContextChangedOrientation object:_context];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    if (_queue != NULL)
    {
        [_metaDataOutput setMetadataObjectsDelegate:nil queue:_queue];
        [_videoDataOutput setSampleBufferDelegate:nil queue:_queue];
    }

    [_metaDataOutput release];
    [_videoDataOutput release];

    if (_queue != NULL)
        dispatch_release(_queue);

#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
    [_zxReader release];
    [_zxHints release];
#endif
#if defined(UMBARCODE_SCAN_ZBAR) && UMBARCODE_SCAN_ZBAR
    [_zbImage release];
    [_zbScanner release];
#endif
#endif /* !simulator */

    [_viewfinderLayers release];
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    [_videoPreviewLayer release];
    [_captureSession release];
    [_videoInput release];
    [_camera release];
#endif

    [_error release];

    [_context release];

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    if (_configurationSemaphore != NULL)
        dispatch_release(_configurationSemaphore);
#endif

    [super dealloc];
}

#pragma mark -

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
- (BOOL)_changeCameraConfiguration:(BOOL(^)(NSError** error))changeBlock error:(NSError**)outError
{
    dispatch_semaphore_wait(_configurationSemaphore, DISPATCH_TIME_FOREVER);

    BOOL success = NO;

    [_captureSession beginConfiguration]; // might be nil

    NSError* lockError = nil;
    if ([_camera lockForConfiguration:&lockError] && lockError == nil)
    {
        success = changeBlock(outError);

        [_camera unlockForConfiguration];
    }
    else if (outError != NULL)
        *outError = lockError;

    [_captureSession commitConfiguration]; // might be nil

    dispatch_semaphore_signal(_configurationSemaphore);

    return success;
}
#endif

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
- (void)_refocus
{
    [self _autofocusOnce];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_resumeContinuousAutofocusing) object:nil];
    [self performSelector:@selector(_resumeContinuousAutofocusing) withObject:nil afterDelay:.1];
}
#endif

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
- (void)_autofocusOnce
{
    [self _changeCameraConfiguration:^BOOL(NSError** error)
                                {
                                    if ([_camera isFocusModeSupported:AVCaptureFocusModeAutoFocus] && !_camera.adjustingFocus)
                                        [_camera setFocusMode:AVCaptureFocusModeAutoFocus];

                                    return YES;
                                }
                              error:NULL];
}
#endif

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
- (void)_resumeContinuousAutofocusing
{
    [self _changeCameraConfiguration:^BOOL(NSError** error)
                                {
                                    // Autofocus: Continuous
                                    if ([_camera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
                                        [_camera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];

                                    // Autofocus: Restricted to Near
                                    if ([_camera respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] && [_camera isAutoFocusRangeRestrictionSupported])
                                        _camera.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;

                                    return YES;
                                }
                              error:NULL];
}
#endif

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
- (void)_initializeAVBowels
{
    _configurationSemaphore = dispatch_semaphore_create(1);

    NSError* error = nil;
    BOOL success = NO;

    do
    {
        // get the camera
        _camera = [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] retain];
        if (_camera == nil)
            break;

        // configure camera, no _captureSession atm
        if (![self _changeCameraConfiguration:^BOOL(NSError** error)
                                            {
                                                // exposure: continuous
                                                if ([_camera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
                                                    _camera.exposureMode = AVCaptureExposureModeContinuousAutoExposure;

                                                // white balance: continuous
                                                if ([_camera isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
                                                    _camera.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;

                                                // torch
                                                if (_camera.hasTorch && (_context.torchMode & kUMBarcodeScanTorchModeInit_Mask) != kUMBarcodeScanTorchModeInit_OFF)
                                                {
                                                    if ((_context.torchMode & kUMBarcodeScanTorchModeInit_Mask) == kUMBarcodeScanTorchModeInit_AUTO && [_camera isTorchModeSupported:AVCaptureTorchModeAuto])
                                                        _camera.torchMode = AVCaptureTorchModeAuto;
                                                    else
                                                    {
                                                        BOOL success = NO;
                                                        if ([_camera respondsToSelector:@selector(setTorchModeOnWithLevel:error:)])
                                                            success = [_camera setTorchModeOnWithLevel:kMinimalTorchLevel error:error];

                                                        if (!success && [_camera isTorchModeSupported:AVCaptureTorchModeOn])
                                                            _camera.torchMode = AVCaptureTorchModeOn;
                                                    }
                                                }

                                                return YES;
                                            }
                                       error:&error])
        {
            break;
        }

        // configure initial camera autofocus, no _captureSession atm
        [self _resumeContinuousAutofocusing];

        // Create session
        _captureSession = [[AVCaptureSession alloc] init];
        if (_captureSession == nil)
            break;

        if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh])
            _captureSession.sessionPreset = AVCaptureSessionPresetHigh;

        // connect camera to input
        _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_camera error:&error];
        if (_videoInput == nil)
            break;

        if ([_captureSession canAddInput:_videoInput])
            [_captureSession addInput:_videoInput];
        else
            break;

        // Tap-to-refocus support
        if([_camera isFocusModeSupported:AVCaptureFocusModeAutoFocus])
            [self addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_refocus)] autorelease]];

        // prepare view-finder gfx
        if (![self _initializeViewFinder])
            break;

        // connect dedicated capture to output
        if (_context.scanMode == kUMBarcodeScanMode_System)
        {
            if (![self _initializeSystemOutput])
                break;
        }
#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
        else if (_context.scanMode == kUMBarcodeScanMode_ZXing)
        {
            if (![self _initializeSystemZXingOutput])
                break;
        }
#endif
#if defined(UMBARCODE_SCAN_ZBAR) && UMBARCODE_SCAN_ZBAR
        else if (_context.scanMode == kUMBarcodeScanMode_ZBar)
        {
            if (![self _initializeSystemZBar])
                break;
        }
#endif

        success = YES;

    } while (0);

    if (!success)
    {
        if (error == nil)
        {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:-50 /* paramErr */ userInfo:nil];
        }

        self.error = error;
    }
}
#endif

- (BOOL)_initializeViewFinder
{
    // create a preview layer
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    if (_videoPreviewLayer == nil)
        return NO;
#endif

    [self _didReceiveDeviceOrientationNotification:nil];

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    [self.layer insertSublayer:_videoPreviewLayer atIndex:0];
#endif

    _viewfinderLayers = [[NSMutableArray alloc] initWithCapacity:0];

    if ([_context.delegate respondsToSelector:@selector(scanViewController:addLayerAtIndex:)])
    {
        // add customized viewfinder layers

        for (NSUInteger index = 0; ; index++)
        {
            CALayer* layer = [_context.delegate scanViewController:[UMBarcodeScanViewController _barcodeScanViewControllerForResponder:self] addLayerAtIndex:index];
            if (layer == nil)
                break;
            else
                [_viewfinderLayers addObject:layer];
        }
    }

    for (CALayer* layer in _viewfinderLayers)
        [self.layer addSublayer:layer];

    return YES;
}

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
- (BOOL)_initializeSystemOutput
{
    _metaDataOutput = [[AVCaptureMetadataOutput alloc] init];
    if (_metaDataOutput == nil)
        return NO;

    if ([_captureSession canAddOutput:_metaDataOutput])
        [_captureSession addOutput:_metaDataOutput];
    else
        return NO;

    NSMutableSet* avBarcodeTypes = [NSMutableSet setWithCapacity:0];

    for (NSString* barcodeType in _context.barcodeTypes)
    {
        NSString* avBarcodeType = [UMBarcodeScanUtilities um2avBarcodeType:barcodeType];
        if (avBarcodeType != nil)
            [avBarcodeTypes addObject:avBarcodeType];
    }

    NSArray* barcodeTypes = [avBarcodeTypes allObjects];
    if ([barcodeTypes count] == 0)
        return NO;

    NSArray* availableTypes = _metaDataOutput.availableMetadataObjectTypes;
    for (NSString* object in barcodeTypes)
        if (![availableTypes containsObject:object])
            return NO;

    _metaDataOutput.metadataObjectTypes = barcodeTypes;

    _queue = dispatch_queue_create(NULL, NULL);
    [_metaDataOutput setMetadataObjectsDelegate:self queue:_queue];

    // uglu hack: the torch mode auto works only when we have video data output capture, doh...
    if ((_context.torchMode & kUMBarcodeScanTorchModeInit_Mask) == kUMBarcodeScanTorchModeInit_AUTO)
    {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        if (_videoDataOutput != nil)
        {
            [_videoDataOutput setSampleBufferDelegate:self queue:_queue];

            if ([_captureSession canAddOutput:_videoDataOutput])
                [_captureSession addOutput:_videoDataOutput];
        }
    }

    return YES;
}
#endif

#if (!defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR) && (defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING)
- (BOOL)_initializeSystemZXingOutput
{
    _zxReader = [[ZXMultiFormatReader reader] retain];
    if (_zxReader == nil)
        return NO;

    _zxHints = [[ZXDecodeHints hints] retain];
    if (_zxHints == nil)
        return NO;

    for (NSString* barcodeType in _context.barcodeTypes)
    {
        ZXBarcodeFormat zxBarcodeType = [UMBarcodeScanUtilities um2zxBarcodeType:barcodeType];
        if (zxBarcodeType != (ZXBarcodeFormat)-1)
            [_zxHints addPossibleFormat:zxBarcodeType];
    }

    if (_zxHints.numberOfPossibleFormats == 0)
        return NO;

    _zxHints.tryHarder = YES;

    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    if (_videoDataOutput == nil)
        return NO;

    [_videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (NSString*)kCVPixelBufferPixelFormatTypeKey,
                                                            nil]];

    [_videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];

    _queue = dispatch_queue_create(NULL, NULL);
    [_videoDataOutput setSampleBufferDelegate:self queue:_queue];

    if ([_captureSession canAddOutput:_videoDataOutput])
        [_captureSession addOutput:_videoDataOutput];
    else
        return NO;

    return YES;
}
#endif

#if (!defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR) && (defined(UMBARCODE_SCAN_ZBAR) && UMBARCODE_SCAN_ZBAR)
- (BOOL)_initializeSystemZBar
{
    _zbImage = [[ZBarImage alloc] init];
    if (_zbImage == nil)
        return NO;

    _zbImage.format = [ZBarImage fourcc: @"Y800"];

    _zbScanner = [[ZBarImageScanner alloc] init];
    if (_zbScanner == nil)
        return NO;

    [_zbScanner setSymbology:ZBAR_NONE config:ZBAR_CFG_ENABLE to:0];
    for (NSString* barcodeType in _context.barcodeTypes)
    {
        zbar_symbol_type_t zbBarcodeType = [UMBarcodeScanUtilities um2zbBarcodeType:barcodeType];
        if (zbBarcodeType != ZBAR_NONE)
            [_zbScanner setSymbology:zbBarcodeType config:ZBAR_CFG_ENABLE to:1];
    }

    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    if (_videoDataOutput == nil)
        return NO;

    [_videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], (NSString*)kCVPixelBufferPixelFormatTypeKey,
                                                            nil]];

    [_videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];

    _queue = dispatch_queue_create(NULL, NULL);
    [_videoDataOutput setSampleBufferDelegate:self queue:_queue];

    if ([_captureSession canAddOutput:_videoDataOutput])
        [_captureSession addOutput:_videoDataOutput];
    else
        return NO;

    return YES;
}
#endif

#pragma mark -

- (void)scanStart
{
    if (!self.enableCapture)
    {
        if (_error != nil) // notify if failed initialization
            [self performSelectorOnMainThread: @selector(_didReadNewCode:) withObject:nil waitUntilDone:NO];
        else
        {
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
            [_captureSession startRunning];
#endif
            self.enableCapture = YES;
        }
    }
}

- (void)scanStop
{
    if (self.enableCapture)
    {
        self.enableCapture = NO;
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
        [_captureSession stopRunning];
#endif
    }
}

#pragma mark -

- (BOOL)enableCapture
{
    return (OSAtomicOr32Barrier(0, &_context->_state) & RUNNING) != 0;
}

- (void)setEnableCapture:(BOOL)enable
{
    if (!enable)
        OSAtomicAnd32Barrier(STOPPED, &_context->_state);
    else if ((OSAtomicOr32OrigBarrier(RUNNING, &_context->_state) & RUNNING) == 0)
        OSAtomicAnd32Barrier(~PAUSED, &_context->_state);
}

- (CGRect)cameraPreviewFrame
{
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    return _videoPreviewLayer.frame;
#else
    if (!CGRectIsEmpty(self.bounds))
        return CGRectInset(self.bounds, kViewFinderMargin, kViewFinderMargin);
    else
        return CGRectZero;
#endif
}

- (BOOL)hasTorch
{
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    return _camera.hasTorch;
#else
    return NO;
#endif
}

- (BOOL)isTorchOn
{
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    return _camera.hasTorch && ((_camera.torchMode == AVCaptureTorchModeAuto && _camera.torchLevel > .0) || _camera.torchMode == AVCaptureTorchModeOn);
#else
    return NO;
#endif
}

- (void)setTorch:(BOOL)onOff
{
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    if (_camera.hasTorch)
    {
        NSError* error = nil;

        [self _changeCameraConfiguration:^BOOL(NSError** error)
                                    {
                                        if (onOff)
                                        {
                                            BOOL success = NO;
                                            if ([_camera respondsToSelector:@selector(setTorchModeOnWithLevel:error:)])
                                                success = [_camera setTorchModeOnWithLevel:kMinimalTorchLevel error:error];

                                            if (!success && [_camera isTorchModeSupported:AVCaptureTorchModeOn])
                                                _camera.torchMode = AVCaptureTorchModeOn;
                                        }
                                        else if ([_camera isTorchModeSupported:AVCaptureTorchModeOff])
                                            _camera.torchMode = AVCaptureTorchModeOff;

                                        return YES;
                                    }
                                   error:&error];
    }
#endif
}

#pragma mark -

- (void)setHidden:(BOOL)hidden
{
    if (hidden != self.hidden)
    {
        if (hidden)
        {
            [self scanStop];
            [super setHidden:hidden];
        }
        else
        {
            [super setHidden:hidden];
            [self scanStart];
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (!CGRectIsEmpty(self.bounds))
    {
        CGRect r = CGRectInset(self.bounds, kViewFinderMargin, kViewFinderMargin);

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
        _videoPreviewLayer.frame = r;

        // fill the entire screen, without this we get empty areas at the long sides
        [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
#endif
        r = CGRectInset(r, kViewFinderFrameMargin, kViewFinderFrameMargin);

        if ([_context.delegate respondsToSelector:@selector(scanViewController:layoutLayer:atIndex:viewRect:)])
        {
            // layout/setup customized layers

            NSUInteger index = 0;
            for (CALayer* layer in _viewfinderLayers)
            {
                [_context.delegate scanViewController:[UMBarcodeScanViewController _barcodeScanViewControllerForResponder:self] layoutLayer:layer atIndex:index viewRect:r];

                index++;
            }
        }
    }
}

#pragma mark -

- (void)_didReceiveDeviceOrientationNotification:(NSNotification*)notification
{
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    if ([[_videoPreviewLayer connection] isVideoOrientationSupported])
        [[_videoPreviewLayer connection] setVideoOrientation:(AVCaptureVideoOrientation)[UIApplication sharedApplication].statusBarOrientation];
#endif
}

- (void)_didReadNewCode:(id)obj
{
    if (obj != nil)
    {
        if (_context.scanMode == kUMBarcodeScanMode_System)
        {
            AVMetadataMachineReadableCodeObject* code = obj;

            [_context.delegate scanViewController:[UMBarcodeScanViewController _barcodeScanViewControllerForResponder:self]
                                    didScanString:[[code.stringValue copy] autorelease]
                                    ofBarcodeType:[UMBarcodeScanUtilities av2umBarcodeType:code.type]];
        }
#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
        else if (_context.scanMode == kUMBarcodeScanMode_ZXing)
        {
            ZXResult* result = obj;

            [_context.delegate scanViewController:[UMBarcodeScanViewController _barcodeScanViewControllerForResponder:self]
                                    didScanString:[[result.text copy] autorelease]
                                    ofBarcodeType:[UMBarcodeScanUtilities zx2umBarcodeType:result.barcodeFormat]];
        }
#endif
#if defined(UMBARCODE_SCAN_ZBAR) && UMBARCODE_SCAN_ZBAR
        else if (_context.scanMode == kUMBarcodeScanMode_ZBar)
        {
            ZBarSymbol* symb = obj;

            [_context.delegate scanViewController:[UMBarcodeScanViewController _barcodeScanViewControllerForResponder:self]
                                    didScanString:[[symb.data copy] autorelease]
                                    ofBarcodeType:[UMBarcodeScanUtilities zb2umBarcodeType:symb.type]];
        }
#endif
    }
    else
    {
        [_context.delegate scanViewController:[UMBarcodeScanViewController _barcodeScanViewControllerForResponder:self]
                           didCancelWithError:[[_error copy] autorelease]];
    }
}

#pragma mark -

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
- (void)captureOutput:(AVCaptureOutput*)captureOutput didOutputMetadataObjects:(NSArray*)metadataObjects fromConnection:(AVCaptureConnection*)connection
{
    if ((OSAtomicOr32Barrier(0, &_context->_state) & (PAUSED|RUNNING)) != RUNNING) // bypass if suspended
        return;

    if (_error != nil)
    {
        OSAtomicXor32Barrier(PAUSED, &_context->_state); // suspend and notify
        [self performSelectorOnMainThread: @selector(_didReadNewCode:) withObject:nil waitUntilDone:NO];
    }
    else
    {
        @autoreleasepool
        {
            AVMetadataMachineReadableCodeObject* code = nil;
            for (AVMetadataMachineReadableCodeObject* object in metadataObjects)
                if ([object isKindOfClass:[AVMetadataMachineReadableCodeObject class]])
                {
                    code = object;
                    break;
                }

            if (code != nil)
            {
                OSAtomicXor32Barrier(PAUSED, &_context->_state); // suspend and notify

                [self performSelectorOnMainThread: @selector(_didReadNewCode:) withObject:code waitUntilDone:NO];
            }
        }
    }
}
#endif

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
- (void)captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection
{
    if ((OSAtomicOr32Barrier(0, &_context->_state) & (PAUSED|RUNNING)) != RUNNING) // bypass if suspended
        return;

    if (_error != nil)
    {
        OSAtomicXor32Barrier(PAUSED, &_context->_state); // suspend and notify
        [self performSelectorOnMainThread: @selector(_didReadNewCode:) withObject:nil waitUntilDone:NO];
    }
    else
    {
        @autoreleasepool
        {
            BOOL resume = YES;

            OSAtomicXor32Barrier(PAUSED, &_context->_state); // suspend

            do
            {
                if (_context.scanMode == kUMBarcodeScanMode_System)
                {
                }
#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
                else if (_context.scanMode == kUMBarcodeScanMode_ZXing)
                {
                    CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
                    if (videoFrame == NULL)
                        break;

                    CGImageRef videoFrameImage = [ZXCGImageLuminanceSource createImageFromBuffer:videoFrame];
                    if (videoFrameImage == NULL)
                        break;

                    ZXCGImageLuminanceSource* source = [[[ZXCGImageLuminanceSource alloc] initWithCGImage:videoFrameImage] autorelease];
                    CGImageRelease(videoFrameImage);

                    if (source == nil)
                        break;

                    ZXHybridBinarizer* binarizer = [[[ZXHybridBinarizer alloc] initWithSource:source] autorelease];
                    if (binarizer == nil)
                        break;

                    ZXBinaryBitmap* bitmap = [[[ZXBinaryBitmap alloc] initWithBinarizer:binarizer] autorelease];
                    if (bitmap == nil)
                        break;

                    NSError* error;
                    ZXResult* result = [_zxReader decode:bitmap hints:_zxHints error:&error];
                    if (result != nil)
                    {
                        resume = NO;

                        [self performSelectorOnMainThread: @selector(_didReadNewCode:) withObject:result waitUntilDone:NO];
                    }
                }
#endif
#if defined(UMBARCODE_SCAN_ZBAR) && UMBARCODE_SCAN_ZBAR
                else if (_context.scanMode == kUMBarcodeScanMode_ZBar)
                {
                    CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
                    if (videoFrame == NULL)
                        break;

                    if (CVPixelBufferLockBaseAddress(videoFrame, kCVPixelBufferLock_ReadOnly) != kCVReturnSuccess)
                        break;

                    void* videoData = CVPixelBufferGetBaseAddressOfPlane(videoFrame, 0);
                    if (videoData == NULL)
                    {
                        CVPixelBufferUnlockBaseAddress(videoFrame, kCVPixelBufferLock_ReadOnly);
                        break;
                    }

                    size_t w = CVPixelBufferGetBytesPerRowOfPlane(videoFrame, 0);
                    size_t h = CVPixelBufferGetHeightOfPlane(videoFrame, 0);
                    [_zbImage setData:videoData withLength:w * h];

                    CGRect r = CGRectMake(.0, .0, w, h);
                    _zbImage.size = r.size;
                    _zbImage.crop = r;

                    if ([_zbScanner scanImage:_zbImage] > 0)
                    {
                        resume = NO;

                        ZBarSymbol* sym = nil;
                        for (sym in _zbScanner.results)
                            break;

                        [self performSelectorOnMainThread: @selector(_didReadNewCode:) withObject:sym waitUntilDone:NO];
                    }

                    [_zbImage setData:NULL withLength:0];

                    CVPixelBufferUnlockBaseAddress(videoFrame, kCVPixelBufferLock_ReadOnly);
                }
#endif

            } while (0);

            if (resume)
                OSAtomicAnd32Barrier(~PAUSED, &_context->_state);
        }
    }
}
#endif

@end
