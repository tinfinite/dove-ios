/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGCreateGroupController.h"

#import "ActionStage.h"
#import "SGraphObjectNode.h"

#import "TGDatabase.h"

#import "TGInterfaceManager.h"

#import "TGGroupInfoCollectionItem.h"
#import "TGGroupInfoUserCollectionItem.h"

#import "TGProgressWindow.h"

#import "TGAlertView.h"
#import "TGTextViewCollectionItem.h"
#import "TGSwitchCollectionItem.h"
#import "TGVariantCollectionItem.h"
#import "TGCommentCollectionItem.h"

#import "TGPickerSheet.h"
#import "T8GroupAndCommunityService.h"

@interface TGCreateGroupController ()
{
    NSArray *_userIds;
    bool _createBroadcast;
    
    TGGroupInfoCollectionItem *_groupInfoItem;
    
    TGCollectionMenuSection *_describeSection;
    TGTextViewCollectionItem *_describeItem;
    
    TGCollectionMenuSection *_settingSection;
    TGVariantCollectionItem *_languageItem;
    TGVariantCollectionItem *_groupTypeItem;
    TGCommentCollectionItem *_groupTypeCommentItem;
    
    TGCollectionMenuSection *_usersSection;
    
    TGProgressWindow *_progressWindow;
    
    bool _makeFieldFirstResponder;
}

@property (nonatomic, strong) NSString *groupTypeKey;
@property (nonatomic, strong) NSString *lanKey;
@property (nonatomic, strong) TGPickerSheet *groupTypeSheet;
@property (nonatomic, strong) TGPickerSheet *languageSheet;
@property (nonatomic, strong) NSArray *groupTypeArray;
@property (nonatomic, strong) NSArray *languageArray;

@end

@implementation TGCreateGroupController

- (instancetype)init
{
    return [self initWithCreateBroadcast:false];
}

- (instancetype)initWithCreateBroadcast:(bool)createBroadcast
{
    self = [super init];
    if (self)
    {
        _createBroadcast = createBroadcast;
        
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        [self setTitleText:_createBroadcast ? TGLocalized(@"Compose.Recipients") : TGLocalized(@"Compose.NewGroup")];
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Create") style:UIBarButtonItemStyleDone target:self action:@selector(createPressed)]];
        self.navigationItem.rightBarButtonItem.enabled = _createBroadcast;
        
        _groupInfoItem = [[TGGroupInfoCollectionItem alloc] init];
        _groupInfoItem.isBroadcast = _createBroadcast;
        _groupInfoItem.interfaceHandle = _actionHandle;
        [_groupInfoItem setConversation:nil];
        [_groupInfoItem setEditing:true];
        TGCollectionMenuSection *groupInfoSection = [[TGCollectionMenuSection alloc] initWithItems:@[_groupInfoItem]];
        [self.menuSections addSection:groupInfoSection];
        
        __weak typeof(self) weakSelf = self;
        _describeItem = [[TGTextViewCollectionItem alloc] initWithNumberOfLines:4];
        _describeItem.textChanged = ^(NSString __unused *text)
        {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf != nil) {
                [strongSelf checkCreateStatus];
            }
        };
        _describeItem.placeHolder = TGLocalized(@"Discover.DescribePlaceHolder");
        _describeSection = [[TGCollectionMenuSection alloc] initWithItems:@[_describeItem]];
        [self.menuSections addSection:_describeSection];
        
        _languageItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Language") variant:TGLocalized(self.lanKey) action:@selector(languageSelect)];
        _languageItem.deselectAutomatically = true;
        _groupTypeItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.GroupType") variant:TGLocalized(@"GroupInfo.Public") action:@selector(groupBoardSelect)];
        _groupTypeItem.deselectAutomatically = true;
        _groupTypeCommentItem = [[TGCommentCollectionItem alloc] initWithText:TGLocalized(@"GroupInfo.GroupTypeDes")];
        _settingSection = [[TGCollectionMenuSection alloc] initWithItems:@[_languageItem, _groupTypeItem, _groupTypeCommentItem]];
        [self.menuSections addSection:_settingSection];
        
        _usersSection = [[TGCollectionMenuSection alloc] init];
        [self.menuSections addSection:_usersSection];
        
        _makeFieldFirstResponder = true;
    }
    return self;
}

