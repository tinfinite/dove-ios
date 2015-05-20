//
//  TGJoinRequestTableViewCell.m
//  Telegraph
//
//  Created by yewei on 15/2/16.
//
//

#import "TGJoinRequestTableViewCell.h"
#import "TGJoinRequestObject.h"
#import "T8GroupHttpRequestService.h"
#import "ActionStage.h"
#import "TGTelegraph.h"
#import "TGLetteredAvatarView.h"

@interface TGJoinRequestTableViewCell ()

@property (nonatomic, strong) TGLetteredAvatarView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UIButton *approveButton;

@end

@implementation TGJoinRequestTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.avatarView];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.descriptionLabel];
        [self.contentView addSubview:self.approveButton];
        
        __weak typeof(self) weakSelf = self;
        
        [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@15);
            make.top.equalTo(@11);
            make.size.mas_equalTo(CGSizeMake(38, 38));
        }];
        
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            make.left.equalTo(strongSelf.avatarView.mas_right).with.offset(15);
            make.top.equalTo(@12);
            make.height.equalTo(@20);
            make.right.equalTo(strongSelf.contentView.mas_right).offset(-85);
        }];
        
        [self.descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            make.left.equalTo(strongSelf.avatarView.mas_right).with.offset(15);
            make.top.equalTo(strongSelf.nameLabel.mas_bottom).offset(5);
            make.height.equalTo(@20);
            make.trailing.lessThanOrEqualTo(strongSelf.approveButton.mas_left).offset(-10);
        }];
        
        [self.approveButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(weakSelf);
            make.size.mas_equalTo(CGSizeMake(60, 28));
            make.right.equalTo(@-15);
        }];
    }
    return self;
}

#pragma mark - private

- (void)approvePress
{
    if ([self.delegate respondsToSelector:@selector(didPressApproveButton:)]) {
        [self.delegate didPressApproveButton:self.indexPath];
    }
}

+ (CGFloat)tableView:(UITableView *)__unused tableView rowHeightForObject:(id)__unused object
{
    return 60;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setObject:(id)object
{
    if ([object isKindOfClass:[TGJoinRequestObject class]]) {
        TGJoinRequestObject *joinRequestModel = (TGJoinRequestObject *)object;
        _nameLabel.text = joinRequestModel.username;
        _descriptionLabel.text = joinRequestModel.message;
        [_avatarView loadImage:joinRequestModel.avatar filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
        _object = object;
    }
}

#pragma mark -getter

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

- (UIButton *)approveButton
{
    if (!_approveButton) {
        _approveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _approveButton.layer.cornerRadius = 5;
        _approveButton.layer.masksToBounds = YES;
        _approveButton.layer.borderColor = UIColorRGB(0x2E7AF2).CGColor;
        _approveButton.layer.borderWidth = 1.0f;
        [_approveButton setTitle:TGLocalized(@"GroupInfo.Approve") forState:UIControlStateNormal];
        [_approveButton setTitleColor:UIColorRGB(0x2E7AF2) forState:UIControlStateNormal];
        _approveButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_approveButton addTarget:self action:@selector(approvePress) forControlEvents:UIControlEventTouchUpInside];
    }
    return _approveButton;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:16];
    }
    return _nameLabel;
}

- (UILabel *)descriptionLabel
{
    if (!_descriptionLabel) {
        _descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.font = [UIFont systemFontOfSize:14];
        _descriptionLabel.textColor = UIColorRGB(0x8F8E93);
    }
    return _descriptionLabel;
}

@end
