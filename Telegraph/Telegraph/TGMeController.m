//
//  TGMeController.m
//  Telegraph
//
//  Created by yewei on 15/4/19.
//
//

#import "TGMeController.h"

#import "ActionStage.h"
#import "SGraphObjectNode.h"

#import "TGActionSheet.h"
#import "TGAlertView.h"
#import "TGProgressWindow.h"
#import "TGRemoteImageView.h"

#import "TGDeleteProfilePhotoActor.h"
#import "TGTimelineUploadPhotoRequestBuilder.h"

#import "TGLegacyCameraController.h"
#import "TGImagePickerController.h"
#import "TGImageSearchController.h"
#import "TGGlobalSettingsController.h"
#import "TGAccountSettingsController.h"
#import "TGMyCommentedController.h"
#import "TGOverlayControllerWindow.h"

#import "TGAccountInfoCollectionItem.h"
#import "TGButtonCollectionItem.h"
#import "TGVariantCollectionItem.h"
#import "TGUserAvatarGalleryItem.h"
#import "TGDiscoverCollectionItem.h"

#import "TGModernGalleryController.h"
#import "TGProfileUserAvatarGalleryModel.h"

#import "TGDatabase.h"
#import "TGTelegraph.h"
#import "TGInterfaceManager.h"
#import "TGAppDelegate.h"

#import "TGAccountSettingsActor.h"

#import "TGNavigationController.h"

#import "T8UserHttpRequestService.h"
#import "T8NodeHttpRequestService.h"
#import "TGMyPostViewController.h"
#import "TGMyUpvotesController.h"
#import "TGVoteForMeController.h"

@interface TGMeController () <TGImagePickerControllerDelegate, TGLegacyCameraControllerDelegate>
{
    int32_t _uid;
    
    bool _editing;
    
    TGAccountInfoCollectionItem *_profileDataItem;
    TGButtonCollectionItem *_setProfilePhotoItem;
    
    TGDiscoverCollectionItem *_commentsItem;
    TGDiscoverCollectionItem *_VotesItem;
    
    TGDiscoverCollectionItem *_myPostsItem;
    TGDiscoverCollectionItem *_myUpvotesItem;
    
    TGDiscoverCollectionItem *_accountItem;
    TGDiscoverCollectionItem *_settingsItem;
    
    UIBarButtonItem *_accountEditingBarButtonItem;
    
    int _unreadCount;
}

@property (nonatomic, strong) TGProgressWindow *progressWindow;

@end

@implementation TGMeController

- (id)initWithUid:(int32_t)uid
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteNotification:) name:Notification_Key_ReceiveComment object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteNotification:) name:Notification_Key_ReceiveUpvote object:nil];
        
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        [ActionStageInstance() watchForPaths:@[
                                               @"/tg/userdatachanges",
                                               @"/tg/userpresencechanges",
                                               @"/tg/service/synchronizationstate"
                                               ] watcher:self];
        
        [ActionStageInstance() requestActor:@"/tg/service/synchronizationstate" options:nil flags:0 watcher:self];
        
        _uid = uid;
        
        _profileDataItem = [[TGAccountInfoCollectionItem alloc] init];
        _profileDataItem.interfaceHandle = _actionHandle;
        
        _setProfilePhotoItem = [[TGButtonCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.SetProfilePhoto") action:@selector(setProfilePhotoPressed)];
        _setProfilePhotoItem.deselectAutomatically = true;
        
        TGCollectionMenuSection *headerSection = [[TGCollectionMenuSection alloc] initWithItems:@[_profileDataItem]];
        [self.menuSections addSection:headerSection];
        
        _commentsItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.Comments") imageName:@"me_comments" action:@selector(commentsPressed)];
        _commentsItem.deselectAutomatically = true;
        _VotesItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.Votes") imageName:@"me_votes" action:@selector(votesPressed)];
        _VotesItem.deselectAutomatically = true;
        
        TGCollectionMenuSection *socialSection = [[TGCollectionMenuSection alloc] initWithItems:@[_commentsItem, _VotesItem]];
        [self.menuSections addSection:socialSection];
        
        _myPostsItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.MyPosts") imageName:@"me_my_post" action:@selector(myPostsPressed)];
        _myPostsItem.deselectAutomatically = true;
        _myUpvotesItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.MyUpvotes") imageName:@"me_myupvotes" action:@selector(myUpvotesPressed)];
        TGCollectionMenuSection *social1Section = [[TGCollectionMenuSection alloc] initWithItems:@[_myPostsItem, _myUpvotesItem]];
        [self.menuSections addSection:social1Section];
        
        _accountItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.Account") imageName:@"me_accounts" action:@selector(accountPressed)];
        _settingsItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.Title") imageName:@"me_settings" action:@selector(settingsPressed)];
        
        TGCollectionMenuSection *accountAndSettingsSection = [[TGCollectionMenuSection alloc] initWithItems:@[_accountItem, _settingsItem]];
        [self.menuSections addSection:accountAndSettingsSection];
    }
    return self;
}

