//
//  TGSelectAtUserController.h
//  Telegraph
//
//  Created by yewei on 15/2/8.
//
//

#import "TGViewController.h"

#import "TGCollectionMenuController.h"
#import "ASWatcher.h"

@protocol TGSelectAtUserControllerDelegate <NSObject>

- (void)didSelectAtUser:(int)uid;

@end

@interface TGSelectAtUserController : TGCollectionMenuController <ASWatcher>

@property (nonatomic, weak) id<TGSelectAtUserControllerDelegate> delegate;
@property (nonatomic, strong) ASHandle *actionHandle;

- (instancetype)initWithConversationId:(int64_t)conversationId;

@end
