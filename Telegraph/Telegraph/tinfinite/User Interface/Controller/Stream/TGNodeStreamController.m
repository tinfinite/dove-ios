//
//  TGNodeStreamController.m
//  Telegraph
//
//  Created by yewei on 15/3/28.
//
//

#import "TGNodeStreamController.h"
#import "TGInterfaceAssets.h"
#import "TGNodeStreamCell.h"
#import "TGModernBarButton.h"
#import "TGPublishPostVC.h"
#import "T8NodeHttpRequestService.h"
#import "SVPullToRefresh.h"
#import "TGNodeDataManager.h"
#import "TGNodeDetailViewController.h"
#import "TGBackdropView.h"
#import "IDMPhotoBrowser.h"
#import "TGTelegraphUserInfoController.h"
#import "TGUsernameController.h"
#import "TGNavigationController.h"
#import "TGReplyGroupViewController.h"
#import "TGTelegraph.h"
#import "TGGroupInfoBoardController.h"

@interface TGNodeStreamController ()<UITableViewDataSource,UITableViewDelegate,TGNodeStreamCellImageTouchDelegate,IDMPhotoBrowserDelegate>

@property (nonatomic, strong) NSString *searchUserName;

@end

@implementation TGNodeStreamController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self isMemberOfClass:[TGNodeStreamController class]]) {
        id tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:kGAIScreenName value:@"公共信息流Tab"];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        self.conversationId = 0;
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [TGInterfaceAssets listsBackgroundColor];
    
    [self setTitleText:TGLocalized(@"Stream.PublicStreamTitle")];
    
    [self setRightBarButtonItem:[self controllerRightBarButtonItem]];
    
    self.currentPage = 0;
    [self prepareCacheData];
    
    CGRect tableFrame = self.view.bounds;
    tableFrame.origin.y = 64;
    tableFrame.size.height -= (64+([self isMemberOfClass:[TGNodeStreamController class]]?49:0));
    _tableView = [[TGListsTableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.opaque = true;
    _tableView.backgroundColor = nil;
    _tableView.showsVerticalScrollIndicator = true;
    
    [self.view addSubview:_tableView];
    
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf refreshNodeStreamData];
    }];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf reloadMoreNodeStreamData];
    }];
    [self.tableView setShowsInfiniteScrolling:NO];
    
    [self.tableView triggerPullToRefresh];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePostDeleteNotification:) name:Notification_Key_Post_Delete object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserBlockNotification:) name:Notification_Key_User_Blocked object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserUnblockNotification:) name:Notification_Key_User_Unblocked object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewPostNotification:) name:Notification_Key_New_Post object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_Key_Post_Delete object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_Key_User_Blocked object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_Key_User_Unblocked object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_Key_New_Post object:nil];
}

- (void)prepareCacheData
{
    StreamType streamType = [self isMemberOfClass:[TGNodeStreamController class]]?StreamTypePublic:StreamTypeGroup;
    self.nodeIds = [[TGNodeDataManager sharedInstance] loadStreamNodeIDs:streamType conversationId:self.conversationId];
    self.listModel = [[[TGNodeDataManager sharedInstance] loadNodes:[self getNodeIdsByCurrentPage:self.currentPage] streamType:streamType] mutableCopy];
}

