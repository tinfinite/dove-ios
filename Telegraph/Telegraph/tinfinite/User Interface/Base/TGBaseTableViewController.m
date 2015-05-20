//
//  TGBaseTableViewController.m
//  Telegraph
//
//  Created by 琦张 on 15/2/15.
//
//

#import "TGBaseTableViewController.h"
#import "TGInterfaceAssets.h"

@interface TGBaseTableViewController ()
{
    UIView *_headerBackgroundView;
}

@end

@implementation TGBaseTableViewController

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
    
    _headerBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.controllerInset.top)];
    _headerBackgroundView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_headerBackgroundView];
    
    [self.view addSubview:self.tableView];
    
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 49, 0);
}

#pragma mark - method
- (void)reloadData
{
    
}

- (void)loadMore
{
    
}

- (bool)shouldAdjustScrollViewInsetsForInversedLayout
{
    return true;
}

#pragma mark - getter
- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        [_tableView setTableFooterView:view];
    }
    return _tableView;
}

- (NSMutableArray *)dataArray
{
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableViewDelegate && UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *) __unused tableView numberOfRowsInSection:(NSInteger)__unused section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *) __unused tableView cellForRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    return nil;
}

@end
