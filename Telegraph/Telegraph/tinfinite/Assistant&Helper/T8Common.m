//
//  T8Common.m
//  Telegraph
//
//  Created by yewei on 15/5/19.
//
//

#import "T8Common.h"
#import "NSMutableDictionary+Ext.h"
#import "TGDatabase.h"
#import "TGNodeDataManager.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "TGAlertView.h"
#import "APService.h"
#import "T8UserHttpRequestService.h"
#import "T8GroupAndCommunityService.h"
#import "T8NodeHttpRequestService.h"
#import "TGTelegraph.h"
#import "TGAppDelegate.h"

@implementation T8Common

+ (void)storeNodeAfterPublishWithForward:(NSString *)forward post:(NSString *)post isPublic:(PostPublishType)isPublic type:(PostSourceType)type groupId:(int64_t)groupID successData:(NSDictionary *)data
{
    NSString *postId = [data objectForKey:@"post_id"];
    if (postId.length>0) {
        NSMutableDictionary *nodeDict = [NSMutableDictionary dictionary];
        [nodeDict addObject:postId forKey:@"id"];
        [nodeDict addObject:@(type) forKey:@"type"];
        [nodeDict addObject:@(isPublic) forKey:@"is_public"];
        [nodeDict addObject:[NSDate getT8TimeStamp] forKey:@"create_at"];
        [nodeDict addObject:@(0) forKey:@"total_score"];
        [nodeDict addObject:@(0) forKey:@"total_reply"];
        [nodeDict addObject:@(0) forKey:@"is_upvote"];
        [nodeDict addObject:@(0) forKey:@"is_downvote"];
        NSMutableDictionary *authorDict = [NSMutableDictionary dictionary];
        [authorDict addObject:T8CONTEXT.t8UserId forKey:@"id"];
        TGUser *user = [TGDatabaseInstance() loadUser:T8CONTEXT.tgUserId];
        [authorDict addObject:user.photoUrlSmall forKey:@"avatar"];
        [authorDict addObject:T8CONTEXT.firstName forKey:@"first_name"];
        [authorDict addObject:T8CONTEXT.lastName forKey:@"last_name"];
        [authorDict addObject:T8CONTEXT.username forKey:@"username"];
        [authorDict addObject:@(T8CONTEXT.tgUserId).stringValue forKey:@"tg_user_id"];
        [authorDict addObject:@"" forKey:@"locale"];
        [nodeDict addObject:authorDict forKey:@"author"];
        NSDictionary *forwardDict = [NSJSONSerialization JSONObjectWithData:[forward dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
        [nodeDict addObject:forwardDict forKey:@"forward"];
        NSDictionary *postDict = [NSJSONSerialization JSONObjectWithData:[post dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
        [nodeDict addObject:postDict forKey:@"post"];
        if (isPublic == PostPublishTypePublishStream || isPublic == PostPublishTypeBoth) {
            [[TGNodeDataManager sharedInstance] storeNodes:@[nodeDict] streamType:StreamTypePublic];
        }
        if (isPublic == PostPublishTypeGroupBoard || isPublic == PostPublishTypeBoth) {
            [[TGNodeDataManager sharedInstance] storeNodes:@[nodeDict] streamType:StreamTypeGroup];
        }
        
        NSMutableDictionary *nodeInfo = [NSMutableDictionary dictionary];
        [nodeInfo addObject:@(isPublic) forKey:@"ispublic"];
        [nodeInfo addObject:@(groupID) forKey:@"groupid"];
        [nodeInfo addObject:postId forKey:@"postid"];
        [[NSNotificationCenter defaultCenter] postNotificationName:Notification_Key_New_Post object:nodeInfo];
    }
}

+ (void)storeNodesAfterGetNodeStreamWithConversationId:(NSString *)conversationId isPublic:(StreamType)isPublic sortType:(SortType) __unused sortType successData:(NSDictionary *)data
{
    NSArray *nodeArray = [data objectForKey:@"data"];
    [[TGNodeDataManager sharedInstance] storeNodes:nodeArray streamType:isPublic];
    NSArray *nodeIDs = [data objectForKey:@"ids"];
    [[TGNodeDataManager sharedInstance] storeStreamWithType:isPublic conversationId:conversationId.integerValue nodeIDs:nodeIDs];
}

+ (void)storeNodesAfterGetNodeStreamWithNodeIds:(NSArray *) __unused ids isPublic:(StreamType)isPublic successData:(NSDictionary *)data
{
    NSArray *nodeArray = [data objectForKey:@"data"];
    [[TGNodeDataManager sharedInstance] storeNodes:nodeArray streamType:isPublic];
}

+ (void)storePostsWithSuccessData:(NSDictionary *)data streamType:(StreamType)streamType
{
    NSArray *nodeArray = [data objectForKey:@"data"];
    [[TGNodeDataManager sharedInstance] storeNodes:nodeArray streamType:streamType];
}

+ (NSString *)createMessageKeyWithMid:(int32_t)mid fromUid:(int64_t)fromUid toUid:(int64_t)toUid date:(NSTimeInterval)date
{
    NSArray *messages = [TGDatabaseInstance() getSameSecondMessageWithFromUid:fromUid toUid:toUid date:date];
    __block NSString *messageKey = @"";
    [messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL __unused *stop) {
        TGMessage *message = (TGMessage *)obj;
        if (message.mid == mid) {
            messageKey = [NSString stringWithFormat:@"%lld_%lld_%.0f_%lu",fromUid,ABS(toUid),date,(unsigned long)idx];
        }
    }];
    return messageKey;
}

+ (void)storeVoteInfoForMessage:(int32_t)messageID successData:(NSDictionary *)data
{
    NSString *action = [data stringForKey:@"action" withDefault:@""];
    if ([action isEqualToString:@"up"]) {
        [TGDatabaseInstance() storeVoteInfoForMessage:messageID count:INT_MIN upVote:YES downVote:NO];
        [T8HudHelper showHUDMessage:TGLocalized(@"Vote.VoteUp")];
    }else if ([action isEqualToString:@"cancel up"]){
        [TGDatabaseInstance() storeVoteInfoForMessage:messageID count:INT_MIN upVote:NO downVote:NO];
        [T8HudHelper showHUDMessage:TGLocalized(@"Vote.CancelVoteUp")];
    }else if ([action isEqualToString:@"down"]) {
        [TGDatabaseInstance() storeVoteInfoForMessage:messageID count:INT_MIN upVote:NO downVote:YES];
        [T8HudHelper showHUDMessage:TGLocalized(@"Vote.VoteDown")];
    }else if ([action isEqualToString:@"cancel down"]){
        [TGDatabaseInstance() storeVoteInfoForMessage:messageID count:INT_MIN upVote:NO downVote:NO];
        [T8HudHelper showHUDMessage:TGLocalized(@"Vote.CancelVoteDown")];
    }
}

+ (void)bindTinfiniteUser
{
    [T8UserHttpRequestService getAccessToken:T8CONTEXT.appKey appUserId:T8CONTEXT.tgUserId successBlock:^(NSDictionary __unused *dictRet) {
        [T8UserHttpRequestService bindUserWithPhone:T8CONTEXT.phone username:T8CONTEXT.username firstName:T8CONTEXT.firstName lastName:T8CONTEXT.lastName accessToken:T8CONTEXT.accessToken successBlock:^(NSDictionary *dictRet) {
            T8CONTEXT.t8UserId = dictRet[@"tinfinite_user_id"];
            [APService setAlias:T8CONTEXT.t8UserId callbackSelector:nil object:nil];
            [[NSUserDefaults standardUserDefaults] setObject:dictRet[@"tinfinite_user_id"] forKey:UserDefaultKey_T8_UserId];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            //如果发现是新用户，调用机器人接口
            if ([dictRet[@"newer"] boolValue] == YES) {
                NSArray *languages = [NSLocale preferredLanguages];
                NSString *currentLan = @"zh-Hans";
                if (languages.count>0) {
                    currentLan = languages.firstObject;
                }
                
                [T8UserHttpRequestService callDoveBotWithClientId:TGTelegraphInstance.clientUserId phone:T8CONTEXT.phone locale:currentLan platform:@"ios" app:@"dove" successBlock:^(NSDictionary __unused *dictRet) {
                    
                    
                    ABRecordRef record = ABPersonCreate();
                    CFErrorRef error;
                    ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFTypeRef)dictRet[@"first_name"], &error);
                    ABRecordSetValue(record, kABPersonLastNameProperty, (__bridge CFTypeRef)dictRet[@"last_name"], &error);
                    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABPersonPhoneProperty);
                    ABMultiValueAddValueAndLabel(multi, (__bridge CFTypeRef)dictRet[@"phone"], (__bridge CFTypeRef)@"phone", NULL);
                    ABRecordSetValue(record, kABPersonPhoneProperty, multi, &error);
                    ABAddressBookRef addressBook = nil;
                    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
                    {
                        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
                        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool __unused granted, CFErrorRef __unused error) {
                            dispatch_semaphore_signal(sema);
                        });
                        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                    }else{
                        addressBook = ABAddressBookCreateWithOptions(NULL, &error);;
                    }
                    
                    BOOL success = ABAddressBookAddRecord(addressBook, record, &error);
                    if (success) {
                        ABAddressBookSave(addressBook, &error);
                    }
                } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                    
                }];
            }
            
            NSDictionary *syncDict = [dictRet objectForKey:@"user_sync_info"];
            
            //同步屏蔽的用户信息
            NSArray *blockedUsers = [syncDict objectForKey:@"block_users"];
            [TGDatabaseInstance() coverBlockedUsers:blockedUsers];
            //同步通知
            [[NSUserDefaults standardUserDefaults] setObject:syncDict forKey:UserDefaultKey_UserSyncInfo];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            //如果发现匿名状态未设置，提示用户，并调用接口更改匿名总开关为public
            NSInteger anonymous = [[syncDict objectForKey:@"tg_group_anonymous_status"] integerValue];
            if (anonymous == 2) {
                TGAlertView *alert = [[TGAlertView alloc] initWithTitle:TGLocalized(@"Stream.AnonymousAlert") message:nil cancelButtonTitle:nil okButtonTitle:TGLocalized(@"Common.OK") completBlock:^(UIAlertView __unused *alert, bool okButtonPressed) {
                    T8CONTEXT.anonymous = NO;
                    if (okButtonPressed) {
                        [T8GroupAndCommunityService updateUserAnonymousInfo:T8CONTEXT.anonymous success:^(NSDictionary __unused *dictRet) {
                            
                        } fail:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                            
                        }];
                    }
                }];
                [alert show];
            }else if (anonymous == 1) {
                T8CONTEXT.anonymous = NO;
            }else{
                T8CONTEXT.anonymous = YES;
            }
            
            NSArray *groupInfos = [TGDatabaseInstance() loadGroupConversationInfo];
            //向服务器同步用户群组信息
            [T8GroupAndCommunityService synchronizeUserGroupsInfo:groupInfos];
            
            //更新用户最新版本信息
            [T8UserHttpRequestService updateUserLatestVersionInfo];
            
            //检查本地头像是否要更新到服务器
            TGUser *user = [TGDatabaseInstance() loadUser:T8CONTEXT.tgUserId];
            NSString *oldUserAvatar = [[NSUserDefaults standardUserDefaults] objectForKey:UserDefaultKey_CurrentAvatarKey];
            if (oldUserAvatar==nil || (oldUserAvatar && ![oldUserAvatar isEqualToString:user.photoUrlSmall])) {
                [T8UserHttpRequestService updateUserInfoToServer];
            }
            
            [T8NodeHttpRequestService getCommentsAndUpvotesUnreadCountWithSuccess:^(NSDictionary *dictRet) {
                NSDictionary *dataDict = dictRet[@"data"];
                int unreadCount = [dataDict[@"new_comments_count"] intValue] + [dataDict[@"new_upvotes_count"] intValue];
                TGDispatchOnMainThread(^{
                    [TGAppDelegateInstance.mainTabsController setUnreadCountForMe:unreadCount];
                });
            } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                
            }];
            
            //检查版本，提示更新
            NSDictionary *buildInfoDict = [dictRet objectForKey:@"build_info"];
            NSDictionary *iosDic = [buildInfoDict objectForKey:@"ios"];
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            NSString *appCurVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
            NSDictionary *versionDic = [iosDic objectForKey:appCurVersion];
            if (versionDic) {
                NSString *versionInfoId = [versionDic objectForKey:@"id"];
                NSString *oldVersionInfoId = [[NSUserDefaults standardUserDefaults] objectForKey:UserDefaultKey_VersaionAlertID];
                if (!(oldVersionInfoId && [oldVersionInfoId isEqualToString:versionInfoId])) {
                    NSString *title = [versionDic objectForKey:@"title"];
                    NSString *content = [versionDic objectForKey:@"content"];
                    NSString *link = [versionDic objectForKey:@"link"];
                    TGAlertView *alert = [[TGAlertView alloc] initWithTitle:title message:content cancelButtonTitle:TGLocalized(@"Common.Cancel") okButtonTitle:TGLocalized(@"Common.Update") completBlock:^(UIAlertView __unused *alert, bool okButtonPressed) {
                        if (okButtonPressed) {
                            [[NSUserDefaults standardUserDefaults] setObject:versionInfoId forKey:UserDefaultKey_VersaionAlertID];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
                        }
                    }];
                    [alert show];
                }
            }
            
        } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
            
        }];
    } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        
    }];
}

@end
