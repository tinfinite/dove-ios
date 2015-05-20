/*
 * This is the source code of Dove for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Tinfinite, 2015.
 */

#import "TGGroupInfoQRCodeController.h"

#import "TGInterfaceAssets.h"
#import "QRCodeGenerator.h"
#import "UIView+Borders.h"
#import "UIView+Dove.h"
#import "UIImage+MDQRCode.h"

#import "TGForwardTargetController.h"

@interface TGGroupInfoQRCodeController ()
{
    TGConversation *_conversation;
}

@property (nonatomic,strong) UIImageView *qrcodeBackgroundView;
@property (nonatomic,strong) UIImageView *qrcodeView;
@property (nonatomic,strong) UILabel *shareTitleLabel;
@property (nonatomic,strong) UILabel *groupNameLabel;
@property (nonatomic,strong) UILabel *descripLabel;
@property (nonatomic,strong) UILabel *urlLabel;
@property (nonatomic,strong) UIButton *forwardButton;
@property (nonatomic,strong) UIButton *savaButton;

@end

@implementation TGGroupInfoQRCodeController

- (instancetype)initConversation:(TGConversation *)conversation
{
    self = [super init];
    if (self) {
        _conversation = conversation;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [TGInterfaceAssets listsBackgroundColor];
    
    [self resetQRCodeBackgroundView];
    
    _shareTitleLabel = [[UILabel alloc] init];
    _shareTitleLabel.frame = CGRectMake(30, _qrcodeBackgroundView.frame.origin.y - 60, self.view.frame.size.width - 60, 30);
    _shareTitleLabel.textAlignment = NSTextAlignmentCenter;
    _shareTitleLabel.textColor = UIColorRGB(0x9b9b9b);
    _shareTitleLabel.font = [UIFont systemFontOfSize:26];
    _shareTitleLabel.text = TGLocalized(@"QRCode.Title");
    [self.view addSubview:_shareTitleLabel];
    
    _forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _forwardButton.frame = CGRectMake(self.view.frame.size.width/4, self.view.frame.size.height*4/5, self.view.frame.size.width/2,50);
    [_forwardButton setTitle:@"Forward" forState:UIControlStateNormal];
    [_forwardButton addTopBorderWithHeight:1 andColor:UIColorRGB(0xcdcdcd)];
    [_forwardButton setTitleColor:UIColorRGB(0x008DF2) forState:UIControlStateNormal];
    [_forwardButton addTarget:self action:@selector(forwardQRCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_forwardButton];
    
    _savaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _savaButton.frame = CGRectMake(self.view.frame.size.width/4, self.view.frame.size.height*4/5+50, self.view.frame.size.width/2,50);
    [_savaButton setTitle:@"Save" forState:UIControlStateNormal];
    [_savaButton addTopBorderWithHeight:1 andColor:UIColorRGB(0xcdcdcd)];
    [_savaButton addBottomBorderWithHeight:1 andColor:UIColorRGB(0xcdcdcd)];
    [_savaButton setTitleColor:UIColorRGB(0x008DF2) forState:UIControlStateNormal];
    [_savaButton addTarget:self action:@selector(savePhotosAlbum) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_savaButton];
}

- (void)resetQRCodeBackgroundView
{
    if (_qrcodeBackgroundView != nil)
    {
        [_qrcodeBackgroundView removeFromSuperview];
    }
    
    CGFloat padding = 30;
    CGRect frame = self.view.bounds;
    frame.size = CGSizeMake(self.view.frame.size.width - 2*padding, self.view.frame.size.width - 2*padding);
    _qrcodeBackgroundView = [[UIImageView alloc] init];
    _qrcodeBackgroundView.frame = frame;
    _qrcodeBackgroundView.center = self.view.center;
    _qrcodeBackgroundView.image = [UIImage imageNamed:@"InviteQRCodeBackground"];
    
    [self.view addSubview:_qrcodeBackgroundView];
    
    
    _qrcodeView = [[UIImageView alloc] init];
    _qrcodeView.frame = CGRectMake(0, 0, _qrcodeBackgroundView.frame.size.width/1.5f, _qrcodeBackgroundView.frame.size.width/1.5f);
    _qrcodeView.center = CGPointMake(_qrcodeBackgroundView.frame.size.width/2, _qrcodeBackgroundView.frame.size.height/2);
    [_qrcodeBackgroundView addSubview:_qrcodeView];
    
    NSString *codeString = [NSString stringWithFormat:@"http://fir.im/Dove?chat_id=%lld&chat_name=%@",_conversation.conversationId,_conversation.chatTitle];
    
    _qrcodeView.image = [UIImage mdQRCodeForString:codeString size:80];
    
    _groupNameLabel = [[UILabel alloc] init];
    _groupNameLabel.frame = CGRectMake(0, 0, _qrcodeBackgroundView.frame.size.width/2.0f, 20);
        _groupNameLabel.center = CGPointMake(_qrcodeBackgroundView.frame.size.width/2, _qrcodeBackgroundView.frame.size.width/7.5f);
    _groupNameLabel.textAlignment = NSTextAlignmentCenter;
    _groupNameLabel.font = [UIFont boldSystemFontOfSize:17];
    _groupNameLabel.textColor = UIColorRGB(0x008DF2);
    _groupNameLabel.text = _conversation.chatTitle;
    [_qrcodeBackgroundView addSubview:_groupNameLabel];
    
    _descripLabel = [[UILabel alloc] init];
    _descripLabel.frame = CGRectMake(0, 0, _qrcodeBackgroundView.frame.size.width, 20);
    _descripLabel.center = CGPointMake(_qrcodeBackgroundView.frame.size.width/2, _qrcodeBackgroundView.frame.size.width*6.7f/8);
    _descripLabel.textAlignment = NSTextAlignmentCenter;
    _descripLabel.font = [UIFont systemFontOfSize:14];
    _descripLabel.textColor = UIColorRGB(0x008DF2);
    _descripLabel.text = TGLocalized(@"QRCode.Notice");
    [_qrcodeBackgroundView addSubview:_descripLabel];
    
    _urlLabel = [[UILabel alloc] init];
    _urlLabel.frame = CGRectMake(0, 0, _qrcodeBackgroundView.frame.size.width, 20);
    _urlLabel.center = CGPointMake(_qrcodeBackgroundView.frame.size.width/2, _qrcodeBackgroundView.frame.size.width*7.2f/8);
    _urlLabel.textAlignment = NSTextAlignmentCenter;
    _urlLabel.font = [UIFont systemFontOfSize:14];
    _urlLabel.textColor = UIColorRGB(0x008DF2);
    _urlLabel.text = @"http://dove.tinfinite.com";
    [_qrcodeBackgroundView addSubview:_urlLabel];
}

- (void)forwardQRCode
{
    UIImage *image = [_qrcodeBackgroundView snapshot];
    
    TGForwardTargetController *forwardController = [[TGForwardTargetController alloc] initWithQRCodeImage:image];
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithRootController:forwardController];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self presentViewController:navigationController animated:true completion:nil];
}

- (void)savePhotosAlbum
{
    UIImage *snapshot = [_qrcodeBackgroundView snapshot];
    UIImageWriteToSavedPhotosAlbum(snapshot, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)__unused image didFinishSavingWithError:(NSError *)error contextInfo:(void *)__unused contextInfo
{
    if (error != NULL){
        [T8HudHelper showHUDMessage:@"保存失败！"];
    }
    else{
        [T8HudHelper showHudMessage:@"保存成功" image:@"Checkmark"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
