//
//  TGGroupInfoJoinRequestController.h
//  Telegraph
//
//  Created by yewei on 15/2/15.
//
//

#import "TGViewController.h"
#import "TGConversation.h"
#import "ASWatcher.h"
#import "TGTelegraph.h"

@interface TGGroupInfoJoinRequestController : TGViewController<ASWatcher>

@property (nonatomic,strong) ASHandle *actionHandle;

- (instancetype)initConversation:(TGConversation *)conversation;

@end
