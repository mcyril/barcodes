//
//  UMBarcodeScanViewController.h
//
//  Created by Cyril Murzin on 02/07/15.
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//

#import "UMBarcodeScanDelegate.h"

enum _UMBarcodeScanMode
{
    kUMBarcodeScanMode_START = 0,
    kUMBarcodeScanMode_System,  // fast, reliable enough, but iOS7+ (some codes iOS8+)
#if defined(UMBARCODE_SCAN_ZBAR) && UMBARCODE_SCAN_ZBAR
    kUMBarcodeScanMode_ZBar,    // ultrafast, reliable enough, but has limited set of formats
#endif
#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
    kUMBarcodeScanMode_ZXing,   // slow, sometimes glitchy, but has good set of formats
#endif

    kUMBarcodeScanMode_COUNT
};
typedef enum _UMBarcodeScanMode UMBarcodeScanMode_t;

@class UMBarcodeScanContext;

#define API_EXPORT  __attribute__((visibility("default")))
#define EXT_EXPORT  extern __attribute__((visibility("default")))

API_EXPORT @interface UMBarcodeScanViewController : UINavigationController
{
@private
    UMBarcodeScanContext* _context;

    BOOL _shouldStoreStatusBarStyle;
    BOOL _statusBarWasOriginallyHidden;
    UIStatusBarStyle _originalStatusBarStyle;
}
@property (nonatomic, retain) NSString* cancelButtonText;
@property (nonatomic, retain) NSString* helpButtonText;
@property (nonatomic, retain) NSString* hintText;

@property (nonatomic, assign) UMBarcodeScanMode_t scanMode;
@property (nonatomic, retain) NSArray* barcodeTypes;

@property (nonatomic, assign) BOOL keepStatusBarStyle;
@property (nonatomic, assign) UIBarStyle navigationBarStyle;
@property (nonatomic, retain) UIColor* navigationBarTintColor;

@property (nonatomic, assign) BOOL allowFreelyRotatingGuide;
@property (nonatomic, assign) BOOL showFoundCodePoints;

- (instancetype)initWithScanDelegate:(id<UMBarcodeScanDelegate>)delegate;

- (BOOL)isSuspended;
- (void)suspend;
- (void)resume;

+ (BOOL)canReadBarcodeWithCamera;

@end

EXT_EXPORT NSString* const kUMBarcodeScanTypeUPCACode;
EXT_EXPORT NSString* const kUMBarcodeScanTypeUPCECode;
EXT_EXPORT NSString* const kUMBarcodeScanTypeCode39Code;
EXT_EXPORT NSString* const kUMBarcodeScanTypeCode39Mod43Code;
EXT_EXPORT NSString* const kUMBarcodeScanTypeEAN13Code;
EXT_EXPORT NSString* const kUMBarcodeScanTypeEAN8Code;
EXT_EXPORT NSString* const kUMBarcodeScanTypeCode93Code;
EXT_EXPORT NSString* const kUMBarcodeScanTypeCode128Code;
EXT_EXPORT NSString* const kUMBarcodeScanTypePDF417Code;
EXT_EXPORT NSString* const kUMBarcodeScanTypeAztecCode;
EXT_EXPORT NSString* const kUMBarcodeScanTypeQRCode;
EXT_EXPORT NSString* const kUMBarcodeScanTypeInterleaved2of5Code;
EXT_EXPORT NSString* const kUMBarcodeScanTypeITF14Code;
EXT_EXPORT NSString* const kUMBarcodeScanTypeDataMatrixCode;
