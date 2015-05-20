//
//  T8UserHttpRequestService.h
//  Telegraph
//
//  Created by yewei on 15/2/14.
//
//

#import <Foundation/Foundation.h>

@interface T8UserHttpRequestService : NSObject

+ (void)getAccessToken:(NSString *)appId
                     appUserId:(int)appUserId
                  successBlock:(RequestSuccess)successBlock
                  failureBlock:(RequestFailuer)failureBlock;

+ (void)bindUserWithPhone:(NSString *)phone
                         username:(NSString *)username
                        firstName:(NSString *)firstName
                         lastName:(NSString *)lastName
                      accessToken:(NSString *)accessToken
                     successBlock:(RequestSuccess)successBlock
                     failureBlock:(RequestFailuer)failureBlock;

+ (void)callDoveBotWithClientId:(int)clientId
                          phone:(NSString *)phone
                         locale:(NSString *)locale
                       platform:(NSString *)platform
                            app:(NSString *)app
                   successBlock:(RequestSuccess)successBlock
                   failureBlock:(RequestFailuer)failureBlock;

//更新用户最新的版本信息，没有回调
+ (void)updateUserLatestVersionInfo;

//向服务端同步用户的信息
+ (void)updateUserInfoToServer;

//同步通知设置
+ (void)updateUserNotificationSettingsWithCommentNotify:(NSInteger)commentNotify
                                           upvoteNotify:(NSInteger)upvoteNotify
                                       applyGroupNotify:(NSInteger)applyGroupNotify
                                           successBlock:(RequestSuccess)successBlock
                                           failureBlock:(RequestFailuer)failureBlock;


@end