- (void)handleNewPostNotification:(NSNotification *)notification
{
    NSMutableDictionary *nodeInfo = notification.object;
    PostPublishType type = [[nodeInfo objectForKey:@"ispublic"] integerValue];
    if ([self isMemberOfClass:[TGNodeStreamController class]] && (type == PostPublishTypePublishStream || type == PostPublishTypeBoth)) {
        NSString *nodeid = [nodeInfo objectForKey:@"postid"];
        NSMutableArray *tmpArr = [self.nodeIds mutableCopy];
        [tmpArr insertObject:nodeid atIndex:0];
        self.nodeIds = [tmpArr copy];
        TGNodeModel *nodeModel = [[TGNodeDataManager sharedInstance] loadNodeWithId:nodeid streamType:StreamTypePublic];
        if (nodeModel) {
            [self.listModel insertObject:nodeModel atIndex:0];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void)handleUserUnblockNotification:(NSNotification *) __unused notification
{
    StreamType streamType = [self isMemberOfClass:[TGNodeStreamController class]]?StreamTypePublic:StreamTypeGroup;
    self.listModel = [[[TGNodeDataManager sharedInstance] loadNodes:[self getAllNodeIdsShow] streamType:streamType] mutableCopy];
    [self.tableView reloadData];
}

- (void)handleUserBlockNotification:(NSNotification *)notification
{
    NSMutableDictionary *dict = (NSMutableDictionary *)notification.object;
    NSString *t8id = [dict objectForKey:@"t8id"];
    NSString *tgid = [dict objectForKey:@"tgid"];
    NSMutableArray *nodes = [NSMutableArray array];
    NSMutableArray *indexs = [NSMutableArray array];
    [self.listModel enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL __unused *stop) {
        TGNodeModel *node = (TGNodeModel *)obj;
        if ([node.author.authorId isEqualToString:t8id] || [node.author.tgUserId isEqualToString:tgid]) {
            [nodes addObject:node];
            [indexs addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
        }
    }];
    if (nodes.count > 0) {
        [self.listModel removeObjectsInArray:nodes];
        [self.tableView deleteRowsAtIndexPaths:indexs withRowAnimation:UITableViewRowAnimationFade];
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
}

- (void)controllerInsetUpdated:(UIEdgeInsets) __unused previousInset
{
    
}

#pragma mark - 
- (void)scrollToTopRequested
{
    [self.tableView triggerPullToRefresh];
}

- (UIBarButtonItem *)controllerRightBarButtonItem
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(publishNodeButtonPressed:)];
}

- (void)publishNodeButtonPressed:(id)__unused sender
{
    NSMutableDictionary *event =
    [[GAIDictionaryBuilder createEventWithCategory:@"公共信息流"
                                            action:@"发布消息"
                                             label:@""
                                             value:nil] build];
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];    
    
    TGPublishPostVC *publish = [[TGPublishPostVC alloc] initWithEnteranceType:PublishEnteranceTypePublishStream andGroupId:0];
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[publish]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)refreshNodeStreamData
{
    self.currentPage = 0;
    
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService getNodeStreamWithConversationId:nil isPublic:StreamTypePublic sortType:SortTypeHotest successBlock:^(NSDictionary *dictRet)
    {
        [T8Common storeNodesAfterGetNodeStreamWithConversationId:@(ABS(self.conversationId)).stringValue isPublic:StreamTypeGroup sortType:SortTypeLatest successData:dictRet];
        
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.nodeIds = [NSArray arrayWithArray:[dictRet objectForKey:@"ids"]];
        
        strongSelf.listModel = [[[TGNodeDataManager sharedInstance] loadNodes:[strongSelf getNodeIdsByCurrentPage:strongSelf.currentPage] streamType:StreamTypePublic] mutableCopy];
        [strongSelf.tableView reloadData];
        
        [strongSelf.tableView.pullToRefreshView stopAnimating];
        
        strongSelf.currentPage++;
        
        [strongSelf.tableView setShowsInfiniteScrolling:YES];
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
        
    } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.tableView.pullToRefreshView stopAnimating];
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
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
    [T8NodeHttpRequestService getNodeStreamWithNodeIds:ids isPublic:StreamTypePublic  successBlock:^(NSDictionary __unused *dictRet)
    {
        [T8Common storeNodesAfterGetNodeStreamWithNodeIds:ids isPublic:StreamTypePublic successData:dictRet];
        
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf.listModel addObjectsFromArray:[[[TGNodeDataManager sharedInstance] loadNodes:[strongSelf getNodeIdsByCurrentPage:strongSelf.currentPage] streamType:StreamTypePublic] mutableCopy]];
        [strongSelf.tableView reloadData];
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
        
        strongSelf.currentPage ++;
        
    } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
    }];
}

- (NSArray *)getNodeIdsByCurrentPage:(NSUInteger)currentPage
{
    NSIndexSet *indexSet = nil;
    NSArray *array = nil;
    if ((currentPage + 1) * 20 < self.nodeIds.count) {
        indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(20 * currentPage, 20)];
        array = [self.nodeIds objectsAtIndexes:indexSet];
    }else if(self.nodeIds.count > 20*currentPage){
        indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(20 * currentPage, self.nodeIds.count - 20 * currentPage)];
        array = [self.nodeIds objectsAtIndexes:indexSet];
    }
    
    return array;
}

- (NSArray *)getAllNodeIdsShow
{
    NSMutableArray *idsArray = [NSMutableArray array];
    
    for (NSUInteger i=0; i<self.currentPage; i++) {
        [idsArray addObjectsFromArray:[self getNodeIdsByCurrentPage:i]];
    }
    
    return [idsArray copy];
}

- (void)searchForeignWithUserName:(NSString *)username
{
    NSString *searchPath = [NSString stringWithFormat:@"/tg/contacts/search/(%ld)", (long)[username hash]];
    [ActionStageInstance() requestActor:searchPath options:[NSDictionary dictionaryWithObjectsAndKeys:username, @"query",[[NSNumber alloc] initWithBool:false], @"searchPhonebook", nil] watcher:self];
}

#pragma mark - ASWatcher
- (void)actorMessageReceived:(NSString *)path messageType:(NSString *)messageType message:(id)message
{
    if ([path hasPrefix:@"/tg/contacts/search"])
    {
        NSArray *users = [message objectForKey:@"users"];
        if (users.count) {
            for (TGUser *user in users) {
                if ([user.userName isEqualToString:self.searchUserName]) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        TGTelegraphUserInfoController *userInfoController = [[TGTelegraphUserInfoController alloc] initWithUid:user.uid];
                        [self.navigationController pushViewController:userInfoController animated:true];
                    });
                    break;
                }
            }
        }
    }
}

