/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGGroupInfoController.h"

#import "ActionStage.h"
#import "SGraphObjectNode.h"

#import "TGConversation.h"
#import "TGDatabase.h"

#import "TGHacks.h"
#import "TGFont.h"
#import "TGStringUtils.h"

#import "TGAppDelegate.h"
#import "TGTelegraph.h"
#import "TGTelegramNetworking.h"

#import "TGInterfaceManager.h"
#import "TGNavigationBar.h"
#import "TGTelegraphDialogListCompanion.h"
#import "TGConversationChangeTitleRequestActor.h"
#import "TGConversationChangePhotoActor.h"

#import "TGHeaderCollectionItem.h"
#import "TGSwitchCollectionItem.h"
#import "TGVariantCollectionItem.h"
#import "TGButtonCollectionItem.h"
#import "TGGroupInfoCollectionItem.h"
#import "TGGroupInfoUserCollectionItem.h"
#import "TGImageCollectionItem.h"
#import "TGDiscoverCollectionItem.h"

#import "TGTelegraphUserInfoController.h"
#import "TGGroupInfoSelectContactController.h"
#import "TGAlertSoundController.h"

#import "TGRemoteImageView.h"
#import "TGLegacyCameraController.h"
#import "TGImagePickerController.h"
#import "TGImageSearchController.h"

#import "TGAlertView.h"
#import "TGActionSheet.h"

#import "TGModernGalleryController.h"
#import "TGGroupAvatarGalleryItem.h"
#import "TGGroupAvatarGalleryModel.h"
#import "TGOverlayControllerWindow.h"

#import "T8StickToTopManager.h"
#import "TGDiscoverManageViewController.h"
#import "T8GroupAndCommunityService.h"
#import "T8GroupHttpRequestService.h"
#import "TGLetteredAvatarView.h"
#import "T8ImageUploadManager.h"
#import "TGGroupInfoBoardController.h"
#import "TGGroupSettingController.h"

#import "NSDictionary+Ext.h"

@interface TGGroupInfoController () <TGGroupInfoSelectContactControllerDelegate, TGAlertSoundControllerDelegate, TGLegacyCameraControllerDelegate, TGImagePickerControllerDelegate>
{
    bool _editing;
    bool _haveEditableUsers;
    
    int64_t _conversationId;
    TGConversation *_conversation;
    
    TGGroupInfoCollectionItem *_groupInfoItem;
    TGButtonCollectionItem *_setGroupPhotoItem;
    
    TGCollectionMenuSection *_groupBoardsAndSettingSection;
    TGDiscoverCollectionItem *_groupBoardItem;
    TGDiscoverCollectionItem *_groupSettingItem;
    
    TGCollectionMenuSection *_upvoteAndMediaSection;
    TGDiscoverCollectionItem *_upvoteMessageItem;
    TGDiscoverCollectionItem *_sharedMediaItem;
    
    TGCollectionMenuSection *_inviteAndJoinSection;
    TGDiscoverCollectionItem *_inviteItem;
    TGDiscoverCollectionItem *_joinRequestItem;
    
    TGCollectionMenuSection *_usersSection;
    TGHeaderCollectionItem *_usersSectionHeader;
    
    NSMutableDictionary *_groupNotificationSettings;
    NSInteger _sharedMediaCount;
    
    NSMutableArray *_soonToBeAddedUserIds;
    NSMutableArray *_soonToBeRemovedUserIds;
    
    UILabel *_leftLabel;
}

@property (nonatomic,strong) TGDiscoverCollectionItem *joinRequestItem;
@property (nonatomic,strong) TGDiscoverCollectionItem *upvoteMessageItem;

@end

@implementation TGGroupInfoController

