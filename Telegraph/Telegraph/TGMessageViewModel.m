#import "TGMessageViewModel.h"

#import "TGImageUtils.h"

#import "TGUser.h"
#import "TGMessage.h"

#import "TGModernViewContext.h"

#import "TGModernRemoteImageViewModel.h"
#import "TGModernButtonViewModel.h"
#import "TGModernCheckButtonViewModel.h"

#import "TGMessageModernConversationItem.h"

#import "TGModernLetteredAvatarViewModel.h"
#import "TGAlertView.h"
#import "T8VoteService.h"
#import "TGDatabase.h"
#import "TGVoteInfoObject.h"
#import "TGVoteView.h"

static CGFloat preferredTextFontSize;

void TGMessageViewModelLayoutSetPreferredTextFontSize(CGFloat fontSize)
{
    preferredTextFontSize = fontSize;
}

static TGMessageViewModelLayoutConstants currentMessageViewModelLayoutConstants;

const TGMessageViewModelLayoutConstants *TGGetMessageViewModelLayoutConstants()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        TGMessageViewModelLayoutConstants constants;
        
        CGFloat minTextFontSize = 0.0f;
        CGFloat maxTextFontSize = 0.0f;
        CGFloat defaultTextFontSize = 0.0f;
        
        CGSize screenSize = TGScreenSize();
        CGFloat screenSide = MAX(screenSize.width, screenSize.height);
        bool isLargeScreen = screenSide >= 667.0f - FLT_EPSILON;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            constants.topInset = 2.0f;
            constants.bottomInset = 2.0f;
            constants.topInsetCollapsed = 1.0f;
            constants.bottomInsetCollapsed = 0.0f;
            
            constants.leftInset = 4.0f;
            constants.rightInset = 4.0f;
            
            constants.leftImageInset = 9.0f;
            constants.rightImageInset = 9.0f;
            
            constants.avatarInset = 3.0f;
            
            constants.textBubblePaddingTop = 5.0f;
            constants.textBubblePaddingBottom = 5.0f;
            constants.textBubbleTextOffsetTop = 1.0f;
            
            minTextFontSize = 12.0f;
            maxTextFontSize = 24.0f;
            
            if (isLargeScreen)
                defaultTextFontSize = 17.0f;
            else
                defaultTextFontSize = 16.0f;
        }
        else
        {
            constants.topInset = 3.0f;
            constants.bottomInset = 3.0f;
            constants.topInsetCollapsed = 1.0f;
            constants.bottomInsetCollapsed = 1.0f;
            
            constants.leftInset = 17.0f;
            constants.rightInset = 17.0f;
            
            constants.leftImageInset = 23.0f;
            constants.rightImageInset = 23.0f;
            
            constants.avatarInset = 11.0f;
            
            constants.textBubblePaddingTop = 5.0f;
            constants.textBubblePaddingBottom = 6.0f;
            constants.textBubbleTextOffsetTop = 1.0f + TGRetinaPixel;
            
            minTextFontSize = 13.0f;
            maxTextFontSize = 25.0f;
            defaultTextFontSize = 17.0f;
        }
        
        if (iosMajorVersion() >= 7 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            CGFloat fontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize - (isLargeScreen ? 0 : 1.0f);
            constants.textFontSize = MAX(minTextFontSize, MIN(maxTextFontSize, fontSize));
        }
        else
        {
            if (preferredTextFontSize == 0)
                constants.textFontSize = defaultTextFontSize;
            else
                constants.textFontSize = MAX(minTextFontSize, MIN(maxTextFontSize, preferredTextFontSize));
        }
        
        currentMessageViewModelLayoutConstants = constants;
    });
    
    return &currentMessageViewModelLayoutConstants;
}

void TGUpdateMessageViewModelLayoutConstants()
{
    CGFloat minTextFontSize = 0.0f;
    CGFloat maxTextFontSize = 0.0f;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        minTextFontSize = 12.0f;
        maxTextFontSize = 24.0f;
    }
    else
    {
        minTextFontSize = 13.0f;
        maxTextFontSize = 25.0f;
    }
    
    CGFloat fontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize - 1.0f;
    currentMessageViewModelLayoutConstants.textFontSize = MAX(minTextFontSize, MIN(maxTextFontSize, fontSize));
}

@interface TGMessageViewModel ()
{
    int _uid;
    NSString *_firstName;
    NSString *_lastName;
    
