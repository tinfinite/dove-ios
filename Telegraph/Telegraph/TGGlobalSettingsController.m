#import "TGGlobalSettingsController.h"

#import "ActionStage.h"
#import "SGraphObjectNode.h"

#import "TGTimelineUploadPhotoRequestBuilder.h"
#import "TGDeleteProfilePhotoActor.h"

#import "TGNotificationSettingsController.h"
#import "TGChatSettingsController.h"
#import "TGPrivacySettingsController.h"

#import "TGDisclosureActionCollectionItem.h"
#import "TGButtonCollectionItem.h"
#import "TGWallpapersCollectionItem.h"
#import "TGSwitchCollectionItem.h"
#import "TGCommentCollectionItem.h"
#import "TGVariantCollectionItem.h"

#import "TGWallpaperListController.h"
#import "TGWallpaperController.h"
#import "TGWallpaperManager.h"

#import "TGActionSheet.h"
#import "TGProgressWindow.h"

#import "TGDatabase.h"
#import "TGTelegraph.h"

#import "TGAppDelegate.h"
#import "TGHacks.h"
#import "TGInterfaceManager.h"
#import "TGAlertView.h"
#import "TGPhoneUtils.h"

#import "TGSettingsController.h"

#import "TGUsernameController.h"

#import "TGAlertView.h"

#import "TGAccountSettingsActor.h"

#import "TGChangePhoneNumberHelpController.h"

#import "GesturePasswordController.h"
#import "T8UserHttpRequestService.h"

@interface TGGlobalSettingsController () <TGWallpaperControllerDelegate>
{
    int32_t _uid;
    
    TGSwitchCollectionItem *_autosavePhotosItem;
    TGSwitchCollectionItem *_autoGesturePasswordItem;
    
    TGWallpapersCollectionItem *_wallpapersItem;
    
    TGDisclosureActionCollectionItem *_notificationsItem;
    TGDisclosureActionCollectionItem *_privacySettingsItem;
    TGDisclosureActionCollectionItem *_chatSettingsItem;
    
    UIBarButtonItem *_accountEditingBarButtonItem;
}

@property (nonatomic, strong) TGProgressWindow *progressWindow;

@end

@implementation TGGlobalSettingsController

