//
//  TGDiscoverManageViewController.h
//  Telegraph
//
//  Created by 琦张 on 15/2/15.
//
//

#import "TGCollectionMenuController.h"

#import "ASWatcher.h"

@interface TGDiscoverManageViewController : TGCollectionMenuController <ASWatcher>

@property (nonatomic, strong) ASHandle *actionHandle;
@property (nonatomic, strong) UIImage *groupAvatar;

- (instancetype)initWithConversationId:(int64_t)conversationId;

@end
