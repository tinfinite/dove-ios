//
//  TGForwardStreamController.m
//  Telegraph
//
//  Created by yewei on 15/3/25.
//
//

#import "TGForwardStreamController.h"
#import "TGInterfaceAssets.h"
#import "SZTextView.h"
#import "TGObserverProxy.h"
#import "TGMessage.h"
#import "TGUser.h"
#import "TGDatabase.h"
#import "T8NodeHttpRequestService.h"
#import "NSMutableDictionary+Ext.h"
#import "T8JsonHelper.h"
#import "TGConversation.h"
#import "TGVoteInfoObject.h"
#import "TGRemoteImageView.h"
#import "TGImageManager.h"
#import "T8ImageUploadManager.h"
#import "TGImageView.h"
#import "TGImageMessageViewModel.h"
#import "TGStringUtils.h"

#import "TGPreparedLocalDocumentMessage.h"

@interface TGForwardStreamController ()
{
    TGObserverProxy *_keyboardWillChangeFrameProxy;
}

@property (nonatomic, strong) SZTextView *contentTextView;
@property (nonatomic, strong) UIView *postView;
@property (nonatomic, strong) UIImageView *checkbox;
@property (nonatomic, assign) BOOL postToPublic;

@property (nonatomic, strong) NSArray *postMessages;
@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic) int64_t conversationId;

@property (nonatomic, strong) UIImage *groupAvatar;

@end

@implementation TGForwardStreamController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_contentTextView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_contentTextView resignFirstResponder];
}

- (id)initWithPostMessages:(NSArray *)postMessages conversationId:(int64_t)conversationId groupAvatar:(UIImage *)groupAvatar
{
    self = [super init];
    if (self)
    {
        _keyboardWillChangeFrameProxy = [[TGObserverProxy alloc] initWithTarget:self targetSelector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification];
        self.postMessages = [NSArray arrayWithArray:postMessages];
        self.conversationId = conversationId;
        self.groupAvatar = groupAvatar;
    }
    return self;
}

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setTitleText:TGLocalized(@"Stream.PublishTitle")];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Stream.Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Stream.Post") style:UIBarButtonItemStylePlain target:self action:@selector(postButtonPressed)];
    
    _contentTextView = [[SZTextView alloc] init];
    _contentTextView.placeholder = TGLocalized(@"Stream.PublishPlaceHolder");
    _contentTextView.frame = CGRectMake(12, 66+10, [UIScreen mainScreen].bounds.size.width-24, [UIScreen mainScreen].bounds.size.height-66-20);
    _contentTextView.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:_contentTextView];
    
    [self.view addSubview:self.postView];
}

- (UIView *)postView
{
    if (!_postView) {
        _postView = [[UIView alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, 75)];
//        _checkbox = [[UIImageView alloc] initWithFrame:CGRectMake(15, 12, 17, 17)];
//        _checkbox.image = [UIImage imageNamed:@"stream_checkbox_unselect"];
//        [_postView addSubview:_checkbox];
        
//        UILabel *notice = [[UILabel alloc] initWithFrame:CGRectMake(40, 12, self.view.frame.size.width - 50, 17)];
//        notice.text = TGLocalized(@"Stream.PostPublicStream");
//        notice.textColor = UIColorRGB(0x4A4A4A);
//        [_postView addSubview:notice];
        
//        UIButton *selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        selectButton.frame = CGRectMake(0, 0, self.view.frame.size.width, 45);
//        [selectButton addTarget:self action:@selector(selectButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//        [_postView addSubview:selectButton];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
        lineView.backgroundColor = UIColorRGB(0xD2D2D2);
        [_postView addSubview:lineView];
        
        UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake(0, 1, self.view.frame.size.width, 75)];
        messageView.backgroundColor = UIColorRGB(0xFAFAFA);
        
        TGMessage *message = [self.postMessages objectAtIndex:0];
        TGUser *user = [TGDatabaseInstance() loadUser:(int)message.fromUid];
        
        UILabel *nameLabel = [[UILabel alloc] init];
        if (user.userName && ![user.userName isEqualToString:@""]) {
            nameLabel.text = [NSString stringWithFormat:@"@%@",user.userName];
        }else{
            nameLabel.text = [NSString stringWithFormat:@"%@ %@",user.firstName,user.lastName];
        }
        nameLabel.font = [UIFont systemFontOfSize:13];
        CGSize nameLabelSize = [nameLabel sizeThatFits:CGSizeMake(200, 13)];
        nameLabel.frame = CGRectMake(15, 10, nameLabelSize.width, nameLabelSize.height);
        [messageView addSubview:nameLabel];
        
        UILabel *messageCountLabel = [[UILabel alloc] init];
        if (self.postMessages.count > 1) {
            messageCountLabel.text = [NSString stringWithFormat:@"%lu messages",(unsigned long)self.postMessages.count];
        }
        messageCountLabel.font = [UIFont systemFontOfSize:13];
        CGSize messageCountLabelSize = [messageCountLabel sizeThatFits:CGSizeMake(200, 13)];
        messageCountLabel.frame = CGRectMake(self.view.frame.size.width - messageCountLabelSize.width - 15, 10, messageCountLabelSize.width, messageCountLabelSize.height);
        [messageView addSubview:messageCountLabel];
        
        UILabel *messageLabel = [[UILabel alloc] init];
        messageLabel.text = message.text;
        messageLabel.textColor = UIColorRGB(0x4A4A4A);
        messageLabel.font = [UIFont systemFontOfSize:15];
        messageLabel.numberOfLines = 0;
        CGSize messageLabelSize = [messageLabel sizeThatFits:CGSizeMake(self.view.frame.size.width-30, 15)];
        if (messageLabelSize.height > 36) {
            messageLabel.frame = CGRectMake(15, 28, messageLabelSize.width, 33.5);
        }else{
            messageLabel.frame = CGRectMake(15, 28, messageLabelSize.width, messageLabelSize.height);
        }
        [messageView addSubview:messageLabel];
        
        if (messageLabelSize.height < 36 && self.postMessages.count > 1) {
            UILabel *ellipsisLabel = [[UILabel alloc] init];
            ellipsisLabel.text = @"...";
            ellipsisLabel.textColor = UIColorRGB(0x4A4A4A);
            ellipsisLabel.font = [UIFont systemFontOfSize:15];
            ellipsisLabel.frame = CGRectMake(15, 48, 100, 18);
            [messageView addSubview:ellipsisLabel];
        }
        
        [_postView addSubview:messageView];
    }
    return _postView;
}

