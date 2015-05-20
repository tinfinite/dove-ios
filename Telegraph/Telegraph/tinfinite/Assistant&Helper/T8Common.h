//
//  T8Common.h
//  Telegraph
//
//  Created by yewei on 15/5/19.
//
//

#import <Foundation/Foundation.h>

@interface T8Common : NSObject

+ (void)storeNodeAfterPublishWithForward:(NSString *)forward post:(NSString *)post isPublic:(PostPublishType)isPublic type:(PostSourceType)type groupId:(int64_t)groupID successData:(NSDictionary *)data;

+ (void)storeNodesAfterGetNodeStreamWithConversationId:(NSString *)conversationId isPublic:(StreamType)isPublic sortType:(SortType)sortType successData:(NSDictionary *)data;

+ (void)storeNodesAfterGetNodeStreamWithNodeIds:(NSArray *)ids isPublic:(StreamType)isPublic successData:(NSDictionary *)data;

+ (void)storePostsWithSuccessData:(NSDictionary *)data streamType:(StreamType)streamType;

+ (NSString *)createMessageKeyWithMid:(int32_t)mid fromUid:(int64_t)fromUid toUid:(int64_t)toUid date:(NSTimeInterval)date;

+ (void)storeVoteInfoForMessage:(int32_t)messageID successData:(NSDictionary *)data;

+ (void)bindTinfiniteUser;

@end