- (instancetype)initWithConversationId:(int64_t)conversationId
{
    self = [super init];
    if (self != nil)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _soonToBeAddedUserIds = [[NSMutableArray alloc] init];
        _soonToBeRemovedUserIds = [[NSMutableArray alloc] init];
        
        _conversationId = conversationId;
        _groupNotificationSettings = [[NSMutableDictionary alloc] initWithDictionary:@{@"muteUntil": @(0), @"soundId": @(1)}];
        [self _loadUsersAndUpdateConversation:[TGDatabaseInstance() loadConversationWithIdCached:_conversationId]];
        
        [self setTitleText:TGLocalized(@"GroupInfo.Title")];
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Edit") style:UIBarButtonItemStylePlain target:self action:@selector(editPressed)] animated:false];
        
        _groupInfoItem = [[TGGroupInfoCollectionItem alloc] init];
        _groupInfoItem.interfaceHandle = _actionHandle;
        
        _setGroupPhotoItem = [[TGButtonCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.SetGroupPhoto") action:@selector(setGroupPhotoPressed)];
        _setGroupPhotoItem.titleColor = TGAccentColor();
        _setGroupPhotoItem.deselectAutomatically = true;
        
        TGButtonCollectionItem *addParticipantItem = [[TGButtonCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.AddParticipant") action:@selector(addParticipantPressed)];
        addParticipantItem.titleColor = TGAccentColor();
        addParticipantItem.deselectAutomatically = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        
        [self.menuSections addSection:[[TGCollectionMenuSection alloc] initWithItems:@[
            _groupInfoItem,
            addParticipantItem
        ]]];
        
        _groupBoardItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.GroupBoard") imageName:@"group_board_blue" action:@selector(groupBoardPressed)];
        _groupSettingItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.GroupSettings") imageName:@"group_setting" action:@selector(groupSettingPressed)];
        _groupBoardsAndSettingSection = [[TGCollectionMenuSection alloc] initWithItems:@[               _groupBoardItem,_groupSettingItem]];
        [self.menuSections addSection:_groupBoardsAndSettingSection];
        
        _upvoteMessageItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"UpvoteMessages.Title") imageName:@"discover_my_praise" action:@selector(upvoteMessagePress)];
        _sharedMediaItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.SharedMedia") imageName:@"group_media" action:@selector(sharedMediaPressed)];
        _upvoteAndMediaSection = [[TGCollectionMenuSection alloc] initWithItems:@[               _upvoteMessageItem,_sharedMediaItem]];
        [self.menuSections addSection:_upvoteAndMediaSection];
        
        _inviteItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.InviteByQRCode") imageName:@"group_qr_code" action:@selector(invitePressed)];
        _joinRequestItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.JionRequest") imageName:@"group_invite" action:@selector(joinRequestPress)];
        _inviteAndJoinSection = [[TGCollectionMenuSection alloc] initWithItems:@[               _inviteItem,_joinRequestItem]];
        UIEdgeInsets inviteAndJoinSectionInsets = _inviteAndJoinSection.insets;
        inviteAndJoinSectionInsets.bottom = 18.0f;
        _inviteAndJoinSection.insets = inviteAndJoinSectionInsets;
        [self.menuSections addSection:_inviteAndJoinSection];
        
        _usersSectionHeader = [[TGHeaderCollectionItem alloc] initWithTitle:@""];
        
        _usersSection = [[TGCollectionMenuSection alloc] initWithItems:@[
            _usersSectionHeader
        ]];
        [self.menuSections addSection:_usersSection];
        
        TGButtonCollectionItem *leaveGroupItem = [[TGButtonCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.DeleteAndExit") action:@selector(leaveGroupPressed)];
        leaveGroupItem.titleColor = TGDestructiveAccentColor();
        leaveGroupItem.alignment = NSTextAlignmentCenter;
        leaveGroupItem.deselectAutomatically = true;
        [self.menuSections addSection:[[TGCollectionMenuSection alloc] initWithItems:@[
            leaveGroupItem
        ]]];
        
        [self _loadUsersAndUpdateConversation:[TGDatabaseInstance() loadConversationWithIdCached:_conversationId]];
            
        [self _updateSharedMediaCount];
        
        [ActionStageInstance() dispatchOnStageQueue:^
        {
            [ActionStageInstance() watchForPaths:@[
                [[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/conversation", _conversationId],
                @"/tg/userdatachanges",
                @"/tg/userpresencechanges",
                @"/as/updateRelativeTimestamps",
                [[NSString alloc] initWithFormat:@"/tg/sharedMediaCount/(%" PRIx64 ")", (int64_t)_conversationId]
            ] watcher:self];
            
            [ActionStageInstance() watchForPath:[NSString stringWithFormat:@"/tg/peerSettings/(%" PRId64 ")", _conversationId] watcher:self];
            [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/peerSettings/(%" PRId64 ",cachedOnly)", _conversationId] options:@{@"peerId": @(_conversationId)} watcher:self];
            
            [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversations/(%lld)/mediahistory/(0)", _conversationId] options:@{@"limit": @(5)} watcher:self];
            
            NSArray *addActions = [ActionStageInstance() rejoinActionsWithGenericPathNow:@"/tg/conversation/@/addMember/@" prefix:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")", _conversationId] watcher:self];
            NSArray *deleteActions = [ActionStageInstance() rejoinActionsWithGenericPathNow:@"/tg/conversation/@/deleteMember/@" prefix:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")", _conversationId] watcher:self];
            NSArray *changeTitleActions = [ActionStageInstance() rejoinActionsWithGenericPathNow:@"/tg/conversation/@/changeTitle/@" prefix:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")", _conversationId] watcher:self];
            NSArray *changeAvatarActions = [ActionStageInstance() rejoinActionsWithGenericPathNow:@"/tg/conversation/@/updateAvatar/@" prefix:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")", _conversationId] watcher:self];
            
            NSString *updatingTitle = nil;
            if (changeTitleActions.count != 0)
            {
                NSString *action = [changeTitleActions lastObject];
                TGConversationChangeTitleRequestActor *actor = (TGConversationChangeTitleRequestActor *)[ActionStageInstance() executingActorWithPath:action];
                if (actor != nil)
                    updatingTitle = actor.currentTitle;
            }
            
            UIImage *updatingAvatar = nil;
            bool haveUpdatingAvatar = false;
            if (changeAvatarActions.count != 0)
            {
                NSString *action = [changeAvatarActions lastObject];
                TGConversationChangePhotoActor *actor = (TGConversationChangePhotoActor *)[ActionStageInstance() executingActorWithPath:action];
                if (actor != nil)
                {
                    updatingAvatar = actor.currentImage;
                    haveUpdatingAvatar = true;
                }
            }

            if (addActions.count != 0 || deleteActions.count != 0 || changeTitleActions.count != 0 || changeAvatarActions.count != 0)
            {
                TGDispatchOnMainThread(^
                {
                    for (NSString *path in addActions)
                    {
                        NSRange range = [path rangeOfString:@"/addMember/("];
                        int32_t uid = (int32_t)[[path substringFromIndex:(range.location + range.length)] intValue];
                        
                        [_soonToBeAddedUserIds addObject:@(uid)];
                    }
                    
                    for (NSString *path in deleteActions)
                    {
                        NSRange range = [path rangeOfString:@"/deleteMember/("];
                        int32_t uid = (int32_t)[[path substringFromIndex:(range.location + range.length)] intValue];
                        
                        [_soonToBeRemovedUserIds addObject:@(uid)];
                    }
                    
                    [_groupInfoItem setUpdatingTitle:updatingTitle];
                    
                    [_groupInfoItem setUpdatingAvatar:updatingAvatar hasUpdatingAvatar:haveUpdatingAvatar];
                    [_setGroupPhotoItem setEnabled:!haveUpdatingAvatar];
                    
                    [self _loadUsersAndUpdateConversation:_conversation];
                });
            }
        }];
    }
    return self;
}

- (void)dealloc
{
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

#pragma mark -

- (void)_resetCollectionView
{
    [super _resetCollectionView];
    
    [self _updateLeftState];
    
    [self.collectionView setAllowEditingCells:_haveEditableUsers animated:false];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self _layoutLeftLabel:self.interfaceOrientation];
    [self updateUIStatus];
    
    __weak typeof(self) weakSelf = self;
    [T8GroupAndCommunityService getGroupInfoWithID:_conversationId successBlock:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSDictionary *community = [dictRet dictForKey:@"community" withDefault:[NSDictionary dictionary]];
        strongSelf.joinRequestItem.variant = @([community intForKey:@"apply_count" withDefault:0]).stringValue;
        //因为和里面列表的数字对不上，列表中只能显示本地数据库中存在的message，所以不显示了
//        if ([[community objectForKey:@"upvote_count"] integerValue] != 0) {
//            strongSelf.upvoteMessageItem.variant = ((NSNumber *)[community objectForKey:@"upvote_count"]).stringValue;
//        }
        
        NSString *desc = [community stringForKey:@"description" withDefault:@""];
        NSString *lan = [community stringForKey:@"language" withDefault:@""];
        GroupDiscoverPrivilege pri = [community intValueForKey:@"privilege" withDefault:1];
        [TGDatabaseInstance() storeConversationInfoWithId:_conversationId privilege:pri description:desc language:lan];
        [strongSelf updateUIStatus];
    } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        
    }];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self _layoutLeftLabel:toInterfaceOrientation];
}

