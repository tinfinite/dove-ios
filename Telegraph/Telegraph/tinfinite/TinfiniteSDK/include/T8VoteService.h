//
//  T8VoteService.h
//  Telegraph
//
//  Created by 琦张 on 15/3/17.
//
//

#import <Foundation/Foundation.h>

@interface T8VoteService : NSObject

+ (void)upvoteMessage:(int32_t)messageID messageKey:(NSString *)msgKey cid:(int64_t)cid text:(NSString *)text success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

+ (void)downvoteMessage:(int32_t)messageID messageKey:(NSString *)msgKey cid:(int64_t)cid text:(NSString *)text success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

+ (void)queryVoteInfo:(NSArray *)idList ids:(NSString *)ids conversationID:(int64_t)conversationID success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

+ (void)getMyUpvoteMessagesWithSuccess:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

+ (void)getGroupUpvoteMessagesWithconversationID:(int64_t)conversationID success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

+ (void)getMyUpvotePostsWithPage:(NSInteger)page limit:(NSInteger)limit timestamp:(NSString *)timestamp success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

@end
