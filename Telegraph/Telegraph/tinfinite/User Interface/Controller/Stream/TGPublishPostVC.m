//
//  TGPublishPostVC.m
//  Telegraph
//
//  Created by 琦张 on 15/3/24.
//
//

#import "TGPublishPostVC.h"
#import "TGBackdropView.h"
#import "SZTextView.h"
#import "TGAttachmentSheetButtonItemView.h"
#import "TGAttachmentSheetRecentControlledButtonItemView.h"
#import "TGAttachmentSheetWindow.h"
#import "TGWebSearchController.h"
#import "TGNavigationController.h"
#import "TGImageSearchController.h"
#import "TGAttachmentSheetRecentItemView.h"
#import "TGLegacyCameraController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "TGImageDownloadActor.h"
#import "TGImageMediaAttachment.h"
#import "TGImageUtils.h"
#import "TGProgressWindow.h"
#import "ATQueue.h"
#import "TGAssetImageManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "TGImagesShowView.h"
#import "T8ImageUploadManager.h"
#import "T8ImageUploadItem.h"
#import "TGLinkShowView.h"
#import "TGApplication.h"

@interface TGPublishPostVC ()<TGLegacyCameraControllerDelegate,TGImagePickerControllerDelegate,UITextViewDelegate>
{
    ATQueue *_mediaProcessingQueue;
}

@property (nonatomic,strong) UIButton *postButton;
@property (nonatomic,strong) UIButton *cancelButton;
@property (nonatomic,strong) UILabel *titleLabel;

@property (nonatomic,strong) SZTextView *contentTextView;
@property (nonatomic,strong) UIButton *attachmentButton;
@property (nonatomic,strong) TGAttachmentSheetWindow *attachmentSheetWindow;

@property (nonatomic,strong) NSMutableArray *selectedImages;
@property (nonatomic,strong) TGImagesShowView *imagesView;
@property (nonatomic,copy) NSString *matchedUrl;
@property (nonatomic,strong) TGLinkShowView *linkView;

@property (nonatomic,assign) CGFloat keyboardOriginY;

@property (nonatomic,assign) PublishEnteranceType enteranceType;
@property (nonatomic,assign) int64_t groupId;

@end

@implementation TGPublishPostVC

- (instancetype)initWithEnteranceType:(PublishEnteranceType)enteranceType andGroupId:(int64_t)groupId
{
    self = [super init];
    if (self) {
        self.enteranceType = enteranceType;
        self.groupId = groupId;
        self.keyboardOriginY = [UIScreen mainScreen].bounds.size.height;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardFrameChangeNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setTitleText:TGLocalized(@"Stream.PublishTitle")];
    [self setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Stream.Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)]];
    [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Stream.Post") style:UIBarButtonItemStylePlain target:self action:@selector(postButtonPressed)]];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
//    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
//    TGBackdropView *backView = [TGBackdropView viewWithLightNavigationBarStyle];
//    backView.frame = CGRectMake(0.0f, 0.0f, screenSize.width, 20 + 44);
//    [self.view addSubview:backView];
//    
//    [backView addSubview:self.cancelButton];
//    [backView addSubview:self.postButton];
//    [backView addSubview:self.titleLabel];
    [self.view addSubview:self.contentTextView];
    [self.view addSubview:self.attachmentButton];
    [self.view addSubview:self.linkView];
    [self.view addSubview:self.imagesView];
    
//    [self.postButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.right.equalTo(backView);
//        make.bottom.equalTo(backView);
//        make.height.equalTo(@44);
//        make.width.equalTo(@80);
//    }];
//    
//    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(backView);
//        make.bottom.equalTo(backView);
//        make.height.equalTo(@44);
//        make.width.equalTo(@80);
//    }];
//    
//    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.centerX.equalTo(backView);
//        make.centerY.equalTo(backView.mas_bottom).offset(-22);
//    }];
    
    [self updateUserInterface];
    
    [self.contentTextView becomeFirstResponder];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)controllerInsetUpdated:(UIEdgeInsets) __unused previousInset
{
    
}

#pragma mark - setter
- (void)setMatchedUrl:(NSString *)matchedUrl
{
    _matchedUrl = matchedUrl;
    if (_matchedUrl.length>0) {
        [self.linkView setLinkUrl:_matchedUrl];
    }
}

#pragma mark - getter
- (TGImagesShowView *)imagesView
{
    if (!_imagesView) {
        _imagesView = [[TGImagesShowView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 98)];
        __weak typeof(self) weakSelf = self;
        _imagesView.updateBlock = ^(){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf updateUserInterface];
            [strongSelf checkPublishStatus];
        };
    }
    return _imagesView;
}