#pragma mark -

- (void)updateUIStatus
{
    GroupDiscoverPrivilege privilege = [TGDatabaseInstance() getPrivilegeWithConversationId:_conversationId];
//    _showInDiscoverItem.variant = privilege==GroupDiscoverPrivilegePublic?TGLocalized(@"Discover.On"):TGLocalized(@"Discover.Off");
}

- (void)editPressed
{
    if (!_editing)
    {
        _editing = true;
        
        [_groupInfoItem setEditing:true animated:true];
        
        NSIndexPath *groupInfoIndexPath = [self indexPathForItem:_groupInfoItem];
        if (groupInfoIndexPath != nil)
        {
            [self.menuSections beginRecordingChanges];
            [self.menuSections insertItem:_setGroupPhotoItem toSection:groupInfoIndexPath.section atIndex:groupInfoIndexPath.row+1];
            [self.menuSections commitRecordedChanges:self.collectionView];
        }
        
        [self enterEditingMode:true];
    }
}

- (void)donePressed
{
    if (_editing)
    {
        _editing = false;
        
        if (!TGStringCompare(_conversation.chatTitle, [_groupInfoItem editingTitle]) && [_groupInfoItem editingTitle] != nil)
            [self _commitUpdateTitle:[_groupInfoItem editingTitle]];
        
        [_groupInfoItem setEditing:false animated:true];
    }
    
    NSIndexPath *setGroupPhotoIndexPath = [self indexPathForItem:_setGroupPhotoItem];
    if (setGroupPhotoIndexPath != nil)
    {
        [self.menuSections beginRecordingChanges];
        [self.menuSections deleteItemFromSection:setGroupPhotoIndexPath.section atIndex:setGroupPhotoIndexPath.row];
        [self.menuSections commitRecordedChanges:self.collectionView];
    }
    
    [self leaveEditingMode:true];
}

- (void)didEnterEditingMode:(bool)animated
{
    [super didEnterEditingMode:animated];
    
    [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Done") style:UIBarButtonItemStyleDone target:self action:@selector(donePressed)] animated:true];
}

- (void)didLeaveEditingMode:(bool)animated
{
    [super didLeaveEditingMode:animated];
    
    [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Edit") style:UIBarButtonItemStylePlain target:self action:@selector(editPressed)] animated:animated];
}

- (void)setGroupPhotoPressed
{
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.TakePhoto") action:@"camera"]];
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.ChoosePhoto") action:@"choosePhoto"]];
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.SearchWebImages") action:@"searchWeb"]];
    
    if (_conversation.chatPhotoSmall.length != 0)
        [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"GroupInfo.SetGroupPhotoDelete") action:@"delete" type:TGActionSheetActionTypeDestructive]];
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]];
    
    [[[TGActionSheet alloc] initWithTitle:nil actions:actions actionBlock:^(TGGroupInfoController *controller, NSString *action)
    {
        if ([action isEqualToString:@"camera"])
            [controller _displayCamera];
        else if ([action isEqualToString:@"choosePhoto"])
            [controller _displayImagePicker:false];
        else if ([action isEqualToString:@"searchWeb"])
            [controller _displayImagePicker:true];
        else if ([action isEqualToString:@"delete"])
            [controller _commitDeleteAvatar];
    } target:self] showInView:self.view];
}

- (void)_displayCamera
{
    TGLegacyCameraController *legacyCameraController = [[TGLegacyCameraController alloc] init];
    legacyCameraController.sourceType = UIImagePickerControllerSourceTypeCamera;
    legacyCameraController.avatarMode = true;
    
    legacyCameraController.completionDelegate = self;
    
    [self presentViewController:legacyCameraController animated:true completion:nil];
}

- (void)_displayImagePicker:(bool)openWebSearch
{
    NSMutableArray *controllerList = [[NSMutableArray alloc] init];
    
    TGImageSearchController *searchController = [[TGImageSearchController alloc] initWithAvatarSelection:true];
    searchController.autoActivateSearch = openWebSearch;
    searchController.delegate = self;
    [controllerList addObject:searchController];
    
    if (!openWebSearch)
    {
        TGImagePickerController *imagePicker = [[TGImagePickerController alloc] initWithGroupUrl:nil groupTitle:nil avatarSelection:true];
        imagePicker.delegate = self;
        
        [controllerList addObject:imagePicker];
    }
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:controllerList];
    navigationController.restrictLandscape = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;

    if ([self inPopover])
    {
        navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleChildInPopover;
    }
    
    [self presentViewController:navigationController animated:true completion:nil];
}

- (void)imagePickerController:(TGImagePickerController *)__unused imagePicker didFinishPickingWithAssets:(NSArray *)assets
{
    UIImage *image = nil;
    
    if (assets.count != 0)
    {
        if ([assets[0] isKindOfClass:[UIImage class]])
            image = assets[0];
    }
    
    if (image != nil)
    {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.6f);
        if (imageData == nil)
            return;
        
        TGImageProcessor filter = [TGRemoteImageView imageProcessorForName:@"circle:64x64"];
        UIImage *avatarImage = filter(image);
        
        [_groupInfoItem setUpdatingAvatar:avatarImage hasUpdatingAvatar:true];
        [_setGroupPhotoItem setEnabled:false];
            
        NSMutableDictionary *uploadOptions = [[NSMutableDictionary alloc] init];
        [uploadOptions setObject:imageData forKey:@"imageData"];
        [uploadOptions setObject:[NSNumber numberWithLongLong:_conversation.conversationId] forKey:@"conversationId"];
        [uploadOptions setObject:avatarImage forKey:@"currentImage"];

        [ActionStageInstance() dispatchOnStageQueue:^
        {
            static int actionId = 0;
            [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/updateAvatar/(updateAvatar%d)", _conversationId, actionId] options:uploadOptions watcher:self];
            [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/updateAvatar/(updateAvatar%d)", _conversationId, actionId++] options:uploadOptions watcher:TGTelegraphInstance];
        }];
    }
    
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)_commitDeleteAvatar
{
    [_groupInfoItem setUpdatingAvatar:nil hasUpdatingAvatar:true];
    [_setGroupPhotoItem setEnabled:false];
    
    NSMutableDictionary *uploadOptions = [[NSMutableDictionary alloc] init];
    [uploadOptions setObject:[NSNumber numberWithLongLong:_conversation.conversationId] forKey:@"conversationId"];
    
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        static int actionId = 0;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/updateAvatar/(deleteAvatar%d)", _conversationId, actionId] options:uploadOptions watcher:self];
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/updateAvatar/(deleteAvatar%d)", _conversationId, actionId++] options:uploadOptions watcher:TGTelegraphInstance];
    }];
}