- (void)dealloc
{
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

- (void)loadView
{
    [super loadView];
    
    _editing = false;
    
    TGUser *user = [TGDatabaseInstance() loadUser:_uid];
    
    [_profileDataItem setUser:user animated:false];
    
    [self setTitleText:TGLocalized(@"Settings.Me")];
    
    _accountEditingBarButtonItem = nil;
    [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Edit") style:UIBarButtonItemStylePlain target:self action:@selector(editButtonPressed)]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self requestUnreadCount];
    
    [ActionStageInstance() dispatchOnStageQueue:^
     {
         NSArray *uploadActions = [ActionStageInstance() rejoinActionsWithGenericPathNow:@"/tg/timeline/@/uploadPhoto/@" prefix:[[NSString alloc] initWithFormat:@"/tg/timeline/(%" PRId32 ")/uploadPhoto/", _uid] watcher:self];
         NSArray *deleteActions = [ActionStageInstance() rejoinActionsWithGenericPathNow:@"/tg/timeline/@/deleteAvatar/@" prefix:[[NSString alloc] initWithFormat:@"/tg/timeline/(%" PRId32 ")/deleteAvatar/", _uid] watcher:self];
         if (uploadActions.count != 0)
         {
             TGTimelineUploadPhotoRequestBuilder *actor = (TGTimelineUploadPhotoRequestBuilder *)[ActionStageInstance() executingActorWithPath:uploadActions.lastObject];
             if (actor != nil)
             {
                 TGDispatchOnMainThread(^
                                        {
                                            [_profileDataItem setUpdatingAvatar:actor.currentPhoto hasUpdatingAvatar:true];
                                            [_setProfilePhotoItem setEnabled:false];
                                        });
             }
         }
         else if (deleteActions.count != 0)
         {
             TGDeleteProfilePhotoActor *actor = (TGDeleteProfilePhotoActor *)[ActionStageInstance() executingActorWithPath:deleteActions.lastObject];
             if (actor != nil)
             {
                 TGDispatchOnMainThread(^
                                        {
                                            [_profileDataItem setUpdatingAvatar:nil hasUpdatingAvatar:true];
                                            [_setProfilePhotoItem setEnabled:false];
                                        });
             }
         }
         
         if ([TGAccountSettingsActor accountSettingsFotCurrentStateId] == nil)
             [ActionStageInstance() requestActor:@"/accountSettings" options:@{} flags:0 watcher:self];
     }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"我 Tab"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_editing)
    {
        [self setEditing:false animated:false];
        [_profileDataItem setUser:[TGDatabaseInstance() loadUser:_uid] animated:false];
    }
}

#pragma mark -

- (void)receiveRemoteNotification:(NSNotification *)__unused notification
{
    [self requestUnreadCount];
}

- (void)requestUnreadCount
{
    [T8NodeHttpRequestService getCommentsAndUpvotesUnreadCountWithSuccess:^(NSDictionary *dictRet) {
        NSDictionary *dataDict = dictRet[@"data"];
        [_commentsItem setUnreadCount:((NSNumber *)dataDict[@"new_comments_count"]).stringValue];
        [_VotesItem setUnreadCount:((NSNumber *)dataDict[@"new_upvotes_count"]).stringValue];
        
        _unreadCount = [dataDict[@"new_comments_count"] intValue] + [dataDict[@"new_upvotes_count"] intValue];
        TGDispatchOnMainThread(^{
            [TGAppDelegateInstance.mainTabsController setUnreadCountForMe:_unreadCount];
        });
    } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        
    }];
}

- (void)editButtonPressed
{
    if (_editing)
    {
        if ([_profileDataItem editingFirstName].length == 0 && [_profileDataItem editingLastName].length == 0)
            return;
    }
    
    [self setEditing:!_editing animated:true];
    
    [self.collectionView updateVisibleItemsNow];
    
    if (!_editing)
    {
        TGUser *user = [TGDatabaseInstance() loadUser:_uid];
        if (!TGStringCompare(user.firstName, [_profileDataItem editingFirstName]) || !TGStringCompare(user.lastName, [_profileDataItem editingLastName]))
        {
            [_profileDataItem setUpdatingFirstName:[_profileDataItem editingFirstName] updatingLastName:[_profileDataItem editingLastName]];
            
            static int actionId = 0;
            NSString *action = [[NSString alloc] initWithFormat:@"/tg/changeUserName/(%d)", actionId++];
            NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:[_profileDataItem editingFirstName], @"firstName", [_profileDataItem editingLastName], @"lastName", nil];
            [ActionStageInstance() requestActor:action options:options flags:0 watcher:self];
        }
    }
}

