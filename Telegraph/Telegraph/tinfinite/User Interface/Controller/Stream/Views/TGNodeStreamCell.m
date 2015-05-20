//
//  TGNodeStreamCell.m
//  Telegraph
//
//  Created by yewei on 15/3/28.
//
//

#import "TGNodeStreamCell.h"
#import "TGNodeHeadView.h"
#import "TGNodeToolView.h"
#import "UIImageView+AFNetworking.h"
#import "TGNodeImageView.h"
#import "UIViewAdditions.h"
#import "NSString+Valid.h"
#import "TGLinkShowViewForCell.h"
#import "TTTAttributedLabel.h"
#import "TGApplication.h"

const CGFloat kTGNodeCellBaseHeight = 129.f;
const CGFloat kTGNodeCellHeaderViewHeight = 64.f;
const CGFloat kTGNodeCellToolViewHeight = 40.f;
const CGFloat kTGNodeCellSeparatorHeight = 15.f;
const CGFloat kTGNodeCellSubviewsBigInterval = 10.f;

@interface TGNodeStreamCell ()<TTTAttributedLabelDelegate>

@property (nonatomic,strong) TGNodeHeadView *headView;
@property (nonatomic,strong) TTTAttributedLabel *commentLabel;
@property (nonatomic,strong) UIButton *msgAuthorButton;
@property (nonatomic,strong) TTTAttributedLabel *msgcontentLabel;
@property (nonatomic,strong) UILabel *msgEllipsisLabel;
@property (nonatomic,strong) UILabel *forwardLabel;
@property (nonatomic,strong) UIButton *forwardPersonButton;
@property (nonatomic,strong) TGNodeImageView *nodeImageView;
@property (nonatomic,strong) TGLinkShowViewForCell *linkView;
@property (nonatomic,strong) TGNodeToolView *toolView;
@property (nonatomic,strong) TGNodeModel *nodeObject;
@property (nonatomic,assign) CGFloat nodeImageviewHeight;

@end

@implementation TGNodeStreamCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self initSubViews];
    }
    return self;
}

