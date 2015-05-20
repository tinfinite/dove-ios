#import "TGPhotoMessageViewModel.h"

#import "TGModernViewContext.h"

#import "TGModernRemoteImageView.h"
#import "TGMessageImageViewModel.h"
#import "TGModernRemoteImageViewModel.h"
#import "TGModernImageViewModel.h"
#import "TGModernColorViewModel.h"
#import "TGModernButtonViewModel.h"

#import "TGMessage.h"

#import "TGStringUtils.h"
#import "TGDateUtils.h"

@interface TGPhotoMessageViewModel ()
{
    TGImageMediaAttachment *_imageMedia;
    
//    TGModernButtonViewModel *_bgModel;
//    TGModernButtonViewModel *_imageVoteButtonModel;
//    TGModernImageViewModel *_arrowUpModel;
//    TGModernImageViewModel *_arrowDownModel;
}

@end

@implementation TGPhotoMessageViewModel

- (instancetype)initWithMessage:(TGMessage *)message imageMedia:(TGImageMediaAttachment *)imageMedia author:(TGUser *)author context:(TGModernViewContext *)context
{
    TGImageInfo *previewImageInfo = imageMedia.imageInfo;
    
    CGSize largestSize = CGSizeZero;
    NSString *legacyCacheUrl = [imageMedia.imageInfo closestImageUrlWithSize:CGSizeMake(1136, 1136) resultingSize:&largestSize pickLargest:true];
    NSString *legacyThumbnailCacheUrl = [imageMedia.imageInfo closestImageUrlWithSize:CGSizeZero resultingSize:NULL];
    
    int64_t localImageId = 0;
    if (imageMedia.imageId == 0 && legacyCacheUrl.length != 0)
    {
        localImageId = murMurHash32(legacyCacheUrl);
    }
    
    if (legacyCacheUrl != nil && (imageMedia.imageId != 0 || localImageId != 0))
    {
        previewImageInfo = [[TGImageInfo alloc] init];
        
        NSMutableString *previewUri = [[NSMutableString alloc] initWithString:@"photo-thumbnail://?"];
        if (imageMedia.imageId != 0)
            [previewUri appendFormat:@"id=%" PRId64 "", imageMedia.imageId];
        else
            [previewUri appendFormat:@"local-id=%" PRId64 "", localImageId];
        
        CGSize thumbnailSize = CGSizeZero;
        CGSize renderSize = CGSizeZero;
        [TGImageMessageViewModel calculateImageSizesForImageSize:largestSize thumbnailSize:&thumbnailSize renderSize:&renderSize squareAspect:message.messageLifetime > 0 && message.messageLifetime <= 60 && message.layer >= 17];
        
        [previewUri appendFormat:@"&width=%d&height=%d&renderWidth=%d&renderHeight=%d", (int)thumbnailSize.width, (int)thumbnailSize.height, (int)renderSize.width, (int)renderSize.height];
        
        NSString *legacyFilePath = nil;
        if ([legacyCacheUrl hasPrefix:@"file://"])
            legacyFilePath = [legacyCacheUrl substringFromIndex:@"file://".length];
        else
            legacyFilePath = [[TGRemoteImageView sharedCache] pathForCachedData:legacyCacheUrl];
        
        if (legacyFilePath != nil)
            [previewUri appendFormat:@"&legacy-file-path=%@", legacyFilePath];
        
        if (legacyThumbnailCacheUrl != nil)
            [previewUri appendFormat:@"&legacy-thumbnail-cache-url=%@", [TGStringUtils stringByEscapingForURL:legacyThumbnailCacheUrl]];
        
        if (message.messageLifetime > 0 && message.messageLifetime <= 60 && message.layer >= 17)
            [previewUri appendString:@"&secret=1"];
        
        [previewImageInfo addImageWithSize:thumbnailSize url:previewUri];
    }
    
    self = [super initWithMessage:message imageInfo:previewImageInfo author:author context:context];
    if (self != nil)
    {
        _imageMedia = imageMedia;
        
        if (message.messageLifetime > 0 && message.messageLifetime <= 60 && message.layer >= 17)
        {
            self.isSecret = true;
            
            [self enableInstantPreview];
        }
        
        if (self.isSecret)
            [self.imageModel setAdditionalDataString:[self defaultAdditionalDataString]];
        
//        if (!message.outgoing && message.cid == message.toUid) {
//            _bgModel = [[TGModernButtonViewModel alloc] init];
//            _bgModel.backgroundImage = [[UIImage imageNamed:@"image_vote_bg"] stretchableImageWithLeftCapWidth:0 topCapHeight:16];
//            [self.imageModel addSubmodel:_bgModel];
//            
//            _imageVoteButtonModel = [[TGModernButtonViewModel alloc] init];
//            [self addSubmodel:_imageVoteButtonModel];
//            
//            _arrowUpModel = [[TGModernImageViewModel alloc] init];
//            [self.imageModel addSubmodel:_arrowUpModel];
//            
//            _arrowDownModel = [[TGModernImageViewModel alloc] init];
//            [self.imageModel addSubmodel:_arrowDownModel];
//        }
    }
    return self;
}

