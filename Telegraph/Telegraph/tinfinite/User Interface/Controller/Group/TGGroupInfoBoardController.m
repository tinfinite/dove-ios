//
//  TGGroupInfoBoardController.m
//  Telegraph
//
//  Created by yewei on 15/4/1.
//
//

#import "TGGroupInfoBoardController.h"
#import "TGInterfaceAssets.h"
#import "TGListsTableView.h"
#import "TGNodeStreamCell.h"
#import "TGModernBarButton.h"
#import "TGPublishPostVC.h"
#import "T8NodeHttpRequestService.h"
#import "SVPullToRefresh.h"
#import "TGNodeDataManager.h"
#import "IDMPhotoBrowser.h"
#import "TGConversation.h"
#import "TGDatabase.h"
#import "TGReplyGroupViewController.h"
#import "TGNavigationController.h"

@interface TGGroupInfoBoardController ()

@property (nonatomic, strong) UIImageView *postIntroView;
@property (nonatomic, strong) UIView *bottomIntroView;
@property (nonatomic, strong) UIImageView *hasNotDataView;
@property (nonatomic, strong) TGGroupObject *groupObject;

@end

@implementation TGGroupInfoBoardController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:GroupBoardIntroKey_Post])
    {
        TGConversation *conversation = [TGDatabaseInstance() loadConversationWithId:self.conversationId];
        if (![TGDatabaseInstance() containsConversationWithId:self.conversationId] || conversation || conversation.leftChat == YES || conversation.kickedFromChat == YES) {
            [self.view addSubview:self.postIntroView];
        }
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:GroupBoardIntroKey_Bottom])
    {
        [self.view addSubview:self.bottomIntroView];
    }
}

- (id)initWithConversationId:(int64_t)conversationId
{
    self = [super init];
    if (self) {
        self.conversationId = conversationId;
    }
    return self;
}

- (id)initWithGroupObject:(TGGroupObject *)groupObject
{
    self = [super init];
    if (self) {
        self.groupObject = groupObject;
        self.conversationId = groupObject.conversationId;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    TGConversation *conversation = [TGDatabaseInstance() loadConversationWithId:self.conversationId];

    if (conversation) {
        [self setTitleText:conversation.chatTitle];
    }else{
        [self setTitleText:self.groupObject.groupName];
    }
    
    if ([TGDatabaseInstance() containsConversationWithId:self.conversationId] && conversation &&conversation.leftChat == NO && conversation.kickedFromChat == NO) {
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(publishNodeButtonPressed:)]];
    }else{
        UIButton *joinButton = [UIButton buttonWithType:UIButtonTypeCustom];
        joinButton.frame = CGRectMake(0, 0, 62, 27);
        [joinButton setTitle:TGLocalized(@"GroupInfo.JoinButton") forState:UIControlStateNormal];
        [joinButton setImage:[UIImage imageNamed:@"group_join_btn"] forState:UIControlStateNormal];
        joinButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        [joinButton addTarget:self action:@selector(joinPressed) forControlEvents:UIControlEventTouchUpInside];
        joinButton.layer.masksToBounds = YES;
        joinButton.layer.cornerRadius = 5;
        joinButton.layer.borderColor = [UIColor whiteColor].CGColor;
        joinButton.layer.borderWidth = 1.0f;
        joinButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:joinButton]];
    }
}

- (void)joinPressed
{
    TGReplyGroupViewController *replyGroupController = [[TGReplyGroupViewController alloc] initWithConversationId:self.groupObject.conversationId groupName:self.groupObject.groupName groupAvatarKey:self.groupObject.avatarKey groupDescription:self.groupObject.groupDesc];
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[replyGroupController]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self presentViewController:navigationController animated:true completion:nil];
}

