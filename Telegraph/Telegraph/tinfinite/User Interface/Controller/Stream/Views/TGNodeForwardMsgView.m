//
//  TGNodeForwardMsgView.m
//  Telegraph
//
//  Created by 琦张 on 15/4/2.
//
//

#import "TGNodeForwardMsgView.h"
#import "NSString+Valid.h"
#import "TGNodePhotoObject.h"
#import "TGApplication.h"

@implementation TGNodeForwardMsgView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, defaultHeight);
        self.backgroundColor = UIColorRGB(0xfafafa);
        
        [self addSubview:self.nameButton];
        [self.nameButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(15);
            make.top.equalTo(self).offset(10);
            make.height.equalTo(@25);
            make.right.lessThanOrEqualTo(self).offset(-15);
        }];
    }
    return self;
}

- (instancetype)initWithMessage:(TGNodeForwardMessageModel *)msgModel
{
    if (msgModel.msgType == ForwardMessageTypeText) {
        self = [[TGNodeForwardTextMsgView alloc] initWithMessage:msgModel];
    }else if (msgModel.msgType == ForwardMessageTypePhoto){
        self = [[TGNodeForwardPhotoMsgView alloc] initWithMessage:msgModel];
    }else{
        self = [self init];
        if (self) {
            self.msgModel = msgModel;
        }
    }
    return self;
}

- (UIButton *)nameButton
{
    if (!_nameButton) {
        _nameButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _nameButton.tintColor = UIColorRGB(0x1a8df2);
        _nameButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0f];
        [_nameButton addTarget:self action:@selector(nameButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nameButton;
}

- (void)setMsgModel:(TGNodeForwardMessageModel *)msgModel
{
    _msgModel = msgModel;
    
    [self.nameButton setTitle:_msgModel.author.name forState:UIControlStateNormal];
    if (_msgModel.author.anonymous || _msgModel.author.username.length==0) {
        self.nameButton.userInteractionEnabled = NO;
        self.nameButton.tintColor = UIColorRGB(0x4a4a4a);
    }else{
        self.nameButton.userInteractionEnabled = YES;
        self.nameButton.tintColor = UIColorRGB(0x1a8df2);
    }
}

#pragma mark - method
- (void)nameButtonPressed
{
    if (self.enterUser) {
        self.enterUser(_msgModel.author.username);
    }
}

@end


@implementation TGNodeForwardTextMsgView

- (instancetype)initWithMessage:(TGNodeForwardMessageModel *)msgModel
{
    self = [super init];
    if (self) {
        self.msgModel = msgModel;
        self.frame = CGRectMake(0, 0, SCREEN_WIDTH, self.frame.size.height+[self.msgModel.msgContent heightForSize:CGSizeMake(SCREEN_WIDTH-30, 9999) font:self.contentLabel.font]);
        
        [self addSubview:self.contentLabel];
        [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(15);
            make.right.equalTo(self).offset(-15);
            make.top.equalTo(self.nameButton.mas_bottom);
        }];
    }
    return self;
}

- (TTTAttributedLabel *)contentLabel
{
    if (!_contentLabel) {
        _contentLabel = [[TTTAttributedLabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:14.0f];
        _contentLabel.textColor = UIColorRGB(0x4a4a4a);
        _contentLabel.numberOfLines = 0;
        _contentLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
        _contentLabel.delegate = self;
        _contentLabel.text = self.msgModel.msgContent;
    }
    return _contentLabel;
}

#pragma mark - TTTAttributedLabelDelegate
- (void)attributedLabel:(TTTAttributedLabel *) __unused label didSelectLinkWithURL:(NSURL *)url
{
//    [[UIApplication sharedApplication] openURL:url];
    [(TGApplication *)[UIApplication sharedApplication] openURL:url forceNative:true];
}

@end


@implementation TGNodeForwardPhotoMsgView

- (instancetype)initWithMessage:(TGNodeForwardMessageModel *)msgModel
{
    self = [super init];
    if (self) {
        self.msgModel = msgModel;
        self.frame = CGRectMake(0, 0, SCREEN_WIDTH, defaultHeight+self.imageView.bounds.size.height);
        
        [self addSubview:self.imageView];
    }
    return self;
}

- (TGNodeImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[TGNodeImageView alloc] initWithFrame:CGRectMake(15, 0, SCREEN_WIDTH-30, 0)];
        TGNodePhotoObject *photoObj = self.msgModel.photoObj;
        CGFloat height = [_imageView setImagesWithArray:@[photoObj]];
        _imageView.frame = CGRectMake(15, 35, SCREEN_WIDTH-30, height);
    }
    return _imageView;
}

@end
