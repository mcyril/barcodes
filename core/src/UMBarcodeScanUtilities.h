//
//  UMBarcodeScanUtilities.h
//
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//  Created by Cyril Murzin
//

#import "UMBarcodeScanViewControllerPvt.h"

#if UMBARCODE_SCAN_ZXING || UMBARCODE_GEN_ZXING
#import "ZXingObjC.h"
#endif

#if UMBARCODE_SCAN_ZBAR
#import "zbar.h"
#endif

#if UMBARCODE_GEN_ZINT
#import "zint.h"
#endif

@interface UMBarcodeScanUtilities : NSObject

+ (BOOL)appHasViewControllerBasedStatusBar;

#if UMBARCODE_SCAN_SYSTEM
+ (NSString*)um2avBarcodeType:(NSString*)umBarcodeType;
+ (NSString*)av2umBarcodeType:(NSString*)avBarcodeType;
#endif

#if UMBARCODE_SCAN_ZXING || UMBARCODE_GEN_ZXING
+ (ZXBarcodeFormat)um2zxBarcodeType:(NSString*)umBarcodeType;
+ (NSString*)zx2umBarcodeType:(ZXBarcodeFormat)zxBarcodeType;
#endif

#if UMBARCODE_SCAN_ZBAR
+ (zbar_symbol_type_t)um2zbBarcodeType:(NSString*)umBarcodeType;
+ (NSString*)zb2umBarcodeType:(zbar_symbol_type_t)zbBarcodeType;
#endif

#if UMBARCODE_GEN_ZINT
+ (int)um2zintBarcodeType:(NSString*)umBarcodeType;
#endif

+ (BOOL)_hasVideoCamera;
+ (BOOL)_canReadBarcodeWithCamera;
+ (UMBarcodeScanMode_t*)_allowedScanModes;

@end

BOOL UMBarcodeScan_isOS7();
BOOL UMBarcodeScan_isOS8();
BOOL UMBarcodeScan_isOS9();

typedef uint8_t InterfaceToDeviceOrientationDelta; // the amount that the interfaceOrientation is rotated relative to the deviceOrientation

enum
{
    InterfaceToDeviceOrientationSame = 1,
    InterfaceToDeviceOrientationUpsideDown = 2,
    InterfaceToDeviceOrientationRotatedClockwise = 3,
    InterfaceToDeviceOrientationRotatedCounterclockwise = 4
};

static inline InterfaceToDeviceOrientationDelta orientationDelta(UIInterfaceOrientation interfaceOrientation, UIDeviceOrientation deviceOrientation)
{
    uint16_t absoluteInterfaceOrientation = 0;
    switch (interfaceOrientation)
    {
    case UIInterfaceOrientationPortrait:
        absoluteInterfaceOrientation = 0;
        break;
    case UIInterfaceOrientationLandscapeLeft:
        absoluteInterfaceOrientation = 270;
        break;
    case UIInterfaceOrientationLandscapeRight:
        absoluteInterfaceOrientation = 90;
        break;
    case UIInterfaceOrientationPortraitUpsideDown:
        absoluteInterfaceOrientation = 180;
        break;
    default:
        break;
    }

    uint16_t absoluteDeviceOrientation = 0;
    switch (deviceOrientation)
    {
    case UIDeviceOrientationPortrait:
        absoluteDeviceOrientation = 0;
        break;
    case UIDeviceOrientationLandscapeRight:
        absoluteDeviceOrientation = 270;
        break;
    case UIDeviceOrientationLandscapeLeft:
        absoluteDeviceOrientation = 90;
        break;
    case UIDeviceOrientationPortraitUpsideDown:
        absoluteDeviceOrientation = 180;
        break;
    default:
        // Note that we are explicitly not dealing with device flat / upside down here, since they do not impact
        // the camera orientation. We assume that someone upstream of us hands this.
        break;
    }

    uint16_t orientationDelta = (360 + absoluteInterfaceOrientation - absoluteDeviceOrientation) % 360;

    InterfaceToDeviceOrientationDelta delta = InterfaceToDeviceOrientationSame;
    switch (orientationDelta)
    {
    case 0:
        delta = InterfaceToDeviceOrientationSame;
        break;
    case 90:
        delta = InterfaceToDeviceOrientationRotatedCounterclockwise;
        break;
    case 180:
        delta = InterfaceToDeviceOrientationUpsideDown;
        break;
    case 270:
        delta = InterfaceToDeviceOrientationRotatedClockwise;
        break;
    default:
        break;
    }

    return delta;
}

static inline CGFloat rotationForOrientationDelta(InterfaceToDeviceOrientationDelta delta)
{
    CGFloat rotation = .0;
    switch (delta)
    {
    case InterfaceToDeviceOrientationSame:
        rotation = .0;
        break;
    case InterfaceToDeviceOrientationRotatedClockwise:
        rotation = (CGFloat)(3. * M_PI_2);
        break;
    case InterfaceToDeviceOrientationUpsideDown:
        rotation = (CGFloat)M_PI;
        break;
    case InterfaceToDeviceOrientationRotatedCounterclockwise:
        rotation = (CGFloat)M_PI_2;
        break;
    default:
        break;
    }

    return rotation;
}

static inline CGRect CGRectWithRotatedRect(CGRect rect)
{
    return CGRectMake(rect.origin.y, rect.origin.x, rect.size.height, rect.size.width);
}

static inline CGRect CGRectWithXYAndSize(CGFloat xOrigin, CGFloat yOrigin, CGSize size)
{
    return CGRectMake(xOrigin, yOrigin, size.width, size.height);
}
