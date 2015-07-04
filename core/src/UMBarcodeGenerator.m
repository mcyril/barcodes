//
//  UMBarcodeGenerator.m
//  barcodes
//
//  Created by Cyril Murzin on 04/07/15.
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//

#import "UMBarcodeGeneratorPvt.h"

#import "UMBarcodeScanContext.h"
#import "UMBarcodeScanUtilities.h"

#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
#import "ZXQRCodeErrorCorrectionLevel.h"
#import "ZXEncodeHints.h"
#import "ZXMultiFormatWriter.h"
#import "ZXBitMatrix.h"
#import "ZXImage.h"
#endif


@implementation UMBarcodeGenerator

+ (UIImage*)imageWithData:(NSString*)data encoding:(CFStringEncoding)encoding barcodeType:(NSString*)type imageSize:(CGSize)size whiteOpaque:(BOOL)opaque error:(NSError**)error
{
#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
    ZXBarcodeFormat format = [UMBarcodeScanUtilities um2zxBarcodeType:type];
    if (format == (ZXBarcodeFormat)-1)
        return nil;

    ZXEncodeHints* hints = [ZXEncodeHints hints];
    hints.encoding = CFStringConvertEncodingToNSStringEncoding(encoding);
    hints.errorCorrectionLevel = (format == kBarcodeFormatAztec ? [ZXQRCodeErrorCorrectionLevel errorCorrectionLevelQ] : [ZXQRCodeErrorCorrectionLevel errorCorrectionLevelM]);
    hints.margin = [NSNumber numberWithInt:4];

    ZXBitMatrix* result = [[ZXMultiFormatWriter writer] encode:data format:format width:ceilf(size.width) height:ceilf(size.height) hints:hints error:error];
    if (result != nil)
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();

        CGFloat blackComponents[] = { .0, 1. };
        CGColorRef black = CGColorCreate(colorSpace, blackComponents);

        CGFloat whiteComponents[] = { opaque ?  1. : .0, opaque ?  1. : .0 };
        CGColorRef white = CGColorCreate(colorSpace, whiteComponents);

        CFRelease(colorSpace);

        ZXImage* image = [ZXImage imageWithMatrix:result onColor:black offColor:white];

        CGColorRelease(white);
        CGColorRelease(black);

        return [UIImage imageWithCGImage:image.cgimage];
    }
    else
#endif
        return nil;
}

@end
