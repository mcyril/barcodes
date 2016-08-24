//
//  UMBarcodeView.h
//
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//  Created by Cyril Murzin
//

@class UMBarcodeScanContext;

#if !UMBARCODE_SCAN_SIMULATOR
@class AVCaptureDevice;
@class AVCaptureSession;
@class AVCaptureDeviceInput;
@class AVCaptureMetadataOutput;
@class AVCaptureVideoDataOutput;
@class AVCaptureVideoPreviewLayer;
#endif

#if UMBARCODE_SCAN_ZXING
@class ZXDecodeHints;
@protocol ZXReader;
#endif

#if UMBARCODE_SCAN_ZBAR
@class ZBarImage;
@class ZBarImageScanner;
#endif

@interface UMBarcodeView : UIView
{
@private
    UMBarcodeScanContext* _context;

#if !UMBARCODE_SCAN_SIMULATOR
    dispatch_queue_t _queue;
    dispatch_semaphore_t _configurationSemaphore;

    AVCaptureDevice* _camera;
    AVCaptureSession* _captureSession;
    AVCaptureDeviceInput* _videoInput;
    AVCaptureVideoDataOutput* _videoDataOutput;
#if UMBARCODE_SCAN_SYSTEM
    AVCaptureMetadataOutput* _metaDataOutput;
#endif
#if UMBARCODE_SCAN_ZXING
    ZXDecodeHints* _zxHints;
    id<ZXReader> _zxReader;
#endif
#if UMBARCODE_SCAN_ZBAR
    ZBarImage* _zbImage;
    ZBarImageScanner* _zbScanner;
#endif
    AVCaptureVideoPreviewLayer* _videoPreviewLayer;
#endif /* !simulator */

    NSMutableArray* _viewfinderLayers;

    NSError* _error;
}
@property (nonatomic, readonly) CGRect cameraPreviewFrame;

@property (nonatomic, readonly) BOOL hasTorch;
@property (nonatomic, readonly) BOOL isTorchOn;
- (void)setTorch:(BOOL)onOff;

- (instancetype)initWithFrame:(CGRect)frame andContext:(UMBarcodeScanContext*)context;

- (void)scanStart;
- (void)scanStop;

@end
