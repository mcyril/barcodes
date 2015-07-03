//
//  UMBarcodeScanDelegate.h
//  UMZebraTest
//
//  Created by Cyril Murzin on 02/07/15.
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//

@class UMBarcodeScanViewController;

@protocol UMBarcodeScanDelegate <NSObject>
@required
- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController didCancelWithError:(NSError*)error;
- (void)scanViewController:(UMBarcodeScanViewController*)scanViewController didScanString:(NSString*)barcodeData ofBarcodeType:(NSString*)barcodeType;

@optional
- (void)scanViewControllerDidPressHelpButton:(UMBarcodeScanViewController*)scanViewController;
@end
