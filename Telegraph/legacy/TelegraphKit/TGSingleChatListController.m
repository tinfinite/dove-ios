//
//  TGSingleChatListController.m
//  Telegraph
//
//  Created by yewei on 15/4/20.
//
//

#import "TGSingleChatListController.h"
#import "TGContactsController.h"

@interface TGSingleChatListController ()

@end

@implementation TGSingleChatListController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"单聊Tab"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)loadView
{
    [super loadView];
    
    UIButton *contactButton = [UIButton buttonWithType:UIButtonTypeCustom];
    contactButton.frame = CGRectMake(0, 0, 44, 44);
    [contactButton setImage:[UIImage imageNamed:@"contact_icon"] forState:UIControlStateNormal];
    [contactButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -10)];
    [contactButton addTarget:self action:@selector(contactButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:contactButton]];
}

- (void)contactButtonPressed
{
    TGContactsController *contactController = [[TGContactsController alloc]initWithContactsMode:TGContactsModeMainContacts | TGContactsModeRegistered | TGContactsModePhonebook];
    [self.navigationController pushViewController:contactController animated:YES];
}

@end
