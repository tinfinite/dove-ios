//
//  TGNodeHeadView.h
//  Telegraph
//
//  Created by yewei on 15/3/29.
//
//

#import <UIKit/UIKit.h>
#import "TGLetteredAvatarView.h"

@interface TGNodeHeadView : UIView

@property (nonatomic,strong) TGLetteredAvatarView *avatarView;
@property (nonatomic,strong) UILabel *nameLabel;
@property (nonatomic,strong) UIImageView *timeView;
@property (nonatomic,strong) UILabel *timeLabel;
@property (nonatomic,strong) UILabel *groupLabel;

@end
