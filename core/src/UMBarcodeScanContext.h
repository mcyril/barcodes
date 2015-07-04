//
//  UMBarcodeScanContext.h
//
//  Created by Cyril Murzin on 02/07/15.
//  Copyright (c) 2015 Ravel Developers Group. All rights reserved.
//

#import "UMBarcodeScanViewControllerPvt.h"

enum _UMBarcodeScanState : uint32_t
{
    STOPPED     = 0,
    RUNNING     = 1,
    PAUSED      = 2
};
typedef enum _UMBarcodeScanState UMBarcodeScanState_t;

@interface UMBarcodeScanContext : NSObject
{
@public
    UMBarcodeScanState_t _state;

@private
    id<UMBarcodeScanDelegate> _delegate;

    NSString* _cancelButtonText;
    NSString* _helpButtonText;
    NSString* _hintLabelText;

    UMBarcodeScanMode_t _scanMode;
    NSArray* _barcodeTypes;

    BOOL _keepStatusBarStyle;
    UIBarStyle _navigationBarStyle;
    UIColor* _navigationBarTintColor;

    UIInterfaceOrientation _initialInterfaceOrientationForViewcontroller;
    BOOL _allowFreelyRotatingGuide;
}
@property (nonatomic, assign) id<UMBarcodeScanDelegate> delegate;

@property (nonatomic, retain) NSString* cancelButtonText;
@property (nonatomic, retain) NSString* helpButtonText;
@property (nonatomic, retain) NSString* hintLabelText;

@property (nonatomic, assign) UMBarcodeScanMode_t scanMode;
@property (nonatomic, retain) NSArray* barcodeTypes;

@property(nonatomic, assign) BOOL keepStatusBarStyle;
@property(nonatomic, assign) UIBarStyle navigationBarStyle;
@property(nonatomic, retain) UIColor* navigationBarTintColor;

@property (nonatomic, assign) UIInterfaceOrientation initialInterfaceOrientationForViewcontroller;
@property (nonatomic, assign) BOOL allowFreelyRotatingGuide;
@property (nonatomic, assign) BOOL showFoundCodePoints;

@end

extern NSString* const kUMBarcodeScanContextChangedOrientation;
