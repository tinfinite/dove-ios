//
//  TGGroupInfoJoinRequestController.m
//  Telegraph
//
//  Created by yewei on 15/2/15.
//
//

#import "TGGroupInfoJoinRequestController.h"
#import "TGListsTableView.h"
#import "TGInterfaceAssets.h"
#import "T8GroupHttpRequestService.h"
#import "NSDictionary+Ext.h"
#import "TGJoinRequestTableViewCell.h"
#import "TGJoinRequestObject.h"
#import "SVPullToRefresh.h"

@interface TGGroupInfoJoinRequestController () <UITableViewDelegate, UITableViewDataSource,TGJoinRequestTableViewCellDelegate>
{
    TGConversation *_conversation;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *listModel;

@property (nonatomic, assign) long long timestamp;
@property (nonatomic, assign) NSInteger currentPage;

@end

@implementation TGGroupInfoJoinRequestController

- (instancetype)initConversation:(TGConversation *)conversation
{
    self = [super init];
    if (self) {
        _conversation = conversation;
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView triggerPullToRefresh];
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [TGInterfaceAssets listsBackgroundColor];
    
    [self setTitleText:TGLocalized(@"GroupInfo.JoinRequestTitle")];
    
    CGRect tableFrame = self.view.bounds;
    tableFrame.origin.y = 64;
    tableFrame.size.height -= 64;
    _tableView = [[TGListsTableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.opaque = true;
    _tableView.backgroundColor = nil;
    
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    _tableView.tableFooterView = view;
    
    [(TGListsTableView *)_tableView adjustBehaviour];
    
    _tableView.showsVerticalScrollIndicator = true;
    
    [self.view addSubview:_tableView];
    
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf refreshJoinRequestData];
    }];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf reloadMoreJoinRequestData];
    }];
}

#pragma mark - private

- (void)refreshJoinRequestData
{
    self.currentPage = 1;
    self.timestamp = 0;
    __weak typeof(self) weakSelf = self;
    RequestSuccess successBlock = ^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.listModel removeAllObjects];
        [strongSelf reloadTableView:dictRet];
        [strongSelf.tableView.pullToRefreshView stopAnimating];
    };
    
    RequestFailuer failuerBlock = ^(NSDictionary *dictRet, NSError __unused*error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (dictRet) {
            [T8HudHelper showHUDMessage:dictRet[@"message"]];
        }
        [strongSelf.tableView.pullToRefreshView stopAnimating];
    };
    
    [T8GroupHttpRequestService getJoinRequestListWithGroupId:@(_conversation.conversationId).stringValue page:self.currentPage limit:20 timestamp:0 accessToken:T8CONTEXT.accessToken successBlock:successBlock failureBlock:failuerBlock];
}

- (void)reloadMoreJoinRequestData
{
    __weak typeof(self) weakSelf = self;
    RequestSuccess successBlock = ^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf reloadTableView:dictRet];
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
    };
    
    RequestFailuer failuerBlock = ^(NSDictionary *dictRet, NSError __unused*error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (dictRet) {
            [T8HudHelper showHUDMessage:dictRet[@"message"]];
        }
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
    };
    
    [T8GroupHttpRequestService getJoinRequestListWithGroupId:@(_conversation.conversationId).stringValue page:self.currentPage limit:20 timestamp:_timestamp accessToken:T8CONTEXT.accessToken successBlock:successBlock failureBlock:failuerBlock];
}