- (id)initWithUid:(int32_t)uid
{
    self = [super init];
    if (self)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        [ActionStageInstance() watchForPaths:@[
            @"/tg/userdatachanges",
            @"/tg/userpresencechanges",
            @"/tg/service/synchronizationstate"
        ] watcher:self];
        
        [ActionStageInstance() requestActor:@"/tg/service/synchronizationstate" options:nil flags:0 watcher:self];
        
        _uid = uid;
        
        _wallpapersItem = [[TGWallpapersCollectionItem alloc] initWithAction:@selector(wallpapersPressed) title:TGLocalized(@"Settings.ChatBackground")];
        _wallpapersItem.interfaceHandle = _actionHandle;
        
        _autoGesturePasswordItem = [[TGSwitchCollectionItem alloc] initWithTitle:TGLocalized(@"GesturePassword.Title") isOn:TGAppDelegateInstance.autoGesturePassword];
        _autoGesturePasswordItem.interfaceHandle = _actionHandle;
        
        TGCollectionMenuSection *settingsSection = [[TGCollectionMenuSection alloc] initWithItems:@[
            (_notificationsItem = [[TGDisclosureActionCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.NotificationsAndSounds") action:@selector(notificationsAndSoundsPressed)]),
            (_privacySettingsItem = [[TGDisclosureActionCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.PrivacySettings") action:@selector(privacySettingsPressed)]),
            (_chatSettingsItem = [[TGDisclosureActionCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.ChatSettings") action:@selector(chatSettingsPressed)]),
            _wallpapersItem,
            _autoGesturePasswordItem
        ]];
        [self.menuSections addSection:settingsSection];
        
        _autosavePhotosItem = [[TGSwitchCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.SaveIncomingPhotos") isOn:TGAppDelegateInstance.autosavePhotos];
        _autosavePhotosItem.interfaceHandle = _actionHandle;
        
        TGCollectionMenuSection *downloadSection = [[TGCollectionMenuSection alloc] initWithItems:@[
            _autosavePhotosItem,
            [[TGCommentCollectionItem alloc] initWithText:TGLocalized(@"Settings.SaveIncomingPhotosHelp")]
        ]];
        [self.menuSections addSection:downloadSection];
        
        TGButtonCollectionItem *logoutItem = nil;
        logoutItem = [[TGButtonCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.Logout") action:@selector(logoutPressed)];
        logoutItem.alignment = NSTextAlignmentCenter;
        logoutItem.titleColor = TGDestructiveAccentColor();
        logoutItem.deselectAutomatically = true;
        
        NSMutableArray *logoutSectionItems = [[NSMutableArray alloc] init];
        [logoutSectionItems addObject:logoutItem];
        
        TGCollectionMenuSection *logoutSection = [[TGCollectionMenuSection alloc] initWithItems:logoutSectionItems];
        [self.menuSections addSection:logoutSection];
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
    
    [self setTitleText:TGLocalized(@"Settings.Title")];
    
    _accountEditingBarButtonItem = nil;;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        if ([TGAccountSettingsActor accountSettingsFotCurrentStateId] == nil)
            [ActionStageInstance() requestActor:@"/accountSettings" options:@{} flags:0 watcher:self];
    }];
    
    [_autoGesturePasswordItem setIsOn:TGAppDelegateInstance.autoGesturePassword animated:false];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"设置页面"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark -

- (void)notificationsAndSoundsPressed
{
    [self.navigationController pushViewController:[[TGNotificationSettingsController alloc] init] animated:true];
}

- (void)privacySettingsPressed
{
    [self.navigationController pushViewController:[[TGPrivacySettingsController alloc] init] animated:true];
}

- (void)chatSettingsPressed
{
    [self.navigationController pushViewController:[[TGChatSettingsController alloc] init] animated:true];
}

- (void)wallpapersPressed
{
    [self.navigationController pushViewController:[[TGWallpaperListController alloc] init] animated:true];
}

- (void)mySettingsPressed
{
    [self.navigationController pushViewController:[[TGSettingsController alloc] init] animated:true];
}

- (void)gesturePasswordPressed
{
    GesturePasswordController *gesturePwd = [[GesturePasswordController alloc] initWithGesturePasswordType:TGAppDelegateInstance.autoGesturePassword uid:_uid];
    gesturePwd.title = TGLocalized(@"GesturePassword.Title");
    [self.navigationController pushViewController:gesturePwd animated:true];
}

- (void)logoutPressed
{
    __weak TGGlobalSettingsController *weakSelf = self;
    
    [[[TGAlertView alloc] initWithTitle:TGLocalized(@"Settings.LogoutConfirmationTitle") message:TGLocalized(@"Settings.LogoutConfirmationText") cancelButtonTitle:TGLocalized(@"Common.Cancel") okButtonTitle:TGLocalized(@"Common.OK") completionBlock:^(bool okButtonPressed)
      {
          if (okButtonPressed)
          {
              __strong TGGlobalSettingsController *strongSelf = weakSelf;
              if (strongSelf != nil)
              {
                  strongSelf.progressWindow = [[TGProgressWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
                  [strongSelf.progressWindow show:true];
                  
                  static int actionId = 0;
                  [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/auth/logout/(%d)", actionId++] options:nil watcher:strongSelf];
              }
          }
      }] show];
}

#pragma mark -

- (void)wallpaperController:(TGWallpaperController *)__unused wallpaperController didSelectWallpaperWithInfo:(TGWallpaperInfo *)wallpaperInfo
{
    [[TGWallpaperManager instance] setCurrentWallpaperWithInfo:wallpaperInfo];
    [_wallpapersItem setCurrentWallpaperInfo:wallpaperInfo];
}

#pragma mark -

- (void)actionStageResourceDispatched:(NSString *)path resource:(id)resource arguments:(id)__unused arguments
{
    if ([path isEqualToString:@"/tg/service/synchronizationstate"])
    {
        [self actorCompleted:ASStatusSuccess path:path result:resource];
    }
}

- (void)actorCompleted:(int)status path:(NSString *)path result:(id)result
{
    if ([path hasPrefix:@"/tg/auth/logout/"])
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
    if ([action isEqualToString:@"wallpaperImagePressed"])
    {   
        if (options[@"wallpaperInfo"] != nil)
        {
            TGWallpaperController *wallpaperController = [[TGWallpaperController alloc] initWithWallpaperInfo:options[@"wallpaperInfo"] thumbnailImage:nil];
            wallpaperController.delegate = self;
            
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                wallpaperController.modalPresentationStyle = UIModalPresentationFormSheet;
            
            [self presentViewController:wallpaperController animated:true completion:nil];
        }
    }
    else if ([action isEqualToString:@"switchItemChanged"])
    {
        if (options[@"item"] == _autosavePhotosItem)
        {
            TGAppDelegateInstance.autosavePhotos = [options[@"value"] boolValue];
            [TGAppDelegateInstance saveSettings];
        }
        if (options[@"item"] == _autoGesturePasswordItem) {
            [self gesturePasswordPressed];
        }
    }
}

- (void)phoneNumberPressed
{
    TGChangePhoneNumberHelpController *phoneNumberController = [[TGChangePhoneNumberHelpController alloc] init];
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[phoneNumberController]];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        navigationController.restrictLandscape = true;
    else
    {
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self presentViewController:navigationController animated:true completion:nil];
}

- (void)usernamePressed
{
    TGUsernameController *usernameController = [[TGUsernameController alloc] init];
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[usernameController]];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        navigationController.restrictLandscape = false;
    else
    {
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self presentViewController:navigationController animated:true completion:nil];
}

- (void)localizationUpdated
{
    [self setTitleText:TGLocalized(@"Settings.Title")];
    
    _notificationsItem.title = TGLocalized(@"Settings.NotificationsAndSounds");
    _privacySettingsItem.title = TGLocalized(@"Settings.PrivacySettings");
    _chatSettingsItem.title = TGLocalized(@"Settings.ChatSettings");
    
    _autosavePhotosItem.title = TGLocalized(@"Settings.SaveIncomingPhotos");
    _wallpapersItem.title = TGLocalized(@"Settings.ChatBackground");
}

@end
