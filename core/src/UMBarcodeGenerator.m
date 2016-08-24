//
//  UMBarcodeGenerator.m
//
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//  Created by Cyril Murzin
//

#import "UMBarcodeGeneratorPvt.h"

#import "UMBarcodeScanContext.h"
#import "UMBarcodeScanUtilities.h"

#if UMBARCODE_SCAN_ZXING
#import "ZXQRCodeErrorCorrectionLevel.h"
#import "ZXEncodeHints.h"
#import "ZXMultiFormatWriter.h"
#import "ZXBitMatrix.h"
#import "ZXImage.h"
#endif
#if UMBARCODE_GEN_ZINT
#import "zint.h"
#endif
#if UMBARCODE_GEN_AZTEC
#import "aztecgen.h"
#endif
#if UMBARCODE_GEN_QR
#import "qrencode.h"
#endif


#if UMBARCODE_GEN_ZXING
//# define ZXING_QR_ECLEVEL     [ZXQRCodeErrorCorrectionLevel errorCorrectionLevelM]
#   define ZXING_QR_ECLEVEL     [ZXQRCodeErrorCorrectionLevel errorCorrectionLevelL]
#   define ZXING_AZTEC_ECLEVEL  [ZXQRCodeErrorCorrectionLevel errorCorrectionLevelQ]
#endif
#if UMBARCODE_GEN_QR
//# define QR_ECLEVEL           QR_ECLEVEL_M
#   define QR_ECLEVEL           QR_ECLEVEL_L
#endif
#if UMBARCODE_GEN_AZTEC
#   define AZTEC_ECLEVEL        23
#endif

#define BARCODE_MARGINS         0   // let caller care of margins

#if UMBARCODE_GEN_AZTEC || UMBARCODE_GEN_QR
static void freeRawData(void* info, const void* data, size_t size)
{
    free((void*)data);
}
#endif

@interface UMBarcodeGenerator ()
#if UMBARCODE_GEN_AZTEC || UMBARCODE_GEN_QR
+ (UIImage*)_imageSquareWithPixels:(unsigned char*)pixels width:(int)width margin:(int)margin constrains:(int)cwidth opaque:(BOOL)opaque;
#endif
@end

@implementation UMBarcodeGenerator

- (instancetype)initWithGenMode:(UMBarcodeGenMode_t)genMode
{
    self = [super init];
    if (self != nil)
    {
        _genMode = genMode;
    }

    return self;
}

- (UIImage*)imageWithData:(NSString*)data encoding:(CFStringEncoding)encoding barcodeType:(NSString*)type imageSize:(CGSize)size whiteOpaque:(BOOL)opaque error:(NSError**)error
{
    UIImage* barImage = nil;

    switch (_genMode)
    {
#if UMBARCODE_GEN_SYSTEM
    case kUMBarcodeGenMode_System:
        {

        }
        break;
#endif
#if UMBARCODE_GEN_ZXING
    case kUMBarcodeGenMode_ZXing:
        {
            ZXBarcodeFormat format = [UMBarcodeScanUtilities um2zxBarcodeType:type];
            if (format == (ZXBarcodeFormat)-1)
                break;

            ZXEncodeHints* hints = [ZXEncodeHints hints];
            hints.encoding = CFStringConvertEncodingToNSStringEncoding(encoding);
            hints.errorCorrectionLevel = (format == kBarcodeFormatAztec ? ZXING_AZTEC_ECLEVEL : ZXING_QR_ECLEVEL);
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

                barImage = image != nil ? [UIImage imageWithCGImage:image.cgimage] : nil;
            }
        }
        break;
#endif
#if UMBARCODE_GEN_ZINT
    case kUMBarcodeGenMode_ZInt:
        {
            int format = [UMBarcodeScanUtilities um2zintBarcodeType:type];
            if (format == -1)
                break;

            NSData* string = [data dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(encoding)];
            if (string != nil)
            {
                struct zint_symbol* symbol = ZBarcode_Create();
                if (symbol != NULL)
                {
                    symbol->symbology = format;

                    int result = ZBarcode_Encode(symbol, (unsigned char *)[string bytes], (int)[string length]);
                    if (result == 0)
                    {
                        result = ZBarcode_Render(symbol, size.width, size.height);
                        if (1 /*result == 0*/) // NOTE: render returns 1?
                        {
                            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                            CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 4 * size.width, colorSpace, kCGImageAlphaPremultipliedFirst);
                            CGColorSpaceRelease(colorSpace);

                            if (context != NULL)
                            {
                                CGRect bounds =
                                        {
                                            .origin = CGPointZero,
                                            .size = size
                                        };

                                CGContextSetShouldAntialias(context, false);

                                if (opaque)
                                {
                                    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
                                    CGContextFillRect(context, bounds);
                                }
                                else
                                    CGContextClearRect(context, bounds);

                                struct zint_render* rendered = symbol->rendered;
                                if (rendered != NULL)
                                {
                                    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);

                                    struct zint_render_line* line = rendered->lines;
                                    while (line != NULL)
                                    {
                                        CGContextFillRect(context, CGRectMake(line->x, line->y, line->width, line->length));

                                        line = line->next;
                                    }
                                }

                                CGImageRef imageRef = CGBitmapContextCreateImage(context);
                                if (imageRef != NULL)
                                {
                                    barImage = [UIImage imageWithCGImage:imageRef];

                                    CGImageRelease(imageRef);
                                }

                                CGContextRelease(context);
                            }
                        }
                    }

                    ZBarcode_Delete(symbol);
                }
            }
        }
        break;
