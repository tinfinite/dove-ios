//
//  TGGroupDialogListViewController.m
//  Telegraph
//
//  Created by yewei on 15/4/20.
//
//

#import "TGGroupDialogListViewController.h"
#import "TGDiscoverGroupController.h"
#import "TGNavigationController.h"
#import "TGComboxView.h"
#import "QRScanViewController.h"
#import "TGUsernameController.h"
#import "TGReplyGroupViewController.h"
#import "TGSelectContactController.h"

@interface TGGroupDialogListViewController ()

@property (nonatomic, strong) UIView *noGroupView;

@end

@implementation TGGroupDialogListViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"群组Tab"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)loadView
{
    [super loadView];
    
    [self setTitleText:TGLocalized(@"Groups.TabTitle")];
    self.titleLabel.text = TGLocalized(@"Groups.TabTitle");
    [self.titleLabel sizeToFit];
    [self setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Discover.Title") style:UIBarButtonItemStylePlain target:self action:@selector(discoverButtonPressed)]];
    [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showComboxView)]];
}

- (void)discoverButtonPressed
{
    TGDiscoverGroupController *discoverGroupController = [[TGDiscoverGroupController alloc] init];
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[discoverGroupController]];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        navigationController.restrictLandscape = true;
    else
    {
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)updateEmptyListContainer
{
    if (self.listModel.count == 0 && self.emptyListContainer == nil)
    {
        self.emptyListContainer = self.noGroupView;
        [self.view insertSubview:self.emptyListContainer belowSubview:self.tableView];
    }
    else if (self.emptyListContainer != nil && self.listModel.count != 0)
    {
        [self.emptyListContainer removeFromSuperview];
        self.emptyListContainer = nil;
    }
    
    [self setTableHidden:self.listModel.count == 0];
    
    if (self.emptyListContainer != nil)
        self.emptyListContainer.hidden = ![self.dialogListCompanion shouldDisplayEmptyListPlaceholder];
}

- (void)startNewGroupPressed
{
    TGSelectContactController *selectContactController = [[TGSelectContactController alloc] initWithCreateGroup:YES createEncrypted:false createBroadcast:false];
    [self.navigationController pushViewController:selectContactController animated:true];
}

- (void)joinNewGroupPressed
{
    QRScanViewController *scan = [[QRScanViewController alloc] init];
    scan.scanSuccessBlock = ^(NSString *result){
        NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:@"^(.*?)chat_id=(.*?)&chat_name=(.*?)$" options:NSRegularExpressionCaseInsensitive error:nil];
        NSUInteger matches = [regular numberOfMatchesInString:result options:0 range:NSMakeRange(0, result.length)];
        if (matches == 0) {
            return;
        }
        NSString *groupID = [regular stringByReplacingMatchesInString:result options:NSMatchingReportCompletion range:NSMakeRange(0, result.length) withTemplate:@"$2"];
        NSString *groupName = [regular stringByReplacingMatchesInString:result options:NSMatchingReportProgress range:NSMakeRange(0, result.length) withTemplate:@"$3"];
        
        //compatible with Android
        NSNumber *groupIDNumber = nil;
        if (groupID.longLongValue > 0) {
            groupIDNumber = @(-groupID.longLongValue);
        }else{
            groupIDNumber = @(groupID.longLongValue);
        }
        
        if ((T8CONTEXT.username == nil) || [T8CONTEXT.username isEqualToString:@""])
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
        }else{
            TGReplyGroupViewController *replyGroupController = [[TGReplyGroupViewController alloc] initWithConversationId:groupIDNumber.longLongValue groupName:groupName groupAvatar:[UIImage imageNamed:@"dove_logo_still"] groupDescription:nil];
            
            TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[replyGroupController]];
            
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            {
                navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
                navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
            }
            
            [self presentViewController:navigationController animated:true completion:nil];
        }
    };
    [self presentViewController:scan animated:YES completion:^{
        
    }];
}

- (void)showComboxView
{
    NSArray *comboxItems =
    @[
      
      [TGComboxItem menuItem:TGLocalized(@"Compose.NewGroup")
                       image:[UIImage imageNamed:@"combox_newgroup"]
             highligtedImage:[UIImage imageNamed:@"combox_newgroup"]
                      target:self
                      action:@selector(startNewGroupPressed)],
      
      [TGComboxItem menuItem:TGLocalized(@"GroupInfo.JoinGroup")
                       image:[UIImage imageNamed:@"combox_scan"]
             highligtedImage:[UIImage imageNamed:@"combox_sacn"]
                      target:self
                      action:@selector(joinNewGroupPressed)]
      ];
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if(!keyWindow)
    {
        NSArray *windows = [UIApplication sharedApplication].windows;
        if(windows.count > 0) keyWindow = [windows lastObject];
        keyWindow = [windows objectAtIndex:0];
    }
    UIView *containerView = [[keyWindow subviews] objectAtIndex:0];
    
    [TGComboxView showPopComBoxWithParentView:containerView items:comboxItems xRightOffset:0 yTopOffset:64];
}

- (UIView *)noGroupView
{
    if (!_noGroupView) {
        _noGroupView = [[UIView alloc] initWithFrame:self.view.bounds];
        _noGroupView.backgroundColor = [UIColor whiteColor];
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 350)];
        view.center = _noGroupView.center;
        [_noGroupView addSubview:view];
        
        UIImageView *groupIcon = [[UIImageView alloc] initWithFrame:CGRectMake(119, 20, 82, 64)];
        groupIcon.image = [UIImage imageNamed:@"discover_group_icon"];
        [view addSubview:groupIcon];
        
        UILabel *descrip1 = [[UILabel alloc] initWithFrame:CGRectMake(85, 100, 150, 40)];
        descrip1.text = TGLocalized(@"Discover.Descrip1");
        descrip1.numberOfLines = 0;
        descrip1.textAlignment = NSTextAlignmentCenter;
        descrip1.textColor = UIColorRGB(0xAAAAAA);
        descrip1.font = [UIFont systemFontOfSize:13];
        [view addSubview:descrip1];
        
        UILabel *descrip2 = [[UILabel alloc] initWithFrame:CGRectMake(90, 190, 140, 44)];
        descrip2.text = TGLocalized(@"Discover.Descrip2");
        descrip2.numberOfLines = 0;
        descrip2.textAlignment = NSTextAlignmentCenter;
        descrip2.textColor = UIColorRGB(0x333333);
        descrip2.font = [UIFont systemFontOfSize:17];
        [view addSubview:descrip2];
        
        UIButton *discoverButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [discoverButton setBackgroundImage:[UIImage imageNamed:@"discover_group_btn"] forState:UIControlStateNormal];
        [discoverButton setTitle:TGLocalized(@"Discover.DiscoverGroup") forState:UIControlStateNormal];
        discoverButton.titleLabel.font = [UIFont systemFontOfSize:13];
        discoverButton.frame = CGRectMake(85, 280, 150, 40);
        [discoverButton addTarget:self action:@selector(discoverButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:discoverButton];
    }
    return _noGroupView;
}

@end
