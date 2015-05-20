//
//  TGBaseTableViewController.h
//  Telegraph
//
//  Created by 琦张 on 15/2/15.
//
//

#import "TGViewController.h"

@interface TGBaseTableViewController : TGViewController<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *dataArray;
@property (nonatomic,assign) NSInteger currentPage;
@property (nonatomic,copy) NSString *timeStamp;

@end
