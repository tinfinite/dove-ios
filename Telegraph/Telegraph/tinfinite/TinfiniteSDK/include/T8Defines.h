//
//  T8Defines.h
//  Telegraph
//
//  Created by 琦张 on 15/2/8.
//
//

#ifndef Telegraph_T8Defines_h
#define Telegraph_T8Defines_h

#define T8CONTEXT  [T8Context getInstance]

typedef enum {
    GroupDiscoverPrivilegePublic = 0,
    GroupDiscoverPrivilegePrivate = 1,
    GroupDiscoverPrivilegeUnknow = 2
}GroupDiscoverPrivilege;

typedef NS_ENUM(NSInteger, GroupBoardStatus) {
    GroupBoardStatusUnknow = 0,
    GroupBoardStatusPublic = 1,
    GroupBoardStatusPrivate = 2
};

typedef NS_ENUM(NSInteger, GroupJoinRequestType)
{
    GroupJoinRequestTypeDelete      = 0,
    GroupJoinRequestTypeRefuse      = 3,
    GroupJoinRequestTypeApprove     = 2,
};

typedef NS_ENUM(NSInteger, PostPublishType) {
    PostPublishTypeGroupBoard = 0,
    PostPublishTypePublishStream = 1,
    PostPublishTypeBoth = 2
};

typedef NS_ENUM(NSInteger, PostSourceType)
{
    PostSourceTypeForward = 1,
    PostSourceTypePublish = 2
};

typedef NS_ENUM(NSInteger, StreamType)
{
    StreamTypeGroup     = 0,
    StreamTypePublic    = 1,
    StreamTypeMyPost    = 2
};

typedef NS_ENUM(NSInteger, SortType)
{
    SortTypeLatest = 0,
    SortTypeHotest = 1
};

typedef NS_ENUM(NSInteger, ForwardMessageType)
{
    ForwardMessageTypeText = 1,
    ForwardMessageTypePhoto = 2
};

typedef NS_ENUM(NSInteger, PublishEnteranceType)
{
    PublishEnteranceTypeGroupBoard = 1,
    PublishEnteranceTypePublishStream = 2
};

typedef NS_ENUM(NSInteger, RecentItemTextType) {
    RecentItemTextTypeSend = 0,
    RecentItemTextTypeAttach = 1
};

typedef NS_ENUM(NSInteger, NotificationType) {
    NotificationTypeComment = 1,
    NotificationTypeUpvote = 2,
    NotificationTypeReplyGroup = 3
};

typedef NS_ENUM(NSInteger, NotificationMsgType) {
    NotificationMsgTypeUnknown = 0,
    NotificationMsgTypeCommentMe = 1,
    NotificationMsgTypeVoteMe = 2
};

// 单例模式
#undef	AS_SINGLETON
#define AS_SINGLETON( __class ) \
+ (__class *)sharedInstance;

#undef	DEF_SINGLETON
#define DEF_SINGLETON( __class ) \
+ (__class *)sharedInstance \
{ \
static dispatch_once_t once; \
static __class * __singleton__; \
dispatch_once( &once, ^{ __singleton__ = [[self alloc] init]; } ); \
return __singleton__; \
}

//屏幕宽度
#define SCREEN_WIDTH ([[UIScreen mainScreen]bounds].size.width)
//屏幕高度
#define SCREEN_HEIGHT ([[UIScreen mainScreen]bounds].size.height)
//iPhone 屏幕尺寸
#define PHONE_SCREEN_SIZE (CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT - PHONE_STATUSBAR_HEIGHT))

//正式环境
//#define kAppBaseURL  @"api.tinfinite.com"

//测试服务器域名
#define kAppBaseURL  @"182.92.225.70"

//张元
//#define kAppBaseURL  @"192.168.1.12:3000"

//API版本号
#define API_VERSION @"/v1.2"

//用此键值从返回结果的dict中获取网络请求对应的yqNetworkIdString, 表示当前发送的网络请求的唯一标示
#define KYQNetworkIdString  @"KYQNetworkIdString"

//网络请求底层失败的原因
#define KYQNetworkErrorMsg  @"KYQNetworkErrorMsg"

//网络请求日志开关
#define OPEN_NETWORK_LOG  1

#define NodeCommentPageLimit 20

//用户协议地址
#define DoveUserTermsUrl @"http://dove.tinfinite.com/terms.html"

//Notification Keys
#define Notification_Key_Stick_Changed @"Notification_Key_Stick_Changed"
#define Notification_Key_Vote_Changed @"Notification_Key_Vote_Changed"
#define Notification_Key_Post_Delete @"Notification_Key_Post_Delete"
#define Notification_Key_User_Blocked @"Notification_Key_User_Blocked"
#define Notification_Key_User_Unblocked @"Notification_Key_User_Unblocked"
#define Notification_Key_New_Post @"Notification_Key_New_Post"

//UserDefaultKey
#define UserDefaultKey_AccessToken @"UserDefaultKey_AccessToken"
#define UserDefaultKey_Server_AccessToken_CreateTime @"UserDefaultKey_Server_AccessToken_CreateTime"
#define UserDefaultKey_Server_AccessToken_ExpireTime @"UserDefaultKey_Server_AccessToken_ExpireTime"
#define UserDefaultKey_Local_AccessToken_CreateTime @"UserDefaultKey_Local_AccessToken_CreateTime"
#define UserDefaultKey_T8_UserId @"UserDefaultKey_T8_UserId"
#define UserDefaultKey_Anonymous @"UserDefaultKey_Anonymous"
#define UserDefaultKey_CurrentAvatarKey @"UserDefaultKey_CurrentAvatarKey"
#define UserDefaultKey_VersaionAlertID @"UserDefaultKey_VersaionAlertID"
#define UserDefaultKey_UserSyncInfo @"UserDefaultKey_UserSyncInfo"

//Store Keys
#define StoreKey_MessageVoteInfo @"StoreKey_MessageVoteInfo"

#define GroupBoardIntroKey_Post @"GroupBoardIntroKey_Post"
#define GroupBoardIntroKey_Bottom @"GroupBoardIntroKey_Bottom"

#define Notification_Key_ReceiveComment @"Notification_Key_ReceiveComment"
#define Notification_Key_ReceiveUpvote @"Notification_Key_ReceiveUpvote"

#endif
