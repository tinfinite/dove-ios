//
//  TGGroupModel.m
//  Telegraph
//
//  Created by 琦张 on 15/2/15.
//
//

#import "TGGroupObject.h"
#import "NSDictionary+Ext.h"

@implementation TGGroupObject

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.t8CommunityId = [dict stringForKey:@"id" withDefault:@""];
        self.creatorId = [dict stringForKey:@"creator_id" withDefault:@""];
        int64_t third_group_id = [dict stringForKey:@"third_group_id" withDefault:@""].longLongValue;
        self.conversationId = third_group_id>0?(-third_group_id):third_group_id;
        self.privilege = [dict intValueForKey:@"privilege" withDefault:-1];
        self.groupDesc = [dict stringForKey:@"description" withDefault:@""];
        self.createTime = [dict stringForKey:@"create_at" withDefault:@""];
        self.imageUrl = [dict stringForKey:@"image" withDefault:@""];
        self.memberCount = [dict intForKey:@"member_count" withDefault:1];
        self.groupName = [dict stringForKey:@"name" withDefault:@""];
        self.language = [dict stringForKey:@"language" withDefault:@""];
        self.points = [dict intForKey:@"points" withDefault:0];
        self.avatarKey = [dict stringForKey:@"third_group_image_key" withDefault:@""];
    }
    return self;
}

@end
