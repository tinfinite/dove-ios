/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGGroupInfoCollectionItem.h"

#import "TGGroupInfoCollectionItemView.h"

#import "TGConversation.h"
#import "ASHandle.h"
#import "TGFont.h"
#import "TGRemoteImageView.h"

@interface TGGroupInfoCollectionItem () <TGGroupInfoCollectionItemViewDelegate>
{
    TGConversation *_conversation;
    NSString *_editingTitle;
    
    NSString *_updatingTitle;
    NSString *_description;
    UIImage *_updatingAvatar;
    bool _hasUpdatingAvatar;
    
    bool _makeFieldFirstResponder;
}

@end

@implementation TGGroupInfoCollectionItem

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        self.selectable = false;
        self.highlightable = false;
    }
    return self;
}

- (Class)itemViewClass
{
    return [TGGroupInfoCollectionItemView class];
}

- (CGSize)itemSizeForContainerSize:(CGSize)containerSize
{
    if (_description) {
        CGFloat maxTitleWidth = containerSize.width - 92.f - 14.f;
        
        CGSize size = [_description sizeWithFont:TGSystemFontOfSize(15.0f) constrainedToSize:CGSizeMake(maxTitleWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        if (size.height >= 36) {
            return CGSizeMake(containerSize.width, 62 + size.height);
        }
    }
    return CGSizeMake(containerSize.width, 90);
}

- (void)bindView:(TGGroupInfoCollectionItemView *)view
{
    [super bindView:view];
    
    view.delegate = self;
    
    view.isBroadcast = _isBroadcast;
    [view setUpdatingTitle:_updatingTitle != nil animated:false];
    [view setUpdatingAvatar:_hasUpdatingAvatar animated:false];
    [view setTitle:_updatingTitle != nil ? _updatingTitle : _conversation.chatTitle];
    [view setDescription:_description != nil ? _description : @""];
    [view setGroupId:_conversation.conversationId];
    
    if (_updatingAvatar == nil)
        [view setAvatarUri:_conversation.chatPhotoSmall animated:false];
    else
        [view setAvatarImage:_updatingAvatar animated:false];
    
    [view setEditing:_editing animated:false];
    
    if (_makeFieldFirstResponder)
    {
        _makeFieldFirstResponder = false;
        [view makeNameFieldFirstResponder];
    }
}

- (void)unbindView
{
    ((TGGroupInfoCollectionItemView *)[self boundView]).delegate = nil;
    
    [super unbindView];
}

- (void)setConversation:(TGConversation *)conversation
{
    _conversation = conversation;
    
    TGGroupInfoCollectionItemView *view = (TGGroupInfoCollectionItemView *)[self boundView];
    if (view != nil)
    {
        if (_updatingAvatar == nil)
            [view setAvatarUri:_conversation.chatPhotoSmall animated:true];
        else
            [view setAvatarImage:_updatingAvatar animated:true];
        
        [view setTitle:_updatingTitle != nil ? _updatingTitle : _conversation.chatTitle];
    }
}

- (void)setUpdatingTitle:(NSString *)updatingTitle
{
    if (!TGStringCompare(_updatingTitle, updatingTitle))
    {
        _updatingTitle = updatingTitle;
        
        TGGroupInfoCollectionItemView *view = (TGGroupInfoCollectionItemView *)[self boundView];
        if (view != nil)
        {
            [view setUpdatingTitle:_updatingTitle != nil animated:true];
            [view setTitle:_updatingTitle != nil ? _updatingTitle : _conversation.chatTitle];
        }
    }
}

- (void)setDescription:(NSString *)description
{
    if (!TGStringCompare(_description, description)) {
        _description = description;
        
        TGGroupInfoCollectionItemView *view = (TGGroupInfoCollectionItemView *)[self boundView];
        if (view != nil)
        {
            [view setDescription:_description != nil ? _description : @""];
        }
    }
}

- (void)copyUpdatingAvatarToCacheWithUri:(NSString *)uri
{
    if ([self boundView] != nil && _updatingAvatar != nil && uri != nil)
    {
        [[TGRemoteImageView sharedCache] cacheImage:_updatingAvatar withData:nil url:[[NSString alloc] initWithFormat:@"{filter:circle:64x64}%@", uri] availability:TGCacheMemory];
    }
}

- (void)makeNameFieldFirstResponder
{
    if ([self boundView] == nil)
        _makeFieldFirstResponder = true;
    else
        [(TGGroupInfoCollectionItemView *)[self boundView] makeNameFieldFirstResponder];
}

- (void)setUpdatingAvatar:(UIImage *)updatingAvatar hasUpdatingAvatar:(bool)hasUpdatingAvatar
{
    if (_updatingAvatar != updatingAvatar || _hasUpdatingAvatar != hasUpdatingAvatar)
    {
        _updatingAvatar = updatingAvatar;
        _hasUpdatingAvatar = hasUpdatingAvatar;
        
        TGGroupInfoCollectionItemView *view = (TGGroupInfoCollectionItemView *)[self boundView];
        if (view != nil)
        {
            [view setUpdatingAvatar:_hasUpdatingAvatar animated:true];
            
            if (_updatingAvatar == nil)
                [view setAvatarUri:_conversation.chatPhotoSmall animated:false];
            else
                [view setAvatarImage:_updatingAvatar animated:false];
        }
    }
}

- (bool)hasUpdatingAvatar
{
    return _hasUpdatingAvatar;
}

- (void)setEditing:(bool)editing animated:(bool)animated
{
    if (_editing != editing)
    {
        _editing = editing;
        
        [(TGGroupInfoCollectionItemView *)[self boundView] setEditing:_editing animated:animated];
    }
}

- (id)avatarView
{
    return [(TGGroupInfoCollectionItemView *)[self boundView] avatarView];
}

- (NSString *)editingTitle
{
    return _editing ? _editingTitle : nil;
}

- (void)groupInfoViewHasTappedAvatar:(TGGroupInfoCollectionItemView *)groupInfoView
{
    if (groupInfoView == [self boundView])
    {
        if (_hasUpdatingAvatar)
            [_interfaceHandle requestAction:@"showUpdatingAvatarOptions" options:nil];
        else
            [_interfaceHandle requestAction:@"openAvatar" options:nil];
    }
}

- (void)groupInfoViewHasChangedEditedTitle:(TGGroupInfoCollectionItemView *)groupInfoView title:(NSString *)title
{
    if (groupInfoView == [self boundView])
    {
        _editingTitle = title;
        [_interfaceHandle requestAction:@"editedTitleChanged" options:@{@"title": title == nil ? @"" : title}];
    }
}

@end
