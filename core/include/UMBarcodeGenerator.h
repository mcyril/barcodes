//
//  UMBarcodeGenerator.h
//  barcodes
//
//  Created by Cyril Murzin on 04/07/15.
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//

#import <UIKit/UIKit.h>

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

API_EXPORT @interface UMBarcodeGenerator : NSObject

+ (UIImage*)imageWithData:(NSString*)data encoding:(CFStringEncoding)encoding barcodeType:(NSString*)type imageSize:(CGSize)size whiteOpaque:(BOOL)opaque error:(NSError**)error;

@end