- (void)updateMessage:(TGMessage *)message viewStorage:(TGModernViewStorage *)viewStorage
{
    [super updateMessage:message viewStorage:viewStorage];
    
    TGImageMediaAttachment *imageMedia = nil;
    for (id attachment in message.mediaAttachments)
    {
        if ([attachment isKindOfClass:[TGImageMediaAttachment class]])
        {
            imageMedia = attachment;
            break;
        }
    }
    
    if (imageMedia != nil)
    {
        TGImageInfo *previewImageInfo = imageMedia.imageInfo;
        
        CGSize largestSize = CGSizeZero;
        NSString *legacyCacheUrl = [imageMedia.imageInfo closestImageUrlWithSize:CGSizeMake(1136, 1136) resultingSize:&largestSize pickLargest:true];
        NSString *legacyThumbnailCacheUrl = [imageMedia.imageInfo closestImageUrlWithSize:CGSizeZero resultingSize:NULL];
        
        int64_t localImageId = 0;
        if (imageMedia.imageId == 0 && legacyCacheUrl.length != 0)
        {
            localImageId = murMurHash32(legacyCacheUrl);
        }
        
        if (legacyCacheUrl != nil && (imageMedia.imageId != 0 || localImageId != 0))
        {
            previewImageInfo = [[TGImageInfo alloc] init];
            
            NSMutableString *previewUri = [[NSMutableString alloc] initWithString:@"photo-thumbnail://?"];
            if (imageMedia.imageId != 0)
                [previewUri appendFormat:@"id=%" PRId64 "", imageMedia.imageId];
            else
                [previewUri appendFormat:@"local-id=%" PRId64 "", localImageId];
            
            CGSize thumbnailSize = CGSizeZero;
            CGSize renderSize = CGSizeZero;
            [TGImageMessageViewModel calculateImageSizesForImageSize:largestSize thumbnailSize:&thumbnailSize renderSize:&renderSize squareAspect:message.messageLifetime > 0 && message.messageLifetime <= 60 && message.layer >= 17];
            
            [previewUri appendFormat:@"&width=%d&height=%d&renderWidth=%d&renderHeight=%d", (int)thumbnailSize.width, (int)thumbnailSize.height, (int)renderSize.width, (int)renderSize.height];
            
            NSString *legacyFilePath = nil;
            if ([legacyCacheUrl hasPrefix:@"file://"])
                legacyFilePath = [legacyCacheUrl substringFromIndex:@"file://".length];
            else
                legacyFilePath = [[TGRemoteImageView sharedCache] pathForCachedData:legacyCacheUrl];
            
            if (legacyFilePath != nil)
                [previewUri appendFormat:@"&legacy-file-path=%@", legacyFilePath];
            
            if (legacyThumbnailCacheUrl != nil)
                [previewUri appendFormat:@"&legacy-thumbnail-cache-url=%@", [TGStringUtils stringByEscapingForURL:legacyThumbnailCacheUrl]];
            
            if (message.messageLifetime > 0 && message.messageLifetime <= 60 && message.layer >= 17)
                [previewUri appendString:@"&secret=1"];
            
            [previewImageInfo addImageWithSize:renderSize url:previewUri];
        }
        
        [self updateImageInfo:previewImageInfo];
    }
}

- (void)updateMessageAttributes
{
    [super updateMessageAttributes];
    
    //_overlayIconModel.hidden = [_context isSecretMessageViewed:_mid];
    //_overlayIconMaskLeftModel.hidden = [_context isSecretMessageScreenshotted:_mid];
    //_overlayIconMaskRightModel.hidden = _overlayIconMaskLeftModel.hidden;
    //_overlayIconMaskTopModel.hidden = _overlayIconMaskLeftModel.hidden;
    //_overlayIconMaskBottomModel.hidden = _overlayIconMaskLeftModel.hidden;
}

- (bool)instantPreviewGesture
{
    return false;
}

- (void)bindSpecialViewsToContainer:(UIView *)container viewStorage:(TGModernViewStorage *)viewStorage atItemPosition:(CGPoint)itemPosition
{
    [super bindSpecialViewsToContainer:container viewStorage:viewStorage atItemPosition:itemPosition];
}

