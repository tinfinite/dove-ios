//
//  TGNodeCommentHeadView.m
//  Telegraph
//
//  Created by 琦张 on 15/3/31.
//
//

#import "TGNodeCommentHeadView.h"

@implementation TGNodeCommentHeadView

- (id)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.avatarView];
        [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(10);
            make.top.equalTo(self).offset(7.5);
            make.size.mas_equalTo(CGSizeMake(38, 38));
        }];
        
        [self addSubview:self.timeLabel];
        [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-15);
            make.centerY.equalTo(self.mas_top).offset(20);
        }];
        
        [self addSubview:self.timeView];
        [self.timeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.timeLabel.mas_left).offset(-6);
            make.centerY.equalTo(self.mas_top).offset(20);
        }];
        
        [self addSubview:self.nameLabel];
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.avatarView.mas_right).offset(10);
            make.centerY.equalTo(self.mas_top).offset(20);
            make.right.lessThanOrEqualTo(self.timeView.mas_left).offset(-10);
        }];
        
        
    }
    return self;
}

#pragma mark - getter
- (TGLetteredAvatarView *)avatarView
{
    if (!_avatarView) {
        _avatarView = [[TGLetteredAvatarView alloc] init];
        _avatarView.layer.cornerRadius = 19;
        _avatarView.layer.masksToBounds = YES;
        _avatarView.userInteractionEnabled = YES;
    }
    return _avatarView;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = UIColorRGB(0x4a4a4a);
        _nameLabel.font = [UIFont boldSystemFontOfSize:14];
    }
    return _nameLabel;
}

- (UIImageView *)timeView
{
    if (!_timeView) {
        _timeView = [[UIImageView alloc] init];
        _timeView.image = [UIImage imageNamed:@"cell_clock"];
    }
    return _timeView;
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.textColor = UIColorRGB(0x9b9b9b);
        _timeLabel.font = [UIFont systemFontOfSize:12];
    }
    return _timeLabel;
}

#pragma mark - method
- (void)updateTime:(NSString *)timeStamp
{
    self.timeLabel.text = [[NSDate getDateFromT8TimeStamp:timeStamp] timeIntervalDescription];
}

@end
