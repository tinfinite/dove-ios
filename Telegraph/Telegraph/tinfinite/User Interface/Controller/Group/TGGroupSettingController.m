//
//  TGGroupSettingController.m
//  Telegraph
//
//  Created by yewei on 15/4/10.
//
//

#import "TGGroupSettingController.h"

#import "TGSwitchCollectionItem.h"
#import "TGVariantCollectionItem.h"
#import "TGCollectionMenuSection.h"
#import "TGCommentCollectionItem.h"

#import "T8StickToTopManager.h"
#import "TGDatabase.h"
#import "TGTelegraph.h"
#import "T8GroupAndCommunityService.h"
#import "TGAlertSoundController.h"
#import "TGAppDelegate.h"
#import "TGNavigationController.h"
#import "TGNavigationBar.h"
#import "SGraphObjectNode.h"
#import "TGDiscoverManageViewController.h"
#import "TGLetteredAvatarView.h"
#import "TGAlertView.h"
#import "TGPickerSheet.h"
#import "TGGroupIntroductionController.h"

@interface TGGroupSettingController ()<TGAlertSoundControllerDelegate>
{
    int64_t _conversationId;
    TGConversation *_conversation;
    
    TGCollectionMenuSection *_notificationsAndStickSection;
    TGSwitchCollectionItem *_notificationsItem;
    TGVariantCollectionItem *_soundItem;
    TGSwitchCollectionItem *_stickToTopItem;
    
    TGCollectionMenuSection *_anonymousSection;
    TGSwitchCollectionItem *_anonymousItem;
    TGCommentCollectionItem *_describeCommentItem;
    
//    TGCollectionMenuSection *_showInDiscoverSection;
//    TGVariantCollectionItem *_showInDiscoverItem;
//    TGSwitchCollectionItem *_groupBoardItem;
//    TGCommentCollectionItem *_groupBoardDesItem;
    
    TGCollectionMenuSection *_groupTypeSection;
    TGVariantCollectionItem *_introductionItem;
    TGVariantCollectionItem *_languageItem;
    TGVariantCollectionItem *_groupTypeItem;
    TGCommentCollectionItem *_groupTypeDesItem;
    
    NSMutableDictionary *_groupNotificationSettings;
    UIImage *_groupAvatar;
}

@property (nonatomic,copy) NSString *lanKey;
@property (nonatomic,strong) NSArray *lanArr;
@property (nonatomic,strong) TGPickerSheet *lanSheet;

@property (nonatomic,copy) NSString *groupTypeKey;
@property (nonatomic,strong) NSArray *groupTypeArr;
@property (nonatomic,strong) TGPickerSheet *groupTypeSheet;

@end

@implementation TGGroupSettingController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    __weak typeof(self) weakSelf = self;
    [T8GroupAndCommunityService getAnonymousInfoWithGroupId:@(ABS(_conversationId)).stringValue successBlock:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf _updateAnonymousItem:[dictRet[@"status"] boolValue]];
        [TGDatabaseInstance() storeConversationInfoWithId:_conversationId anonymous:[dictRet[@"status"] boolValue]];
    } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        
    } ];
}

