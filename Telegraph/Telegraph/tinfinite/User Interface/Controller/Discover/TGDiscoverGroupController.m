//
//  TGDiscoverGroupController.m
//  Telegraph
//
//  Created by yewei on 15/3/24.
//
//

#import "TGDiscoverGroupController.h"
#import "TGGroupInfoCell.h"
#import "T8GroupAndCommunityService.h"
#import "TGGroupObject.h"
#import "TGDatabase.h"
#import "TGInterfaceManager.h"
#import "TGAlertView.h"
#import "T8GroupHttpRequestService.h"
#import "SVPullToRefresh.h"
#import "TGTelegraph.h"
#import "TGReplyGroupViewController.h"
#import "TGNavigationController.h"
#import "TGUsernameController.h"
#import "TGGroupInfoBoardController.h"

#define DiscoverPageLimit 20

@interface TGDiscoverGroupController ()<ASWatcher>

@property (nonatomic,strong) UIView *noneGroupView;
@property (nonatomic,strong) NSMutableArray *recommendList;
@property (nonatomic,strong) NSMutableArray *upvoteList;

@end

@implementation TGDiscoverGroupController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"发现页"];
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
    
    [self setTitleText:TGLocalized(@"Discover.Title")];
    
    [self setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)]];
    
    __weak typeof(self) weakSelf = self;
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf loadMore];
    }];
    [self.tableView addPullToRefreshWithActionHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf reloadData];
    }];
    
    [T8HudHelper showHUDActivity:self.view];
    
    self.tableView.infiniteScrollingView.originalBottomInset = 49.0f;
    self.tableView.pullToRefreshView.originalTopInset = 64.0f;
    self.tableView.pullToRefreshView.originalBottomInset = 49.0f;
    
    if (!self.tableView.pullToRefreshView.lastUpdatedDate && self.tableView.pullToRefreshView.state == SVPullToRefreshStateStopped) {
        [self.tableView triggerPullToRefresh];
    }
}

- (void)cancelPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchHashWithUserName:(NSString *)username
{
    NSString *searchPath = [NSString stringWithFormat:@"/tg/contacts/search/(%ld)", (long)[username hash]];
    [ActionStageInstance() requestActor:searchPath options:[NSDictionary dictionaryWithObjectsAndKeys:username, @"query", [[NSNumber alloc] initWithInt:TGTelegraphInstance.clientUserId], @"ignoreUid", [[NSNumber alloc] initWithBool:false], @"searchPhonebook", nil] watcher:self];
    
}

#pragma mark - ASWatcher
- (void)actorMessageReceived:(NSString *)path messageType:(NSString *)messageType message:(id)message
{
    if ([path hasPrefix:@"/tg/contacts/search"])
    {
        if ([messageType isEqualToString:@"globalResults"])
        {
            NSArray *users = [message objectForKey:@"users"];
            for (TGUser *user in users) {
                
            }
        }
    }
}

#pragma mark - getter
- (UIView *)noneGroupView
{
    if (!_noneGroupView) {
        _noneGroupView = [[UIView alloc] init];
        _noneGroupView.frame = self.tableView.bounds;
        //text
        UILabel *infoLabel = [UILabel new];
        infoLabel.text = TGLocalized(@"Discover.NoneGroupInfo");
        infoLabel.numberOfLines = 10;
        infoLabel.textColor = UIColorRGB(0x9B9B9B);
        infoLabel.font = [UIFont systemFontOfSize:16];
        infoLabel.textAlignment = NSTextAlignmentCenter;
        [_noneGroupView addSubview:infoLabel];
        [infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_noneGroupView);
            make.centerY.equalTo(_noneGroupView).offset(-56.5);
            make.left.equalTo(_noneGroupView).offset(35);
            make.right.equalTo(_noneGroupView).offset(-35);
        }];
    }
    return _noneGroupView;
}

- (NSMutableArray *)recommendList
{
    if (!_recommendList) {
        _recommendList = [[NSMutableArray alloc] init];
    }
    return _recommendList;
}

