//
//  UMBarcodeScanViewController.h
//
//  Created by Cyril Murzin on 02/07/15.
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//

#import <UIKit/UIKit.h>

enum _UMBarcodeScanMode
{
    kUMBarcodeScanMode_NONE = 0,
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

#ifndef API_EXPORT
#define API_EXPORT  __attribute__((visibility("default")))
#endif

#ifndef EXT_EXPORT
#define EXT_EXPORT  extern __attribute__((visibility("default")))
#endif

EXT_EXPORT NSString* const kUMBarcodeTypeUPCACode;
EXT_EXPORT NSString* const kUMBarcodeTypeUPCECode;
EXT_EXPORT NSString* const kUMBarcodeTypeCode39Code;
EXT_EXPORT NSString* const kUMBarcodeTypeCode39Mod43Code;
EXT_EXPORT NSString* const kUMBarcodeTypeEAN13Code;
EXT_EXPORT NSString* const kUMBarcodeTypeEAN8Code;
EXT_EXPORT NSString* const kUMBarcodeTypeCode93Code;
EXT_EXPORT NSString* const kUMBarcodeTypeCode128Code;
EXT_EXPORT NSString* const kUMBarcodeTypePDF417Code;
EXT_EXPORT NSString* const kUMBarcodeTypeAztecCode;
EXT_EXPORT NSString* const kUMBarcodeTypeQRCode;
EXT_EXPORT NSString* const kUMBarcodeTypeInterleaved2of5Code;
EXT_EXPORT NSString* const kUMBarcodeTypeITF14Code;
EXT_EXPORT NSString* const kUMBarcodeTypeDataMatrixCode;

@class UMBarcodeScanViewController;

@protocol UMBarcodeScanDelegate <NSObject>
@required
- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController didCancelWithError:(NSError*)error;
- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController didScanString:(NSString*)barcodeData ofBarcodeType:(NSString*)barcodeType;

@optional
- (void)scanViewControllerDidPressHelpButton:(UMBarcodeScanViewController*)scanViewController;
@end

@class UMBarcodeScanContext;

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
+ (UMBarcodeScanMode_t*)allowedScanModes;

@end
