//
//  GesturePasswordView.h
//  GesturePassword
//
//  Created by hb on 14-8-23.
//  Copyright (c) 2014年 黑と白の印记. All rights reserved.
//

@protocol GesturePasswordDelegate <NSObject>

- (void)forget;
- (void)change;

@end

#import <UIKit/UIKit.h>
#import "TentacleView.h"
#import "TGLetteredAvatarView.h"
#import "TGUser.h"

@interface GesturePasswordView : UIView<TouchBeginDelegate>

@property (nonatomic,strong) TentacleView * tentacleView;

@property (nonatomic,strong) UILabel * state;

@property (nonatomic,assign) id<GesturePasswordDelegate> gesturePasswordDelegate;

@property (nonatomic,strong) TGUser *user;
@property (nonatomic,strong) TGLetteredAvatarView *avatarView;

@end
