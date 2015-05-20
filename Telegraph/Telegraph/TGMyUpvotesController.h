//
//  TGMyUpvotesController.h
//  Telegraph
//
//  Created by yewei on 15/3/19.
//
//

#import "TGViewController.h"
#import "TGConversation.h"
#import "ActionStage.h"

@interface TGMyUpvotesController : TGViewController<ASWatcher>

@property (nonatomic, strong, readonly) ASHandle *actionHandle;

- (instancetype)initConversation:(TGConversation *)conversation;

@end