- (void)dealloc
{
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

- (TGPickerSheet *)groupTypeSheet
{
    if (!_groupTypeSheet) {
        __weak typeof(self) weakSelf = self;
        _groupTypeSheet = [[TGPickerSheet alloc] initWithItems:self.groupTypeArray selectedIndex:0 type:PickerSheetTypeLanguage action:^(id item) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ([item isKindOfClass:[NSString class]]) {
                strongSelf.groupTypeKey = item;
                _groupTypeItem.variant = TGLocalized(item);
            }
        }];
    }
    return _groupTypeSheet;
}

- (TGPickerSheet *)languageSheet
{
    if (!_languageSheet) {
        __weak typeof(self) weakSelf = self;
        _languageSheet = [[TGPickerSheet alloc] initWithItems:self.languageArray selectedIndex:0 type:PickerSheetTypeLanguage action:^(id item) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ([item isKindOfClass:[NSString class]]) {
                strongSelf.lanKey = item;
                _languageItem.variant = TGLocalized(item);
            }
        }];
    }
    return _languageSheet;
}

- (NSArray *)groupTypeArray
{
    if (!_groupTypeArray) {
        _groupTypeArray = [NSArray arrayWithObjects:@"GroupInfo.Public", @"GroupInfo.Private", nil];
    }
    return _groupTypeArray;
}

- (NSArray *)languageArray
{
    if (!_languageArray) {
        _languageArray = [NSArray arrayWithObjects:@"zh", @"en", nil];
    }
    return _languageArray;
}

- (NSString *)groupTypeKey
{
    if (!_groupTypeKey) {
        _groupTypeKey = self.groupTypeArray.firstObject;
    }
    return _groupTypeKey;
}

- (NSString *)lanKey
{
    if (!_lanKey) {
        NSString *systemLan = [NSLocale preferredLanguages].firstObject;
        if ([systemLan isEqualToString:@"zh-Hans"]) {
            systemLan = @"zh";
        }else{
            systemLan = @"en";
        }
        _lanKey = systemLan;
    }
    return _lanKey;
}