- (void)cancelButtonPressed
{
    [self setEditing:false animated:true];
    
    [_profileDataItem setUser:[TGDatabaseInstance() loadUser:_uid] animated:false];
}

- (void)setProfilePhotoPressed
{
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.TakePhoto") action:@"camera"]];
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.ChoosePhoto") action:@"choosePhoto"]];
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.SearchWebImages") action:@"searchWeb"]];
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]];
    
    TGActionSheet *actionSheet = [[TGActionSheet alloc] initWithTitle:nil actions:actions actionBlock:^(TGMeController *controller, NSString *action)
                                  {
                                      if ([action isEqualToString:@"camera"])
                                          [controller _displayCamera];
                                      else if ([action isEqualToString:@"choosePhoto"])
                                          [controller _displayImagePicker:false];
                                      else if ([action isEqualToString:@"searchWeb"])
                                          [controller _displayImagePicker:true];
                                      else if ([action isEqualToString:@"delete"])
                                          [controller _commitDeleteAvatar];
                                  } target:self];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        [actionSheet showInView:self.view];
    else
    {
        NSIndexPath *indexPath = [self indexPathForItem:_setProfilePhotoItem];
        UIView *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        
        [actionSheet showFromRect:CGRectInset([cell convertRect:cell.bounds toView:self.view], 0.0f, -4.0f) inView:self.view animated:true];
    }
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        navigationController.restrictLandscape = true;
    else
    {
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
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
    
    [self _updateProfileImage:image];
    
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)legacyCameraControllerCompletedWithNoResult
{
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)_updateProfileImage:(UIImage *)image
{
    if (image != nil)
    {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.6f);
        if (imageData == nil)
            return;
        
        [(UIView *)[_profileDataItem visibleAvatarView] setHidden:false];
        
        TGImageProcessor filter = [TGRemoteImageView imageProcessorForName:@"circle:64x64"];
        UIImage *avatarImage = filter(image);
        
        [_profileDataItem setUpdatingAvatar:avatarImage hasUpdatingAvatar:true];
        [_setProfilePhotoItem setEnabled:false];
        
        NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
        
        uint8_t fileId[32];
        arc4random_buf(&fileId, 32);
        
        NSMutableString *filePath = [[NSMutableString alloc] init];
        for (int i = 0; i < 32; i++)
        {
            [filePath appendFormat:@"%02x", fileId[i]];
        }
        
        NSString *tmpImagesPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) objectAtIndex:0] stringByAppendingPathComponent:@"upload"];
        static NSFileManager *fileManager = nil;
        if (fileManager == nil)
            fileManager = [[NSFileManager alloc] init];
        NSError *error = nil;
        [fileManager createDirectoryAtPath:tmpImagesPath withIntermediateDirectories:true attributes:nil error:&error];
        NSString *absoluteFilePath = [tmpImagesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.bin", filePath]];
        [imageData writeToFile:absoluteFilePath atomically:false];
        
        [options setObject:filePath forKey:@"originalFileUrl"];
        
        [options setObject:avatarImage forKey:@"currentPhoto"];
        
        [ActionStageInstance() dispatchOnStageQueue:^
         {
             NSString *action = [[NSString alloc] initWithFormat:@"/tg/timeline/(%" PRId32 ")/uploadPhoto/(%@)", _uid, filePath];
             [ActionStageInstance() requestActor:action options:options watcher:self];
             [ActionStageInstance() requestActor:action options:options watcher:TGTelegraphInstance];
         }];
    }
}