- (void)handleNewPostNotification:(NSNotification *)notification
{
    NSMutableDictionary *nodeInfo = notification.object;
    PostPublishType type = [[nodeInfo objectForKey:@"ispublic"] integerValue];
    int64_t groupid = [[nodeInfo objectForKey:@"groupid"] int64Value];
    if ([self isMemberOfClass:[TGGroupInfoBoardController class]] && (type == PostPublishTypeGroupBoard || type == PostPublishTypeBoth) && groupid == self.conversationId) {
        NSString *nodeid = [nodeInfo objectForKey:@"postid"];
        NSMutableArray *tmpArr = [self.nodeIds mutableCopy];
        [tmpArr insertObject:nodeid atIndex:0];
        self.nodeIds = [tmpArr copy];
        TGNodeModel *nodeModel = [[TGNodeDataManager sharedInstance] loadNodeWithId:nodeid streamType:StreamTypeGroup];
        if (nodeModel) {
            [self.listModel insertObject:nodeModel atIndex:0];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.hasNotDataView removeFromSuperview];
        }
    }
}

- (void)handlePostDeleteNotification:(NSNotification *)notification
{
    NSString *postID = notification.object;
    __block TGNodeModel *nodeToDelete = nil;
    __block NSUInteger index = 0;
    [self.listModel enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        TGNodeModel *node = (TGNodeModel *)obj;
        if ([node.nodeId isEqualToString:postID]) {
            nodeToDelete = node;
            index = idx;
            *stop = YES;
        }
    }];
    if (nodeToDelete) {
        [self.listModel removeObject:nodeToDelete];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }
    if (self.listModel.count == 0) {
        [self.view insertSubview:self.hasNotDataView aboveSubview:self.tableView];
    }
}

- (void)refreshNodeStreamData
{
    self.currentPage = 0;
    
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService getNodeStreamWithConversationId:@(ABS(self.conversationId)).stringValue isPublic:StreamTypeGroup sortType:SortTypeLatest successBlock:^(NSDictionary *dictRet)
     {
         [T8Common storeNodesAfterGetNodeStreamWithConversationId:@(ABS(self.conversationId)).stringValue isPublic:StreamTypeGroup sortType:SortTypeLatest successData:dictRet];
         
         __strong typeof(self) strongSelf = weakSelf;
         strongSelf.nodeIds = [NSArray arrayWithArray:[dictRet objectForKey:@"ids"]];
         
         strongSelf.listModel = [[[TGNodeDataManager sharedInstance] loadNodes:[strongSelf getNodeIdsByCurrentPage:strongSelf.currentPage] streamType:StreamTypeGroup] mutableCopy];
         if (strongSelf.listModel.count == 0) {
             [strongSelf.view insertSubview:strongSelf.hasNotDataView aboveSubview:strongSelf.tableView];
         }else{
             [strongSelf.hasNotDataView removeFromSuperview];
         }
         [strongSelf.tableView reloadData];
         [strongSelf.tableView.pullToRefreshView stopAnimating];
         
         strongSelf.currentPage++;
     } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
         __strong typeof(weakSelf) strongSelf = weakSelf;
         [strongSelf.tableView.pullToRefreshView stopAnimating];
     }];
}

- (void)reloadMoreNodeStreamData
{
    NSArray *ids = [self getNodeIdsByCurrentPage:self.currentPage];
    if (!ids) {
        [self.tableView setShowsInfiniteScrolling:NO];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService getNodeStreamWithNodeIds:ids isPublic:StreamTypeGroup successBlock:^(NSDictionary *dictRet)
     {
         [T8Common storeNodesAfterGetNodeStreamWithNodeIds:ids isPublic:StreamTypeGroup successData:dictRet];
         
         __strong typeof(self) strongSelf = weakSelf;
         
         [strongSelf.listModel addObjectsFromArray:[[[TGNodeDataManager sharedInstance] loadNodes:[strongSelf getNodeIdsByCurrentPage:strongSelf.currentPage] streamType:StreamTypeGroup] mutableCopy]];
         [strongSelf.tableView reloadData];
         [strongSelf.tableView.infiniteScrollingView stopAnimating];
         
         strongSelf.currentPage ++;
         
     } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
         __strong typeof(weakSelf) strongSelf = weakSelf;
         [strongSelf.tableView.infiniteScrollingView stopAnimating];
     }];
}

#pragma mark -
- (void)publishNodeButtonPressed:(id)__unused sender
{
    NSMutableDictionary *event =
    [[GAIDictionaryBuilder createEventWithCategory:@"群留言板"
                                            action:@"发布消息"
                                             label:@""
                                             value:nil] build];
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];
    
    TGPublishPostVC *publish = [[TGPublishPostVC alloc] initWithEnteranceType:PublishEnteranceTypeGroupBoard andGroupId:self.conversationId];
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[publish]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self presentViewController:navigationController animated:YES completion:nil];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:GroupBoardIntroKey_Post])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:GroupBoardIntroKey_Post];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:GroupBoardIntroKey_Bottom];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.postIntroView removeFromSuperview];
        [self.bottomIntroView removeFromSuperview];
    }
}

