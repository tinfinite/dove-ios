//
//  TGNodeCommentHeadView.h
//  Telegraph
//
//  Created by 琦张 on 15/3/31.
//
//

#import <UIKit/UIKit.h>
#import "TGLetteredAvatarView.h"

@interface TGNodeCommentHeadView : UIView

@property (nonatomic,strong) TGLetteredAvatarView *avatarView;
@property (nonatomic,strong) UILabel *nameLabel;
@property (nonatomic,strong) UIImageView *timeView;
@property (nonatomic,strong) UILabel *timeLabel;

- (void)updateTime:(NSString *)timeStamp;

@end
