//
//  TGReplyGroupViewController.h
//  Telegraph
//
//  Created by yewei on 15/3/10.
//
//

#import "TGCollectionMenuController.h"
#import "ASWatcher.h"

@interface TGReplyGroupViewController : TGCollectionMenuController <ASWatcher>

@property (nonatomic, strong) ASHandle *actionHandle;

- (instancetype)initWithConversationId:(int64_t)conversationId groupName:(NSString *)groupName groupAvatar:(UIImage *)groupAvatar groupDescription:(NSString *)groupDescription;

- (instancetype)initWithConversationId:(int64_t)conversationId groupName:(NSString *)groupName groupAvatarKey:(NSString *)groupAvatarKey groupDescription:(NSString *)groupDescription;

@end