- (void)closeIntroViewPressed
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:GroupBoardIntroKey_Bottom];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.bottomIntroView removeFromSuperview];
}

#pragma mark - Getter

- (UIImageView *)postIntroView
{
    if (!_postIntroView) {
        _postIntroView = [[UIImageView alloc] init];
        _postIntroView.frame = CGRectMake(self.view.frame.size.width-110, 64, 100, 46);
        _postIntroView.image = [[UIImage imageNamed:@"group_post_intro"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 5, 15, 35)];
        
        UILabel *introLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 17, self.view.frame.size.width - 20, 100)];
        introLabel.numberOfLines = 0;
        introLabel.font = [UIFont systemFontOfSize:18];
        introLabel.textColor = [UIColor whiteColor];
        introLabel.text = TGLocalized(@"GroupInfo.BoardPostIntro");
        [introLabel sizeToFit];
        CGSize introLabelSize = [introLabel sizeThatFits:CGSizeMake(self.view.frame.size.width - 20, CGFLOAT_MAX)];
        
        _postIntroView.frame = CGRectMake(self.view.frame.size.width - introLabelSize.width - 40, 64, introLabelSize.width + 30, introLabelSize.height + 30);
        [_postIntroView addSubview:introLabel];
    }
    
    return _postIntroView;
}

- (UIView *)bottomIntroView
{
    if (!_bottomIntroView) {
        _bottomIntroView = [[UIView alloc] init];
        _bottomIntroView.frame = CGRectZero;
        _bottomIntroView.backgroundColor = UIColorRGB(0x5BDB42);
        
        UILabel *introLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 40, self.view.frame.size.width - 30, 100)];
        introLabel.numberOfLines = 0;
        introLabel.font = [UIFont systemFontOfSize:18];
        introLabel.textColor = [UIColor whiteColor];
        introLabel.text = TGLocalized(@"GroupInfo.BoardBottomIntro");
        [introLabel sizeToFit];
        CGSize introLabelSize = [introLabel sizeThatFits:CGSizeMake(self.view.frame.size.width - 30, CGFLOAT_MAX)];
        
        UIButton *closeButton = [[UIButton alloc] init];
        closeButton.frame = CGRectMake(self.view.frame.size.width - 40, 0, 40, 40);
        [closeButton setImage:[UIImage imageNamed:@"group_intro_close_btn"] forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(closeIntroViewPressed) forControlEvents:UIControlEventTouchUpInside];
        [_bottomIntroView addSubview:closeButton];
        
        _bottomIntroView.frame = CGRectMake(0, self.view.frame.size.height - introLabelSize.height - 80, self.view.frame.size.width, introLabelSize.height+80);
        [_bottomIntroView addSubview:introLabel];
    }
    
    return _bottomIntroView;
}

- (UIImageView *)hasNotDataView
{
    if (!_hasNotDataView) {
        _hasNotDataView = [[UIImageView alloc] init];
        _hasNotDataView.image = [UIImage imageNamed:@"group_no_stream"];
        _hasNotDataView.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.width *868/643);
        
        UILabel *introLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 40, self.view.frame.size.width - 30, 100)];
        introLabel.textAlignment = NSTextAlignmentCenter;
        introLabel.numberOfLines = 0;
        introLabel.font = [UIFont systemFontOfSize:18];
        introLabel.textColor = UIColorRGB(0xB6C1CC);
        introLabel.text = TGLocalized(@"GroupInfo.BoardHasNoData");
        [introLabel sizeToFit];
        CGSize introLabelSize = [introLabel sizeThatFits:CGSizeMake(self.view.frame.size.width - 30, CGFLOAT_MAX)];
        introLabel.center = CGPointMake(self.view.frame.size.width/2, (_hasNotDataView.frame.size.height - introLabelSize.height)/2);
        [_hasNotDataView addSubview:introLabel];
    }
    
    return _hasNotDataView;
}

@end