- (void)_commitCancelAvatarUpdate
{
    [_profileDataItem setUpdatingAvatar:nil hasUpdatingAvatar:false];
    [_setProfilePhotoItem setEnabled:true];
    
    [ActionStageInstance() dispatchOnStageQueue:^
     {
         NSArray *deleteActions = [ActionStageInstance() rejoinActionsWithGenericPathNow:@"/tg/timeline/@/deleteAvatar/@" prefix:[[NSString alloc] initWithFormat:@"/tg/timeline/(%" PRId32 ")", _uid] watcher:self];
         NSArray *uploadActions = [ActionStageInstance() rejoinActionsWithGenericPathNow:@"/tg/timeline/@/uploadPhoto/@" prefix:[[NSString alloc] initWithFormat:@"/tg/timeline/(%" PRId32 ")", _uid] watcher:self];
         
         for (NSString *action in deleteActions)
         {
             [ActionStageInstance() removeAllWatchersFromPath:action];
         }
         
         for (NSString *action in uploadActions)
         {
             [ActionStageInstance() removeAllWatchersFromPath:action];
         }
     }];
}

- (void)_commitDeleteAvatar
{
    [_profileDataItem setUpdatingAvatar:nil hasUpdatingAvatar:true];
    [_setProfilePhotoItem setEnabled:false];
    
    static int actionId = 0;
    
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInt:_uid], @"uid", nil];
    NSString *action = [[NSString alloc] initWithFormat:@"/tg/timeline/(%" PRId32 ")/deleteAvatar/(%d)", _uid, actionId++];
    [ActionStageInstance() requestActor:action options:options watcher:self];
    [ActionStageInstance() requestActor:action options:options watcher:TGTelegraphInstance];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)__unused animated
{
    _editing = editing;
    
    if (_editing)
    {
        [self setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)] animated:true];
        
        _accountEditingBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Done") style:UIBarButtonItemStyleDone target:self action:@selector(editButtonPressed)];
        [self setRightBarButtonItem:_accountEditingBarButtonItem animated:true];
        
        NSIndexPath *profileDataIndexPath = [self indexPathForItem:_profileDataItem];
        if (profileDataIndexPath != nil)
        {
            [self.menuSections beginRecordingChanges];
            [self.menuSections insertItem:_setProfilePhotoItem toSection:profileDataIndexPath.section atIndex:profileDataIndexPath.row+1];
            [self.menuSections commitRecordedChanges:self.collectionView];
        }
    }
    else
    {
        [self setLeftBarButtonItem:nil animated:true];
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Edit") style:UIBarButtonItemStylePlain target:self action:@selector(editButtonPressed)] animated:true];
        _accountEditingBarButtonItem = nil;
        
        NSIndexPath *setProfilePhotoIndexPath = [self indexPathForItem:_setProfilePhotoItem];
        if (setProfilePhotoIndexPath != nil)
        {
            [self.menuSections beginRecordingChanges];
            [self.menuSections deleteItemFromSection:setProfilePhotoIndexPath.section atIndex:setProfilePhotoIndexPath.row];
            [self.menuSections commitRecordedChanges:self.collectionView];
        }
    }
    
    [self.menuSections beginRecordingChanges];
    
    [_profileDataItem setEditing:_editing animated:true];
    _profileDataItem.additinalHeight = _editing ? 30.0f : 0.0f;
    
    if (![self.menuSections commitRecordedChanges:self.collectionView])
        [self _resetCollectionView];
    
    if (_editing && self.collectionView.contentOffset.y + self.collectionView.contentInset.top + (self.collectionView.frame.size.height - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom) - (self.collectionView.contentSize.height) > -30.0f)
    {
        //        NSIndexPath *indexPath = [self indexPathForItem:logoutItem];
        //        if (indexPath != nil)
        //        {
        //[self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:true];
        
        //[self.collectionView scrollRectToVisible:CGRectMake(0.0f, self.collectionView.contentSize.height - 1.0f, 1.0f, 1.0f) animated:true];
        //        }
    }
}