#pragma mark -

- (void)controllerInsetUpdated:(UIEdgeInsets)__unused previousInset
{
    
}

- (void)cancelButtonPressed
{
    [self dismissSelf];
}

- (void)dismissSelf
{
    [self.presentingViewController dismissViewControllerAnimated:true completion:nil];
}

- (void)postButtonPressed
{
    PostPublishType isPublic;
    if (_postToPublic)
    {
        isPublic = PostPublishTypeBoth;
    }else{
        isPublic = PostPublishTypeGroupBoard;
    }
    BOOL hasImage = NO;
    NSMutableArray *contentArray = [[NSMutableArray alloc] init];
    
    for (TGMessage *message in self.postMessages)
    {
        TGUser *user = [TGDatabaseInstance() loadUser:(int)message.fromUid];
        
        NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @(user.uid).stringValue, @"user_id",
                                  user.firstName, @"first_name",
                                  user.lastName, @"last_name",
                                  user.userName, @"username", nil];
        
        TGVoteInfoObject *object = [message.contentProperties objectForKey:StoreKey_MessageVoteInfo];
        
        NSInteger messageType = 1;
        if (message.mediaAttachments.count) {
            for (TGMediaAttachment *attachment in message.mediaAttachments)
            {
                if (attachment.type == TGImageMediaAttachmentType)
                {
                    TGImageMediaAttachment *imageMedia = (TGImageMediaAttachment *)attachment;
                    TGImageInfo *legacyImageInfo = imageMedia.imageInfo;
                    CGSize imageSize = CGSizeZero;
                    NSString *legacyCacheUrl = [legacyImageInfo closestImageUrlWithSize:CGSizeMake(1000.0f, 1000.0f) resultingSize:&imageSize];
                    NSString *legacyThumbnailCacheUrl = [legacyImageInfo closestImageUrlWithSize:CGSizeZero resultingSize:NULL];
                    
                    NSString *legacyFilePath = nil;
                    if ([legacyCacheUrl hasPrefix:@"file://"])
                        legacyFilePath = [legacyCacheUrl substringFromIndex:@"file://".length];
                    else
                        legacyFilePath = [[TGRemoteImageView sharedCache] pathForCachedData:legacyCacheUrl];
                    
                    NSMutableString *imageUri = [[NSMutableString alloc] init];
                    [imageUri appendString:@"media-gallery-image://?"];
                    if (imageMedia.imageId != 0)
                        [imageUri appendFormat:@"&id=%" PRId64 "", imageMedia.imageId];
                    [imageUri appendFormat:@"&legacy-file-path=%@", legacyFilePath];
                    
                    NSString *escapedLegacyThumbnailCacheUrl = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)legacyThumbnailCacheUrl, (__bridge CFStringRef)@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-", (__bridge CFStringRef)@"&?= ", kCFStringEncodingUTF8);
                    [imageUri appendFormat:@"&legacy-thumbnail-cache-url=%@", escapedLegacyThumbnailCacheUrl];
                    
                    [imageUri appendFormat:@"&width=%d", (int)imageSize.width];
                    [imageUri appendFormat:@"&height=%d", (int)imageSize.height];
                    [imageUri appendFormat:@"&renderWidth=%d", (int)imageSize.width];
                    [imageUri appendFormat:@"&renderHeight=%d", (int)imageSize.height];
                    
                    [imageUri appendFormat:@"&messageId=%" PRId32 "", (int32_t)message.mid];
                    [imageUri appendFormat:@"&conversationId=%" PRId64 "", (int64_t)self.conversationId];
                    
                    NSString *escapedCacheUrl = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)legacyCacheUrl, (__bridge CFStringRef)@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-", (__bridge CFStringRef)@"&?= :/", kCFStringEncodingUTF8);
                    [imageUri appendFormat:@"&legacy-cache-url=%@", escapedCacheUrl];
                    
                    UIImage *image = [self loadUri:imageUri withOptions:@{TGImageViewOptionSynchronous: @(true)}];
                    messageType = 2;
                    NSMutableDictionary *messageDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                        userDict, @"user",
                                                        image, @"messagecontent",
                                                        @(messageType), @"messagetype",
                                                        @(object.count), @"messaegpoint",
                                                        @(message.date), @"messagetime",
                                                        @(message.mid), @"messageId", nil];
                    [contentArray addObject:messageDict];
                    
                    hasImage = YES;
                }else if (attachment.type == TGDocumentMediaAttachmentType){
                    TGDocumentMediaAttachment *documentAttachment = (TGDocumentMediaAttachment *)attachment;
                    
                    NSString *filePath = @"";
                    
                    if (documentAttachment.localDocumentId != 0)
                    {
                        filePath = [[TGPreparedLocalDocumentMessage localDocumentDirectoryForLocalDocumentId:documentAttachment.localDocumentId] stringByAppendingPathComponent:[documentAttachment safeFileName]];
                    }
                    else
                    {
                        filePath = [[TGPreparedLocalDocumentMessage localDocumentDirectoryForDocumentId:documentAttachment.documentId] stringByAppendingPathComponent:[documentAttachment safeFileName]];
                    }
                    
                    messageType = 2;
                    
                    NSMutableDictionary *messageDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                        userDict, @"user",
                                                        filePath, @"messagecontent",
                                                        @(messageType), @"messagetype",
                                                        @(object.count), @"messaegpoint",
                                                        @(message.date), @"messagetime",
                                                        @(message.mid), @"messageId", nil];
                    [contentArray addObject:messageDict];
                    
                    hasImage = YES;
                }
            }
        }else{
            NSMutableDictionary *messageDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                userDict, @"user",
                                                message.text, @"messagecontent",
                                                @(messageType), @"messagetype",
                                                @(object.count), @"messaegpoint",
                                                @(message.date), @"messagetime",
                                                @(message.mid), @"messageId", nil];
            [contentArray addObject:messageDict];

        }
    }
    
    [T8HudHelper showHUDActivity:self.view];
    __weak typeof(self) weakSelf = self;
    
    if (hasImage) {
        [[T8ImageUploadManager sharedInstance] uploadForwardImagesBatch:contentArray result:^(BOOL result) {
            if (result) {
                __strong typeof(self) strongSelf = weakSelf;
                [[T8ImageUploadManager sharedInstance] uploadImage:strongSelf.groupAvatar tmpName:@(_conversationId).stringValue successBlock:^(NSString *url) {
                    
                    TGConversation *conversation = [TGDatabaseInstance() loadConversationWithId:strongSelf.conversationId];
                    NSDictionary *forwardDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 contentArray, @"content",
                                                 _contentTextView.text, @"comment",
                                                 @(ABS(conversation.conversationId)), @"third_group_id",
                                                 conversation.chatTitle, @"third_group_name",
                                                 url, @"third_group_image", nil];
                    
                    NSString *forwardString = [T8JsonHelper getJsonStringWithObject:forwardDict];
                    
                    [T8NodeHttpRequestService publishNodeWithForward:forwardString post:@"" isPublic:isPublic type:1 groupId:_conversationId successBlock:^(NSDictionary *dictRet) {
                        [T8HudHelper hideHUDActivity:self.view];
                        [T8HudHelper showHUDMessage:TGLocalized(@"Stream.PublishSuccess")];
                        [strongSelf dismissSelf];
                        [T8Common storeNodeAfterPublishWithForward:forwardString post:@"" isPublic:isPublic type:1 groupId:_conversationId successData:dictRet];
                    } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                        [T8HudHelper hideHUDActivity:self.view];
                        [T8HudHelper showHUDMessage:TGLocalized(@"Stream.PublishFail")];
                    }];
                } failureBlock:^{
                    [T8HudHelper hideHUDActivity:self.view];
                    [T8HudHelper showHUDMessage:TGLocalized(@"Stream.PublishFail")];
                }];
            }else{
                [T8HudHelper hideHUDActivity:self.view];
                [T8HudHelper showHUDMessage:TGLocalized(@"Stream.PublishFail")];
            }
        }];
    }else{
        [[T8ImageUploadManager sharedInstance] uploadImage:self.groupAvatar tmpName:@(_conversationId).stringValue successBlock:^(NSString *url) {
            __strong typeof(self) strongSelf = weakSelf;
            TGConversation *conversation = [TGDatabaseInstance() loadConversationWithId:strongSelf.conversationId];
            NSDictionary *forwardDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                         contentArray, @"content",
                                         _contentTextView.text, @"comment",
                                         @(ABS(conversation.conversationId)), @"third_group_id",
                                         conversation.chatTitle, @"third_group_name",
                                         url, @"third_group_image", nil];
            
            NSString *forwardString = [T8JsonHelper getJsonStringWithObject:forwardDict];
            
            [T8NodeHttpRequestService publishNodeWithForward:forwardString post:@"" isPublic:isPublic type:1 groupId:_conversationId successBlock:^(NSDictionary *dictRet) {
                [T8HudHelper hideHUDActivity:self.view];
                [T8HudHelper showHUDMessage:TGLocalized(@"Stream.PublishSuccess")];
                [strongSelf dismissSelf];
                [T8Common storeNodeAfterPublishWithForward:forwardString post:@"" isPublic:isPublic type:1 groupId:_conversationId successData:dictRet];
            } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                [T8HudHelper hideHUDActivity:self.view];
                [T8HudHelper showHUDMessage:TGLocalized(@"Stream.PublishFail")];
            }];
        } failureBlock:^{
            [T8HudHelper hideHUDActivity:self.view];
            [T8HudHelper showHUDMessage:TGLocalized(@"Stream.PublishFail")];
        }];

    }
    
    NSMutableDictionary *event =
    [[GAIDictionaryBuilder createEventWithCategory:@"聊天页面"
                                            action:@"转发消息到信息流"
                                             label:@""
                                             value:nil] build];
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];    
}