#endif
#if UMBARCODE_GEN_AZTEC
    case kUMBarcodeGenMode_Aztec:
        if ([type isEqualToString:kUMBarcodeTypeAztecCode])
        {
            NSData* string = [data dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(encoding)];
            if (string != nil)
            {
                ag_settings settings = { 0 };
                settings.mask = AG_SF_SYMBOL_FORMAT | AG_SF_REDUNDANCY_FOR_ERROR_CORRECTION;
                settings.symbol_format = AG_FULL_FORMAT;
                settings.redundancy_for_error_correction = AZTEC_ECLEVEL;

                ag_matrix* barcode = NULL;
                const int gen_result = ag_generate(&barcode, [string bytes], [string length], &settings);
                if (gen_result == AG_SUCCESS)
                    barImage = [[self class] _imageSquareWithPixels:barcode->data width:(int)barcode->width margin:BARCODE_MARGINS constrains:ceilf(size.width) opaque:opaque];

                ag_release_matrix(barcode);
            }
        }
        break;
#endif
#if UMBARCODE_GEN_QR
    case kUMBarcodeGenMode_QR:
        if ([type isEqualToString:kUMBarcodeTypeQRCode])
        {
            NSData* string = [data dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(encoding)];
            if (string != nil)
            {
                QRcode* resultCode = QRcode_encodeData((int)[string length], [string bytes], 0, QR_ECLEVEL);
                if (resultCode != NULL)
                {
                    barImage = [[self class] _imageSquareWithPixels:resultCode->data width:resultCode->width margin:BARCODE_MARGINS constrains:ceilf(size.width) opaque:opaque];

                    QRcode_free(resultCode);
                }
            }
        }
        break;
#endif
    default:
        break;
    }

    return barImage;
}

- (BOOL)isAllowedType:(NSString*)barcodeType
{
    BOOL allowed = NO;

    switch (_genMode)
    {
#if UMBARCODE_GEN_SYSTEM
    case kUMBarcodeGenMode_System:
        if ([barcodeType isEqualToString:kUMBarcodeTypeAztecCode])
            allowed = UMBarcodeScan_isOS8();
        else if ([barcodeType isEqualToString:kUMBarcodeTypeQRCode])
            allowed = UMBarcodeScan_isOS8();
        else if ([barcodeType isEqualToString:kUMBarcodeTypeCode128Code])
            allowed = UMBarcodeScan_isOS7();
        else if ([barcodeType isEqualToString:kUMBarcodeTypePDF417Code])
            allowed = UMBarcodeScan_isOS9();
        break;
#endif
#if UMBARCODE_GEN_ZXING
    case kUMBarcodeGenMode_ZXing:
        allowed = ([UMBarcodeScanUtilities um2zxBarcodeType:barcodeType] != (ZXBarcodeFormat)-1);
        break;
#endif
#if UMBARCODE_GEN_ZINT
    case kUMBarcodeGenMode_ZInt:
        allowed = ([UMBarcodeScanUtilities um2zintBarcodeType:barcodeType] != -1);
        break;
#endif
#if UMBARCODE_GEN_AZTEC
    case kUMBarcodeGenMode_Aztec:
        allowed = [barcodeType isEqualToString:kUMBarcodeTypeAztecCode];
        break;
#endif
#if UMBARCODE_GEN_QR
    case kUMBarcodeGenMode_QR:
        allowed = [barcodeType isEqualToString:kUMBarcodeTypeQRCode];
        break;
#endif
    default:
        break;
    }

    return allowed;
}

#if UMBARCODE_GEN_AZTEC || UMBARCODE_GEN_QR
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

+ (UMBarcodeGenMode_t*)allowedGenModes
{
static dispatch_once_t _once;
static UMBarcodeGenMode_t _allowedGenModes[kUMBarcodeGenMode_COUNT + 1];

    dispatch_once(&_once, ^
        {
            int index = 0;
#if UMBARCODE_GEN_SYSTEM
            if (UMBarcodeScan_isOS7())
                _allowedGenModes[index++] = kUMBarcodeGenMode_System;
#endif
#if UMBARCODE_GEN_ZXING
            _allowedGenModes[index++] = kUMBarcodeGenMode_ZXing;
#endif
#if UMBARCODE_GEN_ZINT
            _allowedGenModes[index++] = kUMBarcodeGenMode_ZInt;
#endif
            _allowedGenModes[index++] = kUMBarcodeGenMode_NONE;
        });

    return _allowedGenModes;
}

@end
