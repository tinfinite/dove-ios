//
//  TGGroupInfoUpvoteMessageController.h
//  Telegraph
//
//  Created by yewei on 15/3/16.
//
//

#import "TGViewController.h"
#import "TGConversation.h"
#import "ActionStage.h"

@interface TGGroupInfoUpvoteMessageController : TGViewController<ASWatcher>

@property (nonatomic, strong, readonly) ASHandle *actionHandle;

- (instancetype)initConversation:(TGConversation *)conversation;

@end
