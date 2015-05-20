//
//  T8Group&CommunityService.h
//  Telegraph
//
//  Created by 琦张 on 15/2/15.
//
//

#import <Foundation/Foundation.h>
#import "T8HttpClient.h"

typedef NS_ENUM(NSInteger, GroupAnonymousStatus)
{
    GroupAnonymous = 0,
    GroupUnanonymous
};

@interface T8GroupAndCommunityService : NSObject

+ (void)createCommunityWithThirdGroupID:(int64_t)groupID createrID:(NSString *)t8ID image:(NSString *)imageUrl memberCount:(NSInteger)memberCount privilege:(GroupDiscoverPrivilege)privilege name:(NSString *)name description:(NSString *)description language:(NSString *)language imageKey:(NSString *)imageKey success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

//暂时不再使用
+ (void)updateCommunityPrivilege:(int64_t)groupID privilege:(GroupDiscoverPrivilege)privilege image:(NSString *)imageUrl memberCount:(NSInteger)memberCount name:(NSString *)name description:(NSString *)description success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

+ (void)getDiscoveryGroupListWithPage:(NSInteger)page limit:(NSInteger)limit timeStamp:(NSString *)timeStamp t8ID:(NSString *)t8ID success:(RequestSuccess)successBlock failure:(RequestFailuer)failureBlock;

/**
 *  获取七牛上传图片的access token
 *
 *  @param successBlock
 *  @param failureBlock
 *
 *  @return
 */
+ (void)getQiniuAccessTokenWithSuccessBlock:(RequestSuccess)successBlock failureBlock:(RequestFailuer)failureBlock;

/**
 *  获取群组信息
 *
 *  @param groupID
 *  @param successBlock
 *  @param failureBlock
 *
 *  @return 
 */
+ (void)getGroupInfoWithID:(int64_t)groupID successBlock:(RequestSuccess)successBlock failureBlock:(RequestFailuer)failureBlock;

//同步用户群组匿名信息，暂未使用
+ (void)synchronizationAnonymousInfo:(NSArray *)groups successBlock:(RequestSuccess)successBlock failureBlock:(RequestFailuer)failureBlock;

//修改用户群组匿名信息
+ (void)updateAnonymousInfoWithGroupId:(NSString *)groupId status:(GroupAnonymousStatus)status successBlock:(RequestSuccess)successBlock failureBlock:(RequestFailuer)failureBlock;

//获取用户群组匿名信息
+ (void)getAnonymousInfoWithGroupId:(NSString *)groupId successBlock:(RequestSuccess)successBlock failureBlock:(RequestFailuer)failureBlock;

//修改匿名总开关状态
+ (void)updateUserAnonymousInfo:(BOOL)anonymous
                        success:(RequestSuccess)successBlock
                           fail:(RequestFailuer)failureBlock;

//同步用户群组信息，不需要回调，就是这么任性
+ (void)synchronizeUserGroupsInfo:(NSArray *)groupInfos;

@end
