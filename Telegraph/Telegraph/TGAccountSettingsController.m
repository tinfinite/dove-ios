//
//  TGAccountSettingsController.m
//  Telegraph
//
//  Created by yewei on 15/4/20.
//
//

#import "TGAccountSettingsController.h"
#import "TGVariantCollectionItem.h"
#import "TGDatabase.h"
#import "TGUser.h"
#import "TGPhoneUtils.h"
#import "ActionStage.h"
#import "SGraphObjectNode.h"

#import "TGUsernameController.h"
#import "TGChangePhoneNumberHelpController.h"
#import "TGNavigationController.h"

@interface TGAccountSettingsController ()
{
    int32_t _uid;

    TGVariantCollectionItem *_usernameItem;
    TGVariantCollectionItem *_phoneNumberItem;
}

@end

@implementation TGAccountSettingsController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"账号页面"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (id)initWithUid:(int32_t)uid
{
    self = [super init];
    if (self)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        [ActionStageInstance() watchForPaths:@[
                                               @"/tg/userdatachanges",
                                               @"/tg/userpresencechanges",
                                               ] watcher:self];
        
        _uid = uid;
        
        _phoneNumberItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.PhoneNumber") action:@selector(phoneNumberPressed)];
        _usernameItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"Settings.Username") action:@selector(usernamePressed)];
        
        
        TGCollectionMenuSection *usernameSection = [[TGCollectionMenuSection alloc] initWithItems:@[_phoneNumberItem, _usernameItem]];
                [self.menuSections addSection:usernameSection];

    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    TGUser *user = [TGDatabaseInstance() loadUser:_uid];
    
    [_usernameItem setVariant:user.userName.length == 0 ? TGLocalized(@"Settings.UsernameEmpty") : [[NSString alloc] initWithFormat:@"@%@", user.userName]];
    [_phoneNumberItem setVariant:user.phoneNumber.length == 0 ? @"" : [TGPhoneUtils formatPhone:user.phoneNumber forceInternational:true]];
    
    [self setTitleText:TGLocalized(@"Settings.Account")];
}

- (void)actionStageResourceDispatched:(NSString *)path resource:(id)resource arguments:(id)__unused arguments
{
    if ([path isEqualToString:@"/tg/userdatachanges"] || [path isEqualToString:@"/tg/userpresencechanges"])
    {
        NSArray *users = ((SGraphObjectNode *)resource).object;
        
        for (TGUser *user in users)
        {
            if (user.uid == _uid)
            {
                TGDispatchOnMainThread(^
                                       {
                                           [_usernameItem setVariant:user.userName.length == 0 ? TGLocalized(@"Settings.UsernameEmpty") : [[NSString alloc] initWithFormat:@"@%@", user.userName]];
                                           [_phoneNumberItem setVariant:user.phoneNumber.length == 0 ? @"" : [TGPhoneUtils formatPhone:user.phoneNumber forceInternational:true]];
                                       });
                
                break;
            }
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
    
    _usernameItem.title = TGLocalized(@"Settings.Username");
    _phoneNumberItem.title = TGLocalized(@"Settings.PhoneNumber");
}

@end
