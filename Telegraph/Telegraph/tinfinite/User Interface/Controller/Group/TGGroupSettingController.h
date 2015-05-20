//
//  TGGroupSettingController.h
//  Telegraph
//
//  Created by yewei on 15/4/10.
//
//

#import "TGCollectionMenuController.h"
#import "ASWatcher.h"

@interface TGGroupSettingController : TGCollectionMenuController<ASWatcher>

@property (nonatomic, strong) ASHandle *actionHandle;

- (instancetype)initWithConversationId:(int64_t)conversationId groupAvatar:(UIImage *)groupAvatar;

@end
