//
//  T8StickToTopManager.h
//  Telegraph
//
//  Created by 琦张 on 15/2/8.
//
//

#import <Foundation/Foundation.h>
#import "T8Defines.h"

#define UserDefaultKey_StickedGroups [NSString stringWithFormat:@"UserDefaultKey_StickedGroups_%d",TGTelegraphInstance.clientUserId]
#define UserDefaultKey_StickedUsers [NSString stringWithFormat:@"UserDefaultKey_StickedUsers_%d",TGTelegraphInstance.clientUserId]

#define UserDefaultKey_StickedConversations [NSString stringWithFormat:@"UserDefaultKey_StickedConversations_%d",TGTelegraphInstance.clientUserId]

@interface T8StickToTopManager : NSObject

AS_SINGLETON(T8StickToTopManager)

- (void)stickGroupWithConversationID:(int64_t)conversationId action:(BOOL)stick;
- (void)stickUserWithUserID:(NSInteger)userId action:(BOOL)stick;

- (BOOL)checkIsStickedWithConversationID:(int64_t)conversationId andUserID:(int64_t)userId;

- (void)stickConversationWithID:(NSString *)conversationId action:(BOOL)stick;

- (BOOL)checkConversationIsStickedWithID:(NSString *)conversationId;
- (NSComparisonResult)compareConversationID:(NSString *)conversationOne with:(NSString *)conversationTwo;

@end