- (void)setObject:(id)object
{
    _object = object;
    if ([object isKindOfClass:[TGNodeModel class]])
    {
        TGNodeModel *node = (TGNodeModel *)object;
        if ([node.author.avatar hasPrefix:@"http"]) {
            [self.headView.avatarView setImageWithURL:[NSURL URLWithString:node.author.avatar] placeholderImage:[UIImage imageNamed:@"default_profile_img_s"]];
        }else{
            [self.headView.avatarView loadImage:node.author.avatar filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
        }
        self.headView.nameLabel.text = node.author.name;
        self.headView.groupLabel.text = @"";
        if (node.sourceType == PostSourceTypeForward)
        {
            if (node.forward.comment.length)
            {
//                if ([node.author.avatar hasPrefix:@"http"]) {
//                    [self.headView.avatarView setImageWithURL:[NSURL URLWithString:node.author.avatar] placeholderImage:[UIImage imageNamed:@"default_profile_img_s"]];
//                }else{
//                    [self.headView.avatarView loadImage:node.author.avatar filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
//                }
//                self.headView.nameLabel.text = node.author.name;
                
                self.commentLabel.text = node.forward.comment;
            }else{
//                if (node.forward.groupAvatarKey.length>0) {
//                    [self.headView.avatarView loadImage:node.forward.groupAvatarKey filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
//                }else{
//                    [self.headView.avatarView setImageWithURL:[NSURL URLWithString:node.forward.groupAvatar] placeholderImage:[UIImage imageNamed:@"default_profile_img_s"]];
//                }
//                self.headView.nameLabel.text = node.forward.groupName;
                
//                [self.forwardPersonButton setTitle:node.author.name forState:UIControlStateNormal];
            }
            
            if (self.streamType != StreamTypeGroup) {
                self.headView.groupLabel.text = node.forward.groupName;
            }
            
            NSArray *array = node.forward.photoMsgs;
            if (array.count) {
                self.nodeImageviewHeight = [self.nodeImageView setImagesWithArray:array];
                [self.nodeImageView setDelegate:self];
            }else{
                [self.nodeImageView removeSubviews];
            }
            
            array = node.forward.textMsgs;
            if (array.count > 0) {
                for (TGNodeForwardMessageModel *model in array) {
                    [self.msgAuthorButton setTitle:model.author.name forState:UIControlStateNormal];
                    if (model.author.anonymous || model.author.username.length==0) {
                        self.msgAuthorButton.userInteractionEnabled = NO;
                        self.msgAuthorButton.tintColor = UIColorRGB(0x4a4a4a);
                    }else{
                        self.msgAuthorButton.userInteractionEnabled = YES;
                        self.msgAuthorButton.tintColor = UIColorRGB(0x1a8df2);
                    }
                    self.msgcontentLabel.text = model.msgContent;
                    break;
                }
            }
        }else if(node.sourceType == PostSourceTypePublish){
//            if ([node.author.avatar hasPrefix:@"http"]) {
//                [self.headView.avatarView setImageWithURL:[NSURL URLWithString:node.author.avatar] placeholderImage:[UIImage imageNamed:@"default_profile_img_s"]];
//            }else{
//                [self.headView.avatarView loadImage:node.author.avatar filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
//            }
//            self.headView.nameLabel.text = node.author.name;
            
            if (self.streamType != StreamTypeGroup) {
                self.headView.groupLabel.text = node.post.groupName;
            }
            
            NSArray *array = node.post.images;
            if (array.count) {
                self.nodeImageviewHeight = [self.nodeImageView setImagesWithArray:array];
                [self.nodeImageView setDelegate:self];
            }else{
                [self.nodeImageView removeSubviews];
            }
            
            if (node.post.urlTitle.length>0 || node.post.urlImage.length>0 || node.post.urlDesc.length>0) {
                [self.linkView updateLinkUrl:node.post.url];
                self.linkView.urlLabel.text = node.post.url;
                self.linkView.titleLabel.text = node.post.urlTitle;
                self.linkView.descriptionLabel.text = node.post.urlDesc;
                [self.linkView.imgView setImageWithURL:[NSURL URLWithString:node.post.urlImage] placeholderImage:[UIImage imageNamed:@"default_link_img"]];
            }
        }
        
//        if (node.isPublic == PostPublishTypeGroupBoard)
//        {
//            if ([node.author.avatar hasPrefix:@"http"]) {
//                [self.headView.avatarView setImageWithURL:[NSURL URLWithString:node.author.avatar] placeholderImage:[UIImage imageNamed:@"default_profile_img_s"]];
//            }else{
//                [self.headView.avatarView loadImage:node.author.avatar filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
//            }
//            self.headView.nameLabel.text = node.author.name;
//        }
        
        self.headView.timeLabel.text = [[NSDate getDateFromT8TimeStamp:node.createTime] timeIntervalDescription];
        
        [self.toolView setObject:node];
    }
}

- (void)layoutSubviews
{
    TGNodeModel *node = (TGNodeModel *)self.object;
    CGFloat y = 64;
    
    self.msgAuthorButton.hidden = YES;
    self.msgcontentLabel.hidden = YES;
    self.msgEllipsisLabel.hidden = YES;
//    self.forwardLabel.hidden = YES;
//    self.forwardPersonButton.hidden = YES;
    self.linkView.hidden = YES;
    
    if (node.sourceType == PostSourceTypeForward)
    {
        if (node.forward.comment.length)
        {
            [self.commentLabel setFrame:CGRectMake(15, y, SCREEN_WIDTH - 30, node.forward.commentHeight)];
            self.commentLabel.hidden = NO;
            y += node.forward.commentHeight + kTGNodeCellSubviewsBigInterval+5;
        }else{
            self.commentLabel.hidden = YES;
        }
        
        NSArray *array = node.forward.textMsgs;
        
        for (NSUInteger i = 0; i < array.count; i++) {
            TGNodeForwardMessageModel *model = [array objectAtIndex:i];
            if (i == 0) {
                [self.msgAuthorButton sizeToFit];
                [self.msgAuthorButton setFrame:CGRectMake(15, y, self.msgAuthorButton.frame.size.width, 18)];
                self.msgAuthorButton.hidden = NO;
                [self.msgcontentLabel setFrame:CGRectMake(15, self.msgAuthorButton.bottom + 5, SCREEN_WIDTH - 30, model.messageHeight)];
                self.msgcontentLabel.hidden = NO;
                y += 15 + model.messageHeight +10;
            }else if (i == 1){
                [self.msgEllipsisLabel setFrame:CGRectMake(15, y+8, SCREEN_WIDTH - 30, 18)];
                self.msgEllipsisLabel.hidden = NO;
                if ((array.count - 1) == 1) {
                    _msgEllipsisLabel.text = TGLocalized(@"Stream.ForwardTip1");
                }else{
                    _msgEllipsisLabel.text = [NSString stringWithFormat:TGLocalized(@"Stream.ForwardTip2"),(array.count - 1)];
                }
                y += 15 + 10;
            }else{
                break;
            }
        }
        
        array = node.forward.photoMsgs;
        if (array.count) {
            [self.nodeImageView setFrame:CGRectMake(15, y, SCREEN_WIDTH - 30, self.nodeImageviewHeight)];
            self.nodeImageView.hidden = NO;
        }else{
            self.nodeImageView.hidden = YES;
        }
        
        y += self.nodeImageviewHeight + kTGNodeCellSubviewsBigInterval;
        
//        if ([node.forward.comment isEqualToString:@""]) {
//            [self.forwardLabel setFrame:CGRectMake(15, self.height - kTGNodeCellToolViewHeight - 18 - 20, 80, 13)];
//            [self.forwardLabel sizeToFit];
//            self.forwardLabel.hidden = NO;
//            
//            [self.forwardPersonButton setFrame:CGRectMake(self.forwardLabel.right + 10, y, 200, 40)];
//            [self.forwardPersonButton sizeToFit];
//            self.forwardPersonButton.centerY = self.forwardLabel.centerY;
//            self.forwardPersonButton.hidden = NO;
//            y += 13 +kTGNodeCellSubviewsBigInterval;
//        }else{
//            self.forwardLabel.hidden = YES;
//            self.forwardPersonButton.hidden = YES;
//        }
    }else if(node.sourceType == PostSourceTypePublish){
        if (node.post.text.length)
        {
            [self.commentLabel setText:node.post.text];
            [self.commentLabel setFrame:CGRectMake(15, y, SCREEN_WIDTH-30, node.post.textHeight)];
            self.commentLabel.hidden = NO;
            y += node.post.textHeight + kTGNodeCellSubviewsBigInterval;
        }else{
            self.commentLabel.hidden = YES;
            self.commentLabel.frame = CGRectZero;
        }
        
        NSArray *array = node.post.images;
        if (array.count) {
            [self.nodeImageView setFrame:CGRectMake(15, y, SCREEN_WIDTH - 30, self.nodeImageviewHeight)];
            self.nodeImageView.hidden = NO;
            y += self.nodeImageviewHeight;
        }else{
            self.nodeImageView.hidden = YES;
        }
        
        if (node.post.url.length>0) {
            CGRect frame = self.linkView.frame;
            frame.origin.y = y;
            self.linkView.frame = frame;
            self.linkView.hidden = NO;
        }else{
            self.linkView.hidden = YES;
        }
    }
    
    self.toolView.top = self.height - kTGNodeCellToolViewHeight -kTGNodeCellSeparatorHeight;
    
    [super layoutSubviews];
}

- (void)drawRect:(CGRect)__unused rect
{
    [UIColorRGB(0xDDDDDD) set];
    UIBezierPath *topLine = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.contentView.bounds.size.width, 0)];
    [topLine stroke];
    
    UIBezierPath *toolBarTopLine = [UIBezierPath bezierPathWithRect:CGRectMake(0, self.contentView.bounds.size.height-55, self.contentView.bounds.size.width, 0.5)];
    [toolBarTopLine fill];
    
    UIBezierPath *toolBarBottomLine = [UIBezierPath bezierPathWithRect:CGRectMake(0, self.contentView.bounds.size.height-15, self.contentView.bounds.size.width, 0)];
    [toolBarBottomLine stroke];
    
    [UIColorRGB(0xEBEBF1) setFill];
    UIBezierPath *bottomView = [UIBezierPath bezierPathWithRect:CGRectMake(0, self.contentView.bounds.size.height-15, self.contentView.bounds.size.width, 15)];
    [bottomView fill];
    
    TGNodeModel *node = (TGNodeModel *)self.object;
    if (node.sourceType == PostSourceTypeForward && node.forward.comment.length)
    {
        [UIColorRGB(0xDDDDDD) set];
        UIBezierPath *forwardTopLine = [UIBezierPath bezierPathWithRect:CGRectMake(0, 65 + node.forward.commentHeight+4.5, self.contentView.bounds.size.width, 0.5)];
        [forwardTopLine fill];
        
        [UIColorRGB(0xFAFAFA) setFill];
        UIBezierPath *bottomView = [UIBezierPath bezierPathWithRect:CGRectMake(0, 65 + node.forward.commentHeight+5, self.contentView.bounds.size.width, self.height - kTGNodeCellBaseHeight - node.forward.commentHeight + 3.5)];
        [bottomView fill];
    }
}

