//
//  TGNodeDetailViewController.h
//  Telegraph
//
//  Created by 琦张 on 15/3/31.
//
//

#import "TGBaseTableViewController.h"
#import "TGNodeModel.h"
#import "ASWatcher.h"

@interface TGNodeDetailViewController : TGBaseTableViewController<ASWatcher>

- (id)initWithNodeID:(NSString *)nodeId groupId:(int64_t)groupId streamType:(StreamType)streamType;
- (id)initWithNodeModel:(TGNodeModel *)nodeModel;

@property (nonatomic,strong) ASHandle *actionHandle;

@property (nonatomic,assign) BOOL wantReply;

@end
