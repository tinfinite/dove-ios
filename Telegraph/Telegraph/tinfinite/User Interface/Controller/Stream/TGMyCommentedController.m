//
//  TGMyCommentedController.m
//  Telegraph
//
//  Created by yewei on 15/4/21.
//
//

#import "TGMyCommentedController.h"
#import "SVPullToRefresh.h"
#import "T8NodeHttpRequestService.h"
#import "TGMyCommentedCell.h"
#import "TGListsTableView.h"
#import "TGInterfaceAssets.h"
#import "TGMyCommentedModel.h"
#import "TGNodeDetailViewController.h"

@interface TGMyCommentedController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *commentList;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, copy)   NSString *timeStamp;

@property (nonatomic, strong) UILabel *noCommentLabel;

@end

@implementation TGMyCommentedController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"评论页面"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [TGInterfaceAssets listsBackgroundColor];
    [self setTitleText:TGLocalized(@"Settings.Comments")];
    
    CGRect tableFrame = self.view.bounds;
    tableFrame.origin.y = 64;
    tableFrame.size.height -= 64;
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
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf loadMore];
    }];
    [self.tableView addPullToRefreshWithActionHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf reloadData];
    }];
    
    if (!self.tableView.pullToRefreshView.lastUpdatedDate && self.tableView.pullToRefreshView.state == SVPullToRefreshStateStopped) {
        [self.tableView triggerPullToRefresh];
    }
}

- (void)controllerInsetUpdated:(UIEdgeInsets) __unused previousInset
{
    
}

- (NSMutableArray *)commentList
{
    if (!_commentList) {
        _commentList = [[NSMutableArray alloc] init];
    }
    return _commentList;
}

- (UILabel *)noCommentLabel
{
    if (!_noCommentLabel) {
        _noCommentLabel = [[UILabel alloc] init];
        _noCommentLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
        _noCommentLabel.center = self.view.center;
        _noCommentLabel.text = TGLocalized(@"Settings.NoCommentDescription");
        _noCommentLabel.textColor = UIColorRGB(0xA0A0A4);
        _noCommentLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return _noCommentLabel;
}

- (void)reloadData
{
    self.currentPage = 1;
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService getMyCommentsWithPage:self.currentPage limit:20 timestamp:self.timeStamp success:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf.commentList removeAllObjects];
        
        NSArray *dataArr = [dictRet objectForKey:@"data"];
        for (NSDictionary *dict in dataArr) {
            TGMyCommentedModel *model = [[TGMyCommentedModel alloc] initWithDict:dict];
            [strongSelf.commentList addObject:model];
        }
        
        [strongSelf.tableView reloadData];
        [strongSelf.tableView.pullToRefreshView stopAnimating];

        if (strongSelf.commentList.count == 0) {
            [strongSelf.view addSubview:strongSelf.noCommentLabel];
        }else if (strongSelf.commentList.count < 20){
            [strongSelf.tableView setShowsInfiniteScrolling:NO];
            [strongSelf.noCommentLabel removeFromSuperview];
        }else{
            [strongSelf.noCommentLabel removeFromSuperview];
            strongSelf.tableView.tableFooterView = nil;
        }
    } failure:^(NSDictionary __unused*dictRet, NSError __unused*error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.tableView.pullToRefreshView stopAnimating];
    }];
}

- (void)loadMore
{
    self.currentPage++;
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService getMyCommentsWithPage:self.currentPage limit:20 timestamp:self.timeStamp success:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        NSArray *dataArr = [dictRet objectForKey:@"data"];
        for (NSDictionary *dict in dataArr) {
            TGMyCommentedModel *model = [[TGMyCommentedModel alloc] initWithDict:dict];
            [strongSelf.commentList addObject:model];
        }
        
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
        if (dataArr.count == 0) {
            [strongSelf.tableView setShowsInfiniteScrolling:NO];
        }
        [strongSelf.tableView reloadData];
    } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
    }];
}

#pragma mark - UITableViewDelegate && UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *) __unused tableView numberOfRowsInSection:(NSInteger) __unused section
{
    return self.commentList.count;
}

- (CGFloat)tableView:(UITableView *) __unused tableView heightForRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    TGMyCommentedModel *model = _commentList[indexPath.row];
    return [TGMyCommentedCell tableView:tableView rowHeightForObject:model];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    TGMyCommentedCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[TGMyCommentedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    TGMyCommentedModel *model = _commentList[indexPath.row];
    
    cell.object = model;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TGMyCommentedModel *model = _commentList[indexPath.row];
    
    TGNodeDetailViewController *nodeDetailController = [[TGNodeDetailViewController alloc] initWithNodeID:model.postId groupId:0 streamType:StreamTypePublic];
    [self.navigationController pushViewController:nodeDetailController animated:YES];
}

@end