- (UIImage *)loadUri:(NSString *)uri withOptions:(NSDictionary *)options
{
    UIImage *image = nil;
    
    if (options[TGImageViewOptionEmbeddedImage] != nil)
    {
        image = options[TGImageViewOptionEmbeddedImage];
    }else{
        __autoreleasing id asyncTaskId = nil;
        image = [[TGImageManager instance] loadImageSyncWithUri:uri canWait:[options[TGImageViewOptionSynchronous] boolValue] decode:true acceptPartialData:true asyncTaskId:&asyncTaskId progress:^(float __unused value){} partialCompletion:^(UIImage __unused *partialImage){} completion:^(UIImage __unused *image){}];
    }
    
    if (image != nil)
        return image;
    else
    {
        if (![options[TGImageViewOptionKeepCurrentImageAsPlaceholder] boolValue])
        {
            UIImage *placeholderImage = [[TGImageManager instance] loadAttributeSyncForUri:uri attribute:@"placeholder"];
            if (placeholderImage != nil)
                return placeholderImage;
            
        }
        return nil;
    }
}

- (void)selectButtonPressed
{
    _postToPublic = !_postToPublic;
    if (_postToPublic) {
        _checkbox.image = [UIImage imageNamed:@"stream_checkbox_select"];
    }else{
        _checkbox.image = [UIImage imageNamed:@"stream_checkbox_unselect"];
    }
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    void(^animations)() = ^{
        CGRect frame = self.contentTextView.frame;
        frame.size.height = endFrame.origin.y - 64 - 20 - 75;
        self.contentTextView.frame = frame;
        
        frame = self.postView.frame;
        frame.origin.y = endFrame.origin.y - 75;
        self.postView.frame = frame;
    };
    
    void(^completion)(BOOL) = ^(BOOL __unused finished){
    };
    
    [UIView animateWithDuration:duration delay:0.0f options:(curve << 16 | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:completion];
}

@end