- (void)_commitCancelAvatarUpdate
{
    [_groupInfoItem setUpdatingAvatar:nil hasUpdatingAvatar:false];
    [_setGroupPhotoItem setEnabled:true];
    
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        NSArray *actors = [ActionStageInstance() executingActorsWithPathPrefix:[NSString stringWithFormat:@"/tg/conversation/(%lld)/updateAvatar/", _conversationId]];
        for (ASActor *actor in actors)
        {
            [ActionStageInstance() removeAllWatchersFromPath:actor.path];
        }
    }];
}

- (void)legacyCameraControllerCompletedWithNoResult
{
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)addParticipantPressed
{
    TGGroupInfoSelectContactController *selectContactController = [[TGGroupInfoSelectContactController alloc] initWithContactsMode:TGContactsModeRegistered];
    selectContactController.delegate = self;
    
    NSMutableArray *disabledUsers = [[NSMutableArray alloc] init];
    [disabledUsers addObjectsFromArray:_conversation.chatParticipants.chatParticipantUids];
    [disabledUsers addObjectsFromArray:_soonToBeAddedUserIds];
    
    selectContactController.disabledUsers = disabledUsers;
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[selectContactController] navigationBarClass:[TGWhiteNavigationBar class]];
    if ([self inPopover])
    {
        navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleChildInPopover;
    }
    
    [self presentViewController:navigationController animated:true completion:nil];
}

- (void)selectContactControllerDidSelectUser:(TGUser *)user
{
    if (user.uid != 0 && ![_conversation.chatParticipants.chatParticipantUids containsObject:@(user.uid)])
    {
        __weak typeof(self) weakSelf = self;
        [[[TGAlertView alloc] initWithTitle:nil message:[[NSString alloc] initWithFormat:TGLocalized(@"GroupInfo.AddParticipantConfirmation"), user.displayFirstName] cancelButtonTitle:TGLocalized(@"Common.Cancel") okButtonTitle:TGLocalized(@"Common.OK") completionBlock:^(bool okButtonPressed)
        {
            if (okButtonPressed)
            {
                TGGroupInfoController *strongSelf = weakSelf;
                [strongSelf _commitAddParticipant:user];
            }
        }] show];
    }
}

- (void)_commitAddParticipant:(TGUser *)user
{
    if (![_soonToBeAddedUserIds containsObject:@(user.uid)])
    {
        [_soonToBeAddedUserIds addObject:@(user.uid)];
        [self _loadUsersAndUpdateConversation:_conversation];
        
        for (id item in _usersSection.items)
        {
            if ([item isKindOfClass:[TGGroupInfoUserCollectionItem class]])
            {
                if (((TGGroupInfoUserCollectionItem *)item).user.uid == user.uid)
                {
                    NSIndexPath *indexPath = [self indexPathForItem:item];
                    if (indexPath != nil && [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
                        [self.collectionView selectItemAtIndexPath:indexPath animated:false scrollPosition:UICollectionViewScrollPositionTop];
                    
                    break;
                }
            }
        }
        
        NSString *path = [NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/addMember/(%d)", _conversation.conversationId, user.uid];
        NSDictionary *options = @{@"conversationId": @(_conversationId), @"uid": @(user.uid)};
        [ActionStageInstance() dispatchOnStageQueue:^
        {
            [ActionStageInstance() requestActor:path options:options watcher:self];
            [ActionStageInstance() requestActor:path options:options watcher:TGTelegraphInstance];
        }];
    }
    
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)_commitDeleteParticipant:(int32_t)uid
{
    for (id item in _usersSection.items)
    {
        if ([item isKindOfClass:[TGGroupInfoUserCollectionItem class]] && ((TGGroupInfoUserCollectionItem *)item).user.uid == uid)
        {
            [_soonToBeRemovedUserIds addObject:@(uid)];
            [(TGGroupInfoUserCollectionItem *)item setDisabled:true];
            [(TGGroupInfoUserCollectionItem *)item setCanEdit:false animated:true];
            
            NSDictionary *options = @{@"conversationId": @(_conversationId), @"uid": @(uid)};
            [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/deleteMember/(%d)", _conversationId, uid] options:options watcher:self];
            
            break;
        }
    }
}

- (void)_commitUpdateTitle:(NSString *)title
{
    [_groupInfoItem setUpdatingTitle:title];
    
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        static int actionId = 0;
        NSString *path = [[NSString alloc] initWithFormat:@"/tg/conversation/(%" PRId64 ")/changeTitle/(groupInfoController%d)", _conversation.conversationId, actionId++];
        NSDictionary *options = @{@"conversationId": @(_conversationId), @"title": title == nil ? @"" : title};
        
        [ActionStageInstance() requestActor:path options:options watcher:self];
        [ActionStageInstance() requestActor:path options:options watcher:TGTelegraphInstance];
    }];
}

- (void)leaveGroupPressed
{
    __weak typeof(self) weakSelf = self;
    
    [[[TGActionSheet alloc] initWithTitle:TGLocalized(@"GroupInfo.DeleteAndExitConfirmation") actions:@[
        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"GroupInfo.DeleteAndExit") action:@"leave" type:TGActionSheetActionTypeDestructive],
        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]
    ] actionBlock:^(__unused id target, NSString *action)
    {
        if ([action isEqualToString:@"leave"])
        {
            TGGroupInfoController *strongSelf = weakSelf;
            [strongSelf _commitLeaveGroup];
        }
    } target:self] showInView:self.view];
}

- (void)_commitLeaveGroup
{
    [TGAppDelegateInstance.dialogListController.dialogListCompanion deleteItem:[[TGConversation alloc] initWithConversationId:_conversationId unreadCount:0 serviceUnreadCount:0] animated:false];
    
    if (self.popoverController != nil)
        [self.popoverController dismissPopoverAnimated:true];
    else
        [self.navigationController popToRootViewControllerAnimated:true];
}

- (void)groupBoardPressed
{
    TGGroupInfoBoardController *groupBoard = [[TGGroupInfoBoardController alloc] initWithConversationId:_conversationId];
    [self.navigationController pushViewController:groupBoard animated:YES];
}