- (TGLinkShowView *)linkView
{
    if (!_linkView) {
        _linkView = [[TGLinkShowView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 98)];
        __weak typeof(self) weakSelf = self;
        _linkView.updateBlock = ^(BOOL __unused result){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf updateUserInterface];
        };
        _linkView.deleteBlock = ^(){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf updateUserInterface];
        };
        _linkView.openBlock = ^(NSString *urlStr){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [(TGApplication *)[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr] forceNative:true withParentVC:strongSelf.navigationController];
            [strongSelf.view endEditing:YES];
        };
    }
    return _linkView;
}

- (ATQueue *)mediaProcessingQueue
{
    @synchronized (self)
    {
        if (_mediaProcessingQueue == nil)
            _mediaProcessingQueue = [[ATQueue alloc] init];
    }
    
    return _mediaProcessingQueue;
}

- (UIButton *)postButton
{
    if (!_postButton) {
        _postButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _postButton.tintColor = [UIColor whiteColor];
        [_postButton setTitle:TGLocalized(@"Stream.Post") forState:UIControlStateNormal];
        _postButton.titleLabel.font = [UIFont systemFontOfSize:16];
        _postButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 15);
        _postButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [_postButton addTarget:self action:@selector(postButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _postButton.enabled = NO;
        _postButton.frame = CGRectMake(0, 0, 80, 44);
    }
    return _postButton;
}

- (UIButton *)cancelButton
{
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_cancelButton setTitle:TGLocalized(@"Stream.Cancel") forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
        _cancelButton.titleEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
        _cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_cancelButton addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.frame = CGRectMake(0, 0, 80, 44);
    }
    return _cancelButton;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = TGLocalized(@"Stream.PublishTitle");
    }
    return _titleLabel;
}

- (SZTextView *)contentTextView
{
    if (!_contentTextView) {
        _contentTextView = [[SZTextView alloc] init];
        _contentTextView.placeholder = TGLocalized(@"Stream.PublishPlaceHolder");
        _contentTextView.frame = CGRectMake(12, 66+10, [UIScreen mainScreen].bounds.size.width-24, [UIScreen mainScreen].bounds.size.height-66-20);
        _contentTextView.font = [UIFont systemFontOfSize:16];
        _contentTextView.backgroundColor = [UIColor whiteColor];
        _contentTextView.delegate = self;
    }
    return _contentTextView;
}

