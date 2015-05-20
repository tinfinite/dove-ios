//
//  TGNodeForwardModel.m
//  Telegraph
//
//  Created by 琦张 on 15/3/30.
//
//

#import "TGNodeForwardModel.h"
#import "TGNodePhotoObject.h"
#import "NSString+Valid.h"

@interface TGNodeForwardModel ()


@end

@implementation TGNodeForwardModel

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (dict == nil) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.dataDict = [dict copy];
        self.comment = [dict stringForKey:@"comment" withDefault:@""];
        self.groupId = [NSString stringWithFormat:@"%@",[dict objectForKey:@"third_group_id"]];
        self.groupName = [dict stringForKey:@"third_group_name" withDefault:@""];
        self.groupAvatar = [dict stringForKey:@"third_group_image" withDefault:@""];
        self.groupAvatarKey = [dict stringForKey:@"third_group_image_key" withDefault:@""];
        
        self.messages = [NSMutableArray array];
        self.textMsgs = [NSMutableArray array];
        self.photoMsgs = [NSMutableArray array];
        NSArray *content = [dict arrayForKey:@"content" withDefault:nil];
        if (content) {
            NSInteger index = 0;
            
            for (NSDictionary *messageDict in content) {
                TGNodeForwardMessageModel *message = [[TGNodeForwardMessageModel alloc] initWithDict:messageDict];
                if (message) {
                    [self.messages addObject:message];
                    if (message.msgType == ForwardMessageTypeText) {
                        [self.textMsgs addObject:message];
                    }else if (message.msgType == ForwardMessageTypePhoto){
                        TGNodePhotoObject *object = [[TGNodePhotoObject alloc] initWithOriginUrl:message.msgContent];
                        object.pictureIndexInPost = index;
                        [self.photoMsgs addObject:object];
                        message.photoObj = object;
                        index++;
                    }
                }
            }
        }
        self.commentHeight = [self getCommentHeight];
    }
    return self;
}

- (CGFloat)getCommentHeight
{
    if (self.comment.length) {
        return [self.comment heightForSize:CGSizeMake(SCREEN_WIDTH - 30, 155) font:[UIFont systemFontOfSize:16.0f]];
    }else{
        return 0;
    }
}

@end