- (instancetype)initWithConversationId:(int64_t)conversationId groupAvatar:(UIImage *)groupAvatar
{
    self = [super init];
    if (self != nil) {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _conversationId = conversationId;
        _groupAvatar = groupAvatar;
        
        [self setTitleText:TGLocalized(@"GroupInfo.GroupSettings")];
        
        _notificationsItem = [[TGSwitchCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Notifications") isOn:true];
        _notificationsItem.interfaceHandle = _actionHandle;
        
        _stickToTopItem = [[TGSwitchCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Stick") isOn:[[T8StickToTopManager sharedInstance] checkConversationIsStickedWithID:[NSString stringWithFormat:@"%lld",_conversationId]]];
        _stickToTopItem.interfaceHandle = _actionHandle;
        _soundItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Sound") variant:nil action:@selector(soundPressed)];
        _soundItem.deselectAutomatically = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        
        _notificationsAndStickSection = [[TGCollectionMenuSection alloc] initWithItems:@[
                   _notificationsItem,_stickToTopItem,_soundItem]];
        UIEdgeInsets notificationsAndStickInsets = _notificationsAndStickSection.insets;
        notificationsAndStickInsets.top = 30;
        _notificationsAndStickSection.insets = notificationsAndStickInsets;
        [self.menuSections addSection:_notificationsAndStickSection];
        
        _anonymousItem = [[TGSwitchCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Anonymous") isOn:T8CONTEXT.anonymous?false:[TGDatabaseInstance() getAnonymousWithConversationId:_conversationId]];
        _anonymousItem.interfaceHandle = _actionHandle;
        
        _describeCommentItem = [[TGCommentCollectionItem alloc] initWithText:TGLocalized(@"GroupInfo.AnonymousDescribe")];
        
        _anonymousSection = [[TGCollectionMenuSection alloc] initWithItems:@[            _anonymousItem,_describeCommentItem]];
        UIEdgeInsets anonymousInsets = _anonymousSection.insets;
        anonymousInsets.bottom = 36;
        _anonymousSection.insets = anonymousInsets;
        [self.menuSections addSection:_anonymousSection];
        
        TGConversation *conversation = [TGDatabaseInstance() loadConversationWithId:_conversationId];
        int adminId = conversation.chatParticipants.chatAdminId;
        
        if (adminId == TGTelegraphInstance.clientUserId) {
            
            _introductionItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Introduction") action:@selector(introductionPressed)];
            _introductionItem.deselectAutomatically = true;
            
            NSString *lanKey = [TGDatabaseInstance() getLanguageWithConversationId:_conversationId];
            _languageItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Language") variant:TGLocalized(lanKey) action:@selector(languagePressed)];
            _languageItem.deselectAutomatically = true;
            self.lanKey = lanKey;
            
            _groupTypeItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.GroupType") variant:@"" action:@selector(groupTypePressed)];
            _groupTypeItem.deselectAutomatically = true;
            GroupDiscoverPrivilege privilege = [TGDatabaseInstance() getPrivilegeWithConversationId:_conversationId];
            if (privilege == GroupDiscoverPrivilegePublic) {
                self.groupTypeKey = self.groupTypeArr.firstObject;
            }else{
                self.groupTypeKey = self.groupTypeArr.lastObject;
            }
            
            _groupTypeDesItem = [[TGCommentCollectionItem alloc] initWithText:TGLocalized(@"GroupInfo.GroupTypeDes")];
            
            _groupTypeSection = [[TGCollectionMenuSection alloc] initWithItems:@[_introductionItem, _languageItem, _groupTypeItem, _groupTypeDesItem]];
            [self.menuSections addSection:_groupTypeSection];
            
//            GroupDiscoverPrivilege privilege = [TGDatabaseInstance() getPrivilegeWithConversationId:_conversationId];
//            _showInDiscoverItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Discover") variant:privilege==GroupDiscoverPrivilegePublic?TGLocalized(@"Discover.On"):TGLocalized(@"Discover.Off") action:@selector(enterDiscoverPage)];
//            
//            GroupBoardStatus status = [TGDatabaseInstance() getGroupBoardStatusWithConversationId:_conversationId];
//            _groupBoardItem = [[TGSwitchCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.OpenGroupBoard") isOn:(status==GroupBoardStatusPrivate?false:true)];
//            _groupBoardItem.interfaceHandle = _actionHandle;
//            _groupBoardDesItem = [[TGCommentCollectionItem alloc] initWithText:TGLocalized(@"GroupInfo.OpenGroupBoardDes")];
//            _showInDiscoverSection = [[TGCollectionMenuSection alloc] initWithItems:@[            _showInDiscoverItem, _groupBoardItem, _groupBoardDesItem]];
//            [self.menuSections addSection:_showInDiscoverSection];
        }
        
        [self _updateNotificationItems:false];
        
        [ActionStageInstance() dispatchOnStageQueue:^
         {
             [ActionStageInstance() watchForPath:[NSString stringWithFormat:@"/tg/peerSettings/(%" PRId64 ")", _conversationId] watcher:self];
             [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/peerSettings/(%" PRId64 ",cachedOnly)", _conversationId] options:@{@"peerId": @(_conversationId)} watcher:self];
         }];
    }
    return self;
}

- (void)dealloc
{
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

- (void)actionStageActionRequested:(NSString *)action options:(id)options
{
    if ([action isEqualToString:@"switchItemChanged"])
    {
        TGSwitchCollectionItem *switchItem = options[@"item"];
        if (switchItem == _notificationsItem)
            [self _changeNotificationSettings:switchItem.isOn];
        if (switchItem == _stickToTopItem) {
            [self _changeStickStatus:switchItem.isOn];
        }
        if (switchItem == _anonymousItem) {
            if (switchItem.isOn) {
                if (T8CONTEXT.anonymous) {
                    TGAlertView *alert = [[TGAlertView alloc] initWithTitle:TGLocalized(@"Settings.AnonymousAlert") message:nil cancelButtonTitle:nil okButtonTitle:TGLocalized(@"Common.OK") completBlock:nil];
                    [alert show];
                    switchItem.isOn = false;
                }else{
                    [self _changeAnonymousStatus:switchItem.isOn];
                }
            }else{
                [self _changeAnonymousStatus:switchItem.isOn];
            }
        }
    }
}

- (void)actionStageResourceDispatched:(NSString *)path resource:(id)resource arguments:(id)__unused arguments
{
    if ([path hasPrefix:@"/tg/peerSettings/"])
    {
        [self actorCompleted:ASStatusSuccess path:path result:resource];
    }
}

- (void)actorCompleted:(int)status path:(NSString *)path result:(id)result
{
    if ([path hasPrefix:@"/tg/peerSettings/"])
    {
        if (status == ASStatusSuccess)
        {
            NSDictionary *notificationSettings = ((SGraphObjectNode *)result).object;
            
            TGDispatchOnMainThread(^
                                   {
                                       _groupNotificationSettings = [notificationSettings mutableCopy];
                                       [self _updateNotificationItems:false];
                                   });
        }
    }
}

#pragma mark -
- (void)introductionPressed
{
    TGGroupIntroductionController *introduction = [[TGGroupIntroductionController alloc] initWithConversationId:_conversationId];
    [self.navigationController pushViewController:introduction animated:YES];
}

- (void)languagePressed
{
    self.lanSheet.selectedIndex = [self.lanArr indexOfObject:self.lanKey]==NSNotFound?0:[self.lanArr indexOfObject:self.lanKey];
    [self.lanSheet show];
}

- (void)groupTypePressed
{
    self.groupTypeSheet.selectedIndex = [self.groupTypeArr indexOfObject:self.groupTypeKey]==NSNotFound?0:[self.groupTypeArr indexOfObject:self.groupTypeKey];
    [self.groupTypeSheet show];
}

- (void)soundPressed
{
    TGAlertSoundController *alertSoundController = [[TGAlertSoundController alloc] initWithTitle:TGLocalized(@"GroupInfo.Sound") soundInfoList:[self _soundInfoListForSelectedSoundId:[_groupNotificationSettings[@"soundId"] intValue]]];
    alertSoundController.delegate = self;
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[alertSoundController] navigationBarClass:[TGWhiteNavigationBar class]];
    if ([self inPopover])
    {
        navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleChildInPopover;
    }
    
    [self presentViewController:navigationController animated:true completion:nil];
}

- (void)alertSoundController:(TGAlertSoundController *)__unused alertSoundController didFinishPickingWithSoundInfo:(NSDictionary *)soundInfo
{
    if (soundInfo[@"soundId"] != nil && [soundInfo[@"soundId"] intValue] >= 0 && [soundInfo[@"soundId"] intValue] != [_groupNotificationSettings[@"soundId"] intValue])
    {
        int soundId = [soundInfo[@"soundId"] intValue];
        _groupNotificationSettings[@"soundId"] = @(soundId);
        [self _updateNotificationItems:false];
        
        static int actionId = 0;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/changePeerSettings/(%" PRId64 ")/(groupInfoController%d)", _conversationId, actionId++] options:@{
                                                                                                                                                                               @"peerId": @(_conversationId),
                                                                                                                                                                               @"soundId": @(soundId)
                                                                                                                                                                               } watcher:TGTelegraphInstance];
    }
}

- (NSString *)soundNameFromId:(int)soundId
{
    if (soundId == 0 || soundId == 1)
        return [TGAppDelegateInstance modernAlertSoundTitles][soundId];
    
    if (soundId >= 2 && soundId <= 9)
        return [TGAppDelegateInstance classicAlertSoundTitles][MAX(0, soundId - 2)];
    
    if (soundId >= 100 && soundId <= 111)
        return [TGAppDelegateInstance modernAlertSoundTitles][soundId - 100 + 2];
    return @"";
}

- (NSArray *)_soundInfoListForSelectedSoundId:(int)selectedSoundId
{
    NSMutableArray *infoList = [[NSMutableArray alloc] init];
    
    int defaultSoundId = 1;
    [TGDatabaseInstance() loadPeerNotificationSettings:INT_MAX - 2 soundId:&defaultSoundId muteUntil:NULL previewText:NULL photoNotificationsEnabled:NULL notFound:NULL];
    NSString *defaultSoundTitle = [self soundNameFromId:defaultSoundId];
    
    int index = -1;
    for (NSString *soundName in [TGAppDelegateInstance modernAlertSoundTitles])
    {
        index++;
        
        int soundId = 0;
        bool isDefault = false;
        
        if (index == 1)
        {
            soundId = 1;
            isDefault = true;
        }
        else if (index == 0)
            soundId = 0;
        else
            soundId = index + 100 - 2;
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict[@"title"] = isDefault ? [[NSString alloc] initWithFormat:@"%@ (%@)", soundName, defaultSoundTitle] : soundName;
        dict[@"selected"] = @(selectedSoundId == soundId);
        dict[@"soundName"] = [[NSString alloc] initWithFormat:@"%d", isDefault ? defaultSoundId : soundId];
        dict[@"soundId"] = @(soundId);
        dict[@"groupId"] = @(0);
        [infoList addObject:dict];
    }
    
    index = -1;
    for (NSString *soundName in [TGAppDelegateInstance classicAlertSoundTitles])
    {
        index++;
        
        int soundId = index + 2;
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict[@"title"] = soundName;
        dict[@"selected"] = @(selectedSoundId == soundId);
        dict[@"soundName"] =  [[NSString alloc] initWithFormat:@"%d", soundId];
        dict[@"soundId"] = @(soundId);
        dict[@"groupId"] = @(1);
        [infoList addObject:dict];
    }
    
    return infoList;
}

- (void)_updateAnonymousItem:(BOOL)animated
{
    [_anonymousItem setIsOn:T8CONTEXT.anonymous?false:animated];
}

- (void)_changeStickStatus:(BOOL)stick
{
    [[T8StickToTopManager sharedInstance] stickConversationWithID:[NSString stringWithFormat:@"%lld",_conversationId] action:stick];
}


- (void)_updateNotificationItems:(bool)animated
{
    [_notificationsItem setIsOn:[_groupNotificationSettings[@"muteUntil"] intValue] == 0 animated:animated];
    
    int groupSoundId = [[_groupNotificationSettings objectForKey:@"soundId"] intValue];
    _soundItem.variant = [self soundNameFromId:groupSoundId];
}

- (void)_changeNotificationSettings:(bool)enableNotifications
{
    _groupNotificationSettings[@"muteUntil"] = @(!enableNotifications ? INT_MAX : 0);
    
    static int actionId = 0;
    [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/changePeerSettings/(%" PRId64 ")/(groupInfoController%d)", _conversation.conversationId, actionId++] options:@{@"peerId": @(_conversationId), @"muteUntil": @(!enableNotifications ? INT_MAX : 0)} watcher:TGTelegraphInstance];
}

- (void)_changeAnonymousStatus:(BOOL)anonymous
{
    [T8GroupAndCommunityService updateAnonymousInfoWithGroupId:@(ABS(_conversationId)).stringValue status:anonymous successBlock:^(NSDictionary __unused *dictRet) {
        [TGDatabaseInstance() storeConversationInfoWithId:_conversationId anonymous:anonymous];
    } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        
    }];
}

- (void)enterDiscoverPage
{
    TGDiscoverManageViewController *discover = [[TGDiscoverManageViewController alloc] initWithConversationId:_conversationId];
    discover.groupAvatar = _groupAvatar;
    [self.navigationController pushViewController:discover animated:YES];
}

#pragma mark - getter
- (NSArray *)lanArr
{
    if (!_lanArr) {
        _lanArr = [NSArray arrayWithObjects:@"zh", @"en", nil];
    }
    return _lanArr;
}

- (NSArray *)groupTypeArr
{
    if (!_groupTypeArr) {
        _groupTypeArr = [NSArray arrayWithObjects:@"GroupInfo.Public", @"GroupInfo.Private", nil];
    }
    return _groupTypeArr;
}

- (TGPickerSheet *)lanSheet
{
    if (!_lanSheet) {
        __weak typeof(self) weakSelf = self;
        _lanSheet = [[TGPickerSheet alloc] initWithItems:self.lanArr selectedIndex:[self.lanArr indexOfObject:self.lanKey] type:PickerSheetTypeLanguage action:^(id item) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.lanKey = item;
            [TGDatabaseInstance() storeConversationInfoWithId:_conversationId privilege:GroupDiscoverPrivilegeUnknow description:nil language:item];
            [T8GroupAndCommunityService createCommunityWithThirdGroupID:_conversationId createrID:T8CONTEXT.t8UserId image:nil memberCount:-1 privilege:GroupDiscoverPrivilegeUnknow name:nil description:nil language:item imageKey:nil success:^(NSDictionary __unused *dictRet) {
                
            } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                
            }];
        }];
    }
    return _lanSheet;
}

- (TGPickerSheet *)groupTypeSheet
{
    if (!_groupTypeSheet) {
        __weak typeof(self) weakSelf = self;
        _groupTypeSheet = [[TGPickerSheet alloc] initWithItems:self.groupTypeArr selectedIndex:[self.groupTypeArr indexOfObject:self.groupTypeKey] type:PickerSheetTypeLanguage action:^(id item) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.groupTypeKey = item;
            GroupDiscoverPrivilege privilege = GroupDiscoverPrivilegeUnknow;
            if ([strongSelf.groupTypeArr indexOfObject:item] == 0) {
                privilege = GroupDiscoverPrivilegePublic;
            }else if ([strongSelf.groupTypeArr indexOfObject:item] == 1){
                privilege = GroupDiscoverPrivilegePrivate;
            }
            [TGDatabaseInstance() storeConversationInfoWithId:_conversationId privilege:privilege description:nil language:nil];
            [T8GroupAndCommunityService createCommunityWithThirdGroupID:_conversationId createrID:T8CONTEXT.t8UserId image:nil memberCount:-1 privilege:privilege name:nil description:nil language:nil imageKey:nil success:^(NSDictionary __unused *dictRet) {
                
            } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                
            }];
        }];
    }
    return _groupTypeSheet;
}

#pragma mark - setter
- (void)setGroupTypeKey:(NSString *)groupTypeKey
{
    _groupTypeKey = groupTypeKey;
    
    _groupTypeItem.variant = TGLocalized(groupTypeKey);
}

- (void)setLanKey:(NSString *)lanKey
{
    _lanKey = lanKey;
    
    _languageItem.variant = TGLocalized(lanKey);
}

@end
