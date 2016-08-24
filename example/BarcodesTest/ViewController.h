//
//  ViewController.h
//
//  Created by Cyril Murzin on 02/07/15.
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//

@class UMBarcodeGenerator;

@interface ViewController : UIViewController
{
@private
    UIImageView* _barcodeImage;

    UIButton* _scanSystem;
    UIButton* _scanZXing;
    UIButton* _scanZBar;

    UMBarcodeGenerator* _barcodeGenerator;
}

@end
