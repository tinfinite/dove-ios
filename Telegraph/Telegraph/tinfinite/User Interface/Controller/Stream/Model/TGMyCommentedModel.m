//
//  TGMyCommentedModel.m
//  Telegraph
//
//  Created by yewei on 15/4/22.
//
//

#import "TGMyCommentedModel.h"
#import "NSDictionary+Ext.h"

@implementation TGMyCommentedModel

- (id)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        NSDictionary *dictRet = dict[@"comment"];
        self.commentContent = [dictRet stringForKey:@"content" withDefault:@""];
        self.commentCreateTime = [dictRet stringForKey:@"create_at" withDefault:@""];
        self.commentId = [dictRet stringForKey:@"id" withDefault:@""];
        
        dictRet = dict[@"post"];
        self.postImage = [(dictRet[@"content"]) stringForKey:@"image" withDefault:@""];
        self.postText = [(dictRet[@"content"]) stringForKey:@"text" withDefault:@""];
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