- (void)groupSettingPressed
{
    TGGroupSettingController *groupSetting = [[TGGroupSettingController alloc] initWithConversationId:_conversationId groupAvatar:[((TGLetteredAvatarView *)[_groupInfoItem avatarView]).currentImage copy]];
    [self.navigationController pushViewController:groupSetting animated:YES];
}

- (void)invitePressed
{
    [[TGInterfaceManager instance] navigateToShareQRCodeOfConversation:_conversation navigationController:self.navigationController];
}

- (void)joinRequestPress
{
    [[TGInterfaceManager instance] navigateToJoinRequestOfConversation:_conversation navigationController:self.navigationController];
}

- (void)upvoteMessagePress
{
    [[TGInterfaceManager instance] navigateToUpvoteMessageOfConversation:_conversation navigationController:self.navigationController];
}

- (void)sharedMediaPressed
{
    [[TGInterfaceManager instance] navigateToMediaListOfConversation:_conversationId navigationController:self.navigationController];
}

#pragma mark -

- (void)_updateSharedMediaCount
{
    _sharedMediaItem.variant = _sharedMediaCount == 0 ? TGLocalized(@"GroupInfo.SharedMediaNone") : ( TGIsLocaleArabic() ? [TGStringUtils stringWithLocalizedNumber:_sharedMediaCount] : [[NSString alloc] initWithFormat:@"%ld", (long)_sharedMediaCount]);
}

- (void)_loadUsersAndUpdateConversation:(TGConversation *)conversation
{
    NSMutableArray *participantUsers = [[NSMutableArray alloc] init];
    for (NSNumber *nUid in conversation.chatParticipants.chatParticipantUids)
    {
        TGUser *user = [TGDatabaseInstance() loadUser:[nUid int32Value]];
        if (user != nil)
            [participantUsers addObject:user];
    }
    
    TGDispatchOnMainThread(^
    {
        for (NSNumber *nUid in _soonToBeAddedUserIds)
        {
            if (![conversation.chatParticipants.chatParticipantUids containsObject:nUid])
            {
                TGUser *user = [TGDatabaseInstance() loadUser:[nUid int32Value]];
                if (user != nil)
                    [participantUsers addObject:user];
            }
        }
        
        _conversation = conversation;
        [_groupInfoItem setConversation:_conversation];
        
        [self _updateLeftState];
        [self _updateConversationWithLoadedUsers:participantUsers];
    });
}

- (void)_updateConversationWithLoadedUsers:(NSArray *)participantUsers
{
    NSDictionary *invitedDates = _conversation.chatParticipants.chatInvitedDates;
    
    int32_t selfUid = TGTelegraphInstance.clientUserId;
    NSArray *sortedUsers = [participantUsers sortedArrayUsingComparator:^NSComparisonResult(TGUser *user1, TGUser *user2)
    {
        if (user1.uid == selfUid)
            return NSOrderedAscending;
        else if (user2.uid == selfUid)
            return NSOrderedDescending;
        
        if (user1.presence.online != user2.presence.online)
            return user1.presence.online ? NSOrderedAscending : NSOrderedDescending;
        
        if ((user1.presence.lastSeen < 0) != (user2.presence.lastSeen < 0))
            return user1.presence.lastSeen >= 0 ? NSOrderedAscending : NSOrderedDescending;
        
        if (user1.presence.online)
        {
            NSNumber *nDate1 = invitedDates[[[NSNumber alloc] initWithInt:user1.uid]];
            NSNumber *nDate2 = invitedDates[[[NSNumber alloc] initWithInt:user2.uid]];
            
            if (nDate1 != nil && nDate2 != nil)
                return [nDate1 intValue] < [nDate2 intValue] ? NSOrderedAscending : NSOrderedDescending;
            else if (nDate1 != nil)
                return NSOrderedAscending;
            else if (nDate2 != nil)
                return NSOrderedDescending;
            else
                return user1.uid < user2.uid ? NSOrderedAscending : NSOrderedDescending;
        }
        
        if (user1.presence.lastSeen < 0)
        {
            NSNumber *nDate1 = invitedDates[[[NSNumber alloc] initWithInt:user1.uid]];
            NSNumber *nDate2 = invitedDates[[[NSNumber alloc] initWithInt:user2.uid]];
            
            if (nDate1 != nil && nDate2 != nil)
                return [nDate1 intValue] < [nDate2 intValue] ? NSOrderedAscending : NSOrderedDescending;
            else
                return user1.uid < user2.uid ? NSOrderedAscending : NSOrderedDescending;
        }
        
        return user1.presence.lastSeen > user2.presence.lastSeen ? NSOrderedAscending : NSOrderedDescending;
    }];
    
    NSString *title = @"";
    if (sortedUsers.count == 1)
        title = TGLocalized(@"GroupInfo.ParticipantCount_1");
    else if (sortedUsers.count == 2)
        title = TGLocalized(@"GroupInfo.ParticipantCount_2");
    else if (sortedUsers.count >= 3 && sortedUsers.count <= 10)
        title = [NSString localizedStringWithFormat:TGLocalized(@"GroupInfo.ParticipantCount_3_10"), [TGStringUtils stringWithLocalizedNumber:sortedUsers.count]];
    else
        title = [NSString localizedStringWithFormat:TGLocalized(@"GroupInfo.ParticipantCount_any"), [TGStringUtils stringWithLocalizedNumber:sortedUsers.count]];
    
    [_usersSectionHeader setTitle:title];
    
    NSUInteger sectionIndex = [self indexForSection:_usersSection];
    if (sectionIndex != NSNotFound)
    {
        bool haveChanges = false;
        
        if (_usersSection.items.count - 2 != sortedUsers.count)
            haveChanges = true;
        else
        {
            for (int i = 1, j = 0; i < (int)_usersSection.items.count - 1; i++, j++)
            {
                TGGroupInfoUserCollectionItem *userItem = _usersSection.items[i];
                TGUser *user = sortedUsers[j];
                if (user.uid != userItem.user.uid)
                {
                    haveChanges = true;
                    break;
                }
            }
        }
        
        if (haveChanges)
        {
            int count = _usersSection.items.count - 1;
            while (count > 0)
            {
                [self.menuSections deleteItemFromSection:sectionIndex atIndex:1];
                count--;
            }
            
            int insertIndex = 1;
            for (TGUser *user in sortedUsers)
            {
                TGGroupInfoUserCollectionItem *userItem = [[TGGroupInfoUserCollectionItem alloc] init];
                userItem.interfaceHandle = _actionHandle;
                
                bool disabled = ![_conversation.chatParticipants.chatParticipantUids containsObject:@(user.uid)] || [_soonToBeRemovedUserIds containsObject:@(user.uid)];
                userItem.selectable = user.uid != selfUid && !disabled;
                
                bool canEditInPrinciple = user.uid != selfUid && ((_conversation.chatParticipants.chatAdminId == selfUid || [_conversation.chatParticipants.chatInvitedBy[@(user.uid)] int32Value] == selfUid));
                bool canEdit = userItem.selectable && canEditInPrinciple;
                [userItem setCanEdit:canEdit];
                
                [userItem setUser:user];
                [userItem setDisabled:disabled];
                
                [self.menuSections insertItem:userItem toSection:sectionIndex atIndex:insertIndex];
                insertIndex++;
            }
            
            self.collectionLayout.withoutAnimation = true;
            [UIView performWithoutAnimation:^
            {
                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            }];
            self.collectionLayout.withoutAnimation = false;
            
            //[self.collectionView reloadData];
            
            [self _updateAllowCellEditing:false];
        }
    }
}

