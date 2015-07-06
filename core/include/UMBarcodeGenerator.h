//
//  UMBarcodeGenerator.h
//
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//  Created by Cyril Murzin
//

#import <UIKit/UIKit.h>

#ifndef API_EXPORT
#define API_EXPORT  __attribute__((visibility("default")))
#endif

#ifndef EXT_EXPORT
#define EXT_EXPORT  extern __attribute__((visibility("default")))
#endif

/**
 *    barcode types for generating
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

API_EXPORT @interface UMBarcodeGenerator : NSObject

/**
 *    generate barcode image
 *
 *    @param data     barcode data
 *    @param encoding data encoding which will be used in barcode
 *    @param type     barcode type
 *    @param size     size of generated image
 *    @param opaque   YES if white is opaque, NO is white is transparent
 *    @param error    error occured
 *
 *    @return generated image or nil if error occured
 */
+ (UIImage*)imageWithData:(NSString*)data encoding:(CFStringEncoding)encoding barcodeType:(NSString*)type imageSize:(CGSize)size whiteOpaque:(BOOL)opaque error:(NSError**)error;

@end
