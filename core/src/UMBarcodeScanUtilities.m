//
//  UMBarcodeScanUtilities.m
//  UMZebraTest
//
//  Created by Cyril Murzin on 02/07/15.
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//

#import "UMBarcodeScanUtilities.h"

#import "UMBarcodeScanViewControllerPvt.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>


BOOL __attribute__((noinline)) UMBarcodeScan_isOS7()
{
static dispatch_once_t _once;
static BOOL _isOS7 = NO;

    dispatch_once(&_once, ^
        {
            _isOS7 = (NSClassFromString(@"UIDynamicBehavior") != nil);
        });

    return _isOS7;
}

BOOL __attribute__((noinline)) UMBarcodeScan_isOS8()
{
static dispatch_once_t _once;
static BOOL _isOS8 = NO;

    dispatch_once(&_once, ^
        {
            _isOS8 = (NSClassFromString(@"UIUserNotificationSettings") != nil);
        });

    return _isOS8;
}

BOOL __attribute__((noinline)) UMBarcodeScan_isOS83()
{
static dispatch_once_t _once;
static BOOL _isOS83 = NO;

    dispatch_once(&_once, ^
        {
            _isOS83 = UMBarcodeScan_isOS8() && [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){ 8, 3, 0 }];
        });

    return _isOS83;
}

@implementation UMBarcodeScanUtilities

+ (BOOL)appHasViewControllerBasedStatusBar
{
static BOOL _appHasViewControllerBasedStatusBar = NO;
static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^
            {
                _appHasViewControllerBasedStatusBar = !UMBarcodeScan_isOS7() || [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"] boolValue];
            });

    return _appHasViewControllerBasedStatusBar;
}

+ (NSString*)um2avBarcodeType:(NSString*)umBarcodeType
{
    if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeUPCECode])
        return AVMetadataObjectTypeUPCECode;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeUPCACode])
        return AVMetadataObjectTypeEAN13Code;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeCode39Code])
        return AVMetadataObjectTypeCode39Code;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeCode39Mod43Code])
        return AVMetadataObjectTypeCode39Mod43Code;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeEAN13Code])
        return AVMetadataObjectTypeEAN13Code;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeEAN8Code])
        return AVMetadataObjectTypeEAN8Code;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeCode93Code])
        return AVMetadataObjectTypeCode93Code;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeCode128Code])
        return AVMetadataObjectTypeCode128Code;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypePDF417Code])
        return AVMetadataObjectTypePDF417Code;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeAztecCode])
        return AVMetadataObjectTypeAztecCode;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeQRCode])
        return AVMetadataObjectTypeQRCode;
    else if (UMBarcodeScan_isOS8() && [umBarcodeType isEqualToString:kUMBarcodeScanTypeInterleaved2of5Code])
        return AVMetadataObjectTypeInterleaved2of5Code;
    else if (UMBarcodeScan_isOS8() && [umBarcodeType isEqualToString:kUMBarcodeScanTypeITF14Code])
        return AVMetadataObjectTypeITF14Code;
    else if (UMBarcodeScan_isOS8() && [umBarcodeType isEqualToString:kUMBarcodeScanTypeDataMatrixCode])
        return AVMetadataObjectTypeDataMatrixCode;
    else
        return nil;
}