- (void)setVoteInfoWithMessage:(TGMessage *)msg
{
    NSString *pointStr = [NSString stringWithFormat:@"%@%@",[msg getPointsString],[TGDateUtils stringForShortTime:(int)msg.date]];
    [self.imageModel setTimestampString:pointStr displayCheckmarks:msg.outgoing && msg.deliveryState != TGMessageDeliveryStateFailed checkmarkValue:(!msg.outgoing ? 0 : ((msg.deliveryState == TGMessageDeliveryStateDelivered ? 1 : 0) + (!msg.unread ? 1 : 0))) animated:false];
    
//    if (count == 0) {
//        _bgModel.title = @"";
//        
//        CGRect arrowUpFrame = _arrowUpModel.frame;
//        arrowUpFrame.origin.y = _bgModel.frame.origin.y+_bgModel.frame.size.height/2-15;
//        _arrowUpModel.frame = arrowUpFrame;
//        
//        CGRect arrowDownFrame = _arrowDownModel.frame;
//        arrowDownFrame.origin.y = _bgModel.frame.origin.y+_bgModel.frame.size.height/2+9;
//        _arrowDownModel.frame = arrowDownFrame;
//    }else{
//        _bgModel.title = @(count).stringValue;
//        
//        CGRect arrowUpFrame = _arrowUpModel.frame;
//        arrowUpFrame.origin.y = _bgModel.frame.origin.y+_bgModel.frame.size.height/2-23;
//        _arrowUpModel.frame = arrowUpFrame;
//        
//        CGRect arrowDownFrame = _arrowDownModel.frame;
//        arrowDownFrame.origin.y = _bgModel.frame.origin.y+_bgModel.frame.size.height/2+17;
//        _arrowDownModel.frame = arrowDownFrame;
//    }
    
//    if (_arrowUpModel.boundView != nil) {
//        if (up) {
//            ((UIImageView *)_arrowUpModel.boundView).image = [UIImage imageNamed:@"chat_vote_uparrow_s"];
//            ((UIImageView *)_arrowDownModel.boundView).image = [UIImage imageNamed:@"chat_vote_downarrow_white"];
//        }else if (down) {
//            ((UIImageView *)_arrowUpModel.boundView).image = [UIImage imageNamed:@"chat_vote_uparrow_white"];
//            ((UIImageView *)_arrowDownModel.boundView).image = [UIImage imageNamed:@"chat_vote_downarrow_s"];
//        }else{
//            ((UIImageView *)_arrowUpModel.boundView).image = [UIImage imageNamed:@"chat_vote_uparrow_white"];
//            ((UIImageView *)_arrowDownModel.boundView).image = [UIImage imageNamed:@"chat_vote_downarrow_white"];
//        }
//    }else{
//        if (up) {
//            _arrowUpModel.image = [UIImage imageNamed:@"chat_vote_uparrow_s"];
//            _arrowDownModel.image = [UIImage imageNamed:@"chat_vote_downarrow_white"];
//        }else if (down) {
//            _arrowUpModel.image = [UIImage imageNamed:@"chat_vote_uparrow_white"];
//            _arrowDownModel.image = [UIImage imageNamed:@"chat_vote_downarrow_s"];
//        }else{
//            _arrowUpModel.image = [UIImage imageNamed:@"chat_vote_uparrow_white"];
//            _arrowDownModel.image = [UIImage imageNamed:@"chat_vote_downarrow_white"];
//        }
//    }
}

- (void)bindViewToContainer:(UIView *)container viewStorage:(TGModernViewStorage *)viewStorage
{
    [super bindViewToContainer:container viewStorage:viewStorage];
    
//    if (_imageVoteButtonModel != nil) {
//        [(UIButton *)_imageVoteButtonModel.boundView addTarget:self action:@selector(voteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//        [self updateVoteInfo];
//    }
}

- (void)unbindView:(TGModernViewStorage *)viewStorage
{
//    if (_imageVoteButtonModel != nil) {
//        [(UIButton *)_imageVoteButtonModel.boundView removeTarget:self action:@selector(voteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//    }

    [super unbindView:viewStorage];
}

- (void)layoutForContainerSize:(CGSize)containerSize
{
    [super layoutForContainerSize:containerSize];
    
//    TGMessageViewModelLayoutConstants const *layoutConstants = TGGetMessageViewModelLayoutConstants();
//    CGFloat topSpacing = (_collapseFlags) ? layoutConstants->topInsetCollapsed : layoutConstants->topInset;
//    
//    if (_bgModel != nil) {
//        _bgModel.frame = CGRectMake(self.imageModel.frame.size.width-35-6, 6, 35, 70);
//    }
//    
//    if (_imageVoteButtonModel != nil) {
//        _imageVoteButtonModel.frame = CGRectMake(self.imageModel.frame.origin.x+self.imageModel.frame.size.width-35-6, topSpacing+6, 35, 70);
//    }
//    
//    if (_arrowDownModel != nil) {
//        _arrowDownModel.frame = CGRectMake(_bgModel.frame.origin.x+11, _bgModel.frame.origin.y+_bgModel.frame.size.height/2+9, 12, 6);
//    }
//    
//    if (_arrowUpModel != nil) {
//        _arrowUpModel.frame = CGRectMake(_bgModel.frame.origin.x+11, _bgModel.frame.origin.y+_bgModel.frame.size.height/2-15, 12, 6);
//    }
}

@end
