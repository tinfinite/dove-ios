//
//  TGMyCommentedCell.m
//  Telegraph
//
//  Created by yewei on 15/4/22.
//
//

#import "TGMyCommentedCell.h"
#import "TGMyCommentedModel.h"
#import "NSString+Valid.h"
#import "UIViewAdditions.h"

@interface TGMyCommentedCell ()

@end

@implementation TGMyCommentedCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.avatarView];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.commentLabel];
        [self.contentView addSubview:self.timeLabel];
        [self.contentView addSubview:self.contentImage];
        [self.contentView addSubview:self.contentLabel];
        [self.contentView addSubview:self.lineView];
        
        [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@10);
            make.top.equalTo(@7);
            make.size.mas_equalTo(CGSizeMake(38, 38));
        }];
        
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.avatarView.mas_right).with.offset(10);
            make.top.equalTo(@10);
            make.width.equalTo(@220);
            make.height.equalTo(@18);
        }];
        
        [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@10);
            make.right.equalTo(@-10);
            make.width.equalTo(@120);
            make.height.equalTo(@18);
        }];
    }
    return self;
}

- (void)setObject:(id)object
{
    _object = object;
    if ([object isKindOfClass:[TGMyCommentedModel class]]) {
        TGMyCommentedModel *model = (TGMyCommentedModel *)object;
        [self.avatarView loadImage:model.userAvatar filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
        self.nameLabel.text = model.name;
        
        self.commentLabel.text = model.commentContent;
        
        self.timeLabel.text = [[NSDate getDateFromT8TimeStamp:model.commentCreateTime] timeIntervalDescription];
        
        self.contentLabel.text = model.postText;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    TGMyCommentedModel *model = (TGMyCommentedModel *)self.object;
    
    CGFloat commentLabelHeight = [self.commentLabel.text heightForSize:CGSizeMake(SCREEN_WIDTH - 68, 155) font:[UIFont systemFontOfSize:14.0f]];
    self.commentLabel.frame = CGRectMake(58, 35, SCREEN_WIDTH - 68, commentLabelHeight);
    
    if (model.postImage && model.postImage.length) {
        [self.contentImage setImageWithURL:[NSURL URLWithString:model.postImage] placeholderImage:nil];
        self.contentImage.hidden = NO;
        self.lineView.hidden = YES;
        self.contentImage.frame = CGRectMake(58, self.commentLabel.bottom + 15, 38, 38);
        self.contentLabel.frame = CGRectMake(106, self.commentLabel.bottom + 16, SCREEN_WIDTH - 116, 35);
    }else{
        self.contentImage.hidden = YES;
        self.lineView.hidden = NO;
        self.lineView.frame = CGRectMake(58, self.commentLabel.bottom + 15, 1, 38);
        self.contentLabel.frame = CGRectMake(69, self.commentLabel.bottom + 16, SCREEN_WIDTH - 79, 35);
    }
}

#pragma mark - getter
- (TGLetteredAvatarView *)avatarView
{
    if (!_avatarView) {
        _avatarView = [[TGLetteredAvatarView alloc] init];
    }
    return _avatarView;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:13];
    }
    return _nameLabel;
}

- (UILabel *)commentLabel
{
    if (!_commentLabel) {
        _commentLabel = [[UILabel alloc] init];
        _commentLabel.numberOfLines = 0;
        _commentLabel.font = [UIFont systemFontOfSize:14];
        _commentLabel.textColor = UIColorRGB(0x404040);
    }
    return _commentLabel;
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.textColor = UIColorRGB(0xA0A0A4);
        _timeLabel.font = [UIFont systemFontOfSize:13];
        _timeLabel.textAlignment = NSTextAlignmentRight;
    }
    return _timeLabel;
}

- (UIImageView *)contentImage
{
    if (!_contentImage) {
        _contentImage = [[UIImageView alloc] init];
        _contentImage.backgroundColor = UIColorRGB(0xA0A0A4);
    }
    return _contentImage;
}

- (UILabel *)contentLabel
{
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.numberOfLines = 2;
        _contentLabel.textColor = UIColorRGB(0xA0A0A4);
        _contentLabel.font = [UIFont systemFontOfSize:13];
    }
    return _contentLabel;
}

- (UIView *)lineView
{
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = UIColorRGB(0xA0A0A4);
    }
    return _lineView;
}

- (void)drawRect:(CGRect)__unused rect
{
    [UIColorRGB(0xDDE1E6) set];
    
    UIBezierPath *bottomLine = [UIBezierPath bezierPathWithRect:CGRectMake(0, self.frame.size.height-0.5, self.frame.size.width, 0.5)];
    [bottomLine fill];
}

+ (CGFloat)tableView:(UITableView *)__unused tableView rowHeightForObject:(id)object
{
    CGFloat height = 38;
    TGMyCommentedModel *model = (TGMyCommentedModel *)object;
    
    CGFloat commentLabelHeight = [model.commentContent heightForSize:CGSizeMake(SCREEN_WIDTH - 68, 155) font:[UIFont systemFontOfSize:14.0f]];

    height += commentLabelHeight;
    
    height += 58;
    
    return height;
}


@end
