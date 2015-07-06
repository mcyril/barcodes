//
//  UMBarcodeScanViewController.h
//
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//  Created by Cyril Murzin
//

//  some work derived & base ideas of scan controller are borrowed from CardIO library,
//  the courtesy of eBay Software Foundation. see LICENSE & README files for more info

#import <UIKit/UIKit.h>

/**
 *    scan modes
 */
enum _UMBarcodeScanMode
{
    kUMBarcodeScanMode_NONE = 0,
    kUMBarcodeScanMode_System,  // fast, reliable enough, but iOS7+ (some barcode types available from iOS8+)
    kUMBarcodeScanMode_ZBar,    // ultrafast, reliable enough, but has limited set of formats
    kUMBarcodeScanMode_ZXing,   // slow, sometimes glitchy, but has good set of formats

    kUMBarcodeScanMode_COUNT
};
typedef enum _UMBarcodeScanMode UMBarcodeScanMode_t;

#ifndef API_EXPORT
#define API_EXPORT  __attribute__((visibility("default")))
#endif

#ifndef EXT_EXPORT
#define EXT_EXPORT  extern __attribute__((visibility("default")))
#endif

/**
 *    barcode types for scanning
 */
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

/**
 *    controller delagate
 */
@protocol UMBarcodeScanDelegate <NSObject>
@required

/**
 *    delegate method called when user cancelled (tapped cancel button) scanning process or the error occured
 *
 *    @param scanViewController own controller
 *    @param error              error occured, or nil if operation cancelled
 */
- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController didCancelWithError:(NSError*)error;

/**
 *    delegate method called when barcode scanned succesfully
 *
 *    @param scanViewController own controller
 *    @param barcodeData        scanned data
 *    @param barcodeType        scanned barcode type
 */
- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController didScanString:(NSString*)barcodeData ofBarcodeType:(NSString*)barcodeType;

@optional

/**
 *    delegate method called when user tapped help button
 *
 *    @param scanViewController own controller
 *
 *    @discussion               please take care on suspend/resume of scanning session
 */
- (void)scanViewControllerDidPressHelpButton:(UMBarcodeScanViewController*)scanViewController;

/**
 *    optional customized viefinder layer creation
 *
 *    @param scanViewController own controller
 *    @param index              sequential number of layer to be created
 *
 *    @return                   created layer (don't forget to name it), or nil when all layers created
 */
- (CALayer*)scanViewController:(UMBarcodeScanViewController*)scanViewController addLayerAtIndex:(NSUInteger)index;

/**
 *    optional customized viefinder layer layout
 *
 *    @param scanViewController own controller
 *    @param layer              layer created with scanViewController:addLayerAtIndex:
 *    @param rect               viewfinder area rectangle
 */
- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController layoutLayer:(CALayer*)layer viewRect:(CGRect)rect;
@end

@class UMBarcodeScanContext;

/**
 *    core controller
 */
API_EXPORT @interface UMBarcodeScanViewController : UINavigationController
{
@private
    UMBarcodeScanContext* _context;

    BOOL _shouldStoreStatusBarStyle;
    BOOL _statusBarWasOriginallyHidden;
    UIStatusBarStyle _originalStatusBarStyle;
}

/**
 *    cancel button title ('Cancel' by default)
 */
@property (nonatomic, retain) NSString* cancelButtonText;
/**
 *    help button title (empty by default)
 *    (non empty title means controller should show button)
 */
@property (nonatomic, retain) NSString* helpButtonText;
/**
 *    viewfinder hint text (empty by default)
 *    (non empty text means viewfinder should show hint)
 */
@property (nonatomic, retain) NSString* hintText;

/**
 *    scan mode
 *    (default behaviour: bypass setting of this property sets kUMBarcodeScanMode_System for iOS7+ or kUMBarcodeScanMode_ZXing for iOS6)
 */
@property (nonatomic, assign) UMBarcodeScanMode_t scanMode;
/**
 *    allowed barcode types to scan
 */
@property (nonatomic, retain) NSArray* barcodeTypes;

/**
 *    as per CardIO:
 *    If YES, the status bar's style will be kept as whatever your app has set it to.
 *    If NO, the status bar style will be set to the default style.
 *    Defaults to NO.
 */
@property (nonatomic, assign) BOOL keepStatusBarStyle;
/**
 *    as per CardIO:
 *    The default appearance of the navigation bar is navigationBarStyle == UIBarStyleDefault;
 *    tintColor == nil (pre-iOS 7), barTintColor == nil (iOS 7).
 *    Set either or both of these properties if you want to override these defaults.
 *    @see navigationBarTintColor
 */
@property (nonatomic, assign) UIBarStyle navigationBarStyle;
/**
 *    as per CardIO:
 *    The default appearance of the navigation bar is navigationBarStyle == UIBarStyleDefault;
 *    tintColor == nil (pre-iOS 7), barTintColor == nil (iOS 7).
 *    Set either or both of these properties if you want to override these defaults.
 *    @see navigationBarStyle
 */
@property (nonatomic, retain) UIColor* navigationBarTintColor;
/**
 *    as per CardIO:
 *    By default, in camera view the card guide and the buttons always rotate to match the device's orientation.
 *     All four orientations are permitted, regardless of any app or viewcontroller constraints.
 *    If you wish, the card guide and buttons can instead obey standard iOS constraints, including
 *     the UISupportedInterfaceOrientations settings in your app's plist.
 *    Set to NO to follow standard iOS constraints. Defaults to YES. (Does not affect the manual entry screen.)
 */
@property (nonatomic, assign) BOOL allowFreelyRotatingGuide;

/**
 *    primary (and only) way to initialize controller
 *
 *    @param delegate controller delegate
 *
 *    @return on success created and initialized controller
 */
- (instancetype)initWithScanDelegate:(id<UMBarcodeScanDelegate>)delegate;

/**
 *    check if scanning suspended
 *
 *    @return YES if suspended
 */
- (BOOL)isSuspended;
/**
 *    suspend scanning
 */
- (void)suspend;
/**
 *    resume scanning
 */
- (void)resume;

/**
 *    device has camera capability
 *
 *    @return YES if camera available for barcode scanning
 */
+ (BOOL)canReadBarcodeWithCamera;
/**
 *    list of allowed scan modes (terminating by kUMBarcodeScanMode_NONE)
 *
 *    @return allowed scan modes
 */
+ (UMBarcodeScanMode_t*)allowedScanModes;

@end
