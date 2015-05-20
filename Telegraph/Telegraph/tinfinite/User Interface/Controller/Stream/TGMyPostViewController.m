//
//  TGMyPostViewController.m
//  Telegraph
//
//  Created by 琦张 on 15/4/22.
//
//

#import "TGMyPostViewController.h"
#import "T8NodeHttpRequestService.h"
#import "SVPullToRefresh.h"
#import "TGNodeDataManager.h"

@interface TGMyPostViewController ()

@end

@implementation TGMyPostViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"我发布的页面"];
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
    
    [self setTitleText:TGLocalized(@"Settings.MyPosts")];
    
    [self setRightBarButtonItem:nil];
}

- (void)prepareCacheData
{
    
}

- (void)refreshNodeStreamData
{
    self.currentPage = 1;
    
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService getMyPostsWithPage:self.currentPage limit:20 timestamp:self.timestamp success:^(NSDictionary *dictRet) {
        
        [T8Common storePostsWithSuccessData:dictRet streamType:StreamTypeGroup];
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSMutableArray *ids = [NSMutableArray array];
        NSArray *dataArr = [dictRet objectForKey:@"data"];
        [dataArr enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
            NSString *nodeid = [(NSDictionary *)obj objectForKey:@"id"];
            if (nodeid && nodeid.length>0) {
                [ids addObject:nodeid];
            }
        }];
        strongSelf.listModel = [[[TGNodeDataManager sharedInstance] loadNodes:ids streamType:StreamTypeGroup] mutableCopy];
        [strongSelf.tableView reloadData];
        
        [strongSelf.tableView.pullToRefreshView stopAnimating];
        
        if (ids.count==0) {
            [strongSelf.tableView setShowsInfiniteScrolling:NO];
        }else{
            strongSelf.currentPage++;
        }
        
        [strongSelf.tableView setShowsInfiniteScrolling:YES];
        
    } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.tableView.pullToRefreshView stopAnimating];
    }];
    
//    [T8NodeHttpRequestService getNodeStreamWithConversationId:nil isPublic:StreamTypePublic sortType:SortTypeLatest successBlock:^(NSDictionary *dictRet)
//     {
//         __strong typeof(self) strongSelf = weakSelf;
//         strongSelf.nodeIds = [NSArray arrayWithArray:[dictRet objectForKey:@"ids"]];
//         
//         strongSelf.listModel = [[[TGNodeDataManager sharedInstance] loadNodes:[strongSelf getNodeIdsByCurrentPage:strongSelf.currentPage] streamType:StreamTypePublic] mutableCopy];
//         [strongSelf.tableView reloadData];
//         
//         [strongSelf.tableView.pullToRefreshView stopAnimating];
//         
//         strongSelf.currentPage++;
//         
//     } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
//         __strong typeof(weakSelf) strongSelf = weakSelf;
//         [strongSelf.tableView.pullToRefreshView stopAnimating];
//     }];
}

- (void)reloadMoreNodeStreamData
{
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService getMyPostsWithPage:self.currentPage limit:20 timestamp:self.timestamp success:^(NSDictionary *dictRet) {
        
        [T8Common storePostsWithSuccessData:dictRet streamType:StreamTypeGroup];
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSMutableArray *ids = [NSMutableArray array];
        NSArray *dataArr = [dictRet objectForKey:@"data"];
        [dataArr enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
            NSString *nodeid = [(NSDictionary *)obj objectForKey:@"id"];
            if (nodeid && nodeid.length>0) {
                [ids addObject:nodeid];
            }
        }];
        [strongSelf.listModel addObjectsFromArray:[[TGNodeDataManager sharedInstance] loadNodes:ids streamType:StreamTypeGroup]];
        [strongSelf.tableView reloadData];
        
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
        
        if (ids.count==0) {
            [strongSelf.tableView setShowsInfiniteScrolling:NO];
        }else{
            strongSelf.currentPage++;
        }
        
    } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
    }];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