- (UIButton *)attachmentButton
{
    if (!_attachmentButton) {
        _attachmentButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_attachmentButton setImage:[UIImage imageNamed:@"stream_attach_icon"] forState:UIControlStateNormal];
        [_attachmentButton addTarget:self action:@selector(attachButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _attachmentButton;
}

- (NSMutableArray *)selectedImages
{
    if (!_selectedImages) {
        _selectedImages = [NSMutableArray array];
    }
    return _selectedImages;
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView
{
    if ([[textView.selectedTextRange description] containsString:@"F"]) {
        NSString *textStr = textView.text;
        NSString *pattern = @"((https?|ftp|news)://)([a-z]([a-z0-9\\-]*[\\.。])+([a-z]{2}|aero|arpa|biz|com|coop|edu|gov|info|int|jobs|mil|museum|name|nato|net|org|pro|travel)|(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]))(/[a-z0-9_\\-\\.~]+)*(/([a-z0-9_\\-\\.]*)(\\?[a-z0-9+_\\-\\.%=&]*)?)?(#[a-z][a-z0-9_]*)?\\s";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [regex matchesInString:textStr options:0 range:NSMakeRange(0, textStr.length)];
        if (matches.count>0) {
            NSTextCheckingResult *match = matches.firstObject;
            NSRange matchRange = [match range];
            NSString *matchStr = [textStr substringWithRange:matchRange];
            self.matchedUrl = [matchStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }else{
            self.matchedUrl = @"";
        }
    }
    [self checkPublishStatus];
}

#pragma mark - method
- (void)postButtonPressed
{
//    self.postButton.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (self.selectedImages.count>0) {
        if (self.selectedImages.count>6) {
            [T8HudHelper showHUDMessage:TGLocalized(@"Stream.MaxImageCount")];
//            self.postButton.enabled = YES;
            self.navigationItem.rightBarButtonItem.enabled = NO;
            return;
        }
        
        [T8HudHelper showHUDActivity:self.view];
        __weak typeof(self) weakSelf = self;
        [[T8ImageUploadManager sharedInstance] uploadImagesBatch:self.selectedImages result:^(BOOL result) {
            if (result) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf publishPost];
            }else{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf publishFail];
            }
        }];
    }else{
        [T8HudHelper showHUDActivity:self.view];
        NSMutableDictionary *post = [NSMutableDictionary dictionary];
        [post setObject:[self getContentText] forKey:@"text"];
        [post setObject:@"" forKey:@"image"];
        [post setObject:[self getLinkUrl] forKey:@"url"];
        [post setObject:self.linkView.titleStr?self.linkView.titleStr:@"" forKey:@"url_title"];
        [post setObject:self.linkView.imgUrl?self.linkView.imgUrl:@"" forKey:@"url_image"];
        [post setObject:self.linkView.desc?self.linkView.desc:@"" forKey:@"url_description"];
        NSData *postJsonData = [NSJSONSerialization dataWithJSONObject:post options:0 error:nil];
        NSString *postJsonStr = [[NSString alloc] initWithData:postJsonData encoding:NSUTF8StringEncoding];
        
        PostPublishType publicType = self.enteranceType == PublishEnteranceTypePublishStream?PostPublishTypePublishStream:PostPublishTypeGroupBoard;
        __weak typeof(self) weakSelf = self;
        [T8NodeHttpRequestService publishNodeWithForward:@"" post:postJsonStr isPublic:publicType type:PostSourceTypePublish groupId:self.groupId successBlock:^(NSDictionary *dictRet) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf publishSuccess];
            [T8Common storeNodeAfterPublishWithForward:@"" post:postJsonStr isPublic:publicType type:PostSourceTypePublish groupId:strongSelf.groupId successData:dictRet];
        } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf publishFail];
        }];
    }
    
    NSMutableDictionary *event = nil;
    
    if (self.enteranceType == PublishEnteranceTypePublishStream) {
        [[GAIDictionaryBuilder createEventWithCategory:@"公共信息流"
                                                action:@"发布消息"
                                                 label:@""
                                                 value:nil] build];
    }else{
        [[GAIDictionaryBuilder createEventWithCategory:@"群留言板"
                                                action:@"发布消息"
                                                 label:@""
                                                 value:nil] build];
    }
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];
}

- (void)publishPost
{
    __block NSString *images = @"";
    [self.selectedImages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL __unused *stop) {
        NSDictionary *imageDict = (NSDictionary *)obj;
        NSString *path = [imageDict objectForKey:ImageItemQiniuPath];
        if (idx == 0) {
            images = [images stringByAppendingString:path];
        }else{
            images = [images stringByAppendingFormat:@",%@",path];
        }
    }];
    NSMutableDictionary *post = [NSMutableDictionary dictionary];
    [post setObject:[self getContentText] forKey:@"text"];
    [post setObject:images forKey:@"image"];
    [post setObject:[self getLinkUrl] forKey:@"url"];
    [post setObject:self.linkView.titleStr?self.linkView.titleStr:@"" forKey:@"url_title"];
    [post setObject:self.linkView.imgUrl?self.linkView.imgUrl:@"" forKey:@"url_image"];
    [post setObject:self.linkView.desc?self.linkView.desc:@"" forKey:@"url_description"];
    NSData *postJsonData = [NSJSONSerialization dataWithJSONObject:post options:0 error:nil];
    NSString *postJsonStr = [[NSString alloc] initWithData:postJsonData encoding:NSUTF8StringEncoding];
    
    PostPublishType publicType = self.enteranceType == PublishEnteranceTypePublishStream?PostPublishTypePublishStream:PostPublishTypeGroupBoard;
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService publishNodeWithForward:@"" post:postJsonStr isPublic:publicType type:PostSourceTypePublish groupId:self.groupId successBlock:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf publishSuccess];
        [T8Common storeNodeAfterPublishWithForward:@"" post:postJsonStr isPublic:publicType type:PostSourceTypePublish groupId:strongSelf.groupId successData:dictRet];
    } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf publishFail];
    }];
}