- (void)myPostsPressed
{
    TGMyPostViewController *myPost = [[TGMyPostViewController alloc] init];
    [self.navigationController pushViewController:myPost animated:YES];
}

- (void)myUpvotesPressed
{
    [self.navigationController pushViewController:[[TGMyUpvotesController alloc] initConversation:nil] animated:true];
}

- (void)commentsPressed
{
    _unreadCount -= [_commentsItem.unreadCount intValue];
    TGDispatchOnMainThread(^{
        [TGAppDelegateInstance.mainTabsController setUnreadCountForMe:_unreadCount];
    });
    [_commentsItem setUnreadCount:0];
    
    TGMyCommentedController *myCommentedController = [[TGMyCommentedController alloc] init];
    [self.navigationController pushViewController:myCommentedController animated:YES];
}

- (void)votesPressed
{
    _unreadCount -= [_VotesItem.unreadCount intValue];
    TGDispatchOnMainThread(^{
        [TGAppDelegateInstance.mainTabsController setUnreadCountForMe:_unreadCount];
    });
    [_VotesItem setUnreadCount:0];
    
    TGVoteForMeController *voteForMe = [[TGVoteForMeController alloc] init];
    [self.navigationController pushViewController:voteForMe animated:YES];
}

- (void)accountPressed
{
    TGAccountSettingsController *accountSettingsController = [[TGAccountSettingsController alloc] initWithUid:_uid];
    [self.navigationController pushViewController:accountSettingsController animated:YES];
}

- (void)settingsPressed
{
    TGGlobalSettingsController *globalSettingsController = [[TGGlobalSettingsController alloc] initWithUid:_uid];
    
    [self.navigationController pushViewController:globalSettingsController animated:YES];
}

#pragma mark -

- (void)actionStageResourceDispatched:(NSString *)path resource:(id)resource arguments:(id)__unused arguments
{
    if ([path isEqualToString:@"/tg/service/synchronizationstate"])
    {
        [self actorCompleted:ASStatusSuccess path:path result:resource];
    }
    else if ([path isEqualToString:@"/tg/userdatachanges"] || [path isEqualToString:@"/tg/userpresencechanges"])
    {
        NSArray *users = ((SGraphObjectNode *)resource).object;
        
        for (TGUser *user in users)
        {
            if (user.uid == _uid)
            {
                TGDispatchOnMainThread(^
                                       {
                                           [_profileDataItem setUser:user animated:true];
                                       });
                
                break;
            }
        }
    }
}

