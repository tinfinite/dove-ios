//
//  T8GroupHttpRequestService.h
//  Telegraph
//
//  Created by yewei on 15/2/15.
//
//

#import <Foundation/Foundation.h>
#import "T8HttpClient.h"

@interface T8GroupHttpRequestService : NSObject

+ (void)applyJoinInGroupWithGroupId:(NSString *)groupId
                           tgUserId:(int)userId
                           username:(NSString *)username
                             avatar:(NSString *)avatar
                            message:(NSString *)message
                        accessToken:(NSString *)accessToken
                       successBlock:(RequestSuccess)successBlock
                       failureBlock:(RequestFailuer)failureBlock;

+ (void)getJoinRequestListWithGroupId:(NSString *)groupId
                                 page:(NSInteger)page
                                limit:(int)limit
                            timestamp:(long long)timestamp
                          accessToken:(NSString *)accessToken
                         successBlock:(RequestSuccess)successBlock
                         failureBlock:(RequestFailuer)failureBlock;

+ (void)updateJoinRequestWithApplyId:(NSString *)applyId
                              status:(GroupJoinRequestType)status
                         accessToken:(NSString *)accessToken
                        successBlock:(RequestSuccess)successBlock
                        failureBlock:(RequestFailuer)failureBlock;

+ (void)getGroupBoardUnreadCountWithGroupId:(NSString *)groupId
                                    success:(RequestSuccess)successBlock
                                    failure:(RequestFailuer)failureBlock;

+ (void)getAllGroupBoardUnreadCount:(NSArray *)groupIds
                            success:(RequestSuccess)successBlock
                            failure:(RequestFailuer)failureBlock;


@end
