//
//  GesturePasswordController.h
//  GesturePassword
//
//  Created by hb on 14-8-23.
//  Copyright (c) 2014年 黑と白の印记. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TentacleView.h"
#import "GesturePasswordView.h"
#import "TGViewController.h"

typedef NS_ENUM(NSInteger, GesturePasswordType)
{
    GesturePasswordTypeCreate   = 0,
    GesturePasswordTypeDelete   = 1,
    GesturePasswordTypeDefault  = 2,
};

@interface GesturePasswordController : TGViewController <VerificationDelegate,ResetDelegate,GesturePasswordDelegate>

@property (nonatomic, assign) GesturePasswordType type;

- (id)initWithUid:(int32_t)uid;

- (id)initWithGesturePasswordType:(GesturePasswordType)type uid:(int32_t)uid;

- (void)clear;

- (BOOL)exist;

@end