+ (NSString*)av2umBarcodeType:(NSString*)avBarcodeType
{
    if ([avBarcodeType isEqualToString:AVMetadataObjectTypeUPCECode])
        return kUMBarcodeScanTypeUPCECode;
    else if ([avBarcodeType isEqualToString:AVMetadataObjectTypeCode39Code])
        return kUMBarcodeScanTypeCode39Code;
    else if ([avBarcodeType isEqualToString:AVMetadataObjectTypeCode39Mod43Code])
        return kUMBarcodeScanTypeCode39Mod43Code;
    else if ([avBarcodeType isEqualToString:AVMetadataObjectTypeEAN13Code])
        return kUMBarcodeScanTypeEAN13Code;
    else if ([avBarcodeType isEqualToString:AVMetadataObjectTypeEAN8Code])
        return kUMBarcodeScanTypeEAN8Code;
    else if ([avBarcodeType isEqualToString:AVMetadataObjectTypeCode93Code])
        return kUMBarcodeScanTypeCode93Code;
    else if ([avBarcodeType isEqualToString:AVMetadataObjectTypeCode128Code])
        return kUMBarcodeScanTypeCode128Code;
    else if ([avBarcodeType isEqualToString:AVMetadataObjectTypePDF417Code])
        return kUMBarcodeScanTypePDF417Code;
    else if ([avBarcodeType isEqualToString:AVMetadataObjectTypeAztecCode])
        return kUMBarcodeScanTypeAztecCode;
    else if ([avBarcodeType isEqualToString:AVMetadataObjectTypeQRCode])
        return kUMBarcodeScanTypeQRCode;
    else if (UMBarcodeScan_isOS8() && [avBarcodeType isEqualToString:AVMetadataObjectTypeInterleaved2of5Code])
        return kUMBarcodeScanTypeInterleaved2of5Code;
    else if (UMBarcodeScan_isOS8() && [avBarcodeType isEqualToString:AVMetadataObjectTypeITF14Code])
        return kUMBarcodeScanTypeITF14Code;
    else if (UMBarcodeScan_isOS8() && [avBarcodeType isEqualToString:AVMetadataObjectTypeDataMatrixCode])
        return kUMBarcodeScanTypeDataMatrixCode;
    else
        return nil;
}

#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
+ (ZXBarcodeFormat)um2zxBarcodeType:(NSString*)umBarcodeType
{
    if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeUPCECode])
        return kBarcodeFormatUPCE;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeUPCACode])
        return kBarcodeFormatUPCA;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeCode39Code])
        return kBarcodeFormatCode39;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeEAN13Code])
        return kBarcodeFormatEan13;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeEAN8Code])
        return kBarcodeFormatEan8;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeCode93Code])
        return kBarcodeFormatCode93;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeCode128Code])
        return kBarcodeFormatCode128;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypePDF417Code])
        return kBarcodeFormatPDF417;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeAztecCode])
        return kBarcodeFormatAztec;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeQRCode])
        return kBarcodeFormatQRCode;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeInterleaved2of5Code])
        return kBarcodeFormatITF;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeDataMatrixCode])
        return kBarcodeFormatDataMatrix;
    else
        return (ZXBarcodeFormat)-1;
}

+ (NSString*)zx2umBarcodeType:(ZXBarcodeFormat)zxBarcodeType
{
    switch (zxBarcodeType)
    {
    case kBarcodeFormatAztec:
        return kUMBarcodeScanTypeAztecCode;
    case kBarcodeFormatCode39:
        return kUMBarcodeScanTypeCode39Code;
    case kBarcodeFormatCode93:
        return kUMBarcodeScanTypeCode93Code;
    case kBarcodeFormatCode128:
        return kUMBarcodeScanTypeCode128Code;
    case kBarcodeFormatDataMatrix:
        return kUMBarcodeScanTypeDataMatrixCode;
    case kBarcodeFormatEan8:
        return kUMBarcodeScanTypeEAN8Code;
    case kBarcodeFormatEan13:
        return kUMBarcodeScanTypeEAN13Code;
    case kBarcodeFormatITF:
        return kUMBarcodeScanTypeInterleaved2of5Code;
    case kBarcodeFormatPDF417:
        return kUMBarcodeScanTypePDF417Code;
    case kBarcodeFormatQRCode:
        return kUMBarcodeScanTypeQRCode;
    case kBarcodeFormatUPCA:
        return kUMBarcodeScanTypeUPCACode;
    case kBarcodeFormatUPCE:
        return kUMBarcodeScanTypeUPCECode;
    default:
        return nil;
    }
}
#endif

#if defined(UMBARCODE_SCAN_ZBAR) && UMBARCODE_SCAN_ZBAR
+ (zbar_symbol_type_t)um2zbBarcodeType:(NSString*)umBarcodeType
{
    if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeUPCECode])
        return ZBAR_UPCE;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeUPCACode])
        return ZBAR_UPCA;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeCode39Code])
        return ZBAR_CODE39;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeEAN13Code])
        return ZBAR_EAN13;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeEAN8Code])
        return ZBAR_EAN8;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeCode93Code])
        return ZBAR_CODE93;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeCode128Code])
        return ZBAR_CODE128;
#if 0 // not implemented
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypePDF417Code])
        return ZBAR_PDF417;
#endif
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeAztecCode])
        return ZBAR_QRCODE;
    else if ([umBarcodeType isEqualToString:kUMBarcodeScanTypeInterleaved2of5Code])
        return ZBAR_I25;
    else
        return ZBAR_NONE;
}

