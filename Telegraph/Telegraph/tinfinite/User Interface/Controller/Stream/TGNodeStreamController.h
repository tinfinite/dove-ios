//
//  TGNodeStreamController.h
//  Telegraph
//
//  Created by yewei on 15/3/28.
//
//

#import "TGViewController.h"
#import "TGListsTableView.h"
#import "ASWatcher.h"

@interface TGNodeStreamController : TGViewController<ASWatcher>

@property (nonatomic,strong) ASHandle *actionHandle;

@property (nonatomic, strong) TGListsTableView *tableView;
@property (nonatomic, strong) NSMutableArray *listModel;

@property (nonatomic, strong) NSArray *nodeIds;
@property (nonatomic, assign) NSUInteger currentPage;

@property (nonatomic, assign) int64_t conversationId;

- (NSArray *)getNodeIdsByCurrentPage:(NSUInteger)currentPage;

@end
