//
//  TGJoinRequestModel.m
//  Telegraph
//
//  Created by yewei on 15/2/16.
//
//

#import "TGJoinRequestObject.h"
#import "NSDictionary+Ext.h"

@implementation TGJoinRequestObject

- (id)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.joinRequestId = [dict stringForKey:@"id" withDefault:@""];
        self.message = [dict stringForKey:@"message" withDefault:@""];
        self.groupId = [dict stringForKey:@"telegram_group_id" withDefault:@""];
        self.userId = [dict stringForKey:@"telegram_user_id" withDefault:@""];
        self.avatar = [dict stringForKey:@"telegram_user_avatar" withDefault:@""];
        self.username = [dict stringForKey:@"telegram_username" withDefault:@""];
        self.creatTime = [dict stringForKey:@"create_at" withDefault:@""];
    }
    return self;
}

@end
