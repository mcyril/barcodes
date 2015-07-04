//
//  UMBarcodeScanViewControllerPvt.h
//
//  Created by Cyril Murzin on 02/07/15.
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//

#import "UMBarcodeScanViewController.h"

@interface UMBarcodeScanViewController ()
@property (nonatomic, retain) UMBarcodeScanContext* context;
@property (nonatomic, assign) BOOL shouldStoreStatusBarStyle;
@property (nonatomic, assign) BOOL statusBarWasOriginallyHidden;
@property (nonatomic, assign) UIStatusBarStyle originalStatusBarStyle;

- (BOOL)_isBeingPresentedModally;
- (UIInterfaceOrientationMask)_supportedOverlayOrientationsMask;

+ (UIViewController*)_viewControllerWithContext:(UMBarcodeScanContext*)aContext;
+ (UMBarcodeScanViewController*)_barcodeScanViewControllerForResponder:(UIResponder*)responder;

@end