- (void)publishSuccess
{
    [T8HudHelper hideHUDActivity:self.view];
    [T8HudHelper showHUDMessage:TGLocalized(@"Stream.PublishSuccess")];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)publishFail
{
    [T8HudHelper hideHUDActivity:self.view];
    [T8HudHelper showHUDMessage:TGLocalized(@"Stream.PublishFail")];
//    self.postButton.enabled = YES;
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)checkPublishStatus
{
    BOOL hasImage = self.selectedImages.count>0?YES:NO;
    BOOL hasText = [self.contentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length>0?YES:NO;
    if (hasImage || hasText) {
//        self.postButton.enabled = YES;
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }else{
//        self.postButton.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (NSString *)getContentText
{
    return self.contentTextView.text;
}

- (NSString *)getLinkUrl
{
    return self.matchedUrl!=nil?self.matchedUrl:@"";
}

- (void)cancelButtonPressed
{
    NSMutableDictionary *event = nil;
    
    if (self.enteranceType == PublishEnteranceTypePublishStream) {
        [[GAIDictionaryBuilder createEventWithCategory:@"公共信息流"
                                                action:@"放弃发布消息"
                                                 label:@""
                                                 value:nil] build];
    }else{
        [[GAIDictionaryBuilder createEventWithCategory:@"群留言板"
                                                action:@"放弃发布消息"
                                                 label:@""
                                                 value:nil] build];
    }
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)attachButtonPressed
{
    _attachmentSheetWindow = [[TGAttachmentSheetWindow alloc] init];

    __weak typeof(self) weakSelf = self;
    
    NSMutableArray *items = [NSMutableArray array];
    
    TGAttachmentSheetRecentItemView *recentView = [[TGAttachmentSheetRecentItemView alloc] initWithParentController:self];
    recentView.textType = RecentItemTextTypeAttach;
    __weak TGAttachmentSheetRecentItemView *weakRecentView = recentView;
    
    recentView.done = ^
    {
        TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
        [progressWindow performSelector:@selector(showAnimated) withObject:nil afterDelay:0.5];
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            __strong TGAttachmentSheetRecentItemView *strongRecentView = weakRecentView;
            [strongSelf->_attachmentSheetWindow dismissAnimated:true];
            
            if (strongRecentView != nil)
            {
                NSArray *selectedAssets = [strongRecentView selectedAssets];
                __weak typeof(strongSelf) weakSelf = strongSelf;
                [strongSelf _asyncProcessMediaAssets:selectedAssets completion:^(NSArray *descriptions)
                 {
                     __strong typeof(weakSelf) strongSelf = weakSelf;
                     [strongSelf addImages:[descriptions mutableCopy]];
                     
                     TGDispatchOnMainThread(^
                                            {
                                                [NSObject cancelPreviousPerformRequestsWithTarget:progressWindow selector:@selector(showAnimated) object:nil];
                                                [progressWindow dismiss:true];
                                            });
                 }];
            }
        }
    };
    
    TGAttachmentSheetRecentControlledButtonItemView *multifunctionButtonView = [[TGAttachmentSheetRecentControlledButtonItemView alloc] initWithTitle:TGLocalized(@"Common.ChoosePhoto") pressed:^{
        __strong TGPublishPostVC *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            [strongSelf.view endEditing:true];
            [strongSelf->_attachmentSheetWindow dismissAnimated:true];
            [strongSelf _displayImagePicker:false];
        }
    } alternatePressed:^{
        TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
        [progressWindow performSelector:@selector(showAnimated) withObject:nil afterDelay:0.5];
        
        __strong TGPublishPostVC *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            __strong TGAttachmentSheetRecentItemView *strongRecentView = weakRecentView;
            [strongSelf->_attachmentSheetWindow dismissAnimated:true];
            
            if (strongRecentView != nil)
            {
                NSArray *selectedAssets = [strongRecentView selectedAssets];
                __weak TGPublishPostVC *weakSelf = strongSelf;
                [strongSelf _asyncProcessMediaAssets:selectedAssets completion:^(NSArray *descriptions)
                 {
                     __strong TGPublishPostVC *strongSelf = weakSelf;
                     [strongSelf addImages:[descriptions mutableCopy]];
                     
                     TGDispatchOnMainThread(^
                                            {
                                                [NSObject cancelPreviousPerformRequestsWithTarget:progressWindow selector:@selector(showAnimated) object:nil];
                                                [progressWindow dismiss:true];
                                            });
                 }];
            }
        }
    }];
    
    [recentView setMultifunctionButtonView:multifunctionButtonView];
    recentView.openCamera = ^
    {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            [strongSelf.view endEditing:true];
            [strongSelf->_attachmentSheetWindow dismissAnimated:true];
            [strongSelf _displayPhotoVideoPicker:false];
        }
    };
    
    [items addObject:recentView];
    [items addObject:multifunctionButtonView];
    

    