- (void)checkCreateStatus
{
    self.navigationItem.rightBarButtonItem.enabled = _createBroadcast || ([_groupInfoItem.editingTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length != 0 && [_describeItem.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length != 0);
}

- (void)groupBoardSelect
{
    [self.collectionView endEditing:YES];
    
    self.groupTypeSheet.selectedIndex = [self.groupTypeArray indexOfObject:self.groupTypeKey]==NSNotFound?0:[self.groupTypeArray indexOfObject:self.groupTypeKey];
    [self.groupTypeSheet show];
}

- (void)languageSelect
{
    [self.collectionView endEditing:YES];
    
    self.languageSheet.selectedIndex = [self.languageArray indexOfObject:self.lanKey]==NSNotFound?0:[self.languageArray indexOfObject:self.lanKey];
    [self.languageSheet show];
}

- (void)createPressed
{
    if (_userIds.count != 0 && (_groupInfoItem.editingTitle.length != 0 || _createBroadcast))
    {
        if (_createBroadcast)
        {
            if (_onCreateBroadcastList != nil)
                _onCreateBroadcastList(_groupInfoItem.editingTitle, _userIds);
        }
        else
        {
            _progressWindow = [[TGProgressWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            [_progressWindow show:true];
            
            static int actionId = 0;
            [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversation/createChat/(%d)", actionId++] options:@{
                @"uids": _userIds,
                @"title": [_groupInfoItem.editingTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
            } watcher:self];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (_makeFieldFirstResponder)
    {
        _makeFieldFirstResponder = false;
        [_groupInfoItem makeNameFieldFirstResponder];
    }
}

- (void)setUserIds:(NSArray *)userIds
{
    _userIds = userIds;
    
    NSMutableArray *users = [[NSMutableArray alloc] init];
    for (NSNumber *nUid in _userIds)
    {
        TGUser *user = [TGDatabaseInstance() loadUser:[nUid int32Value]];
        if (user != nil)
            [users addObject:user];
    }
    
    NSUInteger usersSectionIndex = [self indexForSection:_usersSection];
    if (usersSectionIndex != NSNotFound)
    {
        for (int i = _usersSection.items.count - 1; i >= 0; i--)
        {
            [self.menuSections deleteItemFromSection:usersSectionIndex atIndex:0];
        }
    }
    
    for (TGUser *user in users)
    {
        TGGroupInfoUserCollectionItem *userItem = [[TGGroupInfoUserCollectionItem alloc] init];
        [userItem setUser:user];
        userItem.selectable = false;
        [userItem setCanEdit:false];
        [self.menuSections addItemToSection:usersSectionIndex item:userItem];
    }
    
    [self.collectionView reloadData];
}

#pragma mark -

- (void)actionStageActionRequested:(NSString *)action options:(id)__unused options
{
    if ([action isEqualToString:@"editedTitleChanged"])
    {
//        self.navigationItem.rightBarButtonItem.enabled = _createBroadcast || [_groupInfoItem.editingTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length != 0;
        [self checkCreateStatus];
        TGConversation *conversation = [[TGConversation alloc] init];
        conversation.chatTitle = _groupInfoItem.editingTitle;
        [_groupInfoItem setConversation:conversation];
    }
}

- (void)actorCompleted:(int)status path:(NSString *)path result:(id)result
{
    if ([path hasPrefix:@"/tg/conversation/createChat/"])
    {
        TGDispatchOnMainThread(^
        {
            [_progressWindow dismiss:true];
            
            if (status == ASStatusSuccess)
            {
                TGConversation *conversation = ((SGraphObjectNode *)result).object;
                [[TGInterfaceManager instance] navigateToConversationWithId:conversation.conversationId conversation:nil];
                
                //创建成功后调用接口show in discover
                __weak typeof(self) weakSelf = self;
                GroupDiscoverPrivilege privilege = GroupDiscoverPrivilegePublic;
                if (![self.groupTypeKey isEqualToString:@"GroupInfo.Public"]) {
                    privilege = GroupDiscoverPrivilegePrivate;
                }
                [T8GroupAndCommunityService createCommunityWithThirdGroupID:conversation.conversationId createrID:T8CONTEXT.t8UserId image:nil memberCount:conversation.chatParticipantCount privilege:privilege name:conversation.chatTitle description:_describeItem.text language:self.lanKey imageKey:conversation.chatPhotoSmall success:^(NSDictionary __unused *dictRet) {
                    
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [TGDatabaseInstance() storeConversationInfoWithId:conversation.conversationId privilege:privilege description:_describeItem.text language:strongSelf.lanKey];
//                    [TGDatabaseInstance() storeConversationInfoWithId:conversation.conversationId groupBoardStatus:[strongSelf.groupBoardKey isEqualToString:strongSelf.groupBoardArray.firstObject]?GroupBoardStatusPublic:GroupBoardStatusPrivate];
                    
                } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                    
                }];
            }
            else
            {
                TGAlertView *alertView = [[TGAlertView alloc] initWithTitle:nil message:TGLocalized(@"ConversationProfile.ErrorCreatingConversation") delegate:nil cancelButtonTitle:TGLocalized(@"Common.OK") otherButtonTitles:nil];
                [alertView show];
            }
        });
    }
}

@end
