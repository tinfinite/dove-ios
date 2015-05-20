//
//  TGNotificationMsgModel.m
//  Telegraph
//
//  Created by 琦张 on 15/4/27.
//
//

#import "TGNotificationMsgModel.h"

@implementation TGNotificationMsgModel

- (id)initWithDict:(NSDictionary *)dict msgType:(NotificationMsgType)msgType
{
    self = [super init];
    if (self) {
        self.msgType = msgType;
        NSDictionary *dictRet = nil;
        if (msgType == NotificationMsgTypeCommentMe) {
            dictRet = dict[@"comment"];
            self.commentContent = [dictRet stringForKey:@"content" withDefault:@""];
            self.msgCreateTime = [dictRet stringForKey:@"create_at" withDefault:@""];
            self.commentId = [dictRet stringForKey:@"id" withDefault:@""];
        }else if (msgType == NotificationMsgTypeVoteMe){
            self.msgCreateTime = [dict stringForKey:@"create_at" withDefault:@""];
            self.voteAction = [dict stringForKey:@"action" withDefault:@""];
        }
        
        dictRet = dict[@"post"];
        self.postImage = (dictRet[@"content"])[@"image"];
        self.postText = (dictRet[@"content"])[@"text"];
        self.postCreateTime = [dictRet stringForKey:@"create_at" withDefault:@""];
        self.postId = [dictRet stringForKey:@"id" withDefault:@""];
        
        dictRet = dict[@"user"];
        self.userAvatar = [dictRet stringForKey:@"avatar" withDefault:@""];
        self.userFirstName = [dictRet stringForKey:@"first_name" withDefault:@""];
        self.userLastName = [dictRet stringForKey:@"last_name" withDefault:@""];
        self.userId = [dictRet stringForKey:@"id" withDefault:@""];
        self.userTgId = [dictRet stringForKey:@"tg_user_id" withDefault:@""];
        self.userName = [dictRet stringForKey:@"username" withDefault:@""];
        self.name = [self getName];
    }
    return self;
}

- (NSString *)getName
{
    NSString *name = @"";
    
    if (self.userName.length) {
        name = self.userName;
    }else{
        name = [self.userFirstName stringByAppendingFormat:@"%@",self.userLastName];
    }
    return name;
}

@end
