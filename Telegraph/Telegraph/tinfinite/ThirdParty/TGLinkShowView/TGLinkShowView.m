//
//  TGLinkShowView.m
//  Telegraph
//
//  Created by 琦张 on 15/3/28.
//
//

#import "TGLinkShowView.h"
#import "TFHpple.h"
#import "UIImageView+AFNetworking.h"
#import "TGApplication.h"

@interface TGLinkShowView ()

@end

@implementation TGLinkShowView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self addSubview:self.deleteButton];
        [self addSubview:self.imgView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.urlLabel];
        [self addSubview:self.descriptionLabel];
        
        [self configSubViews];
        
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(linkViewTapped:)]];
        
    }
    return self;
}

#pragma mark - method
- (void)linkViewTapped:(UIGestureRecognizer *) __unused recognizer
{
    if (self.openBlock) {
        self.openBlock(self.linkUrl);
    }else{
        [(TGApplication *)[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.linkUrl] forceNative:true];
    }
}

- (void)configSubViews
{
    self.backgroundColor = UIColorRGB(0xfafafa);
    self.layer.borderColor = [UIColorRGB(0xd2d2d2) CGColor];
    self.layer.borderWidth = 0.5f;
    
    self.ready = NO;
    
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(5);
        make.right.equalTo(self).offset(-5);
    }];
    
    [self.imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(10);
        make.top.equalTo(self).offset(10);
        make.height.equalTo(@(self.frame.size.height-20));
        make.width.equalTo(@(self.frame.size.height-20));
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.imgView.mas_right).offset(10);
        make.top.equalTo(self.imgView);
        make.right.lessThanOrEqualTo(self.deleteButton.mas_left).offset(-10);
    }];
    
    [self.urlLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel);
        make.centerY.equalTo(self);
        make.right.equalTo(self).offset(-10);
    }];
    
    [self.descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel);
        make.bottom.equalTo(self.imgView.mas_bottom);
        make.right.equalTo(self).offset(-10);
    }];
}

- (void)deleteButtonPressed
{
    self.ready = NO;
    
    if (self.deleteBlock) {
        self.deleteBlock();
    }
}

- (BOOL)checkStatus
{
    return NO;
}

- (void)updateLinkUrl:(NSString *)url
{
    _linkUrl = url;
}

#pragma mark - setter
- (void)setLinkUrl:(NSString *)linkUrl
{
    if ([linkUrl isEqualToString:_linkUrl]) {
        if (self.ready) {
            return;
        }else{
            if (_titleStr.length>0 || _imgUrl.length>0 || _desc.length>0) {
                self.ready = YES;
            }else{
                self.ready = NO;
            }
            if (self.updateBlock) {
                self.updateBlock(self.ready);
            }
        }
    }
    
    _linkUrl = linkUrl;
    self.imgView.image = [UIImage imageNamed:@"default_link_img"];
    self.titleLabel.text = @"";
    self.urlLabel.text = _linkUrl;
    self.descriptionLabel.text = @"";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[_linkUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]]];
        request.timeoutInterval = 5;
        [request setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.76 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:data];
        
        self.titleStr = nil;
        TFHppleElement *titleOgp = [xpathParser peekAtSearchWithXPathQuery:@"//meta[@property='og:title']/@content"];
        self.titleStr = titleOgp!=nil?titleOgp.content:nil;
        if (!self.titleStr) {
            TFHppleElement *titleEle = [xpathParser peekAtSearchWithXPathQuery:@"//title"];
            self.titleStr = titleEle.content;
        }
        
        self.imgUrl = nil;
        TFHppleElement *imageOgp = [xpathParser peekAtSearchWithXPathQuery:@"//meta[@property='og:image']/@content"];
        self.imgUrl = imageOgp!=nil?imageOgp.content:nil;
        if (!self.imgUrl) {
            TFHppleElement *imageEle = [xpathParser peekAtSearchWithXPathQuery:@"//img/@src"];
            self.imgUrl = imageEle.content;
        }
        self.imgUrl = [self.imgUrl stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        if (![self.imgUrl containsString:@"http://"]) {
            self.imgUrl = [NSString stringWithFormat:@"http://%@",self.imgUrl];
        }
        
        self.desc = nil;
        TFHppleElement *descOgp = [xpathParser peekAtSearchWithXPathQuery:@"//meta[@property='og:description']/@content"];
        self.desc = descOgp!=nil?descOgp.content:nil;
        if (!self.desc) {
            TFHppleElement *descEle = [xpathParser peekAtSearchWithXPathQuery:@"//meta[@name='description']/@content"];
            self.desc = descEle.content;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.titleLabel.text = _titleStr;
            [self.imgView setImageWithURL:[NSURL URLWithString:_imgUrl] placeholderImage:[UIImage imageNamed:@"default_link_img"]];
            self.descriptionLabel.text = _desc;
            self.urlLabel.text = _linkUrl;
            
            if (_titleStr.length>0 || _imgUrl.length>0 || _desc.length>0) {
                self.ready = YES;
            }else{
                self.ready = NO;
            }
            
            if (self.updateBlock) {
                self.updateBlock(self.ready);
            }
        });
        
    });
}

- (void)setTitleStr:(NSString *)titleStr
{
    _titleStr = titleStr;
}

- (void)setImgUrl:(NSString *)imgUrl
{
    _imgUrl = imgUrl;
}

- (void)setDesc:(NSString *)desc
{
    _desc = desc;
}

#pragma mark - getter
- (UIButton *)deleteButton
{
    if (!_deleteButton) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteButton setImage:[UIImage imageNamed:@"publish_image_delete"] forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

- (UIImageView *)imgView
{
    if (!_imgView) {
        _imgView = [[UIImageView alloc] init];
        _imgView.image = [UIImage imageNamed:@"default_link_img"];
        _imgView.contentMode = UIViewContentModeScaleAspectFill;
        _imgView.clipsToBounds = YES;
    }
    return _imgView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:13.0f];
        _titleLabel.textColor = UIColorRGB(0x4a4a4a);
    }
    return _titleLabel;
}

- (UILabel *)urlLabel
{
    if (!_urlLabel) {
        _urlLabel = [[UILabel alloc] init];
        _urlLabel.font = [UIFont systemFontOfSize:12.0f];
        _urlLabel.textColor = UIColorRGB(0x889199);
    }
    return _urlLabel;
}

- (UILabel *)descriptionLabel
{
    if (!_descriptionLabel) {
        _descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.font = [UIFont systemFontOfSize:13.0f];
        _descriptionLabel.textColor = UIColorRGB(0x4a4a4a);
    }
    return _descriptionLabel;
}

@end
