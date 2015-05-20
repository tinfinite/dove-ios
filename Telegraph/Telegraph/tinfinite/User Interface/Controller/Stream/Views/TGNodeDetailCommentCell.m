//
//  TGNodeDetailCommentCell.m
//  Telegraph
//
//  Created by 琦张 on 15/3/31.
//
//

#import "TGNodeDetailCommentCell.h"
#import "TGNodeCommentModel.h"
#import "NSString+Valid.h"
#import "TGDatabase.h"
#import "TGRemoteImageView.h"

#define CommentContentFontSize 14.0f

@implementation TGNodeDetailCommentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.headView];
        [self.contentView addSubview:self.contentLabel];
        
        [self.headView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView);
            make.right.equalTo(self.contentView);
            make.top.equalTo(self.contentView);
            make.height.equalTo(@60);
        }];
        
        [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(55);
            make.right.equalTo(self.contentView).offset(-15);
            make.top.equalTo(self.contentView).offset(39);
        }];
    }
    return self;
}

#pragma mark - getter
- (TGNodeCommentHeadView *)headView
{
    if (!_headView) {
        _headView = [[TGNodeCommentHeadView alloc] init];
    }
    return _headView;
}

- (UILabel *)contentLabel
{
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:CommentContentFontSize];
        _contentLabel.textColor = UIColorRGB(0x4a4a4a);
        _contentLabel.numberOfLines = 0;
    }
    return _contentLabel;
}

#pragma mark - setter
- (void)setObject:(id)object
{
    if (![object isKindOfClass:[TGNodeCommentModel class]]) {
        return;
    }
    
    _object = object;
    TGNodeCommentModel *comment = (TGNodeCommentModel *)object;
    if ([comment.authorAvatar hasPrefix:@"http"]) {
        [self.headView.avatarView setImageWithURL:[NSURL URLWithString:comment.authorAvatar] placeholderImage:[UIImage imageNamed:@"default_profile_img_s"]];
    }else{
        [self.headView.avatarView loadImage:comment.authorAvatar filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
    }
    self.headView.nameLabel.text = comment.authorUsername;
    [self.headView updateTime:comment.createTime];
    self.contentLabel.text = comment.content;
}

+ (CGFloat)tableView:(UITableView *) __unused tableView rowHeightForObject:(id)object
{
    CGFloat contentHeight = 0;
    TGNodeCommentModel *comment = (TGNodeCommentModel *)object;
    contentHeight = [comment.content heightForSize:CGSizeMake([UIScreen mainScreen].bounds.size.width-75, 9999) font:[UIFont systemFontOfSize:CommentContentFontSize]];
    return contentHeight + 58.0f;
}

@end
