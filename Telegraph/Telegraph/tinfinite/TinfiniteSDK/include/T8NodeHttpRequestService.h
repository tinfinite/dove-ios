//
//  T8NodeHttpRequestService.h
//  Telegraph
//
//  Created by yewei on 15/3/26.
//
//

#import <Foundation/Foundation.h>
#import "T8HttpClient.h"

@interface T8NodeHttpRequestService : T8HttpClient

+ (void)publishNodeWithForward:(NSString *)forward
                          post:(NSString *)post
                      isPublic:(PostPublishType)isPublic
                          type:(PostSourceType)type
                       groupId:(int64_t)groupID
                  successBlock:(RequestSuccess)successBlock
                  failureBlock:(RequestFailuer)failureBlock;

+ (void)getNodeStreamWithConversationId:(NSString *)conversationId
                               isPublic:(StreamType)isPublic
                               sortType:(SortType)sortType
                           successBlock:(RequestSuccess)successBlock
                           failureBlock:(RequestFailuer)failureBlock;

+ (void)getNodeStreamWithNodeIds:(NSArray *)ids
                        isPublic:(StreamType)isPublic
                    successBlock:(RequestSuccess)successBlock
                    failureBlock:(RequestFailuer)failureBlock;

/**
 *  顶某个node
 */
+ (void)praiseNodeWithID:(NSString *)nodeId streamID:(NSString *)streamId successBlock:(RequestSuccess)successBlock failureBlock:(RequestFailuer)failureBlock;

/**
 *  踩某个node
 */
+ (void)stepNodeWithID:(NSString *)nodeId streamID:(NSString *)streamId successBlock:(RequestSuccess)successBlock failureBlock:(RequestFailuer)failureBlock;

/**
 *  获取某个node的评论列表
 *
 *  @param postId
 *  @param page
 *  @param limit
 *  @param timestamp
 *  @param successBlock
 *  @param failureBlock
 *
 *  @return
 */
+ (void)getNodeCommentListWithPostID:(NSString *)postId page:(NSInteger)page limit:(NSInteger)limit timestamp:(NSString *)timestamp success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

/**
 *  对某个node发评论
 *
 *  @param postId
 *  @param content
 *  @param successBlock
 *  @param failureBlock
 *
 *  @return
 */
+ (void)postNodeCommentWithPostID:(NSString *)postId content:(NSString *)content streamId:(NSString *)streamId success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

/**
 *  删除node
 *
 *  @param postId
 *  @param successBlock
 *  @param failureBlock
 *
 *  @return 
 */
+ (void)deleteNodeWithID:(NSString *)postId success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

/**
 *  屏蔽某个用户的post
 *
 *  @param userId
 *  @param successBlock
 *  @param failureBlock
 *
 *  @return 
 */
+ (void)blockUserWithTGID:(NSString *)tgUserId andT8ID:(NSString *)t8UserId blockAction:(BOOL)block success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

//获取对我的评论
+ (void)getMyCommentsWithPage:(NSInteger)page limit:(NSInteger)limit timestamp:(NSString *)timestamp success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

+ (void)getMyPostsWithPage:(NSInteger)page limit:(NSInteger)limit timestamp:(NSString *)timestamp success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

//获取评论和投票的未读消息数
+ (void)getCommentsAndUpvotesUnreadCountWithSuccess:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

+ (void)getVoteForMeMessagesWithPage:(NSInteger)page limit:(NSInteger)limit timestamp:(NSString *)timestamp success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

@end