+ (NSString*)zb2umBarcodeType:(zbar_symbol_type_t)zbBarcodeType
{
    switch (zbBarcodeType)
    {
    case ZBAR_CODE39:
        return kUMBarcodeScanTypeCode39Code;
    case ZBAR_CODE93:
        return kUMBarcodeScanTypeCode93Code;
    case ZBAR_CODE128:
        return kUMBarcodeScanTypeCode128Code;
    case ZBAR_EAN8:
        return kUMBarcodeScanTypeEAN8Code;
    case ZBAR_EAN13:
        return kUMBarcodeScanTypeEAN13Code;
    case ZBAR_I25:
        return kUMBarcodeScanTypeInterleaved2of5Code;
#if 0 // not implemented
    case ZBAR_PDF417:
        return kUMBarcodeScanTypePDF417Code;
#endif
    case ZBAR_QRCODE:
        return kUMBarcodeScanTypeQRCode;
    case ZBAR_UPCA:
        return kUMBarcodeScanTypeUPCACode;
    case ZBAR_UPCE:
        return kUMBarcodeScanTypeUPCECode;
    default:
        return nil;
    }
}
#endif

+ (BOOL)hasVideoCamera
{
    // check for a camera
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        return NO;
    }

    // check for video support
    NSArray* availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    BOOL supportsVideo = [availableMediaTypes containsObject:(NSString*)kUTTypeMovie];

    // TODO: Should check AVCaptureDevice's supportsAVCaptureSessionPreset: for our preset.

    return supportsVideo;
}

+ (BOOL)_canReadBarcodeWithCamera
{
    typedef NS_ENUM(NSInteger, ScanAvailabilityStatus)
    {
        ScanAvailabilityUnknown = 0,
        ScanAvailabilityNever = 1,
        ScanAvailabilityAlways = 2
    };

static ScanAvailabilityStatus cachedScanAvailabilityStatus = ScanAvailabilityUnknown;

    if (cachedScanAvailabilityStatus == ScanAvailabilityNever)
    {
        return NO;
    }

    if (cachedScanAvailabilityStatus == ScanAvailabilityUnknown)
    {
        // Check that AVFoundation is present (excludes OS 3.x and below)
        if(!NSClassFromString(@"AVCaptureSession"))
        {
            cachedScanAvailabilityStatus = ScanAvailabilityNever;

            return NO;
        }

        // Check for video camera. This serves as a de facto CPU speed
        // and RAM availability check as well -- only recent devices have a
        // hardware h264 encoder, but only recent devices have beefy enough
        // CPU and RAM. This is not really exactly the right thing to check for,
        // but it is well correlated, and happens to work out correctly for existing devices.
        // In particular, this rules out the iPhone 3G but lets in the 3GS, which
        // we know to be the iPhone cutoff. This lets through iPod touch 4, which
        // is the only iPod touch generation to have a camera (see http://en.wikipedia.org/wiki/IPod_Touch).
        if (![[self class] hasVideoCamera])
        {
            cachedScanAvailabilityStatus = ScanAvailabilityNever;

            return NO;
        }

        if (UMBarcodeScan_isOS7())
        {
            // Check for video permission.
            // But don't set cachedScanAvailabilityStatus here, as the user can change this permission at any time.
            // (Actually, should the user go to Settings and change this permission for this app, apparently the system
            // will immediately SIGKILL (force restart) this app. But let's not depend on this semi-documented behavior.)
            AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (authStatus == AVAuthorizationStatusDenied || authStatus == AVAuthorizationStatusRestricted)
            {
                return NO;
            }
            else
            {
                // Either the user has already granted permission, or else the user has not yet been asked.
                //
                // For the latter case, while we could ask now, unfortunately the necessary
                // [AVCaptureDevice requestAccessForMediaType:completionHandler:] method returns the user's choice
                // to us asynchronously, which doesn't mix well with canReadCardWithCamera being synchronous.
                //
                // Rather than making a backward-incompatible change to canReadCardWithCamera, let's simply allow things
                // to proceed. When the camera view is finally presented, then the user will be prompted to authorize
                // or deny the video permission. If they choose "deny", then they'll probably understand why they're
                // looking at a black screen.
                return YES;
            }
        }

        cachedScanAvailabilityStatus = ScanAvailabilityAlways;
    }

    return YES;
}

@end