- (void)actorCompleted:(int)status path:(NSString *)path result:(id)result
{
    if ([path isEqualToString:@"/tg/service/synchronizationstate"])
    {
        if (status == ASStatusSuccess)
        {
            int state = [((SGraphObjectNode *)result).object intValue];
            
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               int synchronizationState = 0;
                               
                               if (state & 2)
                                   synchronizationState = 1;
                               else if (state & 1)
                                   synchronizationState = 2;
                               else
                                   synchronizationState = 0;
                               
                               [_profileDataItem setSynchronizationStatus:synchronizationState];
                           });
        }
    }
    else if ([path hasPrefix:@"/tg/auth/logout/"])
    {
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           [_progressWindow dismiss:true];
                           _progressWindow = nil;
                           
                           if (status != ASStatusSuccess)
                           {
                               [[[TGAlertView alloc] initWithTitle:nil message:TGLocalized(@"Settings.LogoutError") delegate:nil cancelButtonTitle:TGLocalized(@"Common.OK") otherButtonTitles:nil] show];
                           }
                       });
    }
    else if ([path hasPrefix:@"/tg/changeUserName/"])
    {
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           [_profileDataItem setUpdatingFirstName:nil updatingLastName:nil];
                           [_profileDataItem setUser:[TGDatabaseInstance() loadUser:_uid] animated:false];
                       });
    }
    else if ([path hasPrefix:[[NSString alloc] initWithFormat:@"/tg/timeline/(%" PRId32 ")/uploadPhoto", _uid]] || [path hasPrefix:[[NSString alloc] initWithFormat:@"/tg/timeline/(%" PRId32 ")/deleteAvatar/", _uid]])
    {
        TGUser *user = [TGDatabaseInstance() loadUser:_uid];
        
        TGDispatchOnMainThread(^
                               {
                                   [_setProfilePhotoItem setEnabled:true];
                                   
                                   if (status == ASStatusSuccess)
                                   {
                                       [_profileDataItem copyUpdatingAvatarToCacheWithUri:user.photoUrlSmall];
                                       [_profileDataItem setUpdatingAvatar:nil hasUpdatingAvatar:false];
                                       [_profileDataItem setUser:user animated:false];
                                   }
                                   else
                                   {
                                       [_profileDataItem setUpdatingAvatar:nil hasUpdatingAvatar:false];
                                       
                                       TGAlertView *alertView = [[TGAlertView alloc] initWithTitle:nil message:TGLocalized(@"Profile.ImageUploadError") delegate:nil cancelButtonTitle:TGLocalized(@"Common.OK") otherButtonTitles:nil];
                                       [alertView show];
                                   }
                               });
        
        if (status == ASStatusSuccess) {
            [T8UserHttpRequestService updateUserInfoToServer];
        }
    }
    else if ([path isEqualToString:@"/tg/support/preferredPeer"])
    {
        TGUser *user = status == ASStatusSuccess ? [TGDatabaseInstance() loadUser:[result[@"uid"] intValue]] : nil;
        
        TGDispatchOnMainThread(^
                               {
                                   [_progressWindow dismiss:true];
                                   
                                   if (user != nil)
                                   {
                                       [[TGInterfaceManager instance] navigateToConversationWithId:user.uid conversation:nil performActions:nil atMessage:nil clearStack:true openKeyboard:true animated:true];
                                   }
                               });
    }
}

