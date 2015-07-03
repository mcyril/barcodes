//
//  UMBarcodeScanViewController.h
//  UMZebraTest
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

@interface UMBarcodeScanViewController : UINavigationController
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

extern NSString* const kUMBarcodeScanTypeUPCACode;
extern NSString* const kUMBarcodeScanTypeUPCECode;
extern NSString* const kUMBarcodeScanTypeCode39Code;
extern NSString* const kUMBarcodeScanTypeCode39Mod43Code;
extern NSString* const kUMBarcodeScanTypeEAN13Code;
extern NSString* const kUMBarcodeScanTypeEAN8Code;
extern NSString* const kUMBarcodeScanTypeCode93Code;
extern NSString* const kUMBarcodeScanTypeCode128Code;
extern NSString* const kUMBarcodeScanTypePDF417Code;
extern NSString* const kUMBarcodeScanTypeAztecCode;
extern NSString* const kUMBarcodeScanTypeQRCode;
extern NSString* const kUMBarcodeScanTypeInterleaved2of5Code;
extern NSString* const kUMBarcodeScanTypeITF14Code;
extern NSString* const kUMBarcodeScanTypeDataMatrixCode;