//    [items addObject:[[TGAttachmentSheetButtonItemView alloc] initWithTitle:TGLocalized(@"Conversation.SearchWebImages") pressed:^{
//        __strong typeof(weakSelf) strongSelf = weakSelf;
//        if (strongSelf != nil)
//        {
//            [strongSelf.view endEditing:true];
//            [strongSelf->_attachmentSheetWindow dismissAnimated:true];
//            [strongSelf _displayImagePicker:true];
//        }
//    }]];
    
    TGAttachmentSheetButtonItemView *cancelItem =[[TGAttachmentSheetButtonItemView alloc] initWithTitle:TGLocalized(@"Common.Cancel") pressed:^
                                                  {
                                                      __strong typeof(weakSelf) strongSelf = weakSelf;
                                                      if (strongSelf != nil)
                                                          [strongSelf->_attachmentSheetWindow dismissAnimated:true];
                                                  }];
    [cancelItem setBold:true];
    [items addObject:cancelItem];
    
    _attachmentSheetWindow.view.items = items;
    [_attachmentSheetWindow showAnimated:true];
}

- (void)_asyncProcessMediaAssets:(NSArray *)assets completion:(void (^)(NSArray *))completion
{
    [self _recursiveProcessMediaAssets:assets completion:completion index:0 result:@[]];
}