- (void)initSubViews
{
    [self.contentView addSubview:self.headView];
    [self.contentView addSubview:self.toolView];
}

#pragma mark - getter
- (TGNodeHeadView *)headView
{
    if (!_headView) {
        _headView = [[TGNodeHeadView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, kTGNodeCellHeaderViewHeight)];
        [_headView.avatarView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enterUserDetail:)]];
        _headView.avatarView.userInteractionEnabled = YES;
        [_headView.nameLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enterUserDetail:)]];
        _headView.nameLabel.userInteractionEnabled = YES;
        [_headView.groupLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enterGroupDetail)]];
    }
    return _headView;
}

- (TGNodeToolView *)toolView
{
    if (!_toolView) {
        _toolView = [[TGNodeToolView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, kTGNodeCellToolViewHeight)];
        [_toolView.recommendBtn addTarget:self action:@selector(enterRecommand) forControlEvents:UIControlEventTouchUpInside];
    }
    return _toolView;
}

- (TTTAttributedLabel *)commentLabel
{
    if (!_commentLabel) {
        _commentLabel = [[TTTAttributedLabel alloc] init];
        _commentLabel.numberOfLines = 8;
        _commentLabel.font = [UIFont systemFontOfSize:16];
        _commentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _commentLabel.textColor = UIColorRGB(0x4A4A4A);
        _commentLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
        _commentLabel.delegate = self;
        [self.contentView addSubview:_commentLabel];
    }
    return _commentLabel;
}

