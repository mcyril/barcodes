//
//  UMBarcodeViewController.h
//
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//  Created by Cyril Murzin
//

@class UMBarcodeView;
@class UMBarcodeScanContext;

@interface UMBarcodeViewController : UIViewController
{
@private
    UMBarcodeScanContext* _context;

    BOOL _changeStatusBarHiddenStatus;
    BOOL _newStatusBarHiddenStatus;
    BOOL _originalStatusBarHiddenStatus;

    UIDeviceOrientation _deviceOrientation;

    UIButton* _cancelButton;
    CGSize _cancelButtonFrameSize;

    UIButton* _helpButton;
    CGSize _helpButtonFrameSize;

    UILabel* _hintLabel;

    UMBarcodeView* _barcodeView;
    CALayer* _shadowLayer;
}

- (instancetype)initWithContext:(UMBarcodeScanContext*)aContext;

@end