- (void)_recursiveProcessMediaAssets:(NSArray *)assets completion:(void (^)(NSArray *))completion index:(NSUInteger)index result:(NSArray *)result
{
    __weak typeof(self) weakSelf = self;
    [[self mediaProcessingQueue] dispatch:^
     {
         if (index >= assets.count)
         {
             if (completion)
                 completion(result);
         }
         else
         {
             [TGAssetImageManager requestImageDataWithAsset:assets[index] completionBlock:^(NSData *data, __unused NSError *error)
              {
                  __strong TGPublishPostVC *strongSelf = weakSelf;
                  if (strongSelf != nil)
                  {
                      NSMutableArray *nextResult = [[NSMutableArray alloc] initWithArray:result];
                      
                      if (data != nil)
                      {
                          CC_MD5_CTX md5;
                          CC_MD5_Init(&md5);
                          CC_MD5_Update(&md5, [data bytes], data.length);
                          
                          unsigned char md5Buffer[16];
                          CC_MD5_Final(md5Buffer, &md5);
                          NSString *hash = [[NSString alloc] initWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", md5Buffer[0], md5Buffer[1], md5Buffer[2], md5Buffer[3], md5Buffer[4], md5Buffer[5], md5Buffer[6], md5Buffer[7], md5Buffer[8], md5Buffer[9], md5Buffer[10], md5Buffer[11], md5Buffer[12], md5Buffer[13], md5Buffer[14], md5Buffer[15]];
                          
                          id description = [strongSelf imageDescriptionFromImage:[[UIImage alloc] initWithData:data] optionalAssetUrl:[[NSString alloc] initWithFormat:@"image-%@", hash]];
                          if (description != nil)
                              [nextResult addObject:description];
                      }
                      
                      if (index + 1 >= assets.count)
                      {
                          if (completion)
                              completion(nextResult);
                      }
                      else
                      {
                          [strongSelf _recursiveProcessMediaAssets:assets completion:completion index:index + 1 result:nextResult];
                      }
                  }
              }];
         }
     }];
}

- (void)_displayPhotoVideoPicker:(bool)videoGallery
{
    if (videoGallery)
    {
//        __weak TGModernConversationController *weakSelf = self;
//        void (^videoPicked)(NSString *videoAssetId, NSString *tempFilePath, CGSize dimensions, NSTimeInterval duration, UIImage *thumbnail, TGLiveUploadActorData *liveUploadData) = ^(NSString *videoAssetId, NSString *tempFilePath, CGSize dimensions, NSTimeInterval duration, UIImage *thumbnail, TGLiveUploadActorData *liveUploadData)
//        {
//            TGDispatchOnMainThread(^
//                                   {
//                                       __strong TGModernConversationController *strongSelf = weakSelf;
//                                       
//                                       TGVideoMediaAttachment *videoAttachment = nil;
//                                       if (videoAssetId != nil)
//                                           videoAttachment = [strongSelf.companion serverCachedAssetWithId:videoAssetId];
//                                       
//                                       if (videoAttachment != nil)
//                                           [strongSelf.companion controllerWantsToSendRemoteVideoWithMedia:videoAttachment];
//                                       else
//                                       {
//                                           int fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:tempFilePath error:NULL][NSFileSize] intValue];
//                                           if (fileSize != 0)
//                                           {
//                                               [strongSelf.companion controllerWantsToSendLocalVideoWithTempFilePath:tempFilePath fileSize:(int32_t)fileSize previewImage:thumbnail duration:duration dimensions:dimensions assetUrl:videoAssetId liveUploadData:liveUploadData];
//                                           }
//                                       }
//                                       
//                                       [strongSelf dismissViewControllerAnimated:true completion:nil];
//                                   });
//        };
//        
//        TGMediaFoldersController *mediaFoldersController = [[TGMediaFoldersController alloc] init];
//        mediaFoldersController.videoPicked = videoPicked;
//        mediaFoldersController.liveUpload = [_companion controllerShouldLiveUploadVideo];
//        mediaFoldersController.enableServerAssetCache = [_companion controllerShouldCacheServerAssets];
//        
//        TGModernMediaPickerController *mediaPickerController = [[TGModernMediaPickerController alloc] init];
//        mediaPickerController.videoPicked = videoPicked;
//        mediaPickerController.liveUpload = [_companion controllerShouldLiveUploadVideo];
//        mediaPickerController.enableServerAssetCache = [_companion controllerShouldCacheServerAssets];
//        TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[mediaFoldersController, mediaPickerController]];
//        
//        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
//        {
//            navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
//            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
//        }
//        
//        [self presentViewController:navigationController animated:true completion:nil];
    }
    else
    {
        TGLegacyCameraController *legacyCameraController = [[TGLegacyCameraController alloc] init];
        if (videoGallery)
        {
            legacyCameraController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            legacyCameraController.mediaTypes = [[NSArray alloc] initWithObjects:(__bridge NSString *)kUTTypeMovie, nil];
        }
        else
        {
            legacyCameraController.sourceType = UIImagePickerControllerSourceTypeCamera;
            legacyCameraController.mediaTypes = [[NSArray alloc] initWithObjects:(__bridge NSString *)kUTTypeImage, nil];
        }
        
        legacyCameraController.storeCapturedAssets = true;
        legacyCameraController.completionDelegate = self;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && videoGallery)
        {
            legacyCameraController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        [self presentViewController:legacyCameraController animated:true completion:nil];
    }
}

- (void)_displayImagePicker:(bool)webImages
{
    if (webImages)
    {
        NSMutableArray *controllerList = [[NSMutableArray alloc] init];
        
        TGWebSearchController *searchController = [[TGWebSearchController alloc] init];
        
        __weak typeof(self) weakSelf = self;
        searchController.completion = ^(NSArray *items)
        {
            NSLog(@"items:%@",items);
//            __strong TGModernConversationController *strongSelf = weakSelf;
//            if (strongSelf != nil)
//            {
//                NSMutableArray *imageDescriptions = [[NSMutableArray alloc] init];
//                
//                for (id item in items)
//                {
//                    if ([item isKindOfClass:[TGBingSearchResultItem class]])
//                    {
//                        id imageDescription = [strongSelf.companion imageDescriptionFromBingSearchResult:item];
//                        if (imageDescription != nil)
//                            [imageDescriptions addObject:imageDescription];
//                    }
//                    else if ([item isKindOfClass:[TGGiphySearchResultItem class]])
//                    {
//                        id documentDescription = [strongSelf.companion documentDescriptionFromGiphySearchResult:item];
//                        if (documentDescription != nil)
//                            [imageDescriptions addObject:documentDescription];
//                    }
//                    else if ([item isKindOfClass:[TGWebSearchInternalImageResult class]])
//                    {
//                        id imageDescription = [strongSelf.companion imageDescriptionFromInternalSearchImageResult:item];
//                        if (imageDescription != nil)
//                            [imageDescriptions addObject:imageDescription];
//                    }
//                    else if ([item isKindOfClass:[TGWebSearchInternalGifResult class]])
//                    {
//                        id documentDescription = [strongSelf.companion documentDescriptionFromInternalSearchResult:item];
//                        if (documentDescription != nil)
//                            [imageDescriptions addObject:documentDescription];
//                    }
//                }
//                
//                if (imageDescriptions.count != 0)
//                    [strongSelf.companion controllerWantsToSendImagesWithDescriptions:imageDescriptions];
//            }
        };
        [controllerList addObject:searchController];
        
        TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:controllerList];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        [self presentViewController:navigationController animated:true completion:nil];
    }
    else
    {
        NSMutableArray *controllerList = [[NSMutableArray alloc] init];
        
        TGImageSearchController *searchController = [[TGImageSearchController alloc] initWithAvatarSelection:false];
        searchController.delegate = self;
        searchController.hideSearchControls = true;
        [controllerList addObject:searchController];
        
        TGImagePickerController *imagePicker = [[TGImagePickerController alloc] initWithGroupUrl:nil groupTitle:nil avatarSelection:false];
        imagePicker.delegate = self;
        [controllerList addObject:imagePicker];
        
        TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:controllerList];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        [self presentViewController:navigationController animated:true completion:nil];
    }
}

- (void)handleKeyboardFrameChangeNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    self.keyboardOriginY = endFrame.origin.y;
    [self updateUserInterface];
}

- (void)updateUserInterface
{
    void(^animations)() = ^{
        CGRect frame = self.contentTextView.frame;
        frame.size.height = self.keyboardOriginY - 64 - 10;
        if (self.attachmentButton) {
            frame.size.height -= self.attachmentButton.frame.size.height;
        }
        if (self.selectedImages.count > 0 || self.linkView.ready) {
            frame.size.height -= self.imagesView.frame.size.height;
        }
        self.contentTextView.frame = frame;
        if (self.attachmentButton) {
            self.attachmentButton.frame = CGRectMake(0, self.contentTextView.frame.origin.y+self.contentTextView.frame.size.height, 54, 40);
        }
        if (self.imagesView) {
            CGRect frame = self.imagesView.frame;
            frame.origin.y = self.attachmentButton.frame.origin.y + self.attachmentButton.frame.size.height;
            self.imagesView.frame = frame;
        }
        if (self.linkView) {
            self.linkView.frame = self.imagesView.frame;
        }
        if (self.selectedImages.count > 0) {
            self.imagesView.alpha = 1.0f;
        }else{
            self.imagesView.alpha = 0.0f;
        }
        if (self.linkView.ready) {
            self.linkView.alpha = 1.0f;
        }else{
            self.linkView.alpha = 0.0f;
        }
    };
    
    void(^completion)(BOOL) = ^(BOOL __unused finished){
    };
    
    [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:animations completion:completion];
}

- (NSDictionary *)imageDescriptionFromImage:(UIImage *)image optionalAssetUrl:(NSString *)assetUrl
{
    if (image == nil)
        return nil;
    
//    NSDictionary *serverData = [TGImageDownloadActor serverMediaDataForAssetUrl:assetUrl];
    if (false)
    {    //we don't want remote image
//        if ([serverData objectForKey:@"imageId"] != nil && [serverData objectForKey:@"imageAttachment"] != nil)
//        {
//            TGImageMediaAttachment *imageAttachment = [serverData objectForKey:@"imageAttachment"];
//            if (imageAttachment != nil && imageAttachment.imageInfo != nil)
//            {
//                return @{
//                         @"remoteImage": @{
//                                 @"imageId": @(imageAttachment.imageId),
//                                 @"accessHash": @(imageAttachment.accessHash),
//                                 @"imageInfo": imageAttachment.imageInfo
//                                 }
//                         };
//            }
//        }
    }
    else
    {
        CGSize originalSize = image.size;
        originalSize.width *= image.scale;
        originalSize.height *= image.scale;
        
        CGSize imageSize = TGFitSize(originalSize, CGSizeMake(1280, 1280));
        CGSize thumbnailSize = TGFitSize(originalSize, CGSizeMake(90, 90));
        
        UIImage *fullImage = TGScaleImageToPixelSize(image, imageSize);
        NSData *imageData = UIImageJPEGRepresentation(fullImage, 0.54f);
        
        UIImage *previewImage = TGScaleImageToPixelSize(fullImage, TGFitSize(originalSize, [TGViewController isWidescreen] ? CGSizeMake(220, 220) : CGSizeMake(180, 180)));
        NSData *thumbnailData = UIImageJPEGRepresentation(previewImage, 0.9f);
        
        previewImage = nil;
        fullImage = nil;
        
        if (imageData != nil && thumbnailData != nil)
        {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{
                                                                                          @"imageSize": [NSValue valueWithCGSize:imageSize],
                                                                                          @"thumbnailSize": [NSValue valueWithCGSize:thumbnailSize],
                                                                                          @"imageData": imageData,
                                                                                          @"thumbnailData": thumbnailData
                                                                                          }];
            
            if (assetUrl != nil)
                dict[@"assetUrl"] = assetUrl;
            
            return @{@"localImage": dict};
        }
    }
    
    return nil;
}