- (UIButton *)msgAuthorButton
{
    if (!_msgAuthorButton) {
        _msgAuthorButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _msgAuthorButton.tintColor = UIColorRGB(0x1a8df2);
        _msgAuthorButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        _msgAuthorButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_msgAuthorButton addTarget:self action:@selector(enterFirstMsgAuthorDetail) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_msgAuthorButton];
    }
    return _msgAuthorButton;
}

- (TTTAttributedLabel *)msgcontentLabel
{
    if (!_msgcontentLabel) {
        _msgcontentLabel = [[TTTAttributedLabel alloc] init];
        _msgcontentLabel.numberOfLines = 8;
        _msgcontentLabel.font = [UIFont systemFontOfSize:15];
        _msgcontentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _msgcontentLabel.textColor = UIColorRGB(0x4A4A4A);
        _msgcontentLabel.delegate = self;
        _msgcontentLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
        [self.contentView addSubview:_msgcontentLabel];
    }
    return _msgcontentLabel;
}

- (UILabel *)msgEllipsisLabel
{
    if (!_msgEllipsisLabel) {
        _msgEllipsisLabel = [[UILabel alloc] init];
        _msgEllipsisLabel.font = [UIFont systemFontOfSize:15];
        _msgEllipsisLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _msgEllipsisLabel.textColor = UIColorRGB(0x979797);
        [self.contentView addSubview:_msgEllipsisLabel];
    }
    return _msgEllipsisLabel;
}

- (UILabel *)forwardLabel
{
    if (!_forwardLabel) {
        _forwardLabel = [[UILabel alloc] init];
        _forwardLabel.text = TGLocalized(@"Stream.ForwardBy");
        _forwardLabel.font = [UIFont systemFontOfSize:13];
        _forwardLabel.textColor = UIColorRGB(0x4A4A4A);
        [self.contentView addSubview:_forwardLabel];
    }
    return _forwardLabel;
}

- (UIButton *)forwardPersonButton
{
    if (!_forwardPersonButton) {
        _forwardPersonButton = [[UIButton alloc] init];
        [_forwardPersonButton setTitleColor:UIColorRGB(0x3991F5) forState:UIControlStateNormal];
        _forwardPersonButton.titleLabel.font = [UIFont systemFontOfSize:13];
        _forwardPersonButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_forwardPersonButton addTarget:self action:@selector(forwardPersonButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_forwardPersonButton];
    }
    return _forwardPersonButton;
}

- (TGNodeImageView *)nodeImageView
{
    if (!_nodeImageView) {
        _nodeImageView = [[TGNodeImageView alloc] initWithFrame:CGRectMake(15, 0, SCREEN_WIDTH - 30, 70) withImageCount:4];
        [self.contentView addSubview:_nodeImageView];
    }
    return _nodeImageView;
}

- (TGLinkShowViewForCell *)linkView
{
    if (!_linkView) {
        _linkView = [[TGLinkShowViewForCell alloc] initWithFrame:CGRectMake(15, 0, [UIScreen mainScreen].bounds.size.width-30, 100)];
        [self.contentView addSubview:_linkView];
    }
    return _linkView;
}

#pragma mark - method
- (void)enterFirstMsgAuthorDetail
{
    TGNodeForwardMessageModel *msgModel = ((TGNodeModel *)self.object).forward.textMsgs.firstObject;
    if (self.userBlock && msgModel && msgModel.author.username.length>0) {
        self.userBlock(EnterTypeUserInfo,msgModel.author.username,nil,nil);
    }
}

