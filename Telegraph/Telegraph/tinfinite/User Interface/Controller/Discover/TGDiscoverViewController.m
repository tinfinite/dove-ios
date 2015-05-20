//
//  TGDiscoverViewController.m
//  Telegraph
//
//  Created by 琦张 on 15/2/15.
//
//

#import "TGDiscoverViewController.h"
#import "TGDiscoverCollectionItem.h"
#import "TGDiscoverGroupController.h"
#import "TGMyUpvotesController.h"
#import "TGNodeStreamController.h"

@interface TGDiscoverViewController ()
{
    TGDiscoverCollectionItem *_publicFeedItem;
    TGDiscoverCollectionItem *_discoverGroupItem;
    TGDiscoverCollectionItem *_myUpvoteItem;
}

@end

@implementation TGDiscoverViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"发现Tab"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidLoad
{
    [self setTitleText:TGLocalized(@"Discover.Title")];
    
    _publicFeedItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"Discover.PublicFeed") imageName:@"discover_public_node"action:@selector(publicFeedPressed)];
    _discoverGroupItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"Discover.DiscoverGroup") imageName:@"discover_group" action:@selector(discoverGroupPressed)];
    _myUpvoteItem = [[TGDiscoverCollectionItem alloc] initWithTitle:TGLocalized(@"Discover.MyUpvote") imageName:@"discover_my_praise" action:@selector(myUpvotePressed)];
    
    TGCollectionMenuSection *discoverSection = [[TGCollectionMenuSection alloc] initWithItems:@[_publicFeedItem,_discoverGroupItem,_myUpvoteItem]];
    UIEdgeInsets describeInsets = discoverSection.insets;
    describeInsets.top = 30;
    discoverSection.insets = describeInsets;
    [self.menuSections addSection:discoverSection];
}

- (void)publicFeedPressed
{
    [self.navigationController pushViewController:[[TGNodeStreamController alloc] init] animated:true];
}

- (void)discoverGroupPressed
{
    TGDiscoverGroupController *discoverGroup = [[TGDiscoverGroupController alloc] init];
    [self.navigationController pushViewController:discoverGroup animated:YES];
}

- (void)myUpvotePressed
{
    [self.navigationController pushViewController:[[TGMyUpvotesController alloc] initConversation:nil] animated:true];
}

@end