    TGModernLetteredAvatarViewModel *_avatarModel;
    UITapGestureRecognizer *_boundAvatarTapRecognizer;
    UILongPressGestureRecognizer *_boundAvatarLongPressRecognizer;
    
    TGModernButtonViewModel *_checkAreaModel;
    TGModernCheckButtonViewModel *_checkButtonModel;
}

@end

@implementation TGMessageViewModel

- (instancetype)initWithAuthor:(TGUser *)author context:(TGModernViewContext *)context
{
    self = [super init];
    if (self != nil)
    {
        self.hasNoView = true;
        _context = context;
        
        if (author != nil)
        {
            _uid = author.uid;
            _firstName = author.firstName;
            _lastName = author.lastName;
            
            static UIImage *placeholder = nil;
            static dispatch_once_t onceToken2;
            dispatch_once(&onceToken2, ^
            {
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(40.0f, 40.0f), false, 0.0f);
                CGContextRef context = UIGraphicsGetCurrentContext();
                
                //!placeholder
                CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
                CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 40.0f, 40.0f));
                CGContextSetStrokeColorWithColor(context, UIColorRGB(0xd9d9d9).CGColor);
                CGContextSetLineWidth(context, 1.0f);
                CGContextStrokeEllipseInRect(context, CGRectMake(0.5f, 0.5f, 39.0f, 39.0f));
                
                placeholder = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            });
            
            _avatarModel = [[TGModernLetteredAvatarViewModel alloc] initWithSize:CGSizeMake(38.0f, 38.0f) placeholder:placeholder];
            _avatarModel.skipDrawInContext = true;
            [self addSubmodel:_avatarModel];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleVoteInfoChangedNotification:) name:Notification_Key_Vote_Changed object:nil];
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_Key_Vote_Changed object:nil];
}

- (void)setAuthorAvatarUrl:(NSString *)authorAvatarUrl
{
    if (authorAvatarUrl.length == 0)
        [_avatarModel setAvatarFirstName:_firstName lastName:_lastName uid:_uid];
    else
        [_avatarModel setAvatarUri:authorAvatarUrl];
}

- (void)setVoteInfoWithMessage:(TGMessage *) __unused msg
{
    
}

- (void)updateAssets
{
}

- (void)refreshMetrics
{
}

- (void)updateMessage:(TGMessage *)__unused message viewStorage:(TGModernViewStorage *)__unused viewStorage
{
}

- (void)relativeBoundsUpdated:(CGRect)__unused bounds
{
}

- (void)imageDataInvalidated:(NSString *)__unused imageUrl
{
}

- (CGRect)effectiveContentFrame
{
    return CGRectZero;
}

- (UIView *)referenceViewForImageTransition
{
    return nil;
}

- (void)setTemporaryHighlighted:(bool)__unused temporaryHighlighted viewStorage:(TGModernViewStorage *)__unused viewStorage
{
}

- (void)updateProgress:(bool)__unused progressVisible progress:(float)__unused progress viewStorage:(TGModernViewStorage *)__unused viewStorage animated:(bool)__unused animated
{
}

- (void)updateMediaAvailability:(bool)__unused mediaIsAvailable viewStorage:(TGModernViewStorage *)__unused viewStorage
{
}

- (void)updateMediaVisibility
{
}

- (void)updateMessageAttributes
{
}

- (void)updateInlineMediaContext
{
}

- (void)updateAnimationsEnabled
{
}

- (void)stopInlineMedia
{
}