- (void)enterUserDetail:(UITapGestureRecognizer *)__unused recognizer
{
    if(self.userBlock){
        TGNodeModel *node = (TGNodeModel *)self.object;
        
        self.userBlock(EnterTypeUserInfo,node.author.userName,nil,nil);
        
//        if (node.isPublic != PostPublishTypeGroupBoard && node.sourceType == PostSourceTypeForward && !node.forward.comment.length)
//        {
//            self.userBlock(EnterTypeGroupInfo,node.forward.groupId,node.forward.groupName,_headView.avatarView.image);
//        }else{
//            self.userBlock(EnterTypeUserInfo,node.author.userName,nil,nil);
//        }
    }
}

- (void)enterGroupDetail
{
    if (self.userBlock) {
        TGNodeModel *node = (TGNodeModel *)self.object;
        if (node.sourceType == PostSourceTypeForward) {
            self.userBlock(EnterTypeGroupInfo,node.forward.groupId,node.forward.groupName,node.forward.groupAvatarKey);
        }else if (node.sourceType == PostSourceTypePublish){
            self.userBlock(EnterTypeGroupInfo,node.post.groupID,node.post.groupName,node.post.groupImageKey);
        }
    }
}

- (void)enterRecommand
{
    if (self.recommandBlock) {
        self.recommandBlock(self.object);
    }
}

- (void)share:(id)__unused sender
{
    [T8HudHelper showHUDMessage:@"Being develop"];
}

- (void)forwardPersonButtonPressed
{
    if (self.forwardBlock) {
        TGNodeModel *node = (TGNodeModel *)self.object;
        self.forwardBlock(node.author.tgUserId);
    }
}

#pragma mark  - showImage
- (void)touchImageView:(UIImageView *)imageView WithPictureObject:(id)pictureObj
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(touchImageView:pictureObject:pictures:)])
    {
        TGNodeModel *node = (TGNodeModel *)self.object;
        if (node.sourceType == PostSourceTypeForward)
        {
            [self.delegate touchImageView:imageView pictureObject:pictureObj pictures:node.forward.photoMsgs];
        }else  if(node.sourceType == PostSourceTypePublish){
            [self.delegate touchImageView:imageView pictureObject:pictureObj pictures:node.post.images];
        }
    }
}

+ (CGFloat)tableView:(UITableView *)__unused tableView rowHeightForObject:(id)object
{
    if ([object isKindOfClass:[TGNodeModel class]])
    {
        TGNodeModel *node = (TGNodeModel *)object;
        if (node.cellHeight > 0) {
            return node.cellHeight;
        }
        
        CGFloat height = kTGNodeCellBaseHeight;
        
        if (node.sourceType == PostSourceTypeForward)
        {
            NSArray *array = node.forward.photoMsgs;
            if (array.count>0)
            {
                height += [TGNodeImageView getNodeImageViewHeightByPhotoArray:array] + kTGNodeCellSubviewsBigInterval;
            }
            
            array = node.forward.textMsgs;
            
            for (TGNodeForwardMessageModel *model in array) {
                height += 18 + model.messageHeight + kTGNodeCellSubviewsBigInterval;
                break;
            }
            if (array.count > 1) {
                height += 16+kTGNodeCellSubviewsBigInterval;
            }
            
            if (node.forward.comment.length)
            {
                height += node.forward.commentHeight + kTGNodeCellSubviewsBigInterval;
            }else{
//                height += 13 + kTGNodeCellSubviewsBigInterval;
            }
            
            //todo:link
        }else if(node.sourceType == PostSourceTypePublish){
            
            if (node.post.text.length)
            {
                height += node.post.textHeight + 10;
            }
            
            NSArray *array = node.post.images;
            if (array.count>0)
            {
                height += [TGNodeImageView getNodeImageViewHeightByPhotoArray:array] + kTGNodeCellSubviewsBigInterval;
            }
            
            //todo：link
            if (node.post.url.length>0) {
                height += TGLinkShowViewForCellDefaultHeight;
            }
        }
        
        node.cellHeight = height;
        return height;
    }
    
    return 0;
}

#pragma mark - TTTAttributedLabelDelegate
- (void)attributedLabel:(TTTAttributedLabel *) __unused label didSelectLinkWithURL:(NSURL *)url
{
//    [[UIApplication sharedApplication] openURL:url];
    [(TGApplication *)[UIApplication sharedApplication] openURL:url forceNative:true];
}

@end