- (void)reloadTableView:(NSDictionary *)data
{
    self.currentPage++;
    self.timestamp = [data longLongForKey:@"timestamp" withDefault:0.0];
    
    NSArray *array = [data arrayForKey:@"data" withDefault:[NSArray array]];
    for (NSUInteger i = 0; i<array.count; i++) {
        TGJoinRequestObject *joinRequestModel = [[TGJoinRequestObject alloc] initWithDict:array[i]];
        [self.listModel addObject:joinRequestModel];
    }
    if (array.count < 20) {
        [self.tableView setShowsInfiniteScrolling:NO];
    }
    [self.tableView reloadData];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    return [TGJoinRequestTableViewCell tableView:tableView rowHeightForObject:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *TGGroupInfoJoinRequestCellIdentifier = @"TGGroupInfoJoinRequestCellIdentifier";
    TGJoinRequestTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TGGroupInfoJoinRequestCellIdentifier];
    if (cell == nil)
    {
        cell = [[TGJoinRequestTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:TGGroupInfoJoinRequestCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    TGJoinRequestObject *joinRequestModel = [_listModel objectAtIndex:indexPath.row];
    cell.indexPath = indexPath;
    cell.object = joinRequestModel;
    cell.delegate = self;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)__unused tableView canEditRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)__unused tableView editingStyleForRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    return  UITableViewCellEditingStyleDelete;
}

- (void) tableView:(UITableView *)__unused tableView commitEditingStyle:(UITableViewCellEditingStyle)__unused editingStyle forRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        TGJoinRequestObject *joinRequestModel = [_listModel objectAtIndex:indexPath.row];
        
        [T8GroupHttpRequestService updateJoinRequestWithApplyId:joinRequestModel.joinRequestId status:GroupJoinRequestTypeDelete accessToken:T8CONTEXT.accessToken successBlock:^(NSDictionary *__unused dictRet) {
            
        } failureBlock:^(NSDictionary *__unused dictRet, NSError *__unused error) {
            
        }];
        [self.listModel removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - method
- (void)searchForeignWithUserName:(NSString *)username
{
    NSString *searchPath = [NSString stringWithFormat:@"/tg/contacts/search/(%ld)", (long)[username hash]];
    [ActionStageInstance() requestActor:searchPath options:[NSDictionary dictionaryWithObjectsAndKeys:username, @"query", [[NSNumber alloc] initWithInt:TGTelegraphInstance.clientUserId], @"ignoreUid", [[NSNumber alloc] initWithBool:false], @"searchPhonebook", nil] watcher:self];
    
}

#pragma mark - ASWatcher
- (void)actorMessageReceived:(NSString *)path messageType:(NSString *)__unused messageType message:(id)message
{
    if ([path hasPrefix:@"/tg/contacts/search"])
    {
        NSArray *users = [message objectForKey:@"users"];
        for (TGUser *user in users) {
            NSString *path = [NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/addMember/(%d)", _conversation.conversationId, user.uid];
            NSDictionary *options = @{@"conversationId": @(_conversation.conversationId), @"uid": @(user.uid)};
            [ActionStageInstance() dispatchOnStageQueue:^
             {
                 [ActionStageInstance() requestActor:path options:options watcher:self];
                 [ActionStageInstance() requestActor:path options:options watcher:TGTelegraphInstance];
             }];
        }
    }
}

- (void)actorCompleted:(int)__unused status path:(NSString *)path result:(id)__unused result
{
    if ([path hasPrefix:@"/tg/conversation/"] && [path rangeOfString:@"/addMember/"].length > 0) {
        
    }
}

#pragma mark -TGJoinRequestTableViewCellDelegate
- (void)didPressApproveButton:(NSIndexPath *)indexPath
{
    if (indexPath.row < (NSInteger)_listModel.count) {
        TGJoinRequestObject *joinRequestModel = [_listModel objectAtIndex:indexPath.row];
        [self searchForeignWithUserName:joinRequestModel.username];
        
        __weak typeof(self) weakSelf = self;
        [T8GroupHttpRequestService updateJoinRequestWithApplyId:joinRequestModel.joinRequestId status:GroupJoinRequestTypeApprove accessToken:T8CONTEXT.accessToken successBlock:^(NSDictionary __unused*dictRet) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.listModel removeObject:joinRequestModel];
            [strongSelf.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [strongSelf.tableView reloadData];
        } failureBlock:^(NSDictionary *__unused dictRet, NSError *__unused error) {
            
        }];
    }
}

@end