- (void)updateEditingState:(UIView *)container viewStorage:(TGModernViewStorage *)viewStorage animationDelay:(NSTimeInterval)animationDelay
{
    if (!_needsEditingCheckButton)
        return;
    
    bool editing = _context.editing;
    
    if (editing != _editing)
    {
        _editing = editing;
        
        if (_editing)
        {
            if (_checkAreaModel == nil)
            {
                _checkAreaModel = [[TGModernButtonViewModel alloc] init];
                _checkAreaModel.skipDrawInContext = true;
                _checkAreaModel.frame = self.bounds;
                [self addSubmodel:_checkAreaModel];
                
                if (container != nil)
                {
                    [_checkAreaModel bindViewToContainer:container viewStorage:viewStorage];
                    
                    [(UIButton *)[_checkAreaModel boundView] addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
                }
            }
        }
        else if (_checkAreaModel != nil)
        {
            if ([_checkAreaModel boundView] != nil)
            {
                [(UIButton *)[_checkAreaModel boundView] removeTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            }
            
            [self removeSubmodel:_checkAreaModel viewStorage:viewStorage];
            _checkAreaModel = nil;
        }
        
        if (animationDelay > -FLT_EPSILON && container != nil)
        {
            UIView<TGModernView> *checkView = nil;
            
            if (_editing)
            {
                if (_checkButtonModel == nil)
                {
                    _checkButtonModel = [[TGModernCheckButtonViewModel alloc] initWithFrame:CGRectMake(11.0f, floorf((self.frame.size.height - 30.0f) / 2.0f), 30.0f, 30.0f)];
                    _checkButtonModel.isChecked = [_context isMessageChecked:_mid];
                    [self addSubmodel:_checkButtonModel];
                    
                    if (container != nil)
                    {
                        [_checkButtonModel bindViewToContainer:container viewStorage:viewStorage];
                        
                        [(UIButton *)[_checkButtonModel boundView] addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
                    }
                }
                
                [_checkButtonModel boundView].frame = CGRectOffset(_checkButtonModel.frame, -49.0f, 0.0f);
            }
            else if (_checkButtonModel != nil)
            {
                if ([_checkButtonModel boundView] != nil)
                {
                    [(UIButton *)[_checkButtonModel boundView] removeTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
                }
                
                [self removeSubmodel:_checkButtonModel viewStorage:viewStorage];
                checkView = [_checkButtonModel _dequeueView:viewStorage];
                checkView.frame = _checkButtonModel.frame;
                [container addSubview:checkView];
                _checkButtonModel = nil;
            }
            
            [UIView animateWithDuration:MAX(0.025, 0.18 - animationDelay) delay:animationDelay options:iosMajorVersion() >= 7 ? (7 << 16) : 0 animations:^
            {
                if (self.frame.size.width > FLT_EPSILON)
                    [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
                
                if (_editing)
                    [_checkButtonModel boundView].frame = _checkButtonModel.frame;
                else
                    checkView.frame = CGRectOffset(checkView.frame, -49.0f, 0.0f);
            } completion:^(__unused BOOL finished)
            {
                if (checkView != nil)
                {
                    [checkView removeFromSuperview];
                    [viewStorage enqueueView:checkView];
                }
            }];
        }
        else
        {
            if (self.frame.size.width > FLT_EPSILON)
                [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
            
            if (_editing)
            {
                if (_checkButtonModel == nil)
                {
                    _checkButtonModel = [[TGModernCheckButtonViewModel alloc] initWithFrame:CGRectMake(11.0f, floorf((self.frame.size.height - 30.0f) / 2.0f), 30.0f, 30.0f)];
                    _checkButtonModel.isChecked = [_context isMessageChecked:_mid];
                    [self addSubmodel:_checkButtonModel];
                
                    if (container != nil)
                    {
                        [_checkButtonModel bindViewToContainer:container viewStorage:viewStorage];
                        
                        [(UIButton *)[_checkButtonModel boundView] addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
                    }
                }
            }
            else if (_checkButtonModel != nil)
            {
                if ([_checkButtonModel boundView] != nil)
                {
                    [(UIButton *)[_checkButtonModel boundView] removeTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
                }
                
                [self removeSubmodel:_checkButtonModel viewStorage:viewStorage];
                _checkButtonModel = nil;
            }
        }
    }
    else if (editing)
        _checkButtonModel.isChecked = [_context isMessageChecked:_mid];
}

- (void)bindSpecialViewsToContainer:(UIView *)container viewStorage:(TGModernViewStorage *)viewStorage atItemPosition:(CGPoint)itemPosition
{   
    if (_avatarModel != nil)
    {
        [_avatarModel bindViewToContainer:container viewStorage:viewStorage];
        [_avatarModel boundView].frame = CGRectOffset([_avatarModel boundView].frame, itemPosition.x, itemPosition.y);
    }
}

- (void)bindViewToContainer:(UIView *)container viewStorage:(TGModernViewStorage *)viewStorage
{
    [super bindViewToContainer:container viewStorage:viewStorage];
    
    if (_avatarModel != nil)
    {
        _boundAvatarTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapGesture:)];
        [[_avatarModel boundView] addGestureRecognizer:_boundAvatarTapRecognizer];
        
        _boundAvatarLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(avatarLongPressGesture:)];
        [[_avatarModel boundView] addGestureRecognizer:_boundAvatarLongPressRecognizer];
    }
    
    if (_checkButtonModel != nil)
        [(UIButton *)[_checkButtonModel boundView] addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    if (_checkAreaModel != nil)
        [(UIButton *)[_checkAreaModel boundView] addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)unbindView:(TGModernViewStorage *)viewStorage
{
    if (_avatarModel != nil)
    {
        [[_avatarModel boundView] removeGestureRecognizer:_boundAvatarTapRecognizer];
        [[_avatarModel boundView] removeGestureRecognizer:_boundAvatarLongPressRecognizer];
        _boundAvatarTapRecognizer = nil;
        _boundAvatarLongPressRecognizer = nil;
    }
    
    if (_checkButtonModel != nil)
        [(UIButton *)[_checkButtonModel boundView] removeTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    if (_checkAreaModel != nil)
        [(UIButton *)[_checkAreaModel boundView] removeTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [super unbindView:viewStorage];
}

- (void)avatarTapGesture:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        [_context.companionHandle requestAction:@"userAvatarTapped" options:@{@"uid": @(_uid)}];
    }
}

- (void)avatarLongPressGesture:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [_context.companionHandle requestAction:@"userAvatarLongPress" options:@{@"uid": @(_uid)}];
    }
}

- (void)upButtonPressed
{
    
}

- (void)handleVoteInfoChangedNotification:(NSNotification *)notification
{
    NSMutableArray *needToUpdate = (NSMutableArray *)notification.object;
    TGMessage *message = [TGDatabaseInstance() loadMessageWithMid:_mid];
    NSString *messageKey = [T8Common createMessageKeyWithMid:message.mid fromUid:message.fromUid toUid:message.toUid date:message.date];
    if ([needToUpdate containsObject:messageKey]) {
        [self updateVoteInfo];
    }
}

- (void)updateVoteInfo
{
    TGMessage *message = [TGDatabaseInstance() loadMessageWithMid:_mid];
    [self setVoteInfoWithMessage:message];
}

- (void)checkButtonPressed
{
    if (_checkButtonModel != nil)
    {
        _checkButtonModel.isChecked = !_checkButtonModel.isChecked;
        [_context.companionHandle requestAction:@"messageSelectionChanged" options:@{@"mid": @(_mid), @"selected": @(_checkButtonModel.isChecked)}];
    }
}

- (void)layoutForContainerSize:(CGSize)__unused containerSize
{
    if (_avatarModel != nil)
    {
        _avatarModel.frame = CGRectMake(TGGetMessageViewModelLayoutConstants()->avatarInset + (_editing ? 42.0f : 0.0f), 5, 38, 38);
        _avatarModel.alpha = (_collapseFlags & TGModernConversationItemCollapseBottom) ? 0.0f : 1.0f;
    }
    
    if (_checkButtonModel != nil)
        _checkButtonModel.frame = CGRectMake(11.0f, floorf((self.frame.size.height - 30.0f) / 2.0f), 30.0f, 30.0f);
    
    if (_checkAreaModel != nil)
        _checkAreaModel.frame = self.bounds;
}

- (void)voteButtonPressed
{
    TGMessage *message = [TGDatabaseInstance() loadMessageWithMid:_mid];
    TGVoteInfoObject *obj = [message.contentProperties objectForKey:StoreKey_MessageVoteInfo];
    __weak typeof(self) weakSelf = self;
    TGVoteView *voteView = [[TGVoteView alloc] initWithUpvoteStatus:obj.upvote downvoteStatus:obj.downvote upvoteBlock:^{
        TGMessage *message = [TGDatabaseInstance() loadMessageWithMid:_mid];
        NSString *msgKey = [T8Common createMessageKeyWithMid:message.mid fromUid:message.fromUid toUid:message.toUid date:message.date];
        [T8VoteService upvoteMessage:message.mid messageKey:msgKey cid:message.cid text:message.text success:^(NSDictionary *dictRet) {
            [T8Common storeVoteInfoForMessage:message.mid successData:dictRet];
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf updateVoteInfo];
        } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
            
        }];
    } downvoteBlock:^{
        TGMessage *message = [TGDatabaseInstance() loadMessageWithMid:_mid];
        NSString *msgKey = [T8Common createMessageKeyWithMid:message.mid fromUid:message.fromUid toUid:message.toUid date:message.date];
        [T8VoteService downvoteMessage:message.mid messageKey:msgKey cid:message.cid text:message.text success:^(NSDictionary __unused *dictRet) {
            [T8Common storeVoteInfoForMessage:message.mid successData:dictRet];
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf updateVoteInfo];
        } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
            
        }];
    }];
    [voteView show];
}

@end
