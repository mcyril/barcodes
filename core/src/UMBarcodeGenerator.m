//
//  UMBarcodeGenerator.m
//
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//  Created by Cyril Murzin
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
#else
#import "aztecgen.h"
#import "qrencode.h"
#endif


#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
//# define QR_ECLEVEL      [ZXQRCodeErrorCorrectionLevel errorCorrectionLevelM]
#   define QR_ECLEVEL      [ZXQRCodeErrorCorrectionLevel errorCorrectionLevelL]
#   define AZTEC_ECLEVEL   [ZXQRCodeErrorCorrectionLevel errorCorrectionLevelQ]
#elif defined(UMBARCODE_GEN_ZINT) && UMBARCODE_GEN_ZINT
#else
//# define QR_ECLEVEL      QR_ECLEVEL_M
#   define QR_ECLEVEL      QR_ECLEVEL_L
#   define AZTEC_ECLEVEL   23
#endif

#define BARCODE_MARGINS     0   // let caller care of margins

#if defined(UMBARCODE_GEN_ZINT) && UMBARCODE_GEN_ZINT
#elif !defined(UMBARCODE_SCAN_ZXING) || !UMBARCODE_SCAN_ZXING
static void freeRawData(void* info, const void* data, size_t size)
{
    free((void*)data);
}
#endif

@interface UMBarcodeGenerator ()
#if defined(UMBARCODE_GEN_ZINT) && UMBARCODE_GEN_ZINT
#elif !defined(UMBARCODE_SCAN_ZXING) || !UMBARCODE_SCAN_ZXING
+ (UIImage*)_imageSquareWithPixels:(unsigned char*)pixels width:(int)width margin:(int)margin constrains:(int)cwidth opaque:(BOOL)opaque;
#endif
@end

@implementation UMBarcodeGenerator

+ (UIImage*)imageWithData:(NSString*)data encoding:(CFStringEncoding)encoding barcodeType:(NSString*)type imageSize:(CGSize)size whiteOpaque:(BOOL)opaque error:(NSError**)error
{
#if defined(UMBARCODE_SCAN_ZXING) && UMBARCODE_SCAN_ZXING
    ZXBarcodeFormat format = [UMBarcodeScanUtilities um2zxBarcodeType:type];
    if (format == (ZXBarcodeFormat)-1)
        return nil;

    ZXEncodeHints* hints = [ZXEncodeHints hints];
    hints.encoding = CFStringConvertEncodingToNSStringEncoding(encoding);
    hints.errorCorrectionLevel = (format == kBarcodeFormatAztec ? AZTEC_ECLEVEL : QR_ECLEVEL);
    hints.margin = [NSNumber numberWithInt:BARCODE_MARGINS];

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
        return nil;
#elif defined(UMBARCODE_GEN_ZINT) && UMBARCODE_GEN_ZINT
    return nil; // TODO: xxx
#else
    // without ZXing we're supporting only limited set of barcodes to generate.. why? 'cause I need only these two

    if ([type isEqualToString:kUMBarcodeTypeAztecCode])
    {
        NSData* string = [data dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(encoding)];
        if (string == nil)
            return nil;

        UIImage* image = nil;

        ag_settings settings = { 0 };
        settings.mask = AG_SF_SYMBOL_FORMAT | AG_SF_REDUNDANCY_FOR_ERROR_CORRECTION;
        settings.symbol_format = AG_FULL_FORMAT;
        settings.redundancy_for_error_correction = AZTEC_ECLEVEL;

        ag_matrix* barcode = NULL;
        const int gen_result = ag_generate(&barcode, [string bytes], [string length], &settings);
        if (gen_result == AG_SUCCESS)
            image = [[self class] _imageSquareWithPixels:barcode->data width:(int)barcode->width margin:BARCODE_MARGINS constrains:ceilf(size.width) opaque:opaque];

        ag_release_matrix(barcode);

        return image;
    }
    else if ([type isEqualToString:kUMBarcodeTypeQRCode])
    {
        NSData* string = [data dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(encoding)];
        if (string == nil)
            return nil;

        UIImage* image = nil;

        QRcode* resultCode = QRcode_encodeData((int)[string length], [string bytes], 0, QR_ECLEVEL);
        if (resultCode != NULL)
        {
            image = [[self class] _imageSquareWithPixels:resultCode->data width:resultCode->width margin:BARCODE_MARGINS constrains:ceilf(size.width) opaque:opaque];

            QRcode_free(resultCode);
        }

        return image;
    }
    else
        return nil;
#endif
}

#if defined(UMBARCODE_GEN_ZINT) && UMBARCODE_GEN_ZINT
#elif !defined(UMBARCODE_SCAN_ZXING) || !UMBARCODE_SCAN_ZXING
+ (UIImage*)_imageSquareWithPixels:(unsigned char*)pixels width:(int)width margin:(int)margin constrains:(int)cwidth opaque:(BOOL)opaque
{
    int len = width * width;

    // Set bit-fiddling variables
    int bytesPerPixel = 4;
    int pixelPerDot = cwidth / width;
    if (pixelPerDot < 4)
        return nil;

    // increase image size by margins
    cwidth += 2 * margin * pixelPerDot;

    int bytesPerLine = bytesPerPixel * cwidth;
    int rawDataSize = bytesPerLine * cwidth;

    int offset = (int)((cwidth - pixelPerDot * width) / 2);

    // Allocate raw image buffer
    unsigned char* rawData = (unsigned char*)malloc(rawDataSize);
    memset(rawData, opaque ? 0xff : 0x00, rawDataSize);

    // Fill raw image buffer with image data from QR code matrix
    for (int i = 0; i < len; i++)
    {
        char intensity = (pixels[i] & 1) != 0 ? 0 : 0xff;

        int y = i / width;
        int x = i - (y * width);

        int startX = pixelPerDot * x * bytesPerPixel + (bytesPerPixel * offset);
        int startY = pixelPerDot * y + offset;

        int endX = startX + pixelPerDot * bytesPerPixel;
        int endY = startY + pixelPerDot;

        for (int my = startY; my < endY; my++)
            for (int mx = startX; mx < endX; mx += bytesPerPixel)
            {
                if (opaque)
                {
                    rawData[bytesPerLine * my + mx    ] = intensity;        // red
                    rawData[bytesPerLine * my + mx + 1] = intensity;        // green
                    rawData[bytesPerLine * my + mx + 2] = intensity;        // blue
                }
                else
                    rawData[bytesPerLine * my + mx + 3] = 0xff - intensity; // alpha
            }
    }

    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rawData, rawDataSize, freeRawData);

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(cwidth, cwidth, 8, 8 * bytesPerPixel, bytesPerLine, colorSpaceRef, kCGBitmapByteOrderDefault|kCGImageAlphaLast, provider, NULL, false, kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpaceRef);

    CGDataProviderRelease(provider);

    UIImage* image = [UIImage imageWithCGImage:imageRef];

    CGImageRelease(imageRef);

    return image;
}
#endif

@end