- (void)addImages:(NSMutableArray *)images
{
    [images enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
        NSDictionary *imageDict = (NSDictionary *)obj;
        [self.selectedImages addObject:[imageDict mutableCopy]];
    }];
    
    self.imagesView.images = self.selectedImages;
    
    if (self.selectedImages.count > 0) {
        self.linkView.ready = NO;
    }
    
    [self updateUserInterface];
    
    [self checkPublishStatus];
}

#pragma mark - TGLegacyCameraControllerDelegate
- (void)legacyCameraControllerCompletedWithNoResult
{
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - TGImagePickerControllerDelegate
- (void)imagePickerController:(TGImagePickerController *)__unused imagePicker didFinishPickingWithAssets:(NSArray *)assets
{
    NSMutableArray *imageDescriptions = [NSMutableArray array];
    
    for (id abstractAsset in assets) {
        if ([abstractAsset isKindOfClass:[UIImage class]]) {
            @autoreleasepool
            {
                NSDictionary *imageDescription = [self imageDescriptionFromImage:abstractAsset optionalAssetUrl:nil];
                if (imageDescription != nil)
                    [imageDescriptions addObject:imageDescription];
            }
        }else if ([abstractAsset isKindOfClass:[TGImagePickerAsset class]]){
            @autoreleasepool
            {
                TGImagePickerAsset *asset = abstractAsset;
                
                CC_MD5_CTX md5;
                CC_MD5_Init(&md5);
                
                NSData *metadataData = [[self _dictionaryString:asset.asset.defaultRepresentation.metadata] dataUsingEncoding:NSUTF8StringEncoding];
                CC_MD5_Update(&md5, [metadataData bytes], metadataData.length);
                
                NSData *uriData = [asset.assetUrl dataUsingEncoding:NSUTF8StringEncoding];
                CC_MD5_Update(&md5, [uriData bytes], uriData.length);
                
                int64_t size = asset.asset.defaultRepresentation.size;
                const int64_t batchSize = 4 * 1024;
                
                uint8_t *buf = (uint8_t *)malloc(batchSize);
                NSError *error = nil;
                for (int64_t offset = 0; offset < batchSize; offset += batchSize)
                {
                    NSUInteger length = [asset.asset.defaultRepresentation getBytes:buf fromOffset:offset length:((NSUInteger)(MIN(batchSize, size - offset))) error:&error];
                    CC_MD5_Update(&md5, buf, length);
                }
                free(buf);
                
                unsigned char md5Buffer[16];
                CC_MD5_Final(md5Buffer, &md5);
                NSString *hash = [[NSString alloc] initWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", md5Buffer[0], md5Buffer[1], md5Buffer[2], md5Buffer[3], md5Buffer[4], md5Buffer[5], md5Buffer[6], md5Buffer[7], md5Buffer[8], md5Buffer[9], md5Buffer[10], md5Buffer[11], md5Buffer[12], md5Buffer[13], md5Buffer[14], md5Buffer[15]];
                
                UIImage *image = [[UIImage alloc] initWithCGImage:asset.asset.defaultRepresentation.fullScreenImage];
                
                if (image != nil)
                {
                    NSDictionary *imageDescription = [self imageDescriptionFromImage:image optionalAssetUrl:hash];
                    if (imageDescription != nil)
                        [imageDescriptions addObject:imageDescription];
                }
            }
        }
    }
    
    if (imageDescriptions.count != 0) {
        [self addImages:imageDescriptions];
    }
    
    [self dismissViewControllerAnimated:true completion:nil];
}

- (NSString *)_dictionaryString:(NSDictionary *)dict
{
    NSMutableString *string = [[NSMutableString alloc] init];
    
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id value, __unused BOOL *stop)
     {
         if ([key isKindOfClass:[NSString class]])
             [string appendString:key];
         else if ([key isKindOfClass:[NSNumber class]])
             [string appendString:[key description]];
         [string appendString:@":"];
         
         if ([value isKindOfClass:[NSString class]])
             [string appendString:value];
         else if ([value isKindOfClass:[NSNumber class]])
             [string appendString:[value description]];
         else if ([value isKindOfClass:[NSDictionary class]])
         {
             [string appendString:@"{"];
             [string appendString:[self _dictionaryString:value]];
             [string appendString:@"}"];
         }
         
         [string appendString:@";"];
     }];
    
    return string;
}

@end