- (void)actionStageActionRequested:(NSString *)action options:(id)__unused options
{
    if ([action isEqualToString:@"avatarTapped"])
    {
        TGUser *user = [TGDatabaseInstance() loadUser:_uid];
        
        if ([_profileDataItem hasUpdatingAvatar])
        {
            TGActionSheet *actionSheet = [[TGActionSheet alloc] initWithTitle:nil actions:@[
                                                                                            [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"GroupInfo.SetGroupPhotoStop") action:@"stop" type:TGActionSheetActionTypeDestructive],
                                                                                            [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel],
                                                                                            ] actionBlock:^(id target, NSString *action)
                                          {
                                              if ([action isEqualToString:@"stop"])
                                              {
                                                  [(TGMeController *)target _commitCancelAvatarUpdate];
                                              }
                                          } target:self];
            [actionSheet showInView:self.view];
        }
        else if (user.photoUrlSmall.length == 0)
        {
            if (_setProfilePhotoItem.enabled)
                [self setProfilePhotoPressed];
        }
        else
        {
            TGRemoteImageView *avatarView = [_profileDataItem visibleAvatarView];
            
            if (user != nil && user.photoUrlBig != nil && avatarView.currentImage != nil)
            {
                TGModernGalleryController *modernGallery = [[TGModernGalleryController alloc] init];
                
                TGProfileUserAvatarGalleryModel *model = [[TGProfileUserAvatarGalleryModel alloc] initWithCurrentAvatarLegacyThumbnailImageUri:user.photoUrlSmall currentAvatarLegacyImageUri:user.photoUrlBig currentAvatarImageSize:CGSizeMake(640.0f, 640.0f)];
                
                __weak typeof(self) weakSelf = self;
                
                model.deleteCurrentAvatar = ^
                {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf _commitDeleteAvatar];
                };
                
                modernGallery.model = model;
                
                modernGallery.itemFocused = ^(id<TGModernGalleryItem> item)
                {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf != nil)
                    {
                        if ([item isKindOfClass:[TGUserAvatarGalleryItem class]])
                        {
                            TGUser *user = [TGDatabaseInstance() loadUser:strongSelf->_uid];
                            
                            if (TGStringCompare(((TGUserAvatarGalleryItem *)item).legacyThumbnailUrl, user.photoUrlSmall))
                            {
                                ((UIView *)strongSelf->_profileDataItem.visibleAvatarView).hidden = true;
                            }
                            else
                                ((UIView *)strongSelf->_profileDataItem.visibleAvatarView).hidden = false;
                        }
                    }
                };
                
                modernGallery.beginTransitionIn = ^UIView *(id<TGModernGalleryItem> item, __unused TGModernGalleryItemView *itemView)
                {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf != nil)
                    {
                        if ([item isKindOfClass:[TGUserAvatarGalleryItem class]])
                        {
                            TGUser *user = [TGDatabaseInstance() loadUser:strongSelf->_uid];
                            
                            if (TGStringCompare(((TGUserAvatarGalleryItem *)item).legacyThumbnailUrl, user.photoUrlSmall))
                            {
                                return strongSelf->_profileDataItem.visibleAvatarView;
                            }
                        }
                    }
                    
                    return nil;
                };
                
                modernGallery.beginTransitionOut = ^UIView *(id<TGModernGalleryItem> item)
                {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf != nil)
                    {
                        if ([item isKindOfClass:[TGUserAvatarGalleryItem class]])
                        {
                            TGUser *user = [TGDatabaseInstance() loadUser:strongSelf->_uid];
                            
                            if (TGStringCompare(((TGUserAvatarGalleryItem *)item).legacyThumbnailUrl, user.photoUrlSmall))
                            {
                                return strongSelf->_profileDataItem.visibleAvatarView;
                            }
                        }
                    }
                    
                    return nil;
                };
                
                modernGallery.completedTransitionOut = ^
                {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf != nil)
                    {
                        ((UIView *)strongSelf->_profileDataItem.visibleAvatarView).hidden = false;
                    }
                };
                
                TGOverlayControllerWindow *controllerWindow = [[TGOverlayControllerWindow alloc] initWithParentController:self contentController:modernGallery];
                controllerWindow.hidden = false;
            }
        }
    }
    else if ([action isEqualToString:@"deleteAvatar"])
    {
        [self _commitDeleteAvatar];
    }
    else if ([action isEqualToString:@"editingNameChanged"])
    {
        _accountEditingBarButtonItem.enabled = [_profileDataItem editingFirstName].length != 0;
    }
}

- (void)localizationUpdated
{
    [self setTitleText:TGLocalized(@"Settings.Title")];
    
    if (_editing)
    {
        [self setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)] animated:true];
        
        _accountEditingBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Done") style:UIBarButtonItemStyleDone target:self action:@selector(editButtonPressed)];
        [self setRightBarButtonItem:_accountEditingBarButtonItem animated:false];
    }
    else
    {
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Edit") style:UIBarButtonItemStylePlain target:self action:@selector(editButtonPressed)] animated:false];
        _accountEditingBarButtonItem = nil;
    }
    
    _setProfilePhotoItem.title = TGLocalized(@"Settings.SetProfilePhoto");
    
    [_profileDataItem localizationUpdated];
}


@end
