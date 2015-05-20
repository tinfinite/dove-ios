//
//  TGGroupInfoBoardController.h
//  Telegraph
//
//  Created by yewei on 15/4/1.
//
//

#import "TGViewController.h"
#import "TGNodeStreamController.h"
#import "TGGroupObject.h"

@interface TGGroupInfoBoardController : TGNodeStreamController

- (id)initWithConversationId:(int64_t)conversationId;

- (id)initWithGroupObject:(TGGroupObject *)groupObject;

@end
