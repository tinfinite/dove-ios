//
//  TGMyCommentedCell.h
//  Telegraph
//
//  Created by yewei on 15/4/22.
//
//

#import "T8BaseTableViewCell.h"
#import "TGLetteredAvatarView.h"

@interface TGMyCommentedCell : T8BaseTableViewCell

@property (nonatomic, strong) TGLetteredAvatarView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *commentLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIImageView *contentImage;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIView *lineView;

@end