- (NSMutableArray *)upvoteList
{
    if (!_upvoteList) {
        _upvoteList = [[NSMutableArray alloc] init];
    }
    return _upvoteList;
}

#pragma mark - method
- (void)reloadData
{
    self.currentPage = 1;
    __weak typeof(self) weakSelf = self;
    [T8GroupAndCommunityService getDiscoveryGroupListWithPage:self.currentPage limit:DiscoverPageLimit timeStamp:self.timeStamp t8ID:T8CONTEXT.t8UserId success:^(NSDictionary *dictRet) {
        
        [T8HudHelper hideHUDActivity:self.view];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf.recommendList removeAllObjects];
        [strongSelf.upvoteList removeAllObjects];
        
        NSArray *dataArr = [[dictRet objectForKey:@"data"] objectForKey:@"list"];
        [dataArr enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                TGGroupObject *model = [[TGGroupObject alloc] initWithDict:(NSDictionary *)obj];
                [strongSelf.upvoteList addObject:model];
            }
        }];
        
        dataArr = [[dictRet objectForKey:@"data"] objectForKey:@"recommend"];
        [dataArr enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                TGGroupObject *model = [[TGGroupObject alloc] initWithDict:(NSDictionary *)obj];
                [strongSelf.recommendList addObject:model];
            }
        }];
        
        [strongSelf.tableView.pullToRefreshView stopAnimating];
        if (strongSelf.upvoteList.count == 0) {
            [strongSelf.tableView setShowsInfiniteScrolling:NO];
            strongSelf.tableView.tableFooterView = strongSelf.noneGroupView;
        }else{
            [strongSelf.tableView setShowsInfiniteScrolling:YES];
            strongSelf.tableView.tableFooterView = nil;
        }
        [strongSelf.tableView reloadData];
    } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        [T8HudHelper hideHUDActivity:self.view];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.tableView.pullToRefreshView stopAnimating];
    }];
}

- (void)loadMore
{
    self.currentPage++;
    __weak typeof(self) weakSelf = self;
    [T8GroupAndCommunityService getDiscoveryGroupListWithPage:self.currentPage limit:DiscoverPageLimit timeStamp:self.timeStamp t8ID:T8CONTEXT.t8UserId success:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSArray *dataArr = [[dictRet objectForKey:@"data"] objectForKey:@"list"];
        [dataArr enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if ([obj isKindOfClass:[NSDictionary class]]) {
                TGGroupObject *model = [[TGGroupObject alloc] initWithDict:(NSDictionary *)obj];
                [strongSelf.upvoteList addObject:model];
            }
        }];
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

#pragma mark - getter


#pragma mark - UITableViewDelegate && UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView
{
    if (self.recommendList.count > 0 && self.upvoteList.count) {
        return 2;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *) __unused tableView numberOfRowsInSection:(NSInteger) __unused section
{
    if (section == 0) {
        return self.recommendList.count;
    }else{
        return self.upvoteList.count;
    }
}

- (CGFloat)tableView:(UITableView *) __unused tableView heightForRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    return [TGGroupInfoCell calculateHeightWithModel:nil];
}

- (NSString *)tableView:(UITableView *)__unused tableView titleForHeaderInSection:(NSInteger)__unused section
{
    if (section == 0) {
        return TGLocalized(@"Discover.Recommended");
    }else{
        return TGLocalized(@"Discover.MostUpvoted");
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    TGGroupInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[TGGroupInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    TGGroupObject *model = nil;
    if (indexPath.section == 0) {
        model = [self.recommendList objectAtIndex:indexPath.row];
    }else{
        model = [self.upvoteList objectAtIndex:indexPath.row];
    }
    
    [cell bindModel:model];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TGGroupObject *model = nil;
    if (indexPath.section == 0) {
        model = [self.recommendList objectAtIndex:indexPath.row];
    }else{
        model = [self.upvoteList objectAtIndex:indexPath.row];
    }
    
    TGGroupInfoBoardController *groupInfoBoard = [[TGGroupInfoBoardController alloc] initWithGroupObject:model];
    
    [self.navigationController pushViewController:groupInfoBoard animated:YES];
}


@end
