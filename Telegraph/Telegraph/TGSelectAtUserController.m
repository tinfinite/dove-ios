//
//  TGSelectAtUserController.m
//  Telegraph
//
//  Created by yewei on 15/2/8.
//
//

#import "TGSelectAtUserController.h"

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

@interface TGSelectAtUserController ()<TGGroupInfoSelectContactControllerDelegate, TGAlertSoundControllerDelegate>
{
    bool _editing;
    bool _haveEditableUsers;
    
    int64_t _conversationId;
    TGConversation *_conversation;
    
    TGGroupInfoCollectionItem *_groupInfoItem;
    TGButtonCollectionItem *_setGroupPhotoItem;
    
    TGCollectionMenuSection *_notificationsAndMediaSection;
    TGSwitchCollectionItem *_notificationsItem;
    TGVariantCollectionItem *_sharedMediaItem;
    TGVariantCollectionItem *_soundItem;
    
    TGCollectionMenuSection *_usersSection;
    TGHeaderCollectionItem *_usersSectionHeader;
    
    NSMutableDictionary *_groupNotificationSettings;
    NSInteger _sharedMediaCount;
    
    NSMutableArray *_soonToBeAddedUserIds;
    NSMutableArray *_soonToBeRemovedUserIds;
    
    UILabel *_leftLabel;
}

@end

@implementation TGSelectAtUserController

- (instancetype)initWithConversationId:(int64_t)conversationId
{
    self = [super init];
    if (self != nil)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _conversationId = conversationId;
        
//        [self setTitleText:@"select at user"];
//        [self setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(dismissSelf)] animated:false];
        
        _usersSectionHeader = [[TGHeaderCollectionItem alloc] initWithTitle:@""];
        _usersSection = [[TGCollectionMenuSection alloc] initWithItems:@[_usersSectionHeader]];
        [self.menuSections addSection:_usersSection];
        
        [self _loadUsersAndUpdateConversation:[TGDatabaseInstance() loadConversationWithIdCached:_conversationId]];
    }
    return self;
}

#pragma mark -

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self _layoutLeftLabel:self.interfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self _layoutLeftLabel:toInterfaceOrientation];
}

#pragma mark -

- (void)dismissSelf
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -

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
            int count = _usersSection.items.count - 2;
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

- (void)actionStageActionRequested:(NSString *)action options:(id)options
{
    if ([action isEqualToString:@"openUser"])
    {
        if ([self.delegate respondsToSelector:@selector(didSelectAtUser:)]) {
            int uid = [options[@"uid"] intValue];
            if (uid != 0)
            {
                [self.delegate didSelectAtUser:uid];
                [self dismissSelf];
            }
        }
    }
}


@end