#pragma mark - getter
- (NSMutableArray *)listModel
{
    if (!_listModel) {
        _listModel = [[NSMutableArray alloc] init];
    }
    return _listModel;
}

#pragma mark - Table logic
- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section
{
    return _listModel.count;
}

- (CGFloat)tableView:(UITableView *)__unused tableView heightForRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    return [TGNodeStreamCell tableView:tableView rowHeightForObject:[_listModel objectAtIndex:indexPath.row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *TGGroupInfoJoinRequestCellIdentifier = @"TGNodeStreamCellIdentifier";
    TGNodeStreamCell *cell = [tableView dequeueReusableCellWithIdentifier:TGGroupInfoJoinRequestCellIdentifier];
    if (cell == nil)
    {
        cell = [[TGNodeStreamCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:TGGroupInfoJoinRequestCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        __weak typeof(self) weakSelf = self;
        cell.userBlock = ^(EnterType enterType,NSString *enterId,NSString *groupName,NSString *groupAvatarKey){
            if (enterType == EnterTypeUserInfo) {
                self.searchUserName = enterId;
                [self searchForeignWithUserName:enterId];
            }else if (enterType == EnterTypeGroupInfo){
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
                    TGGroupObject *groupObj = [[TGGroupObject alloc] init];
                    groupObj.conversationId = -enterId.longLongValue;
                    groupObj.groupName = groupName;
                    groupObj.avatarKey = groupAvatarKey;
                    TGGroupInfoBoardController *groupInfoBoard = [[TGGroupInfoBoardController alloc] initWithGroupObject:groupObj];
                    
                    [self.navigationController pushViewController:groupInfoBoard animated:YES];
                    
//                    TGReplyGroupViewController *replyGroupController = [[TGReplyGroupViewController alloc] initWithConversationId:-enterId.longLongValue groupName:groupName groupAvatarKey:groupAvatarKey groupDescription:nil];
                    
//                    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[groupInfoBoard]];
                    
//                    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
//                    {
//                        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
//                        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
//                    }
//                    
//                    [self presentViewController:navigationController animated:true completion:nil];
                }
            }
        };
        cell.recommandBlock = ^(TGNodeModel *nodeObject){
            __strong typeof(self) strongSelf = weakSelf;
            
            StreamType streamType = [strongSelf isMemberOfClass:[TGNodeStreamController class]]?StreamTypePublic:StreamTypeGroup;
            
            TGNodeDetailViewController *nodeDetail = [[TGNodeDetailViewController alloc] initWithNodeID:nodeObject.nodeId groupId:self.conversationId streamType:streamType];
            
            [strongSelf.navigationController pushViewController:nodeDetail animated:YES];
        };
        cell.forwardBlock = ^(NSString *userId){
            __strong typeof(self) strongSelf = weakSelf;
            TGTelegraphUserInfoController *userInfoController = [[TGTelegraphUserInfoController alloc] initWithUid:[userId intValue]];
            [strongSelf.navigationController pushViewController:userInfoController animated:true];
        };
        
        cell.delegate = self;
    }
    
    cell.indexPath = indexPath;
    cell.streamType = [self isMemberOfClass:[TGGroupInfoBoardController class]]?StreamTypeGroup:StreamTypePublic;
    cell.object = [_listModel objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    StreamType streamType = [self isMemberOfClass:[TGNodeStreamController class]]?StreamTypePublic:StreamTypeGroup;
    
    TGNodeModel *node = [_listModel objectAtIndex:indexPath.row];
    TGNodeDetailViewController *nodeDetail = [[TGNodeDetailViewController alloc] initWithNodeID:node.nodeId groupId:self.conversationId streamType:streamType];
    [self.navigationController pushViewController:nodeDetail animated:YES];
}

#pragma mark -TGNodeStreamCellImageTouchDelegate

- (void)touchImageView:(UIImageView *)imageView pictureObject:(TGNodePhotoObject *)pictureObj pictures:(NSArray *)pictures
{
    NSMutableArray *photos = [NSMutableArray new];
    
    IDMPhoto *photo;
    
    for (TGNodePhotoObject *obj in pictures) {
        photo = [IDMPhoto photoWithURL:[NSURL URLWithString:obj.originUrl]];
        [photos addObject:photo];
    }
    
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos animatedFromView:imageView];
    browser.delegate = self;
    browser.displayActionButton = YES;
    browser.displayArrowButton = NO;
    browser.displayCounterLabel = YES;
    browser.usePopAnimation = YES;
    browser.scaleImage = imageView.image;
    browser.view.tintColor = [UIColor whiteColor];
    [browser setInitialPageIndex:pictureObj.pictureIndexInPost];

    [self presentViewController:browser animated:YES completion:nil];
}

@end
