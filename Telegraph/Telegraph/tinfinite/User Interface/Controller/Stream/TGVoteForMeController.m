//
//  TGVoteForMeController.m
//  Telegraph
//
//  Created by 琦张 on 15/4/28.
//
//

#import "TGVoteForMeController.h"
#import "SVPullToRefresh.h"
#import "T8NodeHttpRequestService.h"
#import "TGVoteForMeCell.h"
#import "TGListsTableView.h"
#import "TGInterfaceAssets.h"
#import "TGNotificationMsgModel.h"
#import "TGNodeDetailViewController.h"

@interface TGVoteForMeController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, copy)   NSString *timeStamp;

@property (nonatomic, strong) UILabel *noDataLabel;

@end

@implementation TGVoteForMeController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"投票页面"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [TGInterfaceAssets listsBackgroundColor];
    [self setTitleText:TGLocalized(@"Settings.Votes")];
    
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

- (NSMutableArray *)dataArr
{
    if (!_dataArr) {
        _dataArr = [[NSMutableArray alloc] init];
    }
    return _dataArr;
}

- (UILabel *)noDataLabel
{
    if (!_noDataLabel) {
        _noDataLabel = [[UILabel alloc] init];
        _noDataLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
        _noDataLabel.center = self.view.center;
        _noDataLabel.text = TGLocalized(@"Settings.NoVoteDescription");
        _noDataLabel.textColor = UIColorRGB(0xA0A0A4);
        _noDataLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return _noDataLabel;
}

- (void)reloadData
{
    self.currentPage = 1;
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService getVoteForMeMessagesWithPage:self.currentPage limit:20 timestamp:self.timeStamp success:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf.dataArr removeAllObjects];
        
        NSArray *dataArr = [dictRet objectForKey:@"data"];
        for (NSDictionary *dict in dataArr) {
            TGNotificationMsgModel *model = [[TGNotificationMsgModel alloc] initWithDict:dict msgType:NotificationMsgTypeVoteMe];
            [strongSelf.dataArr addObject:model];
        }
        
        [strongSelf.tableView reloadData];
        [strongSelf.tableView.pullToRefreshView stopAnimating];
        
        if (strongSelf.dataArr.count == 0) {
            [strongSelf.view addSubview:strongSelf.noDataLabel];
        }else if (strongSelf.dataArr.count < 20){
            [strongSelf.tableView setShowsInfiniteScrolling:NO];
            [strongSelf.noDataLabel removeFromSuperview];
        }else{
            [strongSelf.noDataLabel removeFromSuperview];
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
    [T8NodeHttpRequestService getVoteForMeMessagesWithPage:self.currentPage limit:20 timestamp:self.timeStamp success:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        NSArray *dataArr = [dictRet objectForKey:@"data"];
        for (NSDictionary *dict in dataArr) {
            TGNotificationMsgModel *model = [[TGNotificationMsgModel alloc] initWithDict:dict msgType:NotificationMsgTypeVoteMe];
            [strongSelf.dataArr addObject:model];
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
    return self.dataArr.count;
}

- (CGFloat)tableView:(UITableView *) __unused tableView heightForRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    TGNotificationMsgModel *model = _dataArr[indexPath.row];
    return [TGVoteForMeCell tableView:tableView rowHeightForObject:model];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    TGVoteForMeCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[TGVoteForMeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    TGNotificationMsgModel *model = _dataArr[indexPath.row];
    
    cell.object = model;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TGNotificationMsgModel *model = _dataArr[indexPath.row];
    
    TGNodeDetailViewController *nodeDetailController = [[TGNodeDetailViewController alloc] initWithNodeID:model.postId groupId:0 streamType:StreamTypePublic];
    [self.navigationController pushViewController:nodeDetailController animated:YES];
}

@end
