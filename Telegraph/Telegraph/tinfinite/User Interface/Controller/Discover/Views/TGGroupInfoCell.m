//
//  TGGroupInfoCell.m
//  Telegraph
//
//  Created by 琦张 on 15/2/15.
//
//

#define TGGroupInfoCellHeight 75

#import "TGGroupInfoCell.h"
#import "TGGroupObject.h"
#import "UIImageView+AFNetworking.h"

@interface TGGroupInfoCell ()

@property (nonatomic,strong) TGGroupObject *model;

@end

@implementation TGGroupInfoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.avatarView];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.descriptionLabel];
        [self.contentView addSubview:self.pointsLabel];
        [self.contentView addSubview:self.languageLabel];
        
        [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(10);
            make.top.equalTo(self.contentView).offset(6);
            make.width.equalTo(@62);
            make.height.equalTo(@62);
        }];
        
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(80);
            make.centerY.equalTo(self.contentView.mas_top).offset(18);
        }];
        
        [self.descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(80);
            make.top.equalTo(self.contentView).offset(31);
            make.right.equalTo(self.contentView).offset(-10);
        }];
        
        [self.languageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(10);
            make.right.equalTo(self.contentView).offset(-11);
        }];
        
        [self.pointsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(10);
            make.right.equalTo(self.languageLabel.mas_left);
            make.left.greaterThanOrEqualTo(self.nameLabel.mas_right).offset(10);
        }];
    }
    return self;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - getter
- (TGLetteredAvatarView *)avatarView
{
    if (!_avatarView) {
        _avatarView = [[TGLetteredAvatarView alloc] init];
        _avatarView.layer.cornerRadius = 31;
        _avatarView.layer.masksToBounds = YES;
        _avatarView.image = [UIImage imageNamed:@"dove_default_avatar"];
    }
    return _avatarView;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = [UIColor blackColor];
        _nameLabel.font = [UIFont boldSystemFontOfSize:15];
    }
    return _nameLabel;
}

- (UILabel *)descriptionLabel
{
    if (!_descriptionLabel) {
        _descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.textColor = UIColorRGB(0xa0a0a4);
        _descriptionLabel.font = [UIFont systemFontOfSize:14];
        _descriptionLabel.numberOfLines = 2;
        _descriptionLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _descriptionLabel;
}

- (UILabel *)pointsLabel
{
    if (!_pointsLabel) {
        _pointsLabel = [[UILabel alloc] init];
        _pointsLabel.textColor = UIColorRGB(0xa0a0a4);
        _pointsLabel.font = [UIFont systemFontOfSize:13];
    }
    return _pointsLabel;
}

- (UILabel *)languageLabel
{
    if (!_languageLabel) {
        _languageLabel = [[UILabel alloc] init];
        _languageLabel.textColor = UIColorRGB(0xa0a0a4);
        _languageLabel.font = [UIFont systemFontOfSize:14];
    }
    return _languageLabel;
}

#pragma mark - method
+ (CGFloat)calculateHeightWithModel:(id)__unused model
{
    return TGGroupInfoCellHeight;
}

- (void)bindModel:(id)model
{
    if (![model isKindOfClass:[TGGroupObject class]]) {
        return;
    }
    
    _model = model;
    
    if (_model) {
        self.nameLabel.text = _model.groupName;
        self.descriptionLabel.text = _model.groupDesc;
        if (_model.avatarKey.length>0) {
            [self.avatarView loadImage:_model.avatarKey filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_l"]];
        }else{
            [self.avatarView setImageWithURL:[NSURL URLWithString:_model.imageUrl] placeholderImage:[UIImage imageNamed:@"default_profile_img_l"]];
        }
        NSString *lan = _model.language;
        if ([_model.language isEqualToString:@"en"]) {
            lan = @"en";
        }else if ([_model.language isEqualToString:@"zh"]){
            lan = @"zh-Hans";
        }
        if (![lan isEqualToString:[NSLocale preferredLanguages].firstObject]) {
            NSString *key = _model.language;
            if ([key isEqualToString:@"zh-Hans"]) {
                key = @"zh";
            }
            self.languageLabel.text = TGLocalized(key);
        }else{
            self.languageLabel.text = @"";
        }
        if (_model.points > 0) {
            NSString *key = _model.points>1?@"Vote.Points":@"Vote.Point";
            if (self.languageLabel.text.length > 0) {
                self.pointsLabel.text = [NSString stringWithFormat:@"%ld %@  ",(long)_model.points,TGLocalized(key)];
            }else{
                self.pointsLabel.text = [NSString stringWithFormat:@"%ld %@",(long)_model.points,TGLocalized(key)];
            }
        }else{
            self.pointsLabel.text = @"";
        }
    }
}

@end
