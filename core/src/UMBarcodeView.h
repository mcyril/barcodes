//
//  UMBarcodeView.h
//
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//  Created by Cyril Murzin
//

@class UMBarcodeScanContext;

@class AVCaptureDevice;
@class AVCaptureSession;
@class AVCaptureDeviceInput;
@class AVCaptureMetadataOutput;
@class AVCaptureVideoDataOutput;
@class AVCaptureVideoPreviewLayer;

#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
@class ZXDecodeHints;
@protocol ZXReader;
#endif

#if defined(UMBARCODE_SCAN_ZBAR) && UMBARCODE_SCAN_ZBAR
@class ZBarImage;
@class ZBarImageScanner;
#endif

@interface UMBarcodeView : UIView
{
@private
    UMBarcodeScanContext* _context;

#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    dispatch_queue_t _queue;
    dispatch_semaphore_t _configurationSemaphore;

    AVCaptureDevice* _camera;
    AVCaptureSession* _captureSession;
    AVCaptureDeviceInput* _videoInput;
    AVCaptureMetadataOutput* _metaDataOutput;
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
    AVCaptureVideoDataOutput* _videoDataOutput;
#endif
#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
    ZXDecodeHints* _zxHints;
    id<ZXReader> _zxReader;
#endif
#if defined(UMBARCODE_SCAN_ZBAR) && UMBARCODE_SCAN_ZBAR
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