- (void)_updateAllowCellEditing:(bool)animated
{
    bool anyCanEdit = false;
    int32_t selfUid = TGTelegraphInstance.clientUserId;
    
    for (id item in _usersSection.items)
    {
        if ([item isKindOfClass:[TGGroupInfoUserCollectionItem class]])
        {
            TGUser *user = ((TGGroupInfoUserCollectionItem *)item).user;
            
            bool canEditInPrinciple = user.uid != selfUid && ((_conversation.chatParticipants.chatAdminId == selfUid || [_conversation.chatParticipants.chatInvitedBy[@(user.uid)] int32Value] == selfUid));
            
            anyCanEdit |= canEditInPrinciple;
        }
    }
    
    _haveEditableUsers = anyCanEdit;
    [self.collectionView setAllowEditingCells:anyCanEdit animated:animated];
}

- (void)_updateRelativeTimestamps
{
    for (id item in _usersSection.items)
    {
        if ([item isKindOfClass:[TGGroupInfoUserCollectionItem class]])
        {
            [(TGGroupInfoUserCollectionItem *)item updateTimestamp];
        }
    }
}

- (void)_updateUsers:(NSArray *)users
{
    bool updatedAnyUser = false;
    
    NSMutableDictionary *userIdToUser = [[NSMutableDictionary alloc] init];
    for (TGUser *user in users)
    {
        userIdToUser[@(user.uid)] = user;
    }
    
    NSMutableArray *participantUsers = [[NSMutableArray alloc] init];
    
    for (id item in _usersSection.items)
    {
        if ([item isKindOfClass:[TGGroupInfoUserCollectionItem class]])
        {
            TGGroupInfoUserCollectionItem *userItem = item;
            
            TGUser *user = userIdToUser[@(userItem.user.uid)];
            if (user != nil)
            {
                updatedAnyUser = true;
                [userItem setUser:user];
            }
            
            [participantUsers addObject:userItem.user];
        }
    }
    
    if (updatedAnyUser)
    {
        [self _updateConversationWithLoadedUsers:participantUsers];
    }
}

- (void)_layoutLeftLabel:(UIInterfaceOrientation)orientation
{
    if (_leftLabel != nil)
    {
        CGSize screenSize = [TGViewController screenSizeForInterfaceOrientation:orientation];
        CGSize labelSize = [_leftLabel sizeThatFits:CGSizeMake(screenSize.width - 10, screenSize.height)];
        _leftLabel.frame = CGRectMake(CGFloor((screenSize.width - labelSize.width) / 2.0f), CGFloor((screenSize.height - labelSize.height) / 2.0f), labelSize.width, labelSize.height);
    }
}

