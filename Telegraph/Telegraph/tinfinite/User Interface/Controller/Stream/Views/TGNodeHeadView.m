//
//  TGNodeHeadView.m
//  Telegraph
//
//  Created by yewei on 15/3/29.
//
//

#import "TGNodeHeadView.h"

@implementation TGNodeHeadView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        __weak typeof(self) weakSelf = self;
        [self addSubview:self.avatarView];
        [self addSubview:self.nameLabel];
        [self addSubview:self.timeView];
        [self addSubview:self.timeLabel];
        [self addSubview:self.groupLabel];

        [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@15);
            make.left.equalTo(@15);
            make.size.mas_equalTo(CGSizeMake(38, 38));
        }];
        
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            __strong typeof(self) strongSelf = weakSelf;
            make.top.equalTo(@15);
            make.left.equalTo(strongSelf.avatarView.mas_right).offset(12);
//            make.right.lessThanOrEqualTo(self.groupLabel.mas_left).offset(-15);
            make.right.lessThanOrEqualTo(self).offset(-130);
        }];
        
        [self.timeView mas_makeConstraints:^(MASConstraintMaker *make) {
            __strong typeof(self) strongSelf = weakSelf;
            make.left.equalTo(strongSelf.avatarView.mas_right).offset(12);
            make.bottom.equalTo(strongSelf.avatarView.mas_bottom);
            make.size.mas_equalTo(CGSizeMake(15, 15));
        }];
        
        [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            __strong typeof(self) strongSelf = weakSelf;
            make.left.equalTo(self.timeView.mas_right).offset(5);
            make.bottom.equalTo(strongSelf.avatarView.mas_bottom);
            make.height.equalTo(@16);
        }];
        
        [self.groupLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.nameLabel);
            make.right.equalTo(self).offset(-10);
            make.left.greaterThanOrEqualTo(self.nameLabel.mas_right).offset(15);
        }];
        
//        [self addSubview:self.communityBtn];
//        [self.communityBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(self).offset(0);
//            make.right.equalTo(self).offset(0);
//        }];
        
//        [self addSubview:self.degreeView];
//        [self.degreeView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.leading.equalTo(self.nameLabel.mas_right).with.offset(10);
//            make.centerY.equalTo(self.nameLabel);
//            make.width.equalTo(@15);
//            make.height.equalTo(@15);
//            make.trailing.lessThanOrEqualTo(self.communityBtn.mas_left).with.offset(-10);
//        }];
//        
//        [self addSubview:self.genderView];
//        [self.genderView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.leading.equalTo(@60);
//            make.top.equalTo(@35);
//        }];
//        
//        [self addSubview:self.ageLabel];
//        [self.ageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.leading.equalTo(self.genderView.mas_right);
//            make.top.equalTo(self.genderView);
//        }];
//        
//        [self addSubview:self.locationView];
//        [self.locationView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.centerY.equalTo(self.timeView);
//            make.left.equalTo(self.timeLabel.mas_right).with.offset(15);
//        }];
//        
//        [self addSubview:self.locationLabel];
//        [self.locationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(self.genderView);
//            make.right.equalTo(self.mas_right).offset(-10);
//            make.left.equalTo(self.locationView.mas_right).offset(3);
//        }];
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
        _avatarView.backgroundColor = [UIColor clearColor];
    }
    return _avatarView;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = UIColorRGB(0x3991F5);
        _nameLabel.font = [UIFont systemFontOfSize:14.0f];
        _nameLabel.userInteractionEnabled = YES;
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
        _timeLabel.textColor = UIColorRGB(0x979797);
        _timeLabel.font = [UIFont systemFontOfSize:12];
    }
    return _timeLabel;
}

- (UILabel *)groupLabel
{
    if (!_groupLabel) {
        _groupLabel = [[UILabel alloc] init];
        _groupLabel.textColor = UIColorRGB(0x3991F5);
        _groupLabel.font = [UIFont systemFontOfSize:12];
        _groupLabel.userInteractionEnabled = YES;
    }
    return _groupLabel;
}

@end