- (void)_updateLeftState
{
    if ((_conversation.kickedFromChat || _conversation.leftChat) != (_leftLabel != nil))
    {
        if (_conversation.kickedFromChat || _conversation.leftChat)
        {
            _leftLabel = [[UILabel alloc] init];
            _leftLabel.backgroundColor = [UIColor clearColor];
            _leftLabel.textColor = UIColorRGB(0x999999);
            _leftLabel.text = _conversation.kickedFromChat ? TGLocalized(@"GroupInfo.KickedStatus") : TGLocalized(@"GroupInfo.LeftStatus");
            _leftLabel.font = TGSystemFontOfSize(17.0f);
            _leftLabel.lineBreakMode = NSLineBreakByWordWrapping;
            _leftLabel.numberOfLines = 0;
            [self.view addSubview:_leftLabel];
            
            [self _layoutLeftLabel:self.interfaceOrientation];
            
            [self setRightBarButtonItem:nil];
        }
        else
        {
            [_leftLabel removeFromSuperview];
            _leftLabel = nil;
            
            if (_editing)
            {
                [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Done") style:UIBarButtonItemStyleDone target:self action:@selector(donePressed)] animated:false];
            }
            else
            {
                [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Edit") style:UIBarButtonItemStylePlain target:self action:@selector(editPressed)] animated:false];
            }
        }
    }
    
    self.collectionView.hidden = _conversation.kickedFromChat || _conversation.leftChat;
}

#pragma mark -

- (void)actionStageActionRequested:(NSString *)action options:(id)options
{
    if ([action isEqualToString:@"deleteUser"])
    {
        int32_t uid = [options[@"uid"] int32Value];
        if (uid != 0)
            [self _commitDeleteParticipant:uid];
    }
    else if ([action isEqualToString:@"openUser"])
    {
        int32_t uid = [options[@"uid"] int32Value];
        if (uid != 0)
        {
            TGTelegraphUserInfoController *userInfoController = [[TGTelegraphUserInfoController alloc] initWithUid:uid];
            [self.navigationController pushViewController:userInfoController animated:true];
        }
    }
    else if ([action isEqualToString:@"editedTitleChanged"])
    {
        NSString *title = options[@"title"];
        
        if (_editing)
            self.navigationItem.rightBarButtonItem.enabled = title.length != 0;
    }
    else if ([action isEqualToString:@"openAvatar"])
    {
        if (_conversation.chatPhotoSmall.length == 0)
        {
            if (_setGroupPhotoItem.enabled)
                [self setGroupPhotoPressed];
        }
        else
        {
            TGRemoteImageView *avatarView = [_groupInfoItem avatarView];
            
            if (avatarView != nil && avatarView.image != nil)
            {
                TGModernGalleryController *modernGallery = [[TGModernGalleryController alloc] init];
                
                modernGallery.model = [[TGGroupAvatarGalleryModel alloc] initWithMessageId:0 legacyThumbnailUrl:_conversation.chatPhotoSmall legacyUrl:_conversation.chatPhotoBig imageSize:CGSizeMake(640.0f, 640.0f)];
                
                __weak TGGroupInfoController *weakSelf = self;
                
                modernGallery.itemFocused = ^(id<TGModernGalleryItem> item)
                {
                    __strong TGGroupInfoController *strongSelf = weakSelf;
                    if (strongSelf != nil)
                    {
                        if ([item isKindOfClass:[TGGroupAvatarGalleryItem class]])
                        {
                            ((UIView *)strongSelf->_groupInfoItem.avatarView).hidden = true;
                        }
                    }
                };
                
                modernGallery.beginTransitionIn = ^UIView *(id<TGModernGalleryItem> item, __unused TGModernGalleryItemView *itemView)
                {
                    __strong TGGroupInfoController *strongSelf = weakSelf;
                    if (strongSelf != nil)
                    {
                        if ([item isKindOfClass:[TGGroupAvatarGalleryItem class]])
                        {
                            return strongSelf->_groupInfoItem.avatarView;
                        }
                    }
                    
                    return nil;
                };
                
                modernGallery.beginTransitionOut = ^UIView *(id<TGModernGalleryItem> item)
                {
                    __strong TGGroupInfoController *strongSelf = weakSelf;
                    if (strongSelf != nil)
                    {
                        if ([item isKindOfClass:[TGGroupAvatarGalleryItem class]])
                        {
                            return strongSelf->_groupInfoItem.avatarView;
                        }
                    }
                    
                    return nil;
                };
                
                modernGallery.completedTransitionOut = ^
                {
                    __strong TGGroupInfoController *strongSelf = weakSelf;
                    if (strongSelf != nil)
                    {
                        ((UIView *)strongSelf->_groupInfoItem.avatarView).hidden = false;
                    }
                };
                
                TGOverlayControllerWindow *controllerWindow = [[TGOverlayControllerWindow alloc] initWithParentController:self contentController:modernGallery];
                controllerWindow.hidden = false;
            }
        }
    }
    else if ([action isEqualToString:@"showUpdatingAvatarOptions"])
    {
        [[[TGActionSheet alloc] initWithTitle:nil actions:@[
            [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"GroupInfo.SetGroupPhotoStop") action:@"stop" type:TGActionSheetActionTypeDestructive],
            [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]
        ] actionBlock:^(TGGroupInfoController *controller, NSString *action)
        {
            if ([action isEqualToString:@"stop"])
                [controller _commitCancelAvatarUpdate];
        } target:self] showInView:self.view];
    }
}

- (void)actionStageResourceDispatched:(NSString *)path resource:(id)resource arguments:(id)__unused arguments
{
    if ([path isEqualToString:[[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/conversation", _conversationId]])
    {
        TGConversation *conversation = ((SGraphObjectNode *)resource).object;
        
        if (conversation != nil)
            [self _loadUsersAndUpdateConversation:conversation];
    }
    else if ([path hasPrefix:@"/tg/peerSettings/"])
    {
        [self actorCompleted:ASStatusSuccess path:path result:resource];
    }
    else if ([path isEqualToString:@"/as/updateRelativeTimestamps"])
    {
        TGDispatchOnMainThread(^
        {
            [self _updateRelativeTimestamps];
        });
    }
    else if ([path isEqualToString:@"/tg/userdatachanges"] || [path isEqualToString:@"/tg/userpresencechanges"])
    {
        NSArray *users = ((SGraphObjectNode *)resource).object;
        
        TGDispatchOnMainThread(^
        {
            [self _updateUsers:users];
        });
    }
    else if ([path isEqualToString:[[NSString alloc] initWithFormat:@"/tg/sharedMediaCount/(%" PRIx64 ")", (int64_t)_conversationId]])
    {
        TGDispatchOnMainThread(^
        {
            _sharedMediaCount = [resource intValue];
            [self _updateSharedMediaCount];
        });
    }
}

- (void)actorCompleted:(int)status path:(NSString *)path result:(id)result
{
    if ([path hasPrefix:[NSString stringWithFormat:@"/tg/conversations/(%lld)/mediahistory/", _conversationId]])
    {
        if (status == ASStatusSuccess)
        {
            NSDictionary *dict = ((SGraphObjectNode *)result).object;
            TGDispatchOnMainThread(^
            {
                _sharedMediaCount = MAX(0, [[dict objectForKey:@"count"] intValue]);
                [self _updateSharedMediaCount];
            });
        }
    }
    else if ([path hasPrefix:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/addMember/", _conversation.conversationId]])
    {
        TGDispatchOnMainThread(^
        {
            NSRange range = [path rangeOfString:@"/addMember/("];
            int32_t uid = (int32_t)[[path substringFromIndex:(range.location + range.length)] intValue];
            
            [_soonToBeAddedUserIds removeObject:@(uid)];
            
            if (status == ASStatusSuccess)
            {
                TGConversation *updatedConversation = [_conversation copy];
                updatedConversation.chatParticipants = [_conversation.chatParticipants copy];
                int32_t currentDate = (int32_t)[[TGTelegramNetworking instance] approximateRemoteTime];
                [updatedConversation.chatParticipants addParticipantWithId:uid invitedBy:TGTelegraphInstance.clientUserId date:currentDate];
                _conversation = updatedConversation;
                
                [self _updateLeftState];
                
                for (id item in _usersSection.items)
                {
                    if ([item isKindOfClass:[TGGroupInfoUserCollectionItem class]] && ((TGGroupInfoUserCollectionItem *)item).user.uid == uid)
                    {
                        [(TGGroupInfoUserCollectionItem *)item setDisabled:false];
                        [(TGGroupInfoUserCollectionItem *)item setCanEdit:true animated:true];
                        
                        break;
                    }
                }
            }
            else
            {
                [self _loadUsersAndUpdateConversation:_conversation];
                
                NSString *errorText = TGLocalized(@"ConversationProfile.UnknownAddMemberError");
                if (status == -2)
                {
                    TGUser *user = [TGDatabaseInstance() loadUser:uid];
                    if (user != nil)
                        errorText = [[NSString alloc] initWithFormat:TGLocalized(@"ConversationProfile.UserLeftChatError"), user.displayName];
                }
                else if (status == -3)
                {
                    errorText = TGLocalized(@"ConversationProfile.UsersTooMuchError");
                }
                
                [[[TGAlertView alloc] initWithTitle:nil message:errorText cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil] show];
            }
        });
    }
    else if ([path hasPrefix:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/deleteMember/", _conversationId]])
    {
        NSRange range = [path rangeOfString:@"/deleteMember/("];
        int32_t uid = (int32_t)[[path substringFromIndex:(range.location + range.length)] intValue];
        
        TGDispatchOnMainThread(^
        {
            [_soonToBeRemovedUserIds removeObject:@(uid)];
            
            if (status == ASStatusSuccess)
            {
                TGConversation *updatedConversation = [_conversation copy];
                updatedConversation.chatParticipants = [_conversation.chatParticipants copy];
                [updatedConversation.chatParticipants removeParticipantWithId:uid];
                _conversation = updatedConversation;
                
                [self _updateLeftState];
                
                for (id item in _usersSection.items)
                {
                    if ([item isKindOfClass:[TGGroupInfoUserCollectionItem class]] && ((TGGroupInfoUserCollectionItem *)item).user.uid == uid)
                    {
                        NSIndexPath *indexPath = [self indexPathForItem:item];
                        if (indexPath != nil)
                        {
                            [self.menuSections beginRecordingChanges];
                            [self.menuSections deleteItemFromSection:indexPath.section atIndex:indexPath.item];
                            [self.menuSections commitRecordedChanges:self.collectionView];
                            
                            [self _updateAllowCellEditing:true];
                        }
                        
                        break;
                    }
                }
            }
            else
            {
                for (id item in _usersSection.items)
                {
                    if ([item isKindOfClass:[TGGroupInfoUserCollectionItem class]] && ((TGGroupInfoUserCollectionItem *)item).user.uid == uid)
                    {
                        [(TGGroupInfoUserCollectionItem *)item setDisabled:false];
                        
                        break;
                    }
                }
            }
        });
    }
    else if ([path hasPrefix:[[NSString alloc] initWithFormat:@"/tg/conversation/(%" PRId64 ")/changeTitle/", _conversation.conversationId]])
    {
        TGDispatchOnMainThread(^
        {
            [_groupInfoItem setUpdatingTitle:nil];
            
            if (status == ASStatusSuccess)
            {
                TGConversation *resultConversation = ((SGraphObjectNode *)result).object;
                
                TGConversation *updatedConversation = [_conversation copy];
                updatedConversation.chatTitle = resultConversation.chatTitle;
                _conversation = updatedConversation;
                
                [self _updateLeftState];
                
                [_groupInfoItem setConversation:_conversation];
                
                
                GroupDiscoverPrivilege privilege = [TGDatabaseInstance() getPrivilegeWithConversationId:_conversationId];
                
                //由update方法改成create方法，防止未在服务端创建的群组信息无法更新
                [T8GroupAndCommunityService createCommunityWithThirdGroupID:_conversationId createrID:T8CONTEXT.t8UserId image:nil memberCount:_conversation.chatParticipantCount privilege:privilege name:resultConversation.chatTitle description:nil language:nil imageKey:_conversation.chatPhotoSmall success:^(NSDictionary __unused *dictRet) {
                    
                } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                    
                }];
                
//                [T8GroupAndCommunityService updateCommunityPrivilege:_conversationId privilege:privilege image:nil memberCount:_conversation.chatParticipantCount name:resultConversation.chatTitle description:nil success:^(NSDictionary __unused *dictRet) {
//                    
//                } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
//                    
//                }];
            }
        });
    }
    else if ([path hasPrefix:[[NSString alloc] initWithFormat:@"/tg/conversation/(%" PRId64 ")/updateAvatar/", _conversation.conversationId]])
    {
        TGDispatchOnMainThread(^
        {
            if (status == ASStatusSuccess)
            {
                TGConversation *resultConversation = ((SGraphObjectNode *)result).object;
                
                TGConversation *updatedConversation = [_conversation copy];
                updatedConversation.chatPhotoSmall = resultConversation.chatPhotoSmall;
                updatedConversation.chatPhotoMedium = resultConversation.chatPhotoMedium;
                updatedConversation.chatPhotoBig = resultConversation.chatPhotoBig;
                _conversation = updatedConversation;
                
                [self _updateLeftState];
                
                [_groupInfoItem copyUpdatingAvatarToCacheWithUri:_conversation.chatPhotoSmall];
                [_groupInfoItem setConversation:_conversation];
                
                [_groupInfoItem setUpdatingAvatar:nil hasUpdatingAvatar:false];
                [_setGroupPhotoItem setEnabled:true];
                
                //synchronous to Dove
//                TGLetteredAvatarView *avatarView = [_groupInfoItem avatarView];
                
                GroupDiscoverPrivilege privilege = [TGDatabaseInstance() getPrivilegeWithConversationId:_conversationId];
                
                //由update方法改成create方法，防止未在服务端创建的群组信息无法更新
                [T8GroupAndCommunityService createCommunityWithThirdGroupID:_conversationId createrID:T8CONTEXT.t8UserId image:nil memberCount:_conversation.chatParticipantCount privilege:privilege name:resultConversation.chatTitle description:nil language:nil imageKey:_conversation.chatPhotoSmall success:^(NSDictionary __unused *dictRet) {
                    
                } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                    
                }];
                
//                __weak typeof(self) weakSelf = self;
//                [T8HudHelper showHUDActivity:TGLocalized(@"Discover.Waiting") parentView:self.view];
//                [[T8ImageUploadManager sharedInstance] uploadImage:avatarView.currentImage tmpName:@(_conversationId).stringValue successBlock:^(NSString *url) {
//                    [T8GroupAndCommunityService updateCommunityPrivilege:_conversationId privilege:privilege image:url memberCount:_conversation.chatParticipantCount name:nil description:nil success:^(NSDictionary __unused *dictRet) {
//                        __strong typeof(weakSelf) strongSelf = weakSelf;
//                        [strongSelf.navigationController popViewControllerAnimated:YES];
//                        [T8HudHelper hideHUDActivity:self.view];
//                    } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
//                        [T8HudHelper hideHUDActivity:self.view];
//                    }];
//                } failureBlock:^{
//                    [T8HudHelper hideHUDActivity:self.view];
//                }];
            }
            else
            {
                [_groupInfoItem setUpdatingAvatar:nil hasUpdatingAvatar:false];
                [_setGroupPhotoItem setEnabled:true];
            }
        });
    }
}

@end
